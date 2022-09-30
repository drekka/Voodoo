//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import NIOCore

public enum MockServerError: Error, HBHTTPResponseError {

    public static let headerKey = "Simulcra-Error"

    case conversionError(String)
    case templateRender(String)
    case noPortAvailable
    case unexpectedError(Error)

    public var status: HTTPResponseStatus { .internalServerError }

    public var headers: HTTPHeaders {
        switch self {
        case .conversionError(let error),
             .templateRender(let error):
            return [Self.headerKey: error]

        case .noPortAvailable:
            return [Self.headerKey: "All ports taken."]

        case .unexpectedError(let error):
            return [Self.headerKey: error.localizedDescription]
        }
    }

    public func body(allocator _: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        ByteBuffer()
    }
}
