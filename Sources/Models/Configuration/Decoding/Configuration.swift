import Foundation
import PathKit

struct Configuration: Decodable {

    private(set) var endpoints: [any Endpoint] = []

    init(from decoder: Decoder) throws {

        let configurationFile = decoder.userInfo.configurationFile
        VoodooLogger.log("Reading configuration from \(configurationFile)")

        let container = try decoder.singleValueContainer()
        do {
            endpoints = try container.decode([EndpointReference].self).flatMap(\.endpoints)
        } catch DecodingError.typeMismatch {
            endpoints = try container.decode(EndpointReference.self).endpoints
        }

        if endpoints.count == 0 {
            throw VoodooError.Configuration.noEndpointsRead(configurationFile)
        }
    }
}

/// An endpoint reference can refer to
struct EndpointReference: Decodable {

    /// Required by ``EndpointSource``.
    let endpoints: [Endpoint]

    init(from decoder: Decoder) throws {

        let configurationFile = decoder.userInfo.configurationFile

        endpoints = try decoder.decodeConfigurationReference(from: decoder)
        ?? decoder.decode(RESTEndpoint.self, from: decoder)
            ?? decoder.decode(GraphQLEndpoint.self, from: decoder)
            ?? []

        if endpoints.count == 0 {
            throw VoodooError.Configuration.noEndpointsRead(configurationFile)
        }
    }
}

protocol DecodableEndpoint: Decodable {
    static func canDecode(from decoder: Decoder) throws -> Bool
}

private extension Decoder {

    func decodeConfigurationReference(from decoder: Decoder) throws -> [Endpoint]? {

        let container = try decoder.singleValueContainer()

        // First we look for a string which we expect to be either a YAML file or folder reference.
        guard let configReference = try? container.decode(String.self) else {
            return nil
        }

        // Check that the string is a valid and existing configuration file.
        let parentFolder = userInfo.configurationFile.parent()
        let configuration = (parentFolder + Path(configReference)).normalize()
        guard configuration.isConfiguration else {
            throw VoodooError.Configuration.referencedFileNotFound(parentFolder, configReference)
        }

        // Read the file.
        return try ConfigurationLoader().load(from: configuration)
    }

    func decode<E>(_: E.Type, from decoder: Decoder) throws -> [E]? where E: DecodableEndpoint {
        guard try E.canDecode(from: decoder) else {
            return nil
        }
        return [try decoder.singleValueContainer().decode(E.self)]
    }
}

