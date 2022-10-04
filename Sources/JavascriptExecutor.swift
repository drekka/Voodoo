//
//  File.swift
//
//
//  Created by Derek Clarkson on 29/9/2022.
//

import Foundation
import Hummingbird
import JXKit
import NIOCore

/// Defines the response returned from executing a javascript response generator.
struct JavascriptCallResponse: Decodable {
    let statusCode: UInt
    let headers: [String: String]
    let body: HTTPResponse.Body
}

/// Wraps up the initialisation an execution of javascript based API responses.
struct JavascriptExecutor {

    let jsCtx = JXContext()
    let serverCtx: SimulcraContext

    init(forContext serverCtx: SimulcraContext) throws {

        self.serverCtx = serverCtx

        try redirectLogging()

        // Inject dependencies.
        try injectTypes()
    }

    func execute(script: String, for _: HTTPRequest) throws -> JavascriptCallResponse {

        // Load the script into the context then retrieve the function.
        do {
            try jsCtx.eval(script)
        } catch {
            throw SimulcraError.javascriptError("Error evaluating javascript: \(error)")
        }

        // Extract the function.
        let responseFunction = try jsCtx.global["response"]
        guard responseFunction.isFunction else {
            throw SimulcraError.javascriptError("The executed javascript does not contain a function with the signature 'response(request, cache)'.")
        }

        // Call it.
        let rawResponse: JXValue
        do {
            rawResponse = try responseFunction.call(withArguments: [
                // try jsCtx.encode(request.javascriptObject),
                jsCtx.object(),
                serverCtx.cache.asJavascriptObject(in: jsCtx),
            ])
        } catch {
            throw SimulcraError.javascriptError("Javascript execution failed. Error: \(error)")
        }

        if rawResponse.isUndefined {
            throw SimulcraError.javascriptError("The javascript function failed to return a response.")
        }

        do {
            return try rawResponse.toDecodable(ofType: JavascriptCallResponse.self) as JavascriptCallResponse
        } catch {
            throw SimulcraError.javascriptError("The javascript function returned an invalid response. Make sure you are using the 'Response' object to generate a response. Returned error: \(error)")
        }
    }

    private func redirectLogging() throws {
        // Update the log function to print log messages.
        let myFunction = JXValue(newFunctionIn: jsCtx) { context, _, messages in
            messages.forEach { print("Javascript: \($0)") }
            return context.undefined()
        }
        try jsCtx.global["console"].setProperty("log", myFunction)
    }

    private func injectTypes() throws {

        try jsCtx.eval(#"""

        class Response {

            static raw(code, body, headers) {
                return {
                    statusCode: code,
                    body: body ?? Body.empty(),
                    headers: headers ?? {}
                };
            }

            static ok(body, headers) {
                return this.raw(200, body, headers);
            }
        }

        class Body {

            static empty() {
                return {
                    type: "empty"
                };
            }

            static text(text, templateData) {
                return {
                    type: "text",
                    text: text,
                    templateData: templateData ?? {}
                };
            }
        }
        """#)
    }
}

extension Cache {

    /// Wraps this cache in a javascript object.
    func asJavascriptObject(in jsCtx: JXContext) throws -> JXValue {

        let jsGet = JXValue(newFunctionIn: jsCtx) { context, _, args in

            let key = try args[0].stringValue

            let value: Any? = self[key]
            guard let value else {
                return context.null()
            }

            // If the value is an array or dictionary we encode it to JSON and then to an object.
            if value as? [String: Any] != nil || value as? [Any] != nil,
               let json = String(data: try JSONSerialization.data(withJSONObject: value), encoding: .utf8) {
                return context.json(json)
            }

            // If the value is encodable the we encode it into a JXValue.
            if let encodable = value as? Encodable {
                return try context.encode(encodable)
            }

            // Otherwise we don't know how to pass it to javascript so return a null.
            return context.null()
        }

        let jsSet = JXValue(newFunctionIn: jsCtx) { context, _, args in

            let key = try args[0].stringValue

            switch args[1] {

            case let value where value.isNull:
                self.remove(key)

            case let value where value.isBoolean:
                self[key] = value.booleanValue

            case let value where value.isNumber:
                self[key] = try value.numberValue

            case let value where try value.isDate:
                if let date = try value.dateValue {
                    self[key] = date
                }

            case let value where value.isObject:
                let json = try value.toJSON()
                if let jsonData = json.data(using: .utf8) {
                    self[key] = try JSONSerialization.jsonObject(with: jsonData, options: [])
                }

            case let value where value.isString:
                self[key] = try value.stringValue

            default:
                break
            }

            // Have to return something even though it's a void.
            return context.undefined()
        }

        let cache = jsCtx.object()
        try cache.set("get", convertible: jsGet)
        try cache.set("set", convertible: jsSet)

        return cache
    }
}

/// This extension supports decoding the response body objects returned from a javascript call.
///
/// In the data the field `type` contains the enum to map into. The rest of the fields depend on what
/// the `type` has defined.
extension HTTPResponse.Body: Decodable {

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case templateData
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(String.self, forKey: .type) {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            let templateData = try container.decode([String: String].self, forKey: .templateData)
            self = .text(text, templateData: templateData)

        default: // Also handles .empty
            self = .empty
        }
    }
}
