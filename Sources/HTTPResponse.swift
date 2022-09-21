//
//  Created by Derek Clarkson.
//

import Hummingbird
import HummingbirdMustache
import UIKit

/// Type for template data used to inject values.
public typealias TemplateData = [String: Any]

/// Commonly used content types..
public enum ContentType {

    static let key = "content-type"

    public static let textPlain = "text/plain"
    public static let textHTML = "text/html"
    public static let applicationJSON = "application/json"
    public static let applicationFormData = "application/x-www-form-urlencoded"
}

/// Defines a response to an API call.
public enum HTTPResponse {

    // MARK: Core

    /// The base type of response where everything is specified
    case raw(_: HTTPResponseStatus, headers: Headers = [:], body: Body = .empty)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    // MARK: Convenience responses.

    /// Return a HTTP 200  with an optional body and headers.
    case ok(headers: Headers = [:], body: Body = .empty)

    case created(headers: Headers = [:], body: Body = .empty)
    case accepted(headers: Headers = [:], body: Body = .empty)

    case movedPermanently(_ url: String)
    case movedTemporarily(_ url: String)

    case badRequest(headers: Headers = [:], body: Body = .empty)
    case unauthorised(headers: Headers = [:], body: Body = .empty)
    case forbidden(headers: Headers = [:], body: Body = .empty)

    case notFound
    case notAcceptable
    case tooManyRequests

    case internalServerError(headers: Headers = [:], body: Body = .empty)

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

    func hbResponse(for request: HTTPRequest, inServerContext context: ServerContext) async throws -> HBResponse {

        // Captures the request and cache before generating the response.
        func hbResponse(_ status: HTTPResponseStatus, headers: Headers, body: HTTPResponse.Body) throws -> HBResponse {

            let body = try body.hbBody(serverContext: context)

            // Set any headers returned with the body.
            var finalHeaders = headers
            if let contentType = body.1 {
                finalHeaders[ContentType.key] = contentType
            }

            return HBResponse(status: status, headers: finalHeaders.hbHeaders, body: body.0)
        }

        switch self {

        case .raw(let statusCode, headers: let headers, body: let body):
            return try hbResponse(statusCode, headers: headers, body: body)

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

        case .dynamic(let handler):
            return try await handler(request, context.cache).hbResponse(for: request, inServerContext: context)
        }
    }
}

// MARK: - Headers

extension Headers {

    var hbHeaders: HTTPHeaders {
        HTTPHeaders(map { $0 })
    }
}

extension HTTPResponse.Body {

    func hbBody(serverContext context: ServerContext) throws -> (HBResponseBody, String?) {
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

    func render(withTemplateData templateData: TemplateData, context: ServerContext) throws -> HBResponseBody {
        let finalTemplateData = context.requestTemplateData(adding: templateData)
        return try HBMustacheTemplate(string: self).render(finalTemplateData).hbResponseBody
    }
}

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }
}
