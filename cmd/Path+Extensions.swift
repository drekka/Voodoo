import PathKit
import ArgumentParser

/// allows us to set a path as an option type.
///
/// This is handled by the Swift argument module.
extension Path: @retroactive ExpressibleByArgument {

    /// Supports casting a command line argument to a URL.
    public init?(argument: String) {
        self.init(argument)
    }
}
