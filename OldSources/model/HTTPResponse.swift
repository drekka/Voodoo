import AnyCodable
import Foundation
import Hummingbird
import HummingbirdMustache
import JXKit
import NIOFoundationCompat

/// Type for template data used to inject values.
public typealias TemplateData = [String: Any?]
public typealias HeaderDictionary = [String: String]

/// Defines a response to an API call.
public enum HTTPResponse {

    // Core

    /// The base type of response where everything is specified
    case raw(_: HTTPResponseStatus, headers: HeaderDictionary? = nil, body: Body = .empty)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    /// Similar to ``dynamic(_:)``, ``javascript(_:)`` is a dynamic response. The difference is that instead of compiled Swift code, we are calling
    /// javascript at runtime which allows developers to execute dynamic responses without having to compile the server.
    case javascript(_ script: String)

    // Convenience

    /// Return a HTTP 200 with an optional body and headers.
    case ok(headers: HeaderDictionary? = nil, body: Body = .empty)

    case created(headers: HeaderDictionary? = nil, body: Body = .empty)
    case accepted(headers: HeaderDictionary? = nil, body: Body = .empty)

    case movedPermanently(_ url: String)
    case temporaryRedirect(_ url: String)
    case permanentRedirect(_ url: String)

    case badRequest(headers: HeaderDictionary? = nil, body: Body = .empty)
    case unauthorised(headers: HeaderDictionary? = nil, body: Body = .empty)
    case forbidden(headers: HeaderDictionary? = nil, body: Body = .empty)

    case notFound
    case notAcceptable
    case tooManyRequests

    case internalServerError(headers: HeaderDictionary? = nil, body: Body = .empty)
}

/// This extension supports decoding the response from javascript or YAML.
extension HTTPResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case status
        case body
        case url
        case headers
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Now look for a hard coded response.
        let statusCode = try container.decode(Int.self, forKey: .status)
        let status = HTTPResponseStatus(statusCode: statusCode)

        let body = try container.decodeIfPresent(HTTPResponse.Body.self, forKey: .body) ?? .empty
        let headers = try container.decodeIfPresent(HeaderDictionary.self, forKey: .headers)

        switch status {
        case .ok:
            self = .ok(headers: headers, body: body)

        case .created:
            self = .created(headers: headers, body: body)

        case .accepted:
            self = .accepted(headers: headers, body: body)

        case .movedPermanently:
            self = try .movedPermanently(container.decode(String.self, forKey: .url))

        case .temporaryRedirect:
            self = try .temporaryRedirect(container.decode(String.self, forKey: .url))

        case .permanentRedirect:
            self = try .permanentRedirect(container.decode(String.self, forKey: .url))

        case .badRequest:
            self = .badRequest(headers: headers, body: body)

        case .unauthorized:
            self = .unauthorised(headers: headers, body: body)

        case .forbidden:
            self = .forbidden(headers: headers, body: body)

        case .notFound:
            self = .notFound
        case .notAcceptable:
            self = .notAcceptable
        case .tooManyRequests:
            self = .tooManyRequests

        case .internalServerError:
            self = .internalServerError(headers: headers, body: body)

        default:
            self = .raw(status, headers: headers, body: body)
        }
    }
}

/// This extension creates Hummingbird responses.
extension HTTPResponse {

    func hbResponse(for request: HTTPRequest, inServerContext context: VoodooContext) async throws -> HBResponse {

        try await sleepIfRequired(for: context.delay)

        // Captures the request and cache before generating the response.
        func hbResponse(_ status: HTTPResponseStatus, headers: HeaderDictionary?, body: HTTPResponse.Body) throws -> HBResponse {

            let body = try body.hbBody(forRequest: request, serverContext: context)

            // Add additional headers returned with the body.
            var finalHeaders = headers ?? [:]
            if let contentType = body.1 {
                finalHeaders[Header.contentType] = contentType
            }

            return HBResponse(status: status, headers: finalHeaders.hbHeaders, body: body.0)
        }

        switch self {

            // Core

        case let .raw(status, headers: headers, body: body):
            return try hbResponse(status, headers: headers, body: body)

        case let .dynamic(handler):
            return try await handler(request, context.cache).hbResponse(for: request, inServerContext: context)

        case let .javascript(script):
            let response = try JavascriptExecutor(serverContext: context).execute(script: script, for: request)
            return try await response.hbResponse(for: request, inServerContext: context)

            // Convenience

        case let .ok(headers, body):
            return try hbResponse(.ok, headers: headers, body: body)

        case let .created(headers: headers, body: body):
            return try hbResponse(.created, headers: headers, body: body)

        case let .accepted(headers: headers, body: body):
            return try hbResponse(.accepted, headers: headers, body: body)

        case let .movedPermanently(url):
            return HBResponse(status: .movedPermanently, headers: [Header.location: url])

        case let .temporaryRedirect(url):
            return HBResponse(status: .temporaryRedirect, headers: [Header.location: url])

        case let .permanentRedirect(url):
            return HBResponse(status: .permanentRedirect, headers: [Header.location: url])

        case let .badRequest(headers: headers, body: body):
            return try hbResponse(.badRequest, headers: headers, body: body)

        case let .unauthorised(headers: headers, body: body):
            return try hbResponse(.unauthorized, headers: headers, body: body)

        case let .forbidden(headers: headers, body: body):
            return try hbResponse(.forbidden, headers: headers, body: body)

        case .notFound:
            return HBResponse(status: .notFound)

        case .notAcceptable:
            return HBResponse(status: .notAcceptable)

        case .tooManyRequests:
            return HBResponse(status: .tooManyRequests)

        case let .internalServerError(headers: headers, body: body):
            return try hbResponse(.internalServerError, headers: headers, body: body)
        }
    }

    private func sleepIfRequired(for delay: Double) async throws {
        guard delay > 0.0 else {
            return
        }

        #if os(macOS) || os(iOS)
            if #available(macOS 13, iOS 16.0, *) {
                // This form of sleep is only available since iOS16 and Mac13, not in Linux as yet.
                try await Task.sleep(for: .milliseconds(delay * 1000))
                return
            }
        #endif

        // Older versions and Linux.
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000.0))
    }
}

// MARK: - Headers

extension HeaderDictionary {

    var hbHeaders: HTTPHeaders {
        HTTPHeaders(map { $0 })
    }
}
