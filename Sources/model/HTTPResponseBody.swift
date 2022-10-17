//
//  File.swift
//
//
//  Created by Derek Clarkson on 6/10/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import Yams

public extension HTTPResponse {

    /// Used to define what sort of output is expected when encoding the data.
    enum Output {
        case json
        case yaml
    }

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
        case template(_ templateName: String, templateData: TemplateData? = nil, contentType: String = ContentType.applicationJSON)

        /// generates structured data form the passed payload.
        ///
        /// By default this produces JSON, but other formats can be added in the future.
        /// Before returning the text will be passed to the Mustache template engine with the template data.
        ///
        /// - parameters:
        ///   - payload: The payload to generate the data from.
        ///   - output: The output format to use for the data.
        ///   - templateData: Additional values that can be injected into the structured text.
        case structured(_ payload: StructuredData, output: Output = .json, templateData: TemplateData? = nil)

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
        case type
        case text
        case url
        case data
        case name
        case contentType
        case templateData
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(String.self, forKey: .type)
        switch type {

        case "empty":
            self = .empty

        case "text":
            let text = try container.decode(String.self, forKey: .text)
            let templateData = try container.decodeIfPresent([String: StructuredData].self, forKey: .templateData)
            self = .text(text, templateData: templateData)

        case "data":
            let data = try container.decode(Data.self, forKey: .data)
            let contentType = try container.decode(String.self, forKey: .contentType)
            self = .data(data, contentType: contentType)

        case "json":
            let json = try container.decode(StructuredData.self, forKey: .data)
            let templateData = try container.decodeIfPresent([String: StructuredData].self, forKey: .templateData)
            self = .structured(json, output: .json, templateData: templateData)

        case "yaml":
            let yaml = try container.decode(StructuredData.self, forKey: .data)
            let templateData = try container.decodeIfPresent([String: StructuredData].self, forKey: .templateData)
            self = .structured(yaml, output: .yaml, templateData: templateData)

        case "file":
            let fileURL = try container.decode(URL.self, forKey: .url)
            let contentType = try container.decode(String.self, forKey: .contentType)
            self = .file(fileURL, contentType: contentType)

        case "template":
            let name = try container.decode(String.self, forKey: .name)
            let templateData = try container.decodeIfPresent([String: StructuredData].self, forKey: .templateData)
            let contentType = try container.decode(String.self, forKey: .contentType)
            self = .template(name, templateData: templateData, contentType: contentType)

        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown value '\(type)'")
        }
    }
}

/// Supports creating Hummingbird data.
extension HTTPResponse.Body {

    func hbBody(forRequest request: HTTPRequest, serverContext context: SimulcraContext) throws -> (HBResponseBody, String?) {
        switch self {

        case .empty:
            return (.empty, nil)

        case .text(let text, let templateData):
            return (try text.render(withTemplateData: templateData, forRequest: request, context: context), ContentType.textPlain)

        case .data(let data, let contentType):
            return (data.hbResponseBody, contentType)

        case .structured(let payload, let output, let templateData):
            switch output {
            case .json:
                return (try JSONEncoder().encode(payload)
                    .render(withTemplateData: templateData, forRequest: request, context: context), ContentType.applicationJSON)
            case .yaml:
                return (try YAMLEncoder().encode(payload)
                    .render(withTemplateData: templateData, forRequest: request, context: context), ContentType.applicationYAML)
            }

        case .file(let url, let contentType):
            return (try Data(contentsOf: url).hbResponseBody, contentType)

        case .template(let templateName, let templateData, let contentType):
            let finalTemplateData = context.requestTemplateData(forRequest: request, adding: templateData)
            guard let json = context.mustacheRenderer.render(finalTemplateData, withTemplate: templateName) else {
                throw SimulcraError.templateRenderingFailure("Rendering template '\(templateName)' failed.")
            }
            return (json.hbResponseBody, contentType)
        }
    }
}

// MARK: - Supporting extensions

extension Data {
    /// Renders this data as a response body.
    ///
    /// - parameters:
    ///     - templateData: Additional data that can be injected into this string assuming this string contains mustache keys.
    ///     - request: the request being fulfilled.
    ///     - context: The server context.
    func render(withTemplateData templateData: TemplateData?, forRequest request: HTTPRequest, context: SimulcraContext) throws -> HBResponseBody {
        guard let string = String(data: self, encoding: .utf8) else {
            throw SimulcraError.conversionError("Unable to convert data to a String")
        }
        return try string.render(withTemplateData: templateData, forRequest: request, context: context)
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
    func render(withTemplateData templateData: TemplateData?, forRequest request: HTTPRequest, context: SimulcraContext) throws -> HBResponseBody {
        let finalTemplateData = context.requestTemplateData(forRequest: request, adding: templateData)
        return try HBMustacheTemplate(string: self).render(finalTemplateData).hbResponseBody
    }
}

extension Data {

    var hbResponseBody: HBResponseBody {
        .byteBuffer(ByteBuffer(data: self))
    }
}
