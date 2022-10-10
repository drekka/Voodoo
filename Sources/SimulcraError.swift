//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import NIOCore

public enum SimulcraError: Error, HBHTTPResponseError {

    public static let headerKey = "Simulcra-Error"

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
        switch self {
        case .conversionError(let message),
             .templateRenderingFailure(let message),
             .javascriptError(let message),
             .configLoadFailure(let message):
            return [Self.headerKey: message]

        case .noPortAvailable:
            return [Self.headerKey: "All ports taken."]

        case .invalidConfigPath(let path):
            return [Self.headerKey: "Invalid config path \(path)"]

        case .directoryNotExists(let path):
            return [Self.headerKey: "Missing or not a directory: \(path)"]

        case .unexpectedError(let error):
            return [Self.headerKey: error.localizedDescription]
        }
    }

    public func body(allocator _: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        ByteBuffer()
    }
}
