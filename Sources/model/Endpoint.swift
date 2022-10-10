//
//  Created by Derek Clarkson.
//

import Foundation
import NIOHTTP1

/// The definition of a mocked endpoint.
public struct Endpoint: Decodable {

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

        // Set the signature properties.
        let signature = try container.decode(String.self, forKey: .signature)
        if decoder.userInfo[ConfigLoader.userInfoVerboseKey] as? Bool ?? false {
            print("👻 \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] as? String ?? ""), found endpoint config: \(signature)")
        }

        let components = signature.split(separator: " ")
        if components.endIndex != 2 {
            throw DecodingError.dataCorruptedError(forKey: .signature,
                                                   in: container,
                                                   debugDescription: "Incorrect signature. Expected <method> <path>")
        }

        method = HTTPMethod(rawValue: components[0].uppercased())
        path = String(components[1])

        // Now setup the response.

        // First look for javascript.
        if let script = try container.decodeIfPresent(String.self, forKey: .javascript) {
            response = .javascript(script)
            return
        }

        // Now a javascript file.
        if let scriptFile = try container.decodeIfPresent(String.self, forKey: .javascriptFile) {

            guard let directory = decoder.userInfo[ConfigLoader.userInfoDirectoryKey] as? URL else {
                preconditionFailure("Directory missing from user info (developer error)")
            }

            let scriptURL = directory.appendingPathComponent(scriptFile)
            guard scriptURL.fileSystemExists == .isFile else {
                throw DecodingError.dataCorruptedError(forKey: .javascriptFile,
                                                       in: container,
                                                       debugDescription: "Unable to find referenced javascript file '\(scriptURL.relativePath)'")
            }

            response = .javascript(try String(contentsOf: scriptURL))
            return
        }

        // Now test for a response data structure.
        if let httpResponse = try container.decodeIfPresent(HTTPResponse.self, forKey: .response) {
            response = httpResponse
            return
        }

        // At this point it's an error.
        let context = DecodingError.Context(codingPath: container.codingPath,
                                            debugDescription: "Expected to find '\(CodingKeys.response.stringValue)', '\(CodingKeys.javascript.stringValue)' or '\(CodingKeys.javascriptFile.stringValue)'")
        throw DecodingError.dataCorrupted(context)
    }
}
