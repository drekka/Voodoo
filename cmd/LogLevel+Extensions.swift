import ArgumentParser
import Foundation
import Voodoo

// extension LogLevel: EnumerableFlag {
//    public static var allCases: [LogLevel] { [.server, .info, .debug] }
// }

/// allows us to set a ``LogLovel`` as an option type.
extension LogLevel: ExpressibleByArgument {

    /// Supports casting a command line argument to a URL.
    var keyword: String {
        switch self {
        case .server: return "server"
        case .info: return "info"
        case .debug: return "debug"
        case .internal: return "internal"
        }
    }

    // MARK: - ExpressibleByArgument

    public init?(argument: String) {
        switch argument.lowercased() {
        case Self.server.keyword:
            self = .server
        case Self.info.keyword:
            self = .info
        case Self.debug.keyword:
            self = .debug
        case Self.internal.keyword:
            self = .internal
        default:
            return nil
        }
    }

    public var defaultValueDescription: String { Self.info.keyword }

    public static var allValueStrings: [String] { allCases.map { $0.keyword }}
}
