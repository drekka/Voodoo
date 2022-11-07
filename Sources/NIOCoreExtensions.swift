//
//  File.swift
//
//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
import NIOCore
import NIOHTTP1

extension ByteBuffer {

    /// Convenience property for accessing all the bytes in the buffer.
    var data: Data? {
        getData(at: 0, length: readableBytes)
    }
}

/// Make the HTTP method decodable from YAML files.
extension HTTPMethod: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawMethod = try container.decode(String.self)
        self = HTTPMethod(rawValue: rawMethod.uppercased())
    }
}


