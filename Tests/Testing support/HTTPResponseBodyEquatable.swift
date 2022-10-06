//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
@testable import SimulcraCore

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
