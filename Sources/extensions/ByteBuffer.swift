import Foundation
import NIOCore
import NIOHTTP1

extension ByteBuffer {

    /// Convenience property for returning the contents of the buffer as `Data`.
    var data: Data? {
        getData(at: 0, length: readableBytes)
    }
}
