import Foundation
import AnyCodable

extension HTTPResponse.Body: Decodable {

    private enum CodingKeys: String, CodingKey {

        // Response types
        case text
        case file
        case json
        case yaml
        case template

        // Optional extra data that can be added to the above types.
        case contentType
        case templateData
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try decoding a raw text response.
        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self = try .text(text, templateData: container.decodedTemplateData)
            return
        }

        // Try decoding a JSON response
        if let json = try container.decodeIfPresent(AnyCodable.self, forKey: .json)?.value {
            self = try .json(json, templateData: container.decodedTemplateData)
            return
        }

        // Try decoding a YAML response.
        if let yml = try container.decodeIfPresent(AnyCodable.self, forKey: .yaml)?.value {
            self = try .yaml(yml, templateData: container.decodedTemplateData)
            return
        }

        // Try decoding a reference to a file.
        if let filePath = try container.decodeIfPresent(String.self, forKey: .file) {
            let fileURL = URL(fileURLWithPath: filePath)
            self = try .file(fileURL, contentType: container.decodedContentType)
            return
        }

        // Try decoding a template reference.
        if let name = try container.decodeIfPresent(String.self, forKey: .template) {
            self = try .template(name, templateData: container.decodedTemplateData, contentType: container.decodedContentType)
            return
        }

        // Otherwise throw an error.
        throw VoodooError.Configuration.unknownResponse(decoder.configurationFile, <#T##String#>)
    }
}
