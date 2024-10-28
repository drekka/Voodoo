import Foundation
import PathKit
import Yams

/// Loads all the endpoints found in a YAML file, or a directory of YAML files.
public struct ConfigurationLoader {

    /// User info key for accessing the current configuration file being decoded.
    static let configurationFile = CodingUserInfoKey(rawValue: "configurationFile")!

    /// Loads all the endpoints found in a YAML file, or a directory of YAML files.
    ///
    /// - parameter path: A file URL that references either a file or directory.
    public func load(from path: Path) throws -> [any Endpoint] {

        guard path.isConfiguration else {
            throw VoodooError.Configuration.notAConfiguration(path)
        }

        guard path.exists else {
            throw VoodooError.Configuration.fileNotFound(path)
        }

        if path.isFile {
            return try readConfig(file: path)
        }

        // Must be a directory by here.
        VoodooLogger.log("Reading configurations in directory \(path.normalize())")
        return try path.children()
            .filter(\.isConfiguration)
            .flatMap { try $0.isFile ? readConfig(file: $0) : load(from: $0) }
    }

    private func readConfig(file: Path) throws -> [any Endpoint] {
        try YAMLDecoder()
            .decode(Configuration.self,
                    from: file.read(.utf8),
                    userInfo: [
                        Self.configurationFile: file,
                    ])
            .endpoints
    }
}
