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

    static let userInfoDirectoryKey = CodingUserInfoKey(rawValue: "directory")!
    static let userInfoVerboseKey = CodingUserInfoKey(rawValue: "verbose")!

    private let verbose: Bool

    public init(verbose: Bool) {
        self.verbose = verbose
    }

    public func load(from directory: URL) throws -> [Endpoint] {

        // Find all the YAML files.
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        let files = FileManager.default.enumerator(at: directory,
                                                   includingPropertiesForKeys: resourceKeys,
                                                   options: .skipsHiddenFiles) { _, _ in true }
        guard let files else { return [] }

        let resourceKeysSet = Set(resourceKeys)
        try files.lazy
            .compactMap { $0 as? URL }
            .filter {
                let properties = try? $0.resourceValues(forKeys: resourceKeysSet)
                return !(properties?.isDirectory ?? false) && $0.pathExtension.lowercased() == "yml"
            }
            .forEach {
                try read(file: $0)
                print("\($0)")
            }

        return []
    }

    private func read(file: URL) throws {
        let data = try Data(contentsOf: file)
        let directory = file.deletingLastPathComponent()
        let fileContents = try YAMLDecoder().decode(ConfigFile.self,
                                                    from: data,
                                                    userInfo: [
                                                        ConfigLoader.userInfoDirectoryKey: directory,
                                                        ConfigLoader.userInfoVerboseKey: verbose,
                                                    ])
    }
}
