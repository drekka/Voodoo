import Foundation
import Hummingbird

/// Contains the details of a received request and provide convenient access to commonly used data.
public protocol HTTPRequest {

    /// The HTTP method.
    var method: HTTPMethod { get }

    /// A dictionary of headers.
    var headers: [(String, String)] { get }

    /// The URL's path.
    var path: String { get }

    /// The components of the path.
    ///
    /// These are derived by splitting the path by '/' characters.
    var pathComponents: [String] { get }

    /// A dictionary of parameters extracted from the path.
    var pathArguments: [String: String] { get }

    // The URL query string.
    var query: String? { get }

    /// Query key value pairs.
    ///
    /// Unlike other ``KeyedData`` returned from the request,  is done as an array because it's possible for there to be multiple occurances
    /// of the same key on a path, but with different values.
    var queryArguments: [(String, String)] { get }

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

    /// Examines the request and if it is a GraphQL request, returns the details of that request.
    var graphQLRequest: GraphQLRequest? { get }

    /// Returns true if the passed content type is a match.
    ///
    /// Note that this does a contains to allow for extra parameters added to a content type such as encoding.
    func contentType(is contentType: HTTPHeader.ContentType) -> Bool

    /// Decodes the incoming JSON body as the expected type.
    ///
    /// - parameter type: The decodable type we are expecting to find in the request body.
    /// - returns: An instant of `type` if the decode succeeds. `nil` otherwise.
    func decodeBodyJSON<T>(as type: T.Type) -> T? where T: Decodable
}
