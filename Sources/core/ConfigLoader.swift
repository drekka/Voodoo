import Foundation
import UniformTypeIdentifiers
import Yams

/// Loads all the endpoints found in a YAML file, or a directory of YAML files.
public struct ConfigLoader {

    static let userInfoDirectoryKey = CodingUserInfoKey(rawValue: "directory")!
    static let userInfoFilenameKey = CodingUserInfoKey(rawValue: "filename")!

    public init() {}

    /// Loads all the endpoints found in a YAML file, or a directory of YAML files.
    ///
    /// - parameter path: A file URL that references either a file or directory.
    public func load(from path: URL) throws -> [Endpoint] {

        switch FileSystem.shared.fileSystemStatus(for: path) {

        case .file:

            guard path.utType == .yaml else {
                throw VoodooError.configLoadFailure("\(path.absoluteString) does not reference a YAMKL file.")
            }

            return try readConfig(file: path)

        case .directory:
            voodooLog("Reading config files from \(path)")
            return try FileSystem.shared.enumerateFiles(in: path) { _, utType in utType == .yaml }
                .flatMap(readConfig(file:))

        default:
            let fileSystemPath = path.filePath
            voodooLog("Config file or directory does not exist '\(fileSystemPath)'")
            throw VoodooError.invalidConfigPath(fileSystemPath)
        }
    }

    private func readConfig(file: URL) throws -> [Endpoint] {

        voodooLog("Reading config file \(file.relativePath)")
        let data = try Data(contentsOf: file)
        return try YAMLDecoder().decode(ConfigFile.self,
                                        from: data,
                                        userInfo: [
                                            ConfigLoader.userInfoDirectoryKey: file.deletingLastPathComponent(),
                                            ConfigLoader.userInfoFilenameKey: file.lastPathComponent,
                                        ]).endpoints
    }
}
