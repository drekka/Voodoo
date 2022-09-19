//
//  Created by Derek Clarkson on 4/8/2022.
//

import Foundation
import Hummingbird

protocol Response

extension HTTPResponse {

    func hbResponse(for request: HTTPRequest, cache: Cache) async -> HBResponse {
        switch self {
        case .raw(let statusCode, headers: let headers, body: let body):
            return HBResponse(status: statusCode, headers: headers.hbHeaders, body: body.hbBody(for: request, cache: cache))

        case .ok(let headers, let body):
            return HBResponse(status: .ok, headers: headers.hbHeaders, body: body.hbBody)

        case .created(headers: let headers, body: let body):
            return HBResponse(status: .created, headers: headers.hbHeaders, body: body.hbBody)

        case .accepted(headers: let headers, body: let body):
            return HBResponse(status: .accepted, headers: headers.hbHeaders, body: body.hbBody)

        case .movedPermanently:
            return HBResponse(status: .movedPermanently)

        case .movedTemporarily:
            return HBResponse(status: .temporaryRedirect)

        case .badRequest(headers: let headers, body: let body):
            return HBResponse(status: .badRequest, headers: headers.hbHeaders, body: body.hbBody)

        case .unauthorised(headers: let headers, body: let body):
            return HBResponse(status: .unauthorized, headers: headers.hbHeaders, body: body.hbBody)

        case .forbidden(headers: let headers, body: let body):
            return HBResponse(status: .forbidden, headers: headers.hbHeaders, body: body.hbBody)

        case .notFound:
            return HBResponse(status: .notFound)

        case .notAcceptable:
            return HBResponse(status: .notAcceptable)

        case .tooManyRequests:
            return HBResponse(status: .tooManyRequests)

        case .internalServerError(headers: let headers, body: let body):
            return HBResponse(status: .internalServerError, headers: headers.hbHeaders, body: body.hbBody)

        case .dynamic(let handler):
            return await handler(request, cache).hbResponse(for: request, cache: cache)
        }
    }
}

// MARK: - Headers

extension Optional where Wrapped == Headers {

    var hbHeaders: HTTPHeaders {
        switch self {
        case .none: return [:]
        case .some(let headers): return HTTPHeaders(headers.map { $0 })
        }
    }
}

extension Optional where Wrapped == HTTPResponse.Body {

    func hbBody(for request: HTTPRequest, cache: Cache) -> HBResponseBody {
        guard case .some(let wrapped) = self else {
            return .empty
        }

        switch wrapped {

        case .json(let encodable, let templateData):

            break
        case .data(let data):
            break
        case .text(let text, let templateData):
            break
        case .url(let url):
            break

        case .template(_, templateData: let templateData):
            break
        }
        return .empty
    }
}
