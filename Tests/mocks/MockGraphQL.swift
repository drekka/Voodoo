//
//  File.swift
//
//
//  Created by Derek Clarkson on 2/11/2022.
//

import Foundation
@testable import GraphQL
@testable import SimulacraCore

// MARK: - Simulacra factories

extension SimulacraCore.Operation {
    static func mock(withName name: String,
                     type: GraphQL.OperationType,
                     variables: [(String, String, GraphQLValue?)] = [],
                     directives: [String] = [],
                     fields: [GraphQL.Field] = [],
                     fragmentReferences: [GraphQL.FragmentSpread] = []) -> SimulacraCore.Operation {
        let gQLVariableDefinitions = variables.map {
            GraphQL.VariableDefinition(variable: GraphQL.Variable(name: $0.0.gQLName), type: NamedType(name: $0.1.gQLName), defaultValue: $0.2.gQLValue)
        }
        let gQLOperation = GraphQL.OperationDefinition(operation: type,
                                                       name: name.gQLName,
                                                       variableDefinitions: gQLVariableDefinitions,
                                                       directives: directives.gQLDirectives,
                                                       selectionSet: GraphQL.SelectionSet(selections: fields + fragmentReferences))
        return Operation(gQLOperation: gQLOperation)
    }
}

extension SimulacraCore.Fragment {
    static func mock(withName name: String,
                     directives: [String] = [],
                     fields: [GraphQL.Field] = [],
                     fragmentReferences: [GraphQL.FragmentSpread] = []) -> SimulacraCore.Fragment {
        let gQLFragmentDefinition = GraphQL.FragmentDefinition(name: name.gQLName,
                                                               typeCondition: "".gQLNamedType,
                                                               directives: directives.gQLDirectives,
                                                               selectionSet: GraphQL.SelectionSet(selections: fields + fragmentReferences))
        return Fragment(gQLFragment: gQLFragmentDefinition)
    }
}

extension SimulacraCore.Field {

    static func mock(withName name: String,
                     alias: String? = nil,
                     directives: [String] = [],
                     arguments: [(String, GraphQLValue?)] = [],
                     fields: [GraphQL.Field] = [],
                     fragmentReferences: [GraphQL.FragmentSpread] = []) -> SimulacraCore.Field {
        let gQLField = mockGraphQLField(withName: name,
                                        alias: alias,
                                        directives: directives,
                                        arguments: arguments,
                                        fields: fields,
                                        fragmentReferences: fragmentReferences)
        return Field(gQLSelection: gQLField)!
    }

    static func mockGraphQLField(withName name: String,
                                 alias: String? = nil,
                                 directives: [String] = [],
                                 arguments: [(String, GraphQLValue?)] = [],
                                 fields: [GraphQL.Field] = [],
                                 fragmentReferences: [GraphQL.FragmentSpread] = []) -> GraphQL.Field {
        GraphQL.Field(alias: alias?.gQLName,
                      name: name.gQLName,
                      arguments: arguments.gQLArguments,
                      directives: directives.gQLDirectives,
                      selectionSet: GraphQL.SelectionSet(selections: fields + fragmentReferences))
    }

    static func mockGraphQLFragmentSpread(withName name: String,
                                          directives: [String] = []) -> GraphQL.FragmentSpread {
        GraphQL.FragmentSpread(name: name.gQLName, directives: directives.gQLDirectives)
    }
}

extension SimulacraCore.FragmentReference {
    static func mock(withName name: String, directives: [String] = []) -> SimulacraCore.FragmentReference {
        let gQLDirectives = directives.gQLDirectives
        let selection = GraphQL.FragmentSpread(name: name.gQLName, directives: gQLDirectives)
        return FragmentReference(gQLSelection: selection)!
    }
}

extension SimulacraCore.Directive {
    static func mock(withName name: String, arguments: [(String, GraphQLValue?)] = []) -> SimulacraCore.Directive {
        let gQLArguments = arguments.gQLArguments
        let gQLDirective = GraphQL.Directive(name: name.gQLName, arguments: gQLArguments)
        return Directive(gQLDirective: gQLDirective)
    }
}

extension SimulacraCore.Argument {

    static func mock(withName name: String, value: GraphQLValue? = nil) -> SimulacraCore.Argument {
        let gQLArgument = GraphQL.Argument(name: name.gQLName, value: value.gQLValue)
        return Argument(gQLArgument: gQLArgument)
    }
}

extension SimulacraCore.Variable {

    static func mock(withName name: String, type: String, defaultValue: GraphQLValue? = nil) -> SimulacraCore.Variable {
        let gQLVariable = GraphQL.Variable(name: name.gQLName)
        let gQLVariableDefinition = GraphQL.VariableDefinition(variable: gQLVariable, type: type.gQLNamedType, defaultValue: defaultValue.gQLValue)
        return Variable(gQLVariableDefinition: gQLVariableDefinition)
    }
}

// MARK: - Supporting factories

extension Array where Element == String {
    var gQLDirectives: [GraphQL.Directive] {
        map { GraphQL.Directive(name: $0.gQLName, arguments: []) }
    }
}

extension Array where Element == (String, GraphQLValue?) {
    var gQLArguments: [GraphQL.Argument] {
        map { GraphQL.Argument(name: $0.0.gQLName, value: $0.1.gQLValue) }
    }
}

// MARK: - Value factories

protocol GraphQLValue {
    var gQLValue: Value { get }
}

extension Optional: GraphQLValue where Wrapped == GraphQLValue {
    var gQLValue: Value {
        guard case .some(let value) = self else {
            return GraphQL.NullValue()
        }
        return value.gQLValue
    }
}

extension String {

    var gQLName: GraphQL.Name {
        GraphQL.Name(value: self)
    }

    var gQLNamedType: GraphQL.NamedType {
        GraphQL.NamedType(name: GraphQL.Name(value: self))
    }
}

extension String: GraphQLValue {
    var gQLValue: Value {
        if hasPrefix("$") {
            return GraphQL.Variable(name: GraphQL.Name(value: String(dropFirst(1))))
        }
        return GraphQL.StringValue(value: self)
    }
}

extension Int: GraphQLValue {
    var gQLValue: Value {
        GraphQL.IntValue(value: String(self))
    }
}
