import AnyCodable
import Foundation

public extension HTTPResponse {

    /// Defines the body of a response for requests that can return one.
    enum Body {

        /// No body to be returned.
        case empty

        /// Loads the body from a template registered with the template engine.
        ///
        /// - parameters:
        ///   - templateName: The name of a stencil template as known to the template engine.
        ///   - templateData: A dictionary containing additional data required by the template.
        ///   - contentType: The `content-type` to be returned in the HTTP response. This should match the content-type of the template.
        case template(_ templateName: String, templateData: TemplateData = [:], contentType: any HTTPContentTypeProvider)

        /// generates a JSON payload.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - payload: The payload to generate the data from.
        ///   - templateData: Additional values that can be injected into the text.
        case json(_ payload: Any, templateData: TemplateData = [:])

        /// generates a YAML payload.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - payload: The payload to generate the data from.
        ///   - templateData: Additional values that can be injected into the text.
        case yaml(_ payload: Any, templateData: TemplateData = [:])

        /// Returns the passed text as the body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - text: The text to be used as the body of the response.
        ///   - templateData: Additional values that can be injected into the text.
        case text(_ text: String, templateData: TemplateData = [:])

        /// Use the data returned from the passed file url as the body of response.
        case file(_ url: URL, contentType: any HTTPContentTypeProvider)

        /// Returns raw data as the specified content type.
        ///
        /// - parameters
        ///     - data: The data to be returned. This will be encoded if necessary.
        ///     - contentType: The content type to pass in the `Content-Type` header.
        case data(_ data: Data, contentType: any HTTPContentTypeProvider)
    }
}

