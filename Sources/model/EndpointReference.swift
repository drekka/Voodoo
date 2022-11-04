//
//  File.swift
//
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

        if let fileReference = try container.decodeEndpoint(String.self) {
            if decoder.verbose { print("👻 \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] as? String ?? ""), found file reference: \(fileReference)") }
            let subLoader = ConfigLoader(verbose: decoder.verbose)
            endpoints = try subLoader.load(from: decoder.configDirectory.appendingPathComponent(fileReference))

        } else if let httpEndpoint = try container.decodeEndpoint(HTTPEndpoint.self) {
            endpoints = [httpEndpoint]

        } else if let graphQLEndpoint = try container.decodeEndpoint(GraphQLEndpoint.self) {
            endpoints = [graphQLEndpoint]
        } else {
            throw SimulacraError.configLoadFailure("Failure decoding end points in \(decoder.userInfo[ConfigLoader.userInfoFilenameKey] ?? "[Unknown]")")
        }
    }
}

extension SingleValueDecodingContainer {

    func decodeEndpoint<T>(_ type: T.Type) throws -> T? where T: Decodable {
        do {
            return try decode(type)
        } catch DecodingError.typeMismatch {
            // Type miss match becomes a nil return.
            return nil
        }
    }
}
