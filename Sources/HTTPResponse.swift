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

    static let textPlain = "text/plain"
    static let applicationJSON = "application/json"
    static let applicationFormData = "application/x-www-form-urlencoded"
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

        /// Loads the body by serialising a `Encodable` object into JSON.
        case template(_ templateName: TemplateNameSource, templateData: TemplateData = [:])

        /// Loads the body by serialising a `Encodable` object into JSON.
        ///
        /// `templateData` is passed because it allows an ``Encodable`` object to have values injected into the resulting JSON.
        case json(_ encodable: Encodable, templateData: TemplateData = [:])

        /// Use the data returned from the passed url as the body of response.
        /// Can be a remote or local file URL.
        case url(_ url: URL)

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
            let finalTemplateData = context.requestTemplateData(adding: templateData)
            let content = try HBMustacheTemplate(string: json).render(finalTemplateData)
            return (.byteBuffer(ByteBuffer(string: content)), ContentType.applicationJSON)

        case .data(let data, let contentType):
            return (.empty, nil)

        case .text(let text, let templateData):
            return (.byteBuffer(ByteBuffer(string: text)), ContentType.textPlain)

        case .url(let url):
            return (.empty, nil)

        case .template(_, templateData: let templateData):
            return (.empty, nil)
        }
    }
}
