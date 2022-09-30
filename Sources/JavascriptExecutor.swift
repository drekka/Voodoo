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
    let statusCode: Int
    let body: HTTPResponse.Body
}

/// Wraps up the initialisation an execution of javascript based API responses.
struct JavascriptExecutor {

    let jsCtx = JXContext()
    let serverCtx: MockServerContext

    init(forContext serverCtx: MockServerContext) throws {

        self.serverCtx = serverCtx

        // trap errors
        jsCtx.exceptionHandler = { _, exception in
            print("Javascript error: \(String(describing: exception))")
        }

        // Update the log function to print log messages.
        let myFunction = JXValue(newFunctionIn: jsCtx) { context, _, messages in
            messages.forEach { print("Javascript: \($0)") }
            return context.undefined()
        }
        try jsCtx.global["console"].setProperty("log", myFunction)

        // Inject dependencies.
        try injectTypes()
    }

    func executeMockAPI(
        script: String,
        for _: HTTPRequest,
        completion: (HTTPResponseStatus, HeaderDictionary, HTTPResponse.Body) throws -> HBResponse
    ) throws -> HBResponse {

        // Load the script into the context then retrieve the function.
        try jsCtx.eval(script)

        // Extract the function.
        let responseFunction = try jsCtx.global["response"]
        guard responseFunction.isFunction else {
            throw JavascriptError.responseFunctionNotFound
        }

        // Call it.
        let rawResponse = try responseFunction.call(withArguments: [
            // try jsCtx.encode(request.javascriptObject),
            jsCtx.object(),
            serverCtx.cache.asJavascriptObject(in: jsCtx),
        ])
        if rawResponse.isUndefined {
            throw JavascriptError.noResponseReturned
        }

        let response: JavascriptCallResponse = try rawResponse.toDecodable(ofType: JavascriptCallResponse.self)

        return try completion(HTTPResponseStatus(statusCode: response.statusCode), [:], response.body)
    }

    private func injectTypes() throws {

        try jsCtx.eval(#"""

        class Response {
            static ok(body) {
                return {
                    statusCode: 200,
                    body: body ?? Body.empty()
                };
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
            let value = self[key]

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

            case let value where try value.isArray, let value where value.isObject:
                let json = try value.toJSON(indent: 0)
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
        try cache.set("get", object: jsGet)
        try cache.set("set", object: jsSet)

        return cache
    }
}

/// This extension supports decoding responses from javascript calls using a pre-defined structure.
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
