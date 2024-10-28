import Foundation
import NIOHTTP1

/// The definition of a mocked endpoint.
public struct HTTPEndpoint {

    let method: HTTPMethod
    let path: String
    let response: HTTPResponse

    /// Default initialiser.
    ///
    /// - parameters:
    ///   - method: The HTTP method to watch for.
    ///   - path: The path to watch. May contains wildcard placeholders for path elements. Placeholders
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - response: The response to generate when this API is called.
    public init(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        self.method = method
        self.path = path
        self.response = response
    }
}

extension HTTPEndpoint: Endpoint {

    public static func canDecode(from decoder: Decoder) throws -> Bool {
        let container = try decoder.container(keyedBy: EndpointKeys.self)
        return container.contains(.http)
    }

    enum EndpointKeys: CodingKey {
        case http
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: EndpointKeys.self)
        let methodPath = try container.methodPath()
        method = methodPath.0
        path = methodPath.1

        response = try decoder.decodeResponse()
    }
}

private extension KeyedDecodingContainer where Key == HTTPEndpoint.EndpointKeys {

    enum EndpointSelectorKeys: CodingKey {
        case api
    }

    // Processes the "<method> <path>" string of an YAML signature.
    func methodPath() throws -> (HTTPMethod, String) {

        // Get the request api property.
        let selectorContainer = try nestedContainer(keyedBy: EndpointSelectorKeys.self, forKey: .http)
        let api = try selectorContainer.decode(String.self, forKey: .api)

        if try superDecoder(forKey: .http).verbose {
            print("💀 \(try superDecoder(forKey: .http).configFileName), found endpoint config: \(api)")
        }

        // Split the api value into the method and path.
        let components = api.split(separator: " ")
        if components.endIndex != 2 {
            throw DecodingError.dataCorruptedError(forKey: .api,
                                                   in: selectorContainer,
                                                   debugDescription: "Incorrect 'api' value. Expected <method> <path>")
        }

        return (HTTPMethod(rawValue: components[0].uppercased()), String(components[1]))
    }
}
