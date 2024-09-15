import Foundation
import PathKit

/// Extensions for code completeting user info data from the decoder.
extension Decoder {

    /// The config directory as passed to Voodoo.
    var configDirectory: Path {
        guard let directory = userInfo[ConfigLoader.userInfoDirectoryKey] as? Path else {
            preconditionFailure("User info incomplete (developer error).")
        }
        return directory
    }

    /// The name of the current file being decoded.
    var configFileName: String {
        guard let filename = userInfo[ConfigLoader.userInfoFilenameKey] as? String else {
            preconditionFailure("User info incomplete (developer error).")
        }
        return filename
    }

    /// The server's verbose setting.
    var verbose: Bool {
        userInfo[ConfigLoader.userInfoVerboseKey] as? Bool ?? false
    }
}
