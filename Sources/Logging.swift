import Foundation

struct VoodooLogger {

    static let verbose = true

    static func log(_ message: String) {
        if verbose {
            print("💀 \(message)")
        }
    }
}
