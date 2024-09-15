import Foundation
import Hummingbird

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }

    func string() throws -> String {
        guard let string = String(data: self, encoding: .utf8) else {
            throw VoodooError.conversionError("Unable to convert data to a String")
        }
        return string
    }
}
