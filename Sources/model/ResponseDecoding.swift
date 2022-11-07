//
//  File.swift
//
//
//  Created by Derek Clarkson on 6/11/2022.
//

import Foundation

/// Top level keys for the response choices in a config file.
enum ResponseKeys: CodingKey {

    /// A fixed response/.
    case response

    /// An inline javascript function to be called.
    case javascript

    /// A reference to a file that contains the javascript function to be called.
    case javascriptFile
}

/// Common code to read a response from a YAML file in an init.
///
/// Originally this was done as a protocol to be added to the type where the decoding was required. However it would not
/// compile because it added a function to the type which was being called before all the values of the type had been set.
/// ie. Any 'response' value.
extension Decoder {

    /// Decodes a response from the container, assuming it has the appropriate key.
    func decodeResponse() throws -> HTTPResponse {

        let container = try container(keyedBy: ResponseKeys.self)

        // Look for an inline script.
        if let script = try container.decodeIfPresent(String.self, forKey: .javascript) {
            return .javascript(script)
        }

        // Look for a script file reference.
        if let scriptFile = try container.decodeIfPresent(String.self, forKey: .javascriptFile) {
            let scriptFileURL = configDirectory.appendingPathComponent(scriptFile)
            guard scriptFileURL.fileSystemStatus == .isFile else {
                throw DecodingError.dataCorruptedError(forKey: .javascriptFile,
                                                       in: container,
                                                       debugDescription: "Unable to find referenced javascript file '\(scriptFileURL.filePath)'")
            }

            return .javascript(try String(contentsOf: scriptFileURL))
        }

        // Now check for a fixed response.
        if let response = try container.decodeIfPresent(HTTPResponse.self, forKey: .response) {
            return response
        }

        // At this point it's an error.
        let context = DecodingError.Context(codingPath: codingPath,
                                            debugDescription: "Expected to find '\(ResponseKeys.response.stringValue)', '\(ResponseKeys.javascript.stringValue)' or '\(ResponseKeys.javascriptFile.stringValue)'")
        throw DecodingError.dataCorrupted(context)
    }
}

