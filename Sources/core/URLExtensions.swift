//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation

/// The result of making a ``FileManager.default.exists(atPath:isDirectory:)`` query as an enum so we
/// have a single value rather than two.
public enum FileSystemStatus {
    case notFound, isFile, isDirectory
}

public extension URL {

    /// Returns the type of a file system reference
    ///
    /// - returns: Whether the reference is a file, directory or was not found.
    var fileSystemStatus: FileSystemStatus {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
            return isDirectory.boolValue ? .isDirectory : .isFile
        }
        return .notFound
    }

    /// Ensure that the path returned from a file URL is the full and correct path.
    ///
    /// Otherwise, if we just use ``URL.relativePath`` we don't get the base directory structure.
    var filePath: String {
        standardizedFileURL.relativePath
    }
}
