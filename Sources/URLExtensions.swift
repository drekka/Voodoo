//
//  File.swift
//
//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation

/// The result of making a ``FileManager.default.exists(atPath:isDirectory:)`` query.
public enum FileManagerExistsState {
    case notFound, isFile, isDirectory
}

public extension URL {

    /// Returns true if the URL is a file URL that points to an existing file or directory..
    var fileSystemExists: FileManagerExistsState {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: relativePath, isDirectory: &isDirectory) {
            return isDirectory.boolValue ? .isDirectory : .isFile
        }
        return .notFound
    }
}
