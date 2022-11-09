//
//  Created by Derek Clarkson on 5/10/2022.
//

import AnyCodable
import Foundation
import Hummingbird
@testable import Voodoo

// Whilst using `Equatable` isn't my preferred method for asserts, with tests in this code base it makes more sense.

extension HBResponseBody: Equatable {

    public static func == (lhs: HummingbirdCore.HBResponseBody, rhs: HummingbirdCore.HBResponseBody) -> Bool {
        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.byteBuffer(let lhsBuffer), .byteBuffer(let rhsBuffer)):
            return lhsBuffer.data == rhsBuffer.data

        default:
            return false
        }
    }
}

extension HTTPResponse: Equatable {

    public static func == (lhs: Voodoo.HTTPResponse, rhs: Voodoo.HTTPResponse) -> Bool {
        switch (lhs, rhs) {
        case (.raw(let lhsStatus, let lhsHeaders, let lhsBody), .raw(let rhsStatus, let rhsHeaders, let rhsBody)):

            guard lhsHeaders?.count == rhsHeaders?.count else {
                return false
            }

            return lhsStatus == rhsStatus && lhsHeaders == rhsHeaders && lhsBody == rhsBody

        case (.javascript(let lhsScript), .javascript(let rhsScript)):
            return lhsScript == rhsScript

        case (.ok(let lhsHeaders, let lhsBody), .ok(let rhsHeaders, let rhsBody)),
             (.created(let lhsHeaders, let lhsBody), .created(let rhsHeaders, let rhsBody)),
             (.accepted(let lhsHeaders, let lhsBody), .accepted(let rhsHeaders, let rhsBody)):

            guard lhsHeaders?.count == rhsHeaders?.count else {
                return false
            }

            return lhsHeaders == rhsHeaders && lhsBody == rhsBody

        case (.movedPermanently(let lhsURL), .movedPermanently(let rhsURL)),
             (.permanentRedirect(let lhsURL), .permanentRedirect(let rhsURL)),
             (.temporaryRedirect(let lhsURL), .temporaryRedirect(let rhsURL)):
            return lhsURL == rhsURL

        case (.notFound, .notFound),
             (.notAcceptable, .notAcceptable),
             (.tooManyRequests, .tooManyRequests):
            return true

        case (.internalServerError(let lhsHeaders, let lhsBody), .internalServerError(let rhsHeaders, let rhsBody)):

            guard lhsHeaders?.count == rhsHeaders?.count else {
                return false
            }

            return lhsHeaders == rhsHeaders && lhsBody == rhsBody

        default:
            return false
        }
    }
}

extension HTTPResponse.Body: Equatable {

    public static func == (lhs: Voodoo.HTTPResponse.Body, rhs: Voodoo.HTTPResponse.Body) -> Bool {

        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.template(let lhsName, let lhsTemplateData, let lhsContentType), .template(let rhsName, let rhsTemplateData, let rhsContentType)):
            return lhsName == rhsName
                && AnyCodable(lhsTemplateData) == AnyCodable(rhsTemplateData)
                && lhsContentType == rhsContentType

        case (.text(let lhsText, let lhsTemplateData), .text(let rhsText, let rhsTemplateData)):
            return lhsText == rhsText
                && AnyCodable(lhsTemplateData) == AnyCodable(rhsTemplateData)

        case (.json(let lhs, let lhsTemplateData), .json(let rhs, let rhsTemplateData)),
             (.yaml(let lhs, let lhsTemplateData), .yaml(let rhs, let rhsTemplateData)):
            return AnyCodable(lhs) == AnyCodable(rhs)
                && AnyCodable(lhsTemplateData) == AnyCodable(rhsTemplateData)

        case (.data(let lhsData, let lhsContentType), .data(let rhsData, let rhsContentType)):
            return lhsData == rhsData
                && AnyCodable(lhsContentType) == AnyCodable(rhsContentType)

        case (.file(let lhsURL, let lhsContentType), .file(let rhsURL, let rhsContentType)):
            return lhsURL == rhsURL && lhsContentType == rhsContentType

        default:
            return false
        }
    }
}

// Template data comparisons.

extension [String: AnyCodable]? {
    static func == (_: Self, rhs: Self) -> Bool {
        switch (rhs, rhs) {
        case (.none, .none):
            return true
        case (.some(let lhs), .some(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
