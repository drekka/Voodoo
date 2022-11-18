//
//  Created by Derek Clarkson on 6/10/2022.
//

import AnyCodable
import Foundation
import Hummingbird
import HummingbirdMustache
import Yams

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
        case template(_ templateName: String, templateData: TemplateData? = nil, contentType: String = Header.ContentType.applicationJSON)

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

        /// Use the data returned from the passed file url as the body of response.
        case file(_ url: URL, contentType: String)

        /// Returns raw data as the specified content type.
        ///
        /// - parameters
        ///     - data: The data to be returned. This will be encoded if necessary.
        ///     - contentType: The content type to pass in the `Content-Type` header.
        case data(_ data: Data, contentType: String)
    }
}

/// This extension supports decoding response body objects from javascript or YAML.
///
/// In the data the field `type` contains the enum to map into. The rest of the fields depend on what
/// the `type` has defined.
extension HTTPResponse.Body: Decodable {

    enum CodingKeys: String, CodingKey {

        // Types
        case text
        case file
        case json
        case yaml
        case template

        // Optional extra data
        case contentType
        case templateData
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self = .text(text, templateData: try container.templateData)
            return
        }

        if let json = try container.decodeIfPresent(AnyCodable.self, forKey: .json)?.value {
            self = .json(json, templateData: try container.templateData)
            return
        }

        if let yml = try container.decodeIfPresent(AnyCodable.self, forKey: .yaml)?.value {
            self = .yaml(yml, templateData: try container.templateData)
            return
        }

        if let filePath = try container.decodeIfPresent(String.self, forKey: .file) {
            let fileURL = URL(fileURLWithPath: filePath)
            self = .file(fileURL, contentType: try container.contentType)
            return
        }

        if let name = try container.decodeIfPresent(String.self, forKey: .template) {
            self = .template(name, templateData: try container.templateData, contentType: try container.contentType)
            return
        }

        let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to determine response body. Possibly incorrect or invalid keys.")
        throw DecodingError.dataCorrupted(context)
    }
}

extension KeyedDecodingContainer where Key == HTTPResponse.Body.CodingKeys {

    var contentType: String {
        get throws {
            try decodeIfPresent(String.self, forKey: .contentType) ?? Header.ContentType.applicationJSON
        }
    }

    var templateData: [String: Any]? {
        get throws {
            try decodeIfPresent(AnyCodable.self, forKey: .templateData)?.value as? [String: Any]
        }
    }
}

// MARK: - Getting Hummingbird responses

extension HTTPResponse.Body {

    func hbBody(forRequest request: HTTPRequest, serverContext context: VoodooContext) throws -> (HBResponseBody, String?) {
        switch self {

        case .empty:
            return (.empty, nil)

        case .text(let text, let templateData):
            return (try text.render(withTemplateData: templateData, forRequest: request, context: context), Header.ContentType.textPlain)

        case .data(let data, let contentType):
            return (data.hbResponseBody, contentType)

        case .json(let payload, let templateData):

            do {
                let template: String
                switch payload {
                case let payload as String: template = payload
                case let payload as Encodable: template = try JSONEncoder().encode(payload).string()
                default: template = try JSONSerialization.data(withJSONObject: payload).string()
                }
                return (try template.render(withTemplateData: templateData, forRequest: request, context: context), Header.ContentType.applicationJSON)

            } catch {
                throw VoodooError.conversionError("Unable to convert '\(payload)' to JSON: \(error.localizedDescription)")
            }

        case .yaml(let payload, let templateData):
            do {
                let template: String
                switch payload {
                case let payload as String: template = payload
                case let payload as Encodable: template = try YAMLEncoder().encode(payload)
                default:
                    // Try wrapping and decoding.
                    let payload = AnyCodable(payload)
                    template = try YAMLEncoder().encode(payload)
                }
                return (try template.render(withTemplateData: templateData, forRequest: request, context: context), Header.ContentType.applicationYAML)

            } catch {
                throw VoodooError.conversionError("Unable to convert '\(payload)' to YAML: \(error.localizedDescription)")
            }

        case .file(let url, let contentType):
            return (try Data(contentsOf: url).hbResponseBody, contentType)

        case .template(let templateName, let templateData, let contentType):
            let finalTemplateData = context.requestTemplateData(forRequest: request, adding: templateData)
            if context.mustacheRenderer.getTemplate(named: templateName) == nil {
                throw VoodooError.templateRenderingFailure("Mustache template '\(templateName)' not found")
            }
            guard let payload = context.mustacheRenderer.render(finalTemplateData, withTemplate: templateName) else {
                throw VoodooError.templateRenderingFailure("Rendering template '\(templateName)' failed.")
            }
            return (payload.hbResponseBody, contentType)
        }
    }
}

// MARK: - Supporting extensions

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }

    func string() throws -> String {
        guard let string = String(data: self, encoding: .utf8) else {
            throw VoodooError.conversionError("Unable to convert data to a String")
        }
        return string
    }
}

extension String {

    /// Returns this string as a `HBRequestBody.byteBuffer`.
    var hbRequestBody: HBRequestBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    /// Returns this string as a `HBResponseBody.byteBuffer`.
    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(string: self))
    }

    /// Renders this string as a response body.
    ///
    /// - parameters:
    ///     - templateData: Additional data that can be injected into this string assuming this string contains mustache keys.
    ///     - request: The request being fulfilled.
    ///     - context: The server context.
    func render(withTemplateData templateData: TemplateData?, forRequest request: HTTPRequest, context: VoodooContext) throws -> HBResponseBody {
        let dynamicTemplate = try HBMustacheTemplate(string: self)
        context.mustacheRenderer.register(dynamicTemplate, named: "_dynamic")
        let finalTemplateData = context.requestTemplateData(forRequest: request, adding: templateData)
        guard let payload = context.mustacheRenderer.render(finalTemplateData, withTemplate: "_dynamic") else {
            throw VoodooError.templateRenderingFailure("Rendering template failed.")
        }
        return payload.hbResponseBody
    }
}
