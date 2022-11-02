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
    let serverCtx: SimulacraContext

    init(serverContext: SimulacraContext) throws {

        serverCtx = serverContext

        try redirectLogging()

        // Inject javascript types.
        try jsCtx.eval(JavascriptModels.responseBodyType)
        try jsCtx.eval(JavascriptModels.responseType)
    }

    func execute(script: String, for request: HTTPRequest) throws -> HTTPResponse {

        // Load the script into the context then retrieve the function.
        do {
            try jsCtx.eval(script)
        } catch {
            throw SimulacraError.javascriptError("Error evaluating javascript: \(error)")
        }

        // Extract the function.
        let responseFunction = try jsCtx.global["response"]
        guard responseFunction.isFunction else {
            throw SimulacraError.javascriptError("The executed javascript does not contain a function with the signature 'response(request, cache)'.")
        }

        // Proxy the javascript cache to the server cache so it handles dynamic lookup style property access.
        let cache = jsCtx.object()
        let proxy = try cache.proxy(get: serverCtx.cache.cacheGet, set: serverCtx.cache.cacheSet)

        // Call it.
        let rawResponse: JXValue
        do {
            rawResponse = try responseFunction.call(withArguments: [
                request.asJavascriptObject(in: jsCtx),
                proxy,
            ])
        } catch {
            throw SimulacraError.javascriptError("Javascript execution failed. Error: \(error)")
        }

        if rawResponse.isUndefined {
            throw SimulacraError.javascriptError("The javascript function failed to return a response.")
        }

        do {
            return try rawResponse.toDecodable(ofType: HTTPResponse.self) as HTTPResponse
        } catch {
            throw SimulacraError.javascriptError("The javascript function returned an unexpected response. Make sure you are using the 'Response' object to generate a response. Returned error: \(error)")
        }
    }

    private func redirectLogging() throws {
        // Update the log function to print log messages.
        let redirect = JXValue(newFunctionIn: jsCtx) { context, _, messages in
            messages.forEach { print("Javascript: \($0)") }
            return context.undefined()
        }
        try jsCtx.global["console"].setProperty("log", redirect)
    }
}

extension HTTPRequest {

    /// Creates a javascript wrapper that forwards the requests properties and functions.
    func asJavascriptObject(in jsCtx: JXContext) throws -> JXValue {

        let request = jsCtx.object()

        try request.defineProperty("method") { property in property.context.string(method.rawValue) }

        try request.defineProperty("headers", populatedWith: headers)

        try request.defineProperty("path") { property in property.context.string(path) }
        try request.defineProperty("pathComponents") { property in try property.context.array(pathComponents.map { property.context.string($0) }) }
        try request.defineProperty("pathParameters", populatedWith: pathParameters)

        try request.defineProperty("query") { property in query == nil ? property.context.null() : property.context.string(query!) }
        try request.defineProperty("queryParameters", populatedWith: queryParameters)

        try request.defineProperty("body") { property in body == nil ? property.context.null() : try property.context.data(body!) }

        try request.defineProperty("bodyJSON") { property in
            // .json(...) converts a JSON string into an object so bypass bodyJSON
            // because we'd be converting from JSON to objects and back to JSON which is pointless.
            if let json = try body?.string() {
                return try property.context.json(json)
            }
            return property.context.null()
        }

        try request.defineProperty("formParameters", populatedWith: formParameters)

        return request
    }
}

extension JXValue {

    /// Wraps up some boiler plate for JXKit.
    public func defineProperty(_ property: String, getter: @escaping (JXValue) throws -> JXValue) throws {
        try defineProperty(context.string(property), JXProperty(getter: getter, enumerable: true))
    }

    /// Builds a container with the keys in the passed keyed values posing as the property names. Each property will return
    /// either an array or value depending on whether there are multiple values with the same key.
    func defineProperty(_ property: String, populatedWith keyedValues: KeyedValues) throws {
        try defineObjectProperty(property) { obj in
            try keyedValues.uniqueKeys.forEach { key in
                try obj.defineProperty(key) { property in
                    let values = (keyedValues[key] as [String]).map { property.context.string($0) }
                    return values.endIndex == 1 ? values[0] : try property.context.array(values)
                }
            }
        }
    }

    /// Builds a container with the keys in the passed dictionary posing as the property names.
    func defineProperty(_ property: String, populatedWith dictionary: [String: String]) throws {
        try defineObjectProperty(property) { obj in
            try dictionary.forEach { key, value in
                try obj.defineProperty(key) { property in
                    property.context.string(value)
                }
            }
        }
    }

    /// Boilerplate to define an object property using a closure.
    func defineObjectProperty(_ property: String, using setup: @escaping (JXValue) throws -> Void) throws {
        try defineProperty(property) { parentObj in
            let obj = parentObj.context.object()
            try setup(obj)
            return obj
        }
    }
}

extension Cache {

    func cacheGet(context: JXContext, object _: JXValue?, args: [JXValue]) throws -> JXValue {

        // Index 0 is target javascript object, index 1 is the key of the property being requested.
        let key = try args[1].string

        guard let value = self[key] else {
            return context.null()
        }

        // If the value is an array or dictionary we encode it to JSON and then to an object.
        if value as? [String: Any] != nil || value as? [Any] != nil {
            return try context.json(try JSONSerialization.data(withJSONObject: value).string())
        }

        // If the value is encodable the we encode it into a JXValue.
        if let encodable = value as? Encodable {
            return try context.encode(encodable)
        }

        // Otherwise we don't know how to pass it to javascript so return a null.
        return context.null()
    }

    func cacheSet(context: JXContext, object _: JXValue?, args: [JXValue]) throws -> JXValue {

        let key = try args[1].string

        switch args[2] {

        case let value where value.isNull:
            remove(key)

        case let value where value.isBoolean:
            self[key] = value.bool

        case let value where value.isNumber:
            self[key] = try value.double

        case let value where try value.isDate:
            self[key] = try value.date

        case let value where value.isObject:
            let json = try value.toJSON()
            if let jsonData = json.data(using: .utf8) {
                self[key] = try JSONSerialization.jsonObject(with: jsonData, options: [])
            }

        case let value where value.isString:
            self[key] = try value.string

        default:
            break
        }

        // Have to return something even though it's a void.
        return context.undefined()
    }
}
