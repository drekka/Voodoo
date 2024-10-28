import Foundation
import PathKit

private enum RESTEndpointKeys: CodingKey {
    case http
    case response

    enum SelectorKeys: CodingKey {
        case api
    }

    enum ResponseKeys: CodingKey {
        case response
        case javascript
        case javascriptFile
    }
}

extension RESTEndpoint: DecodableEndpoint {

    static func canDecode(from decoder: Decoder) throws -> Bool {
        let container = try decoder.container(keyedBy: RESTEndpointKeys.self)
        return container.contains(.http) && container.contains(.response)
    }

    public init(from decoder: Decoder) throws {

        let configurationFile = decoder.userInfo.configurationFile

        // First decode the HTTP method and path used to select this response.
        let restContainer = try decoder.container(keyedBy: RESTEndpointKeys.self)
        let selectorContainer = try restContainer.nestedContainer(keyedBy: RESTEndpointKeys.SelectorKeys.self, forKey: .http)

        let methodPath = try selectorContainer.methodPath(in: configurationFile)
        method = methodPath.0
        path = methodPath.1

        // Now decode the response.
        let responseContainer = try restContainer.nestedContainer(keyedBy: RESTEndpointKeys.ResponseKeys.self, forKey: .response)
        if let response = try responseContainer.decodeIfPresent(HTTPResponse.self, forKey: .response) {
            self.response = response

        } else if let javascript = try responseContainer.decodeIfPresent(String.self, forKey: .javascript) {
            response = .javascript(javascript)

        } else if let javascriptFileReference = try responseContainer.decodeIfPresent(String.self, forKey: .javascriptFile) {
            let parentFolder = configurationFile.parent()
            let javascriptFile = (parentFolder + Path(javascriptFileReference)).normalize()
            guard javascriptFile.exists else {
                throw VoodooError.Configuration.referencedFileNotFound(configurationFile, javascriptFileReference)
            }
            response = .javascript(try javascriptFile.read())
        }

        throw VoodooError.Configuration.unknownResponse(configurationFile, "\(method) \(path)")
    }
}

private extension KeyedDecodingContainer where Key == RESTEndpointKeys.SelectorKeys {

    /// Scans the response's method and path from it's `api` value, asusming it's in the format
    ///  "<method> <path>".
    func methodPath(in configurationFile: Path) throws -> (method: HTTPMethod, path: String) {

        // Get the request api property.
        let api = try decode(String.self, forKey: .api)

        VoodooLogger.log("Found HTTP endpoint selector: \(api)")

        // Split the api value into the method and path.
        let components = api.split(separator: " ").map(String.init)
        if components.endIndex != 2 {
            throw VoodooError.Configuration.invalidHTTPSelector(configurationFile, api)
        }
        guard let method = HTTPMethod(components[0]) else {
            throw VoodooError.Configuration.invalidHTTPSelector(configurationFile, api)
        }

        return (method: method, path: components[1])
    }

}
