//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation

/// Decodes a config file (YAML).
struct ConfigFile: Decodable, EndpointSource {

    let endpoints: [Endpoint]

    init(from decoder: Decoder) throws {

        // if the data is an array then it's a list of files and endpoints.
        let container = try decoder.singleValueContainer()
        do {
            endpoints = try container.decode([EndpointReference].self).flatMap(\.endpoints)
        } catch DecodingError.typeMismatch {
            endpoints = try container.decode(EndpointReference.self).endpoints
        }
    }
}
