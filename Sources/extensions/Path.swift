import PathKit

/// Extension to support decoding a path from a JSON or YAML file.
extension Path: @retroactive Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Path(try container.decode(String.self))
    }
}
