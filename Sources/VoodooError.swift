import Foundation
@preconcurrency import PathKit

public enum VoodooError: Error {

    enum Configuration: Error {

        /// Path is not a valid directory or YAML file.
        case notAConfiguration(Path)

        /// Path is not a valid directory or YAML file.
        case fileNotFound(Path)

        /// The referened configuration does not exist.
        case referencedFileNotFound(Path, String)

        case invalidHTTPSelector(Path, String)

        case invalidResponseStatusCode(Path, String, Int)
        case unknownResponse(Path, String)

        case noEndpointsRead(Path)
    }

    case invalidHeaderLocationURL(String)
}
