import Foundation
import PathKit
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
    /// - parameter path: A path referencing a file or directory.
    public func load(from path: Path) throws -> [Endpoint] {

        if path.isFile {
            return try readConfig(file: path)
        }

        if path.isDirectory {
            if verbose { print("💀 Reading config from \(path)") }

            return try path.children()
                .filter {
                    $0.isFile && $0.extension?.lowercased() == "yml"
                }
                .flatMap(readConfig)
        }

        if verbose { print("💀 Config file or directory does not exist '\(path.description)'") }
        throw VoodooError.invalidConfigPath(path)
    }

    private func readConfig(file: Path) throws -> [Endpoint] {
        if verbose { print("💀 Reading config file \(file)") }
        let directory = file.parent()
        return try YAMLDecoder().decode(ConfigFile.self,
                                        from: try file.read(),
                                        userInfo: [
                                            ConfigLoader.userInfoDirectoryKey: directory,
                                            ConfigLoader.userInfoFilenameKey: file.lastComponent,
                                            ConfigLoader.userInfoVerboseKey: verbose,
                                        ]).endpoints
    }
}
