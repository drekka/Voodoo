//
//  File.swift
//
//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation

/// Extensions for accessing user info data previously stored in the decoder.
extension Decoder {

    /// Returns the base directory for the config.
    var configDirectory: URL {
        guard let directory = userInfo[ConfigLoader.userInfoDirectoryKey] as? URL else {
            preconditionFailure("User info incomplete (developer error).")
        }
        return directory
    }

    var configFileName: String {
        guard let filename = userInfo[ConfigLoader.userInfoFilenameKey] as? String else {
            preconditionFailure("User info incomplete (developer error).")
        }
        return filename
    }

    /// Returns the server's verbose setting.
    var verbose: Bool {
        userInfo[ConfigLoader.userInfoVerboseKey] as? Bool ?? false
    }
}
