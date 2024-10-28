import AnyCodable
import Foundation
import GraphQL
import Hummingbird

/// Simple data structure representing a GraphQL request.
///
/// Note that this is not meant to be a full useable GraphQL request. For that
/// use the GraphQL API directory. This version is for the purposes of matching
/// and analysing incoming requests for the purposes of returning mocked payloads.
///
/// _This is NOT a working GraphQL implementation._
public protocol GraphQLRequest {
    var rawQuery: String { get }
    var operations: [String: Operation] { get }
    var fragments: [Fragment] { get }
    var variables: [String: Any] { get }
    var selectedOperation: String? { get }
}
