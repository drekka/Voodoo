//
//  Created by Derek Clarkson on 11/7/2022.
//

import Foundation
import Hummingbird

/// Provides access to header and query parameters.
@dynamicMemberLookup
public protocol KeyedValues {
    var uniqueKeys: [String] { get }
    subscript(_: String) -> String? { get }
    subscript(_: String) -> [String] { get }
    subscript(dynamicMember _: String) -> String? { get }
    subscript(dynamicMember _: String) -> [String] { get }
}

/// Contains the details of a received request and provide convenient access to commonly used data.
public protocol HTTPRequest {

    /// The HTTP method.
    var method: HTTPMethod { get }

    /// A dictionary of headers.
    var headers: KeyedValues { get }

    /// The URL path.
    var path: String { get }

    /// The components of the path. Always starts with the root '/' component.
    var pathComponents: [String] { get }

    /// A dictionary of parameters extracted from the path.
    var pathParameters: [String: String] { get }

    // The URL query string.
    var query: String? { get }

    /// An array of query key value tuples.
    ///
    /// This is done as an array because it's possible to repeat keys with different values.
    var queryParameters: KeyedValues { get }

    /// The raw body of the request if there is one.
    var body: Data? { get }

    /// Attempts to parse the body as a JSON object.
    ///
    /// Returns the raw JSON data structure or a `nil` if it cannot be parsed.
    var bodyJSON: Any? { get }

    /// Attempts to parse the body as a YAML object.
    ///
    /// Returns the raw YAML data structure or a `nil` if it cannot be parsed.
    var bodyYAML: Any? { get }

    /// If the request is a form submission then this contains the fields and their values from the form.
    var formParameters: [String: String] { get }
}
