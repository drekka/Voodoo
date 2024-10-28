import Foundation

extension HTTPMethod {

    init?(_ method: String) {
        switch method.lowercased() {
        case "get": self = .get
        case "put": self = .put
        case "post": self = .post
        case "delete": self = .delete
        case "head": self = .head
        case "options": self = .options
        default: return nil
        }
    }
}
