//
//  File.swift
//
//
//  Created by Derek Clarkson on 2/11/2022.
//

import Foundation

/// ``Matchable`` allows a type to be matched against another type. What defines a "match" is left up to the type to determine.
protocol Matchable {

    /// Match this against another type and return 'true' if they match.
    /// - parameter other: The other instance to match.
    func matches(_ other: Self) -> Bool
}

// MARK: - GraphQL matching

extension GraphQLRequest: Matchable {

    /// With GraphQL a match is when all the operations, fragments and variables in this
    /// request are present in the other request. Effectively this means when this request
    /// is a subset of the other request. This is useful when we want to use a simple request
    /// as a means to match an incoming request.
    func matches(_ other: GraphQLRequest) -> Bool {
        var selectedOperationMatched = true
        if let selectedOperation {
            selectedOperationMatched = selectedOperation == other.selectedOperation
        }
        return selectedOperationMatched
        && operations.match(other.operations)
        && fragments.match(other.fragments)
    }
}

extension Operation: Matchable {
    func matches(_ other: Operation) -> Bool {
        name == other.name
        && type == other.type
        && fields.match(other.fields)
        && variables.match(other.variables)
        && directives.match(other.directives)
        && fragmentReferences.match(other.fragmentReferences)
    }
}

extension Fragment: Matchable {
    func matches(_ other: Fragment) -> Bool {
        name == other.name
            && directives.match(other.directives)
            && fragmentReferences.match(other.fragmentReferences)
            && fields.match(other.fields)
    }
}

extension Field: Matchable {
    func matches(_ other: Field) -> Bool {
        fieldName == other.fieldName
            && alias == other.alias
            && directives.match(other.directives)
            && arguments.match(other.arguments)
            && fragmentReferences.match(other.fragmentReferences)
            && fields.match(other.fields)
    }
}

extension FragmentReference: Matchable {
    func matches(_ other: FragmentReference) -> Bool {
        name == other.name && directives.match(other.directives)
    }
}

extension Directive: Matchable {
    func matches(_ other: Directive) -> Bool {
        name == other.name && arguments.match(other.arguments)
    }
}

extension Argument: Matchable {
    func matches(_ other: Argument) -> Bool {
        name == other.name && match(value, matches: other.value)
    }
}

extension Variable: Matchable {
    func matches(_ other: Variable) -> Bool {
        name == other.name
    }
}

// MARK: - Supporting functions

/// Used to compare the fields in dictionary with the fields from another dictionary.
extension Dictionary where Key == String, Value: Matchable {

    /// Compares the contents of this dictionary with the contents of a second dictionary
    /// and returns `true` if all the elements of this array match with an element
    /// in the other array. The size of the dictionaries is not part of the match, and
    /// multiple elements may match the same element in the other array.
    ///
    /// - parameter other: The dictionary to match against.
    func match(_ other: [Key: Value]) -> Bool {
        allSatisfy { thisKeyValue in
            if let otherMatchable = other[thisKeyValue.key] {
                return thisKeyValue.value.matches(otherMatchable)
            }
            return false
        }
    }
}

/// This extension adds support for ``Matchable`` arrays.
extension Array where Element: Matchable {

    /// Compares the contents of this array with the contents of a second array
    /// and returns `true` if all the elements of this array match with an element
    /// in the other array. The order of size of the arrays is not part of the match and
    /// multiple elements may match the same element in the other array.
    ///
    /// - parameter other: The array to match against.
    func match(_ other: [Element]) -> Bool {
        allSatisfy { item in
            other.contains { item.matches($0) }
        }
    }
}

extension Matchable {

    /// This is used to match primitive non-matchable values.
    func match(_ value: Any?, matches otherValue: Any?) -> Bool {

        // If this value is `nil` we are ignoring the match so return a success.
        guard let value else { return true }

        // If the other value is nil then the match fails.
        guard let otherValue else { return false }

        switch (value, otherValue) {

        case (let x as Bool, let y as Bool):
            return x == y

        case (let x as Double, let y as Double):
            return x == y

        case (let x as Float, let y as Float):
            return x == y

        case (let x as Int, let y as Int):
            return x == y

        case (let x as String, let y as String):
            return x == y

        default:
            return false
        }
    }
}
