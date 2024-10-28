import AnyCodable
import Foundation
import HTTPTypes

/// Defines a response to an API call.
public enum HTTPResponse {

    // MARK: - Core

    /// The base type of response where everything is specified
    case raw(_: Int, headers: Set<HTTPHeader> = .init(), body: Body = .empty)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    /// Similar to ``dynamic(_:)``, ``javascript(_:)`` is a dynamic response. The difference is that instead of compiled Swift code, we are calling
    /// javascript at runtime which allows developers to execute dynamic responses without having to compile the server.
    case javascript(_ script: String)

    // MARK: - Convenience

    /// Return a HTTP 200 with an optional body and headers.
    case ok(headers: Set<HTTPHeader> = .init(), body: Body = .empty)

    case created(headers: Set<HTTPHeader> = .init(), body: Body = .empty)
    case accepted(headers: Set<HTTPHeader> = .init(), body: Body = .empty)

    case movedPermanently(_ url: String)
    case temporaryRedirect(_ url: String)

    case badRequest(headers: Set<HTTPHeader> = .init(), body: Body = .empty)
    case unauthorised(headers: Set<HTTPHeader> = .init(), body: Body = .empty)
    case forbidden(headers: Set<HTTPHeader> = .init(), body: Body = .empty)
    case notFound
    case tooManyRequests

    case internalServerError(headers: Set<HTTPHeader> = .init(), body: Body = .empty)
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
}

