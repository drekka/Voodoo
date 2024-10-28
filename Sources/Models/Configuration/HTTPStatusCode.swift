import Foundation

public enum HTTPStatusCode: Int {

    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204

    case movedPermanently = 301
    case temporaryRedirect = 302
    case seeOther = 303
    case temporaryRedirectWithPost = 307
    case permanentRedirectWithPost = 308

    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case imATeapot = 418
    case tooManyRequests = 429

    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
}
