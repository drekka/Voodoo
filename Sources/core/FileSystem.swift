import Foundation
import UniformTypeIdentifiers

/// The result of making a ``FileManager.default.exists(atPath:isDirectory:)`` query as an enum so we
/// have a single value rather than decyphering two.
public enum FileSystemStatus {
    case notFound, file, directory
}

/// Local file systyem access using Foundation types to do the work.
struct FileSystem {

    /// The current file system.
    static var shared = FileSystem()

    /// Returns the status of a file referenced by a URL.
    ///
    /// - returns: Whether the reference is a file, directory or was not found.
    func fileSystemStatus(for url: URL) -> FileSystemStatus {
        url.fileSystemStatus
    }

    func enumerateFiles(in directory: URL, with filter: ((URL, UTType?) -> Bool)? = nil) throws -> [URL] {

        // Define what data we want back from the search.
        #if os(macOS) || os(iOS)
            // `.produceRelativePathURLs` does not appear to be available in the Linux version of swift.
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .producesRelativePathURLs]
        #else
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        #endif

        // Define that we need to now whether the returned items are directories or files.
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .contentTypeKey]

        // Get the files, recursing into any subdirectories.
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: resourceKeys, options: options) else {
            return []
        }

        return files.lazy.compactMap {

            // Only process files.
            guard let fileURL = $0 as? URL,
                  let fileAttributes = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  !(fileAttributes.isDirectory ?? true) else {
                return nil
            }

            // And apply thye filter if passed.
            if let filter, !filter(fileURL, fileAttributes.contentType) {
                return nil
            }

            return fileURL
        }
    }
}

// MARK: - Extensions

extension URL {

    public var fileSystemStatus: FileSystemStatus {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
            return isDirectory.boolValue ? .directory : .file
        }
        return .notFound
    }

    /// Ensure that the path returned from a file URL is the full and correct path.
    ///
    /// Otherwise, if we just use ``URL.relativePath`` we don't get the base directory structure.
    var filePath: String {
        standardizedFileURL.relativePath
    }

    /// Returns the ``UTType`` of the referenced file.
    var utType: UTType? {
        try? resourceValues(forKeys: Set(arrayLiteral: .contentTypeKey)).contentType
    }
}
