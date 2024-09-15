import NIOHTTP1

/// Make the HTTP method decodable from YAML files.
extension HTTPMethod: @retroactive Decodable {

    /// Decodes a `HTTPMethod` from a coder in a case-insensitive manner.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawMethod = try container.decode(String.self)
        self = HTTPMethod(rawValue: rawMethod.uppercased())
    }
}
