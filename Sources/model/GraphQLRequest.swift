import AnyCodable
import Foundation
import GraphQL

/// Used to decode a incoming request.
struct GraphQLPayload: Codable {
    let query: String
    let operation: String?
    let variables: AnyCodable?
}

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

    /// Default initializer
    public init(query: String, operation: String? = nil, variables: [String: Any]? = nil) throws {
        rawQuery = query
        selectedOperation = operation
        self.variables = variables ?? [:]
        try analyse(query: query)
    }

    /// Convenience initializer for parsing variable strings.
    public convenience init(query: String, operation: String? = nil, variables: String?) throws {
        // Assume any passed variables follow the GraphQL recommendation of being in a JSON dictionary form.
        var variablesDictionary: [String: Any]?
        if let variables,
           let data = variables.data(using: .utf8) {
            variablesDictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }

        try self.init(query: query, operation: operation, variables: variablesDictionary)
    }

    /// Convenience intializer for reading queries from incoming requests.
    public convenience init(request: HTTPRequest) throws {

        switch request.method {

        case .GET:
            guard let escapedQuery = request.queryParameters.query,
                  let query = escapedQuery.removingPercentEncoding else {
                throw VoodooError.invalidGraphQLRequest("Missing GraphQL query argument.")
            }
            try self.init(query: query,
                          operation: request.queryParameters.operationName,
                          variables: request.queryParameters.variables)

        // If the content type is graphQL then treat the whole body as the query.
        // Per https://graphql.org/learn/serving-over-http/#post-request
        case .POST where request.contentType(is: .applicationGraphQL):
            guard let body = request.body,
                  let query = String(data: body, encoding: .utf8) else {
                throw VoodooError.invalidGraphQLRequest("Missing GraphQL query argument in body of request.")
            }
            try self.init(query: query)

        // If the content type is JSON then assume the body contains a dictionary.
        // Per https://graphql.org/learn/serving-over-http/#post-request
        case .POST where request.contentType(is: .applicationJSON):
            guard let body = request.body,
                  let content = try? JSONDecoder().decode(GraphQLPayload.self, from: body) else {
                throw VoodooError.invalidGraphQLRequest("Missing GraphQL query argument in body of request.")
            }
            try self.init(query: content.query,
                          operation: content.operation,
                          variables: content.variables?.value as? [String: Any])

        default:
            throw VoodooError.invalidGraphQLRequest("GraphQL endpoing only accepts GET and POST requests.")
        }
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
