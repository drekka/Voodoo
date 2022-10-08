//
//  Created by Derek Clarkson.
//

import NIOHTTP1

/// The definition of a mocked endpoint.
public struct Endpoint: Decodable {

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

    enum CodingKeys: CodingKey {
        case signature
        case response
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let signature = try container.decode(String.self, forKey: .signature)
        let components = signature.split(separator: " ")
        if components.endIndex != 2 {
            throw DecodingError.dataCorruptedError(forKey: .signature,
                                                   in: container,
                                                   debugDescription: "Incorrect signature. Expected <method> <path>")
        }

        method = HTTPMethod(rawValue: components[0].uppercased())
        path = String(components[1])
        response = try container.decode(HTTPResponse.self, forKey: .response)
    }
}
