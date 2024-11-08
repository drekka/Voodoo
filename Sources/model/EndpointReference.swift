//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation

/// Decodes the object from a YAML config file, and attempts to map it into the various types of structures that can exist at the top level.
struct EndpointReference: Decodable, EndpointSource {

    /// Required by ``EndpointSource``.
    let endpoints: [Endpoint]

    init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()

        // First we look for a string which we assume to be a file reference.
        if let fileReference = try? container.decode(String.self) {
            voodooLog(level: .debug, "\(decoder.userInfo[ConfigLoader.userInfoFilenameKey] as? String ?? ""), found potential file reference: \(fileReference)")
            endpoints = try ConfigLoader().load(from: decoder.configDirectory.appendingPathComponent(fileReference))
            return
        }

        // Now try and decode one of the Endpoint types.
        let endpointTypes: [Endpoint.Type] = [HTTPEndpoint.self, GraphQLEndpoint.self]
        if let decodableEndpointType = try endpointTypes.first(where: { try $0.canDecode(from: decoder) }) {
            endpoints = try [container.decode(decodableEndpointType)]
            return
        }

        // If none of those then we don't know what this is so we throw an error.
        throw VoodooError.configLoadFailure("Failure decoding end points in \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] ?? "[Unknown]")")
    }
}
