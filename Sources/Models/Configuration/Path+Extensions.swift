import PathKit

extension Path {

    /// Returns true if the path is a directory or a YAML file.
    var isConfiguration: Bool {
        if isDirectory { return true }
        let loweredExtension = self.extension?.lowercased()
        return loweredExtension == "yml" || loweredExtension == "yaml"
    }
}
