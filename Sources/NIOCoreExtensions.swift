//
//  File.swift
//
//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
import NIOCore

extension ByteBuffer {

    /// Convenience property for accessing all the bytes in the buffer.
    var data: Data? {
        getData(at: 0, length: readableBytes)
    }
}
