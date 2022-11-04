//
//  Created by Derek Clarkson.
//

import Foundation
import NIOHTTP1


/// The definition of a mocked endpoint.
public struct HTTPEndpoint: Endpoint {

    let method: HTTPMethod
    let path: String
    let response: HTTPResponse

    /// Default initialiser.
    ///
    /// - parameters:
    ///   - method: The HTTP method to watch for.
    ///   - path: The path to watch. May contains wildcard placeholders for path elements. Placeholders
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - response: The response to generate when this API is called.
    public init(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        self.method = method
        self.path = path
        self.response = response
    }

    enum CodingKeys: CodingKey {
        case signature
        case response
        case javascript
        case javascriptFile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let methodPath = try container.methodPath(userInfo: decoder.userInfo)
        method = methodPath.0
        path = methodPath.1
        response = try container.decodeInlineScriptResponse()
            ?? (try container.decodeScriptFileResponse(userInfo: decoder.userInfo))
            ?? (try container.decodeFixedResponse())
            ?? (try container.throwMissingResponseError())
    }
}

/// Extensions that let us coalesce the code in the init.
extension KeyedDecodingContainer where Key == HTTPEndpoint.CodingKeys {

    // Processes the "<method> <path>" string of an YAML signature.
    func methodPath(userInfo: [CodingUserInfoKey: Any]) throws -> (HTTPMethod, String) {
        // Set the signature properties.
        // TODO: Does super decoder work here?
        let signature = try decode(String.self, forKey: .signature)
        if userInfo[ConfigLoader.userInfoVerboseKey] as? Bool ?? false {
            print("👻 \(userInfo[ConfigLoader.userInfoFilenameKey] as? String ?? ""), found endpoint config: \(signature)")
        }

        let components = signature.split(separator: " ")
        if components.endIndex != 2 {
            throw DecodingError.dataCorruptedError(forKey: .signature,
                                                   in: self,
                                                   debugDescription: "Incorrect signature. Expected <method> <path>")
        }

        return (HTTPMethod(rawValue: components[0].uppercased()), String(components[1]))
    }

    /// Throws an error if there is a missing response.
    func throwMissingResponseError() throws -> HTTPResponse {
        // At this point it's an error.
        let context = DecodingError.Context(codingPath: codingPath,
                                            debugDescription: "Expected to find '\(Key.response.stringValue)', '\(Key.javascript.stringValue)' or '\(Key.javascriptFile.stringValue)'")
        throw DecodingError.dataCorrupted(context)
    }

    func decodeFixedResponse() throws -> HTTPResponse? {
        try decodeIfPresent(HTTPResponse.self, forKey: .response)
    }

    func decodeInlineScriptResponse() throws -> HTTPResponse? {
        guard let script = try decodeIfPresent(String.self, forKey: .javascript) else {
            return nil
        }
        return .javascript(script)
    }

    func decodeScriptFileResponse(userInfo: [CodingUserInfoKey: Any]) throws -> HTTPResponse? {

        guard let scriptFile = try decodeIfPresent(String.self, forKey: .javascriptFile) else {
            return nil
        }

        guard let directory = userInfo[ConfigLoader.userInfoDirectoryKey] as? URL else {
            preconditionFailure("Directory missing from user info (developer error)")
        }

        let scriptFileURL = directory.appendingPathComponent(scriptFile)
        guard scriptFileURL.fileSystemStatus == .isFile else {
            throw DecodingError.dataCorruptedError(forKey: .javascriptFile,
                                                   in: self,
                                                   debugDescription: "Unable to find referenced javascript file '\(scriptFileURL.filePath)'")
        }

        return .javascript(try String(contentsOf: scriptFileURL))
    }
}
