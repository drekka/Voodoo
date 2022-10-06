//
//  Created by Derek Clarkson.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import JXKit
import NIOFoundationCompat

/// Type for template data used to inject values.
public typealias TemplateData = [String: Any]
public typealias HeaderDictionary = [String: String]

/// Commonly used content types..
public enum ContentType {

    public static let key = "content-type"

    public static let textPlain = "text/plain"
    public static let textHTML = "text/html"
    public static let applicationJSON = "application/json"
    public static let applicationFormData = "application/x-www-form-urlencoded"
}

/// Defines a response to an API call.
public enum HTTPResponse {

    // Core

    /// The base type of response where everything is specified
    case raw(_: HTTPResponseStatus, headers: HeaderDictionary? = nil, body: Body = .empty)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    /// Similar to ``dynamic(_:)``, ``javascript(_:)`` is a dynamic response. The difference is that instead of compiled Swift code, we are calling
    /// javascript at runtime which allows developers to execute dynamic responses without having to compile the server.
    case javascript(_ script: String)

    // Convenience

    /// Return a HTTP 200  with an optional body and headers.
    case ok(headers: HeaderDictionary? = nil, body: Body = .empty)

    case created(headers: HeaderDictionary? = nil, body: Body = .empty)
    case accepted(headers: HeaderDictionary? = nil, body: Body = .empty)

    case movedPermanently(_ url: String)
    case movedTemporarily(_ url: String)

    case badRequest(headers: HeaderDictionary? = nil, body: Body = .empty)
    case unauthorised(headers: HeaderDictionary? = nil, body: Body = .empty)
    case forbidden(headers: HeaderDictionary? = nil, body: Body = .empty)

    case notFound
    case notAcceptable
    case tooManyRequests

    case internalServerError(headers: HeaderDictionary? = nil, body: Body = .empty)

    /// Defines the body of a response where a response can have one.
    public enum Body {

        /// No body to be returned.
        case empty

        /// Loads the body from a template registered with the Mustache template engine.
        ///
        /// - parameters:
        ///   - templateName: The name of the template as registered in the template engine.
        ///   - templateData: A dictionary containing additional data required by the template.
        ///   - contentType: The `content-type` to be returned in the HTTP response. This should match the content-type of the template.
        case template(_ templateName: String, templateData: TemplateData? = nil, contentType: String = ContentType.applicationJSON)

        /// Serialises an `Encodable` object into JSON.
        ///
        /// This is the preferred way to generate a body from an object if the object conforms to `Encodable`. If it doesn't, then ``jsonObject(_:templateData:)`` can
        /// be used instead.
        ///
        /// - parameters:
        ///   - encodable: The object to be converted to JSON.
        ///   - templateData: Values that can be injected into the generated JSON.
        case jsonEncodable(_ encodable: Encodable, templateData: TemplateData? = nil)

        /// Serialises the passed object into JSON.
        ///
        /// This is used for things like dictionaries and arrays with the `Any` data types that are not ``Encodable``.
        ///
        /// - parameters:
        ///   - object: The object to be converted to JSON.
        ///   - templateData: Values that can be injected into the generated JSON.
        case jsonObject(_ object: Any, templateData: TemplateData? = nil)

        /// Use the data returned from the passed file url as the body of response.
        case file(_ url: URL, contentType: String)

        /// Returns the passed text as a JSON body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - json: The json to be used as the body of the response.
        ///   - templateData: Additional values that can be injected into the text.
        case json(_ json: String, templateData: TemplateData? = nil)

        /// Returns the passed text as the body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - text: The text to be used as the body of the response.
        ///   - templateData: Additional values that can be injected into the text.
        case text(_ text: String, templateData: TemplateData? = nil)

        /// Returns raw data as the specified content type.
        ///
        /// - parameters
        ///     - data: The data to be returned. This will be encoded if necessary.
        ///     - contentType: The content type to pass in the `Content-Type` header.
        case data(_ data: Data, contentType: String)
    }
}
