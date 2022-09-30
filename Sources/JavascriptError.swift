//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/9/2022.
//

import Foundation
import Hummingbird
import NIOCore

/// Various errors that can be thrown from the javascript executor.
public enum JavascriptError: Error, HBHTTPResponseError {

    case responseFunctionNotFound
    case noResponseReturned

    public var status: HTTPResponseStatus { .internalServerError }

    public var headers: HTTPHeaders {
        switch self {
        case .responseFunctionNotFound:
            return [MockServerError.headerKey: "The executed javascript does not contain a function with the signature 'response(request, cache)'."]
        case .noResponseReturned:
            return [MockServerError.headerKey: "The javascript function failed to return a response."]
        }
    }

    public func body(allocator _: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        ByteBuffer()
    }
}
