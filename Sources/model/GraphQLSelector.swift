//
//  File.swift
//  
//
//  Created by Derek Clarkson on 11/11/2022.
//

import Foundation

/// Matches an incoming GraphQL request to the stored response.
public enum GraphQLSelector {

    /// By matching on one or more operation names in the request.
    ///
    /// All of the operation names must be present, however the incoming query can have other operation ames. ie. This does a partial match.
    case operations([String])

    /// By matching this graphQL request against the incoming request.
    ///
    /// If this request "matches", ie returns `true` from the ``Matchable.matches(...)``
    /// function then the response is returned.
    case query(GraphQLRequest)

    /// Convenience function that generates an ``operations(_:)-swift.enum.case``.
    ///
    /// This allows a developer to not have to type the brackets around a single operation name.
    public static func operations(_ names: String...) -> GraphQLSelector {
        .operations(names)
    }
}
