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

/// Wraps up the initialisation an execution of javascript based API responses.
struct JavascriptExecutor {

    let jsCtx = JXContext()

    init() throws {

        try redirectLogging()

        // Inject javascript types.
        try jsCtx.eval(JavascriptSource.responseBodyType)
        try jsCtx.eval(JavascriptSource.responseType)
    }

    func execute(script: String, for request: HTTPRequest, context serverCtx: SimulcraContext) throws -> HTTPResponse {

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
                request.asJavascriptObject(in: jsCtx),
                serverCtx.cache.asJavascriptObject(in: jsCtx),
            ])
        } catch {
            throw SimulcraError.javascriptError("Javascript execution failed. Error: \(error)")
        }

        if rawResponse.isUndefined {
            throw SimulcraError.javascriptError("The javascript function failed to return a response.")
        }

        do {
            return try rawResponse.toDecodable(ofType: HTTPResponse.self) as HTTPResponse
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
}

extension HTTPRequest {
    func asJavascriptObject(in jsCtx: JXContext) throws -> JXValue {

        let request = jsCtx.object()

        try request.defineProperty("method") { property in property.ctx.string(method.rawValue) }

        try request.defineProperty("headers", populatedWith: headers)

        try request.defineProperty("path") { property in property.ctx.string(path) }
        try request.defineProperty("pathComponents") { property in try property.ctx.array(pathComponents.map { property.ctx.string($0) }) }
        try request.defineProperty("pathParameters", populatedWith: pathParameters)

        try request.defineProperty("query") { property in query == nil ? property.ctx.null() : property.ctx.string(query!) }
        try request.defineProperty("queryParameters", populatedWith: queryParameters)

        try request.defineProperty("body") { property in body == nil ? property.ctx.null() : try property.ctx.data(body!) }

        try request.defineProperty("bodyJSON") { property in
            // .json(...) converts a JSON string into an object so bypass bodyJSON
            // because we'd be converting from JSON to objects and back to JSON which is pointless.
            if let body, let json = String(data: body, encoding: .utf8) {
                return try property.ctx.json(json)
            }
            return property.ctx.null()
        }

        try request.defineProperty("formParameters", populatedWith: formParameters)

        return request
    }
}

extension JXValue {

    /// Wraps up some boiler plate for JXKit.
    public func defineProperty(_ property: String, getter: @escaping (JXValue) throws -> JXValue) throws {
        try defineProperty(ctx.string(property), JXProperty(getter: getter, enumerable: true))
    }

    /// Builds a container with the keys in the passed keyed values posing as the property names. Each property will return
    /// either an array or value depending on whether there are multiple values with the same key.
    func defineProperty(_ property: String, populatedWith keyedValues: KeyedValues) throws {
        try defineObjectProperty(property) { obj in
            try keyedValues.uniqueKeys.forEach { key in
                try obj.defineProperty(key) { property in
                    let values = (keyedValues[key] as [String]).map { property.ctx.string($0) }
                    return values.endIndex == 1 ? values[0] : try property.ctx.array(values)
                }
            }
        }
    }

    /// Builds a container with the keys in the passed dictionary posing as the property names.
    func defineProperty(_ property: String, populatedWith dictionary: [String: String]) throws {
        try defineObjectProperty(property) { obj in
            try dictionary.forEach { key, value in
                try obj.defineProperty(key) { property in
                    property.ctx.string(value)
                }
            }
        }
    }

    /// Boilerplate to define an object property using a closure.
    func defineObjectProperty(_ property: String, using setup: @escaping (JXValue) throws -> Void) throws {
        try defineProperty(property) { parentObj in
            let obj = parentObj.ctx.object()
            try setup(obj)
            return obj
        }
    }
}

extension Cache {

    /// Wraps this cache in a javascript object.
    func asJavascriptObject(in jsCtx: JXContext) throws -> JXValue {
        let cache = jsCtx.object()
        try cache.set("get", convertible: JXValue(newFunctionIn: jsCtx, callback: cacheGet))
        try cache.set("set", convertible: JXValue(newFunctionIn: jsCtx, callback: cacheSet))
        return cache
    }

    private func cacheGet(context: JXContext, object _: JXValue?, args: [JXValue]) throws -> JXValue {

        let key = try args[0].stringValue

        let value: Any? = self[key]
        guard let value else {
            return context.null()
        }

        // If the value is an array or dictionary we encode it to JSON and then to an object.
        if value as? [String: Any] != nil || value as? [Any] != nil,
           let json = String(data: try JSONSerialization.data(withJSONObject: value), encoding: .utf8) {
            return try context.json(json)
        }

        // If the value is encodable the we encode it into a JXValue.
        if let encodable = value as? Encodable {
            return try context.encode(encodable)
        }

        // Otherwise we don't know how to pass it to javascript so return a null.
        return context.null()
    }

    private func cacheSet(context: JXContext, object _: JXValue?, args: [JXValue]) throws -> JXValue {

        let key = try args[0].stringValue

        switch args[1] {

        case let value where value.isNull:
            remove(key)

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
}
