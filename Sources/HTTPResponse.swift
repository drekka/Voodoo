//
//  Created by Derek Clarkson.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import JXKit
import NIOFoundationCompat

/// Type for template data used to inject values.
public typealias TemplateData = [String: Any]
public typealias HeaderDictionary = [String: String]

/// Commonly used content types..
public enum ContentType {

    public static let key = "content-type"

    public static let textPlain = "text/plain"
    public static let textHTML = "text/html"
    public static let applicationJSON = "application/json"
    public static let applicationFormData = "application/x-www-form-urlencoded"
}

/// Defines a response to an API call.
public enum HTTPResponse {

    // Core

    /// The base type of response where everything is specified
    case raw(_: HTTPResponseStatus, headers: HeaderDictionary = [:], body: Body = .empty)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    /// Similar to ``dynamic(_:)``, ``javascript(_:)`` is a dynamic response. The difference is that instead of compiled Swift code, we are calling
    /// javascript at runtime which allows developers to execute dynamic responses without having to compile the server.
    case javascript(_ script: String)

    // Convenience

    /// Return a HTTP 200  with an optional body and headers.
    case ok(headers: HeaderDictionary = [:], body: Body = .empty)

    case created(headers: HeaderDictionary = [:], body: Body = .empty)
    case accepted(headers: HeaderDictionary = [:], body: Body = .empty)

    case movedPermanently(_ url: String)
    case movedTemporarily(_ url: String)

    case badRequest(headers: HeaderDictionary = [:], body: Body = .empty)
    case unauthorised(headers: HeaderDictionary = [:], body: Body = .empty)
    case forbidden(headers: HeaderDictionary = [:], body: Body = .empty)

    case notFound
    case notAcceptable
    case tooManyRequests

    case internalServerError(headers: HeaderDictionary = [:], body: Body = .empty)

    /// Defines the body of a response where a response can have one.
    public enum Body {

        /// No body to be returned.
        case empty

        /// Loads the body from a template registered with the Mustache template engine.
        ///
        /// - parameters:
        ///   - templateName: The name of the template as registered in the template engine.
        ///   - templateData: A dictionary containing additional data required by the template.
        ///   - contentType: The `content-type` to be returned in the HTTP response. This should match the content-type of the template.
        case template(_ templateName: String, templateData: TemplateData = [:], contentType: String = ContentType.applicationJSON)

        /// Loads the body by serialising a `Encodable` object into JSON.
        ///
        /// `templateData` is passed because it allows a `Encodable` object to have values injected into the resulting JSON.
        case json(_ encodable: Encodable, templateData: TemplateData = [:])

        /// Use the data returned from the passed file url as the body of response.
        case file(_ url: URL, contentType: String)

        /// Returns the passed text as the body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        case text(_ text: String, templateData: TemplateData = [:])

        /// Returns raw data as the specified content type.
        case data(_ data: Data, contentType: String? = nil)
    }
}

extension HTTPResponse {

    func hbResponse(for request: HTTPRequest, inServerContext context: MockServerContext) async throws -> HBResponse {

        // Captures the request and cache before generating the response.
        func hbResponse(_ status: HTTPResponseStatus, headers: HeaderDictionary, body: HTTPResponse.Body) throws -> HBResponse {

            let body = try body.hbBody(serverContext: context)

            // Add additional headers returned with the body.
            var finalHeaders = headers
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
            return try executor.executeMockAPI(script: script, for: request, completion: hbResponse)

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
//        var results: [String: Encodable] = [:]
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

    func hbBody(serverContext context: MockServerContext) throws -> (HBResponseBody, String?) {
        switch self {

        case .empty:
            return (.empty, nil)

        case .json(let encodable, let templateData):
            let jsonData = try JSONEncoder().encode(encodable)
            guard let json = String(data: jsonData, encoding: .utf8) else {
                throw MockServerError.conversionError("Unable to convert JSON data to a String")
            }
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
                throw MockServerError.templateRender("Rendering template '\(templateName)' failed.")
            }
            return (json.hbResponseBody, contentType)
        }
    }
}

// MARK: - Supporting extensions

extension String {

    var hbRequestBody: HBRequestBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    func render(withTemplateData templateData: TemplateData, context: MockServerContext) throws -> HBResponseBody {
        let finalTemplateData = context.requestTemplateData(adding: templateData)
        return try HBMustacheTemplate(string: self).render(finalTemplateData).hbResponseBody
    }
}

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }
}
