import Foundation
import Hummingbird
import Yams
import AnyCodable

extension HTTPResponse.Body {

    func hbBody(forRequest request: HTTPRequest, context: ServerContext) throws -> (HBResponseBody, HTTPHeader.ContentType?) {
        switch self {

        case .empty:
            return (.empty, nil)

        case .text(let text, let templateData):
            let payload = try context.templateRenderer.render(text: text, for: request, withCachedData: context.cache,responseData: templateData)
            return (payload.hbResponseBody, .textPlain)

        case .data(let data, let contentType):
            return (data.hbResponseBody, contentType)

        case .json(let payload, let templateData):
            do {
                let template = switch payload {
                case let payload as String: payload
                case let payload as Encodable: try JSONEncoder().encode(payload).string()
                default: try JSONSerialization.data(withJSONObject: payload).string()
                }
                let payload = try context.templateRenderer.render(text: template, for: request, withCachedData: context.cache, responseData: templateData)
                return (payload.hbResponseBody, .applicationJSON)

            } catch {
                throw VoodooError.conversionError("Unable to convert '\(payload)' to JSON: \(error.localizedDescription)")
            }

        case .yaml(let payload, let templateData):
            do {
                let template = switch payload {
                case let payload as String: payload
                case let payload as Encodable: try YAMLEncoder().encode(payload)
                default: try YAMLEncoder().encode(AnyCodable(payload))
                }
                let payload = try context.templateRenderer.render(text: template, for: request, withCachedData: context.cache, responseData: templateData)
                return (payload.hbResponseBody, .applicationYAML)

            } catch {
                throw VoodooError.conversionError("Unable to convert '\(payload)' to YAML: \(error.localizedDescription)")
            }

        case .file(let path, let contentType):
            return try (path.read().hbResponseBody, contentType)

        case .template(let templateName, let templateData, let contentType):
            let payload = try context.templateRenderer.render(template: templateName, for: request, withCachedData: context.cache, responseData: templateData)
            return (payload.hbResponseBody, contentType)
        }
    }
}
