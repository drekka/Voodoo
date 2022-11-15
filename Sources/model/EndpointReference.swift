//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation

/// Decodes a line from a YAML config file. If it's just text it assumes it refers to another YAML file to be loaded.
/// Otherwise it
struct EndpointReference: Decodable, EndpointSource {

    let endpoints: [Endpoint]

    init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()

        // A string is expected to be a file reference
        if let fileReference = try? container.decode(String.self) {
            if decoder.verbose { print("💀 \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] as? String ?? ""), found potential file reference: \(fileReference)") }
            let subLoader = ConfigLoader(verbose: decoder.verbose)
            endpoints = try subLoader.load(from: decoder.configDirectory.appendingPathComponent(fileReference))
            return
        }

        // We attempt to decode a HTTPEndpoint.
        if let httpEndpoint = try container.decodeEndpoint(HTTPEndpoint.self) {
            endpoints = [httpEndpoint]
            return
        }

        // We next attempt to decode a GraphQLEndpoint.
        if let graphQLEndpoint = try container.decodeEndpoint(GraphQLEndpoint.self) {
            endpoints = [graphQLEndpoint]
            return
        }

        // If none of those then we don't know what this is so throw an error.
        throw VoodooError.configLoadFailure("Failure decoding end points in \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] ?? "[Unknown]")")
    }
}

extension SingleValueDecodingContainer {

    func decodeEndpoint<T>(_ type: T.Type) throws -> T? where T: Decodable {
        do {
            return try decode(type)
        } catch VoodooError.wrongEndpointType {
            // Type miss match becomes a nil return.
            return nil
        }
    }
}
