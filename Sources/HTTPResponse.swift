//
//  Created by Derek Clarkson.
//

import UIKit
import Hummingbird

/// Type for template data used to inject values.
public typealias TemplateData = [String: Any]

/// Defines a response to an API call.
public enum HTTPResponse {

    // MARK: Base responses.

    /// The base type of response where everything is specified
    case raw(_ :HTTPResponseStatus, headers: Headers? = nil, body:Body? = nil)

    /// Custom closure run to generate a response.
    case dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)

    // MARK: Convenience responses.

    /// Return a HTTP 200  with an optional body and headers.
    case ok(headers: Headers? = nil, body: Body? = nil)

    case created(headers: Headers? = nil, body: Body? = nil)
    case accepted(headers: Headers? = nil, body: Body? = nil)

    case movedPermanently(_ url: String)
    case movedTemporarily(_ url: String)

    case badRequest(headers: Headers? = nil, body: Body? = nil)
    case unauthorised(headers: Headers? = nil, body: Body? = nil)
    case forbidden(headers: Headers? = nil, body: Body? = nil)

    case notFound
    case notAcceptable
    case tooManyRequests

    case internalServerError(headers: Headers? = nil, body: Body? = nil)

    /// Defines the body of a response where a response can have one.
    public enum Body {

        /// Loads the body by serialising a `Encodable` object into JSON.
        case template(_ templateName: TemplateNameSource, templateData: TemplateData? = nil)

        /// Loads the body by serialising a `Encodable` object into JSON.
        ///
        /// `templateData` is passed because it allows an ``Encodable`` object to have values injected into the resulting JSON.
        case json(_ encodable: Encodable, templateData: TemplateData? = nil)

        /// Use the data returned from the passed url as the body of response.
        /// Can be a remote or local file URL.
        case url(_ url: URL)

        /// Returns the passed text as the body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        case text(_ text: String, templateData: TemplateData? = nil)

        /// Returns raw data as the specified content type.
        case data(_ data: Data, contentType: String? = nil)
    }

}
