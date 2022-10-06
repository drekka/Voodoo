//
//  File.swift
//  
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

extension HTTPResponse {

    func hbResponse(for request: HTTPRequest, inServerContext context: SimulcraContext) async throws -> HBResponse {

        // Captures the request and cache before generating the response.
        func hbResponse(_ status: HTTPResponseStatus, headers: HeaderDictionary?, body: HTTPResponse.Body) throws -> HBResponse {

            let body = try body.hbBody(serverContext: context)

            // Add additional headers returned with the body.
            var finalHeaders = headers ?? [:]
            if let contentType = body.1 {
                finalHeaders[ContentType.key] = contentType
            }

            return HBResponse(status: status, headers: finalHeaders.hbHeaders, body: body.0)
        }

        switch self {

            // Core

        case .raw(let statusCode, headers: let headers, body: let body):
            return try hbResponse(statusCode, headers: headers, body: body)

        case .dynamic(let handler):
            return try await handler(request, context.cache).hbResponse(for: request, inServerContext: context)

        case .javascript(let script):
            let executor = try JavascriptExecutor(forContext: context)
            let response = try executor.execute(script: script, for: request)
            return try await response.hbResponse(for: request, inServerContext: context)

            // Convenience

        case .ok(let headers, let body):
            return try hbResponse(.ok, headers: headers, body: body)

        case .created(headers: let headers, body: let body):
            return try hbResponse(.created, headers: headers, body: body)

        case .accepted(headers: let headers, body: let body):
            return try hbResponse(.accepted, headers: headers, body: body)

        case .movedPermanently:
            return HBResponse(status: .movedPermanently)

        case .movedTemporarily:
            return HBResponse(status: .temporaryRedirect)

        case .badRequest(headers: let headers, body: let body):
            return try hbResponse(.badRequest, headers: headers, body: body)

        case .unauthorised(headers: let headers, body: let body):
            return try hbResponse(.unauthorized, headers: headers, body: body)

        case .forbidden(headers: let headers, body: let body):
            return try hbResponse(.forbidden, headers: headers, body: body)

        case .notFound:
            return HBResponse(status: .notFound)

        case .notAcceptable:
            return HBResponse(status: .notAcceptable)

        case .tooManyRequests:
            return HBResponse(status: .tooManyRequests)

        case .internalServerError(headers: let headers, body: let body):
            return try hbResponse(.internalServerError, headers: headers, body: body)
        }
    }
}

// MARK: - Javascript types

// extension HTTPRequest {
//    var javascriptRequest: [String: Encodable] {
//
//
//
//    }
// }
//
// struct JavascriptHTTPRequest: Encodable {
//
//    let request: HTTPRequest
//
//    enum CodingKeys: String, CodingKey {
//        case method
//    }
//
//    var method: String { request.method.rawValue }
//    var headers: [String: Encodable] {
//        var results: [String: Encodable]? = nil
//        request.headers.forEach {
//            let values: [String] = self[$0.0]
//            switch values.endIndex {
//            case 0:
//                break
//            case 1:
//                results[$0] = values.first
//            default:
//                results[$0] = values
//            }
//        }
//        return results }
//    var path: String { request.path }
//    var pathComponents: [String] { request.pathComponents }
//    var pathParameters: PathParameters { request.pathParameters }
//    var query: String? { request.query }
//    var queryParameters: [String: Encodable] { request.queryParameters.encodable }
//    var body: Data? { request.body }
//    var bodyJSON: Any? { request.bodyJSON }
//    var formParameters: FormParameters { request.formParameters }
//
// }

extension KeyedValues {
    func encodable(allKeys: () -> [String]) -> [String: Encodable] {
        var results: [String: Encodable] = [:]
        allKeys().forEach {
            let values: [String] = self[$0]
            switch values.endIndex {
            case 0:
                break
            case 1:
                results[$0] = values.first
            default:
                results[$0] = values
            }
        }
        return results
    }
}

// MARK: - Headers

extension HeaderDictionary {

    var hbHeaders: HTTPHeaders {
        HTTPHeaders(map { $0 })
    }
}

// MARK: - Response bodies

extension HTTPResponse.Body {

    func hbBody(serverContext context: SimulcraContext) throws -> (HBResponseBody, String?) {
        switch self {

        case .empty:
            return (.empty, nil)

        case .jsonObject(let object, let templateData):
            let jsonData = try JSONSerialization.data(withJSONObject: object)
            guard let json = String(data: jsonData, encoding: .utf8) else {
                throw SimulcraError.conversionError("Unable to convert JSON data to a String")
            }
            return (try json.render(withTemplateData: templateData, context: context), ContentType.applicationJSON)

        case .jsonEncodable(let encodable, let templateData):
            let jsonData = try JSONEncoder().encode(encodable)
            guard let json = String(data: jsonData, encoding: .utf8) else {
                throw SimulcraError.conversionError("Unable to convert JSON data to a String")
            }
            return (try json.render(withTemplateData: templateData, context: context), ContentType.applicationJSON)

        case .json(let json, let templateData):
            return (try json.render(withTemplateData: templateData, context: context), ContentType.applicationJSON)

        case .data(let data, let contentType):
            return (data.hbResponseBody, contentType)

        case .text(let text, let templateData):
            return (try text.render(withTemplateData: templateData, context: context), ContentType.textPlain)

        case .file(let url, let contentType):
            let contents = try Data(contentsOf: url)
            return (contents.hbResponseBody, contentType)

        case .template(let templateName, let templateData, let contentType):
            let renderer = context.mustacheRenderer
            let finalTemplateData = context.requestTemplateData(adding: templateData)
            guard let json = renderer.render(finalTemplateData, withTemplate: templateName) else {
                throw SimulcraError.templateRenderingFailure("Rendering template '\(templateName)' failed.")
            }
            return (json.hbResponseBody, contentType)
        }
    }
}

// MARK: - Supporting extensions

extension String {

    /// Returns this string as a `HBRequestBody.byteBuffer`.
    var hbRequestBody: HBRequestBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    /// Returns this string as a `HBResponseBody.byteBuffer`.
    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    /// Renders this string as a response body.
    ///
    /// - parameters:
    ///     - templateData: Additional data that can be injected into this string assuming this string contains mustache keys..
    ///     - context: The server context.
    func render(withTemplateData templateData: TemplateData?, context: SimulcraContext) throws -> HBResponseBody {
        let finalTemplateData = context.requestTemplateData(adding: templateData)
        return try HBMustacheTemplate(string: self).render(finalTemplateData).hbResponseBody
    }
}

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }
}
