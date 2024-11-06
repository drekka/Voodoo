import ArgumentParser
import Foundation

/// allows us to set a URL as an option type.
extension URL: @retroactive ExpressibleByArgument {

    /// Supports casting a command line argument to a URL.
    public init?(argument: String) {
        self.init(fileURLWithPath: argument)
    }
}
