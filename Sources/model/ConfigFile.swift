//
//  File.swift
//
//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation

struct EndpointReference: Decodable, EndpointSource {

    let apis: [Endpoint]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {

            let fileReference = try container.decode(String.self)

            guard let directory = decoder.userInfo[ConfigLoader.userInfoDirectoryKey] as? URL,
            let verbose = decoder.userInfo[ConfigLoader.userInfoVerboseKey] as? Bool else {
                throw SimulcraError.configLoadFailure("User info incomplete (developer error).")
            }

            let subLoader = ConfigLoader(verbose: verbose)
            apis = try subLoader.load(from: directory.appendingPathComponent(fileReference))

        } catch DecodingError.typeMismatch {
            apis = [try container.decode(Endpoint.self)]
        }
    }
}

struct ConfigFile: Decodable, EndpointSource {

    let apis: [Endpoint]

    init(from decoder: Decoder) throws {

        // if the data is an array then it's a list of files and endpoints.
        let container = try decoder.singleValueContainer()
        do {
            apis = try container.decode([EndpointReference].self).flatMap { $0.apis }
        } catch DecodingError.typeMismatch {
            apis = try container.decode(EndpointReference.self).apis
        }
    }
}
