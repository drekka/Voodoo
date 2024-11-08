//
//  File.swift
//
//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation

/// Extensions for code completeting user info data from the decoder.
extension Decoder {

    /// The config directory as passed to Voodoo.
    var configDirectory: URL {
        guard let directory = userInfo[ConfigLoader.userInfoDirectoryKey] as? URL else {
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
}
