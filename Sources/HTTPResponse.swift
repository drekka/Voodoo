//
//  Created by Derek Clarkson on 1/10/21.
//

import Swifter

public enum HTTPResponse {
    case switchProtocols(_ headers: [String: String], _ handler: (Socket) -> Void)
    case ok(_ responseBody: HTTPResponseBody)
    case created
    case accepted
    case movedPermanently(_ url: String)
    case movedTemporarily(_ url: String)
    case badRequest(_ responseBody: HTTPResponseBody?)
    case unauthorized
    case forbidden
    case notFound
    case notAcceptable
    case tooManyRequests
    case internalServerError
    case raw(_ code: Int, _ phrase: String, _ headers: [String: String]?, _ writer: ((HttpResponseBodyWriter) throws -> Void)?)
    case custom(_ handler: (HttpRequest) -> HTTPResponse)

    func asSwifterResponse(forRequest request: HttpRequest) throws -> HttpResponse {
        switch self {
        case .switchProtocols(let headers, let handler): return .switchProtocols(headers, handler)
        case .ok(let responseBody): return .ok(try responseBody.asSwifterResponseBody(forRequest: request))
        case .created: return .created
        case .accepted: return .accepted
        case .movedPermanently(let url): return .movedPermanently(url)
        case .movedTemporarily(let url): return .movedTemporarily(url)
        case .badRequest(let responseBody): return .badRequest(try responseBody?.asSwifterResponseBody(forRequest: request))
        case .unauthorized: return .unauthorized
        case .forbidden: return .forbidden
        case .notFound: return .notFound
        case .notAcceptable: return .notAcceptable
        case .tooManyRequests: return .tooManyRequests
        case .internalServerError: return .internalServerError
        case .raw(let code, let phrase, let headers, let writer): return .raw(code, phrase, headers, writer)
        case .custom(let handler): return try handler(request).asSwifterResponse(forRequest: request)
        }
    }
}
