import Foundation
import PathKit

extension Dictionary where Key == CodingUserInfoKey {

    /// Retrieves the current configuration file being decoded.
    var configurationFile: Path {
        guard let file = self[ConfigurationLoader.configurationFile] as? Path else {
            fatalError("Configuration file not found in decoder's user info")
        }
        return file
    }
}
