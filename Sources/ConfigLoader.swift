//
//  File.swift
//
//
//  Created by Derek Clarkson on 8/10/2022.
//

import Foundation
import Yams

/// Loads a configuration from a directory of YAML files.
public struct ConfigLoader {

    public init(directory: URL) {

        // Find all the YAML files.
        let resourceKeys:[URLResourceKey] = [.isDirectoryKey]
        let files = FileManager.default.enumerator(at: directory,
                                                   includingPropertiesForKeys: resourceKeys,
                                                   options: .skipsHiddenFiles) { _, _ in
            true
        }
        if let files {
            for case let file as URL in files {
                guard let resourceValues = try? file.resourceValues(forKeys: Set(resourceKeys)),
                        let isDirectory = resourceValues.isDirectory
                        else {
                            return
                    }
                print("\(file) -> \(isDirectory)")
            }
        }
    }
}
