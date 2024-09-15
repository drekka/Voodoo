import AnyCodable
import Foundation
import Hummingbird
import Yams
import PathKit

public extension HTTPResponse {

    /// Defines the body of a response where a response can have one.
    enum Body {

        /// No body to be returned.
        case empty

        /// Loads the body from a template registered with the Mustache template engine.
        ///
        /// - parameters:
        ///   - templateName: The name of the template as registered in the template engine.
        ///   - templateData: A dictionary containing additional data required by the template.
        ///   - contentType: The `content-type` to be returned in the HTTP response. This should match the content-type of the template.
        case template(_ templateName: String, templateData: TemplateData? = nil, contentType: HTTPHeader.ContentType = .applicationJSON)

        /// generates a JSON payload.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - payload: The payload to generate the data from.
        ///   - templateData: Additional values that can be injected into the text.
        case json(_ payload: Any, templateData: TemplateData? = nil)

        /// generates a YAML payload.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - payload: The payload to generate the data from.
        ///   - templateData: Additional values that can be injected into the text.
        case yaml(_ payload: Any, templateData: TemplateData? = nil)

        /// Returns the passed text as the body.
        ///
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - text: The text to be used as the body of the response.
        ///   - templateData: Additional values that can be injected into the text.
        case text(_ text: String, templateData: TemplateData? = nil)

        /// Use the data returned from the passed file path as the body of response.
        case file(_ path: Path, contentType: HTTPHeader.ContentType)

        /// Returns raw data as the specified content type.
        ///
        /// - parameters
        ///     - data: The data to be returned. This will be encoded if necessary.
        ///     - contentType: The content type to pass in the `Content-Type` header.
        case data(_ data: Data, contentType: HTTPHeader.ContentType)
    }
}

/// This extension supports decoding response body objects from javascript or YAML.
///
/// In the data the field `type` contains the enum to map into. The rest of the fields depend on what
/// the `type` has defined.
extension HTTPResponse.Body: Decodable {

    enum CodingKeys: String, CodingKey {

        // Fields
        case text
        case file
        case json
        case yaml
        case template

        // Optional extra fields
        case contentType
        case templateData
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self = try .text(text, templateData: container.templateData)
            return
        }

        if let json = try container.decodeIfPresent(AnyCodable.self, forKey: .json)?.value {
            self = try .json(json, templateData: container.templateData)
            return
        }

        if let yml = try container.decodeIfPresent(AnyCodable.self, forKey: .yaml)?.value {
            self = try .yaml(yml, templateData: container.templateData)
            return
        }

        if let filePath = try container.decodeIfPresent(Path.self, forKey: .file) {
            self = try .file(filePath, contentType: container.contentType)
            return
        }

        if let name = try container.decodeIfPresent(String.self, forKey: .template) {
            self = try .template(name, templateData: container.templateData, contentType: container.contentType)
            return
        }

        let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to determine response body. Possibly incorrect or invalid keys.")
        throw DecodingError.dataCorrupted(context)
    }
}
