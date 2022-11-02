//
//  File.swift
//
//
//  Created by Derek Clarkson on 31/10/2022.
//

import Foundation
import GraphQL

// The primary purpose here is to map the more complex GraphQL type into some local types that we can compare easily to incoming requests.

/// Core GraphQL operation.
public struct Operation: FieldContainer {
    public let type: OperationType
    public let name: String?
    public let variables: [Variable]
    public let directives: [Directive]
    public let fields: [String: Field]
    public let fragmentReferences: [FragmentReference]

    init(gQLOperation: GraphQL.OperationDefinition) {
        type = gQLOperation.operation
        name = gQLOperation.name?.value
        variables = gQLOperation.variableDefinitions.map(Variable.init(gQLVariableDefinition:))
        directives = gQLOperation.directives.map(Directive.init(gQLDirective:))
        fields = gQLOperation.selectionSet.selections.fields
        fragmentReferences = gQLOperation.selectionSet.selections.compactMap(FragmentReference.init(gQLSelection:))
    }
}

public struct Fragment: FieldContainer {
    public let name: String
    public let directives: [Directive]
    public let fields: [String: Field]
    public let fragmentReferences: [FragmentReference]
    init(gQLFragment: GraphQL.FragmentDefinition) {
        name = gQLFragment.name.value
        directives = gQLFragment.directives.map(Directive.init(gQLDirective:))
        fields = gQLFragment.selectionSet.selections.fields
        fragmentReferences = gQLFragment.selectionSet.selections.compactMap(FragmentReference.init(gQLSelection:))
    }
}

public struct Field: FieldContainer {
    public let fieldName: String
    public let alias: String?
    public let directives: [Directive]
    public let arguments: [Argument]
    public let fields: [String: Field]
    public let fragmentReferences: [FragmentReference]

    init?(gQLSelection: GraphQL.Selection) {
        guard let gQLField = gQLSelection as? GraphQL.Field else {
            return nil
        }
        fieldName = gQLField.name.value
        alias = gQLField.alias?.value
        directives = gQLField.directives.map(Directive.init(gQLDirective:))
        arguments = gQLField.arguments.map(Argument.init(gQLArgument:))
        fields = gQLField.selectionSet?.selections.fields ?? [:]
        fragmentReferences = gQLField.selectionSet?.selections.compactMap(FragmentReference.init(gQLSelection:)) ?? []
    }
}

public struct FragmentReference {
    public let name: String
    public let directives: [Directive]
    init?(gQLSelection: GraphQL.Selection) {
        guard let gQLFragmentReference = gQLSelection as? GraphQL.FragmentSpread else {
            return nil
        }
        name = gQLFragmentReference.name.value
        directives = gQLFragmentReference.directives.map(Directive.init(gQLDirective:))
    }
}

public struct Directive {
    public let name: String
    public let arguments: [Argument]
    init(gQLDirective: GraphQL.Directive) {
        name = gQLDirective.name.value
        arguments = gQLDirective.arguments.map(Argument.init(gQLArgument:))
    }
}

public struct Argument {
    public let name: String
    public let value: Any?
    init(gQLArgument: GraphQL.Argument) {
        name = gQLArgument.name.value
        value = gQLArgument.value.rawValue
    }
}

public struct Variable {
    public let name: String
    public let type: String
    public let defaultValue: Any?
    init(gQLVariableDefinition: GraphQL.VariableDefinition) {
        name = gQLVariableDefinition.variable.name.value
        type = (gQLVariableDefinition.type as? NamedType)?.name.value ?? "[Unknown]"
        defaultValue = gQLVariableDefinition.defaultValue?.rawValue
    }
}

// MARK: - Dynamic member lookup

/// Common field lookup for GraphQL field containers.
@dynamicMemberLookup
public protocol FieldContainer {
    var fields: [String: Field] { get }
    subscript(dynamicMember _: String) -> Field? { get }
}

public extension FieldContainer {
    subscript(dynamicMember fieldName: String) -> Field? {
        fields[fieldName]
    }
}

// MARK: - Support functions

extension GraphQL.Value {
    var rawValue: Any? {
        switch self {
        case let value as IntValue: return Int(value.value)
        case let value as FloatValue: return Double(value.value)
        case let value as StringValue: return value.value
        case let value as BooleanValue: return value.value
        case is NullValue: return nil
        case let value as EnumValue: return value.value
        case let value as ListValue: return value.values.map { $0.rawValue }
        case let value as ObjectValue: return Dictionary(value.fields.map { ($0.name.value, $0.value.rawValue) }) { $1 }
        default: return nil
        }
    }
}

extension Array where Element == Selection {
    var fields: [String: Field] {
        Dictionary(uniqueKeysWithValues: compactMap {
            guard let field = Field(gQLSelection: $0) else {
                return nil
            }
            return (field.alias ?? field.fieldName, field)
        })
    }
}
