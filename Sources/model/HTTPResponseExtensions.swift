//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import NIOHTTP1

/// This extension supports decoding the response from javascript or YAML.
extension HTTPResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case statusCode
        case body
        case url
        case headers
        case javascript
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        let javascript = try container.decodeIfPresent(String.self, forKey: .javascript)

        switch (statusCode, javascript) {

        case (.some(let statusCode), .none):

            let status = HTTPResponseStatus(statusCode: statusCode)
            let body = try container.decodeIfPresent(HTTPResponse.Body.self, forKey: .body) ?? .empty
            let headers = try container.decodeIfPresent(HeaderDictionary.self, forKey: .headers)

            switch status {
            case .ok:
                self = .ok(headers: headers, body: body)

            case .created:
                self = .created(headers: headers, body: body)

            case .accepted:
                self = .accepted(headers: headers, body: body)

            case .movedPermanently:
                self = .movedPermanently(try container.decode(String.self, forKey: .url))

            case .temporaryRedirect:
                self = .movedTemporarily(try container.decode(String.self, forKey: .url))

            case .notFound:
                self = .notFound
            case .notAcceptable:
                self = .notAcceptable
            case .tooManyRequests:
                self = .tooManyRequests

            case .internalServerError:
                self = .internalServerError(headers: headers, body: body)

            default:
                self = .raw(status, headers: headers, body: body)
            }

        case (.none, .some(let javascript)):
            self = .javascript(javascript)

        case (.none, .none):
            throw DecodingError.dataCorruptedError(forKey: .statusCode, in: container, debugDescription: "Must have one of 'statusCode' or 'javascript'.")

        default:
            throw DecodingError.dataCorruptedError(forKey: .javascript, in: container, debugDescription: "Cannot have both 'statusCode' and 'javascript'.")
        }
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
        case data
        case json
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
            let templateData = try container.decodeIfPresent([String: String].self, forKey: .templateData)
            self = .text(text, templateData: templateData)

        case "data":
            let data = try container.decode(Data.self, forKey: .data)
            let contentType = try container.decode(String.self, forKey: .contentType)
            self = .data(data, contentType: contentType)

        case "json":
            let json = try container.decode(String.self, forKey: .json)
            let templateData = try container.decodeIfPresent([String: String].self, forKey: .templateData)
            self = .json(json, templateData: templateData)

        default: // Also handles .empty
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown value '\(type)'")
        }
    }
}
