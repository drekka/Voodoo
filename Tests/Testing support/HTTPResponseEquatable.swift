//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Hummingbird
@testable import SimulcraCore

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

    public static func == (lhs: SimulcraCore.HTTPResponse, rhs: SimulcraCore.HTTPResponse) -> Bool {
        switch (lhs, rhs) {

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
             (.temporaryRedirect(let lhsURL), .temporaryRedirect(let rhsURL)):
            return lhsURL == rhsURL

        case (.notFound, .notFound),
            (.notAcceptable,.notAcceptable),
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

    public static func == (lhs: SimulcraCore.HTTPResponse.Body, rhs: SimulcraCore.HTTPResponse.Body) -> Bool {

        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.template(let lhsName, _, _), .template(let rhsName, _, _)):
            return lhsName == rhsName

        case (.text(let lhsText, _), .text(let rhsText, _)):
            return lhsText == rhsText // && lhsTemplateData == rhsTemplateData

        case (.json(let lhsJSON, _), .json(let rhsJSON, _)):
            return lhsJSON == rhsJSON // && lhsTemplateData == rhsTemplateData

        case (.data(let lhsData, let lhsContentType), .data(let rhsData, let rhsContentType)):
            return lhsData == rhsData && lhsContentType == rhsContentType

        default:
            return false
        }
    }
}
