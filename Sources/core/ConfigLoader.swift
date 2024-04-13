//
//  Created by Derek Clarkson on 8/10/2022.
//

import Foundation
import Yams

/// Loads all the endpoints found in a YAML file, or a directory of YAML files.
public struct ConfigLoader {

    static let userInfoDirectoryKey = CodingUserInfoKey(rawValue: "directory")!
    static let userInfoFilenameKey = CodingUserInfoKey(rawValue: "filename")!
    static let userInfoVerboseKey = CodingUserInfoKey(rawValue: "verbose")!

    private let verbose: Bool

    public init(verbose: Bool) {
        self.verbose = verbose
    }

    /// Loads all the endpoints found in a YAML file, or a directory of YAML files.
    ///
    /// - parameter path: A file URL that references either a file or directory.
    public func load(from path: URL) throws -> [Endpoint] {

        switch path.fileSystemStatus {

        case .isFile:
            return try readConfig(file: path)

        case .isDirectory:
            if verbose { print("💀 Reading config from \(path.filePath)") }

            #if os(macOS) || os(iOS)
                // `.produceRelativePathURLs` does not appear to be available in the Linux version of swift.
                let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .producesRelativePathURLs]
            #else
                let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
            #endif
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
            guard let files = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: options) else {
                return []
            }

            let resourceKeysSet = Set(resourceKeys)
            return try files.lazy
                .compactMap { $0 as? URL }
                .filter {
                    let properties = try? $0.resourceValues(forKeys: resourceKeysSet)
                    return !(properties?.isDirectory ?? false) && $0.pathExtension.lowercased() == "yml"
                }
                .flatMap(readConfig)

        default:
            let fileSystemPath = path.filePath
            if verbose { print("💀 Config file or directory does not exist '\(fileSystemPath)'") }
            throw VoodooError.invalidConfigPath(fileSystemPath)
        }
    }

    private func readConfig(file: URL) throws -> [Endpoint] {
        if verbose { print("💀 Reading config file \(file.relativePath)") }
        let data = try Data(contentsOf: file)
        let directory = file.deletingLastPathComponent()
        return try YAMLDecoder().decode(ConfigFile.self,
                                        from: data,
                                        userInfo: [
                                            ConfigLoader.userInfoDirectoryKey: directory,
                                            ConfigLoader.userInfoFilenameKey: file.lastPathComponent,
                                            ConfigLoader.userInfoVerboseKey: verbose,
                                        ]).endpoints
    }
}
