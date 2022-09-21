//
//  Created by Derek Clarkson.
//

import Hummingbird

/// The definition of a mocked endpoint.
public struct Endpoint {

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
