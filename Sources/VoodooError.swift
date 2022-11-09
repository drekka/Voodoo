//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import NIOHTTP1

public enum VoodooError: Error, HBHTTPResponseError {

    case noPortAvailable

    case unexpectedError(Error)

    case configLoadFailure(String)
    case invalidConfigPath(String)
    case directoryNotExists(String)

    case noHTTPEndpoint(String)

    case invalidGraphQLRequest(String)
    case noGraphQLEndpoint

    case javascriptError(String)
    case conversionError(String)
    case templateRenderingFailure(String)

    public var status: HTTPResponseStatus {
        switch self {
        case .noGraphQLEndpoint, .noHTTPEndpoint:
            return .notFound
        default:
            return .internalServerError
        }
    }

    public var headers: HTTPHeaders {
        [Header.contentType: Header.ContentType.textPlain]
    }

    public var localizedDescription: String {
        switch self {
        case .conversionError(let message),
             .templateRenderingFailure(let message),
             .javascriptError(let message),
             .configLoadFailure(let message),
             .invalidGraphQLRequest(let message),
             .noHTTPEndpoint(let message):
            return message

        case .noGraphQLEndpoint:
            return "Request does not match any registred endpoint."

        case .noPortAvailable:
            return "All ports taken."

        case .invalidConfigPath(let path):
            return "Invalid config path \(path)"

        case .directoryNotExists(let path):
            return "Missing or URL was not a directory: \(path)"

        case .unexpectedError(let error):
            return error.localizedDescription
        }
    }

    public func body(allocator _: ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        ByteBuffer(string: localizedDescription)
    }
}
