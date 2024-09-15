import Foundation
import Hummingbird

extension String {

    /// Returns this string as a `HBRequestBody.byteBuffer`.
    var hbRequestBody: HBRequestBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    /// Returns this string as a `HBResponseBody.byteBuffer`.
    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(string: self))
    }
}
