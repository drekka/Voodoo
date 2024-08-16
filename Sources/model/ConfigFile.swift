import Foundation

/// Decodes a config file.
///
/// Usually a YAML file, this is the entry point for decoding the servers configuration from a file.
struct ConfigFile: Decodable, EndpointSource {

    /// The end points read from the file and all the files it references.
    let endpoints: [Endpoint]

    init(from decoder: Decoder) throws {

        // try decoding a list of endpoints first and it that doesn't work, then try decoding a single endpoint.
        let container = try decoder.singleValueContainer()
        do {
            endpoints = try container.decode([EndpointReference].self).flatMap(\.endpoints)
        } catch DecodingError.typeMismatch {
            endpoints = try container.decode(EndpointReference.self).endpoints
        }
    }
}
