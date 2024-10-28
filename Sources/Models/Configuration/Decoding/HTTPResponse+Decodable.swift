import Foundation
import HTTPTypes

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

        // Now look for a hard coded status code such as 200, 403, etc and default to ok.
        let statusCode = (try? container.decode(Int.self, forKey: .status)) ?? 200
        let status = HTTPStatusCode(rawValue: statusCode)

        // Decode the response, defaulting to an empty response.
        let body = try container.decodeIfPresent(HTTPResponse.Body.self, forKey: .body) ?? .empty

        // Extract headers
        let headers = try Set((container.decodeIfPresent([String: String].self, forKey: .headers) ?? [:])
            .map(HTTPHeader.init(keyValue:)))

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

        case .badRequest:
            self = .badRequest(headers: headers, body: body)
        case .unauthorized:
            self = .unauthorised(headers: headers, body: body)
        case .forbidden:
            self = .forbidden(headers: headers, body: body)
        case .notFound:
            self = .notFound
        case .tooManyRequests:
            self = .tooManyRequests

        case .internalServerError:
            self = .internalServerError(headers: headers, body: body)

        case .notImplemented:
            self = .notImplemented
        case .badGateway:
            self = .badGateway
        case .serviceUnavailable:
            self = .serviceUnavailable
        case .gatewayTimeout:
            self = .gatewayTimeout

        default:
            self = .raw(statusCode, headers: headers, body: body)
        }
    }
}
