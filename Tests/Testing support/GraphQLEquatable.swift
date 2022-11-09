//
//  Created by Derek Clarkson on 5/11/2022.
//

import Foundation
@testable import Voodoo

extension GraphQLSelector: Equatable {
    public static func == (lhs: GraphQLSelector, rhs: GraphQLSelector) -> Bool {
        switch (lhs, rhs) {
        case (.operationName(let lhsOperationName), .operationName(let rhsOperationName)):
            return lhsOperationName == rhsOperationName
        case (.selector(let lhsSelector), .selector(let rhsSelector)):
            return lhsSelector == rhsSelector
        default:
            return false
        }
    }
}

extension GraphQLRequest: Equatable {
    public static func == (lhs: GraphQLRequest, rhs: GraphQLRequest) -> Bool {
        lhs.rawQuery == rhs.rawQuery
    }
}
