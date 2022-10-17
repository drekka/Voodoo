//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
@testable import SimulcraCore

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

    public static func == (lhs: SimulcraCore.HTTPResponse.Body, rhs: SimulcraCore.HTTPResponse.Body) -> Bool {

        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.template(let lhsName, let lhsTemplateData, let lhsContentType), .template(let rhsName, let rhsTemplateData, let rhsContentType)):
            return lhsName == rhsName && lhsTemplateData == rhsTemplateData && lhsContentType == rhsContentType

        case (.text(let lhsText, let lhsTemplateData), .text(let rhsText, let rhsTemplateData)):
            return lhsText == rhsText && lhsTemplateData == rhsTemplateData

        case (.structured(let lhsData, let lhsOutput, let lhsTemplateData), .structured(let rhsData, let rhsOutput, let rhsTemplateData)):
            return lhsData == rhsData
                && lhsOutput == rhsOutput
                && lhsTemplateData == rhsTemplateData

        case (.data(let lhsData, let lhsContentType), .data(let rhsData, let rhsContentType)):
            return lhsData == rhsData && lhsContentType == rhsContentType

        case (.file(let lhsURL, let lhsContentType), .file(let rhsURL, let rhsContentType)):
            return lhsURL == rhsURL && lhsContentType == rhsContentType

        default:
            return false
        }
    }
}

// Template data comparisons.

extension Optional where Wrapped == [String: Any] {
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

extension Dictionary {

    static func == (lhs: Self, rhs: Self) -> Bool where Key == String, Value == Any {
        guard lhs.count == rhs.count else { return false }
        for key in lhs.keys {
            if (lhs[key] as? (any Hashable))?.hashValue != (rhs[key] as? (any Hashable))?.hashValue {
                return false
            }
        }
        return true
    }
}

extension StructuredData: Equatable {
    public static func == (lhs: SimulcraCore.StructuredData, rhs: SimulcraCore.StructuredData) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.boolean(let lhs), .boolean(let rhs)):
            return lhs == rhs
        case (.integer(let lhs), .integer(let rhs)):
            return lhs == rhs
        case (.double(let lhs), .double(let rhs)):
            return lhs == rhs
        case (.date(let lhs), .date(let rhs)):
            return lhs == rhs
        case (.array(let lhs), .array(let rhs)):
            return lhs == rhs
        case (.dictionary(let lhs), .dictionary(let rhs)):
            return lhs == rhs
        case (.encodable(let lhs), .encodable(let rhs)):
            return type(of: lhs) == type(of: rhs)
        default:
            return false
        }
    }
}

extension StructuredData {

    subscript(index: Int) -> StructuredData? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    subscript(key: String) -> StructuredData? {
        if case .dictionary(let dictionary) = self {
            return dictionary[key]
        }
        return nil
    }

    var asString: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    var asArray: [StructuredData]? {
        if case .array(let array) = self {
            return array
        }
        return nil
    }

    var asDictionary: [String: StructuredData]? {
        if case .dictionary(let dictionary) = self {
            return dictionary
        }
        return nil
    }
}
