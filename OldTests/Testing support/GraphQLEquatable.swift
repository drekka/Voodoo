//
//  Created by Derek Clarkson on 5/11/2022.
//

import Foundation
@testable import Voodoo

extension GraphQLSelector: Equatable {
    public static func == (lhs: GraphQLSelector, rhs: GraphQLSelector) -> Bool {
        switch (lhs, rhs) {
        case (.operations(let lhsOperations), .operations(let rhsOperations)):
            return lhsOperations == rhsOperations
        case (.query(let lhsSelector), .query(let rhsSelector)):
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
