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
    static let userInfoFilenameKey = CodingUserInfoKey(rawValue: "filename")!
    static let userInfoVerboseKey = CodingUserInfoKey(rawValue: "verbose")!

    private let verbose: Bool

    public init(verbose: Bool) {
        self.verbose = verbose
    }

    public func load(from path: URL) throws -> [Endpoint] {

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let fileSystemName = path.relativePath
        guard fileManager.fileExists(atPath: fileSystemName, isDirectory: &isDirectory) else {
            print("👻 Config file/directory does not exist \(fileSystemName)")
            throw SimulcraError.invalidConfigPath(fileSystemName)
        }

        // If the reference is a file then load it.
        if !isDirectory.boolValue {
            return try readConfig(file: path)
        }

        // Otherwise find all the YAML files in the directory and load them.
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        let files = fileManager.enumerator(at: path,
                                           includingPropertiesForKeys: resourceKeys,
                                           options: .skipsHiddenFiles) { _, _ in true }
        guard let files else { return [] }

        let resourceKeysSet = Set(resourceKeys)
        return try files.lazy
            .compactMap { $0 as? URL }
            .filter {
                let properties = try? $0.resourceValues(forKeys: resourceKeysSet)
                return !(properties?.isDirectory ?? false) && $0.pathExtension.lowercased() == "yml"
            }
            .flatMap(readConfig)
    }

    private func readConfig(file: URL) throws -> [Endpoint] {
        if verbose {
            print("👻 Reading config file \(file.relativePath)")
        }
        let data = try Data(contentsOf: file)
        let directory = file.deletingLastPathComponent()
        return try YAMLDecoder().decode(ConfigFile.self,
                                        from: data,
                                        userInfo: [
                                            ConfigLoader.userInfoDirectoryKey: directory,
                                            ConfigLoader.userInfoFilenameKey: file.lastPathComponent,
                                            ConfigLoader.userInfoVerboseKey: verbose,
                                        ]).apis
    }
}
