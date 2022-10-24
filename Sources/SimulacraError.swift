//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import NIOCore

public enum SimulacraError: Error, HBHTTPResponseError {

    public static let headerKey = "Simulacra-Error"

    case conversionError(String)
    case templateRenderingFailure(String)
    case noPortAvailable
    case unexpectedError(Error)
    case javascriptError(String)
    case configLoadFailure(String)
    case invalidConfigPath(String)
    case directoryNotExists(String)

    public var status: HTTPResponseStatus { .internalServerError }

    public var headers: HTTPHeaders {
        return [Self.headerKey: localizedDescription]
    }

    public var localizedDescription: String {
        switch self {
        case .conversionError(let message),
             .templateRenderingFailure(let message),
             .javascriptError(let message),
             .configLoadFailure(let message):
            return message

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

    public func body(allocator _: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        ByteBuffer()
    }
}
