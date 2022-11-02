//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/10/2022.
//

import Foundation
import GraphQL

/// Simple data structure representing a GraphQL request.
///
/// Note that this is not meant to be a full useable GraphQL request. For that
/// use the GraphQL API directory. This version is for the purposes of matching
/// and analysing incoming requests for the purposes of then returning mocks.
///
/// _This is NOT a working GraphQL implementation._
public class GraphQLRequest {

    private let unNamedKey = ""

    public let rawQuery: String
    public var defaultOperation: Operation? {
        operations[unNamedKey]
    }

    public private(set) var operations: [String: Operation] = [:]
    public private(set) var fragments: [Fragment] = []
    public private(set) var variables: [String: Any]
    public let selectedOperation: String?

    // MARK: - Initialisers

    public init(query: String, operation: String? = nil, variables: [String: Any]? = nil) throws {
        rawQuery = query
        selectedOperation = operation
        self.variables = variables ?? [:]
        try analyse(query: query)
    }

    public convenience init(query: String, operation: String? = nil, variables: String? = nil) throws {
        // Assume any passed variables follow the GraphQL recommendation of being in a JSON dictionary form.
        var variablesDictionary: [String: Any]?
        if let variables,
           let data = variables.data(using: .utf8) {
            variablesDictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }

        try self.init(query: query, operation: operation, variables: variablesDictionary)
    }

    public convenience init?(request: HTTPRequest) throws {

        guard request.method == .GET,
              let escapedQuery = request.queryParameters.query,
              let query = escapedQuery.removingPercentEncoding else {
            return nil
        }

        try self.init(query: query,
                      operation: request.queryParameters.operationName,
                      variables: request.queryParameters.variables)
    }

    // MARK: - Analysing

    func analyse(query: String) throws {
        let source = Source(body: query)
        for definition in try parse(source: source).definitions {
            switch definition {
            case let gQLOperation as OperationDefinition:
                let operation = Operation(gQLOperation: gQLOperation)
                operations[operation.name ?? unNamedKey] = operation

            case let gQLFragment as FragmentDefinition:
                fragments.append(Fragment(gQLFragment: gQLFragment))

            default:
                break
            }
        }
    }
}
