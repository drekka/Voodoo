//
//  File.swift
//
//
//  Created by Derek Clarkson on 2/11/2022.
//

import Foundation
import Nimble
@testable import SimulacraCore
import XCTest

class GraphQLMatchingTests: XCTestCase {

    // MARK: - Requests

    func testRequest() throws {
        let incomingQuery = "query {jediHeros:hero{name}}"
        let matcherQuery = "query {jediHeros:hero{name}}"

        let incomingRequest = try GraphQLRequest(query: incomingQuery, operation: "jediHeros")
        let matcher = try GraphQLRequest(query: matcherQuery, operation: "jediHeros")

        expect(matcher.matches(incomingRequest)) == true
    }

    func testRequestMatchOneQueryFromManyUsingName() throws {
        let incomingQuery = """
        query empireHeros {
            hero(episode: EMPIRE) {
                name
            }
        }
        query jediHeros {
            hero(episode: JEDI) {
                name
            }
        }
        """
        let matcherQuery = "query jediHeros {hero{name}}"

        let incomingRequest = try GraphQLRequest(query: incomingQuery, operation: "jediHeros")
        let matcher = try GraphQLRequest(query: matcherQuery)

        expect(matcher.matches(incomingRequest)) == true
    }

    // MARK: - Operation

    func testOperation() {
        let o1 = Operation.mock(withName: "abc", type: .query)
        let o2 = Operation.mock(withName: "abc", type: .query)
        let o3 = Operation.mock(withName: "abc", type: .mutation)
        let o4 = Operation.mock(withName: "def", type: .query)
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o4)) == false
    }

    func testOperationWithVariables() {
        let o1 = Operation.mock(withName: "abc", type: .query, variables: [("def", "String", nil)])
        let o2 = Operation.mock(withName: "abc", type: .query, variables: [("def", "String", nil)])
        let o3 = Operation.mock(withName: "abc", type: .query, variables: [("123", "String", nil)])
        let o4 = Operation.mock(withName: "123", type: .query, variables: [("def", "String", nil)])
        let o5 = Operation.mock(withName: "abc",
                                type: .query,
                                variables: [("123", "String", nil),("def", "String", nil),("456", "String", nil)])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o4)) == false
        expect(o1.matches(o5)) == true
    }

    func testOperationWithVariablesPartialMatch() {
        let o1 = Operation.mock(withName: "abc", type: .query)
        let o2 = Operation.mock(withName: "abc", type: .query, variables: [("def", "String", nil)])
        let o3 = Operation.mock(withName: "123", type: .query, variables: [("def", "String", nil)])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
    }

    func testOperationWithDirectives() {
        let o1 = Operation.mock(withName: "abc", type: .query, directives: ["def"])
        let o2 = Operation.mock(withName: "abc", type: .query, directives: ["def"])
        let o3 = Operation.mock(withName: "abc", type: .query, directives: ["123"])
        let o4 = Operation.mock(withName: "123", type: .query, directives: ["def"])
        let o5 = Operation.mock(withName: "abc", type: .query, directives: ["123", "def", "456"])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o4)) == false
        expect(o1.matches(o5)) == true
    }

    func testOperationWithDirectivesPartialMatch() {
        let o1 = Operation.mock(withName: "abc", type: .query)
        let o2 = Operation.mock(withName: "abc", type: .query, directives: ["def"])
        let o3 = Operation.mock(withName: "123", type: .query, directives: ["abc"])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
    }

    func testOperationWithFields() {
        let o1 = Operation.mock(withName: "abc", type: .query, fields: [Field.mockGraphQLField(withName: "def")])
        let o2 = Operation.mock(withName: "abc", type: .query, fields: [Field.mockGraphQLField(withName: "def")])
        let o3 = Operation.mock(withName: "abc", type: .query, fields: [Field.mockGraphQLField(withName: "123")])
        let o4 = Operation.mock(withName: "123", type: .query, fields: [Field.mockGraphQLField(withName: "def")])
        let o5 = Operation.mock(withName: "abc",
                                type: .query,
                                fields: [
                                    Field.mockGraphQLField(withName: "123"),
                                    Field.mockGraphQLField(withName: "def"),
                                    Field.mockGraphQLField(withName: "456"),
                                ])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o4)) == false
        expect(o1.matches(o5)) == true
    }

    func testOperationWithFieldsPartialMatch() {
        let o1 = Operation.mock(withName: "abc", type: .query)
        let o2 = Operation.mock(withName: "abc", type: .query, fields: [Field.mockGraphQLField(withName: "def")])
        let o3 = Operation.mock(withName: "123", type: .query, fields: [Field.mockGraphQLField(withName: "abc")])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o3)) == false
    }

    func testOperationWithFragments() {
        let o1 = Operation.mock(withName: "abc", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let o2 = Operation.mock(withName: "abc", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let o3 = Operation.mock(withName: "abc", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "123")])
        let o4 = Operation.mock(withName: "123", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "abc")])
        let o5 = Operation.mock(withName: "abc",
                                type: .query,
                                fragmentReferences: [
                                    Field.mockGraphQLFragmentSpread(withName: "123"),
                                    Field.mockGraphQLFragmentSpread(withName: "def"),
                                    Field.mockGraphQLFragmentSpread(withName: "456"),
                                ])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
        expect(o1.matches(o4)) == false
        expect(o1.matches(o5)) == true
    }

    func testOperationWithFragmentsPartialMatch() {
        let o1 = Operation.mock(withName: "abc", type: .query)
        let o2 = Operation.mock(withName: "abc", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let o3 = Operation.mock(withName: "123", type: .query, fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "abc")])
        expect(o1.matches(o2)) == true
        expect(o1.matches(o3)) == false
    }

    // MARK: - Fragment

    func testFragment() {
        let f1 = Fragment.mock(withName: "abc")
        let f2 = Fragment.mock(withName: "abc")
        let f3 = Fragment.mock(withName: "xyz")
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
    }

    func testFragmentWithDirectives() {
        let f1 = Fragment.mock(withName: "abc", directives: ["def"])
        let f2 = Fragment.mock(withName: "abc", directives: ["def"])
        let f3 = Fragment.mock(withName: "abc", directives: ["123"])
        let f4 = Fragment.mock(withName: "xyz", directives: ["def"])
        let f5 = Fragment.mock(withName: "abc", directives: ["123", "def", "456"])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
        expect(f1.matches(f5)) == true
    }

    func testFragmentWithDirectivesPartialMatch() {
        let f1 = Fragment.mock(withName: "abc")
        let f2 = Fragment.mock(withName: "abc", directives: ["def"])
        let f3 = Fragment.mock(withName: "def", directives: ["abc"])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
    }

    func testFragmentWithFields() {
        let f1 = Fragment.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "ghi")])
        let f2 = Fragment.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "ghi")])
        let f3 = Fragment.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "123")])
        let f4 = Fragment.mock(withName: "xyz", fields: [Field.mockGraphQLField(withName: "ghi")])
        let f5 = Fragment.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "123"), Field.mockGraphQLField(withName: "ghi"), Field.mockGraphQLField(withName: "456")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
        expect(f1.matches(f5)) == true
    }

    func testFragmentWithFieldsPartialMatch() {
        let f1 = Fragment.mock(withName: "abc")
        let f2 = Fragment.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "ghi")])
        let f3 = Fragment.mock(withName: "123", fields: [Field.mockGraphQLField(withName: "abc")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
    }

    func testFragmentWithFragmentReferences() {
        let f1 = Fragment.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f2 = Fragment.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f3 = Fragment.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "123")])
        let f4 = Fragment.mock(withName: "123", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f5 = Fragment.mock(withName: "abc",
                               fragmentReferences: [
                                   Field.mockGraphQLFragmentSpread(withName: "123"),
                                   Field.mockGraphQLFragmentSpread(withName: "def"),
                                   Field.mockGraphQLFragmentSpread(withName: "456"),
                               ])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
        expect(f1.matches(f5)) == true
    }

    func testFragmentWithFragmentReferencesPartialMatch() {
        let f1 = Fragment.mock(withName: "abc")
        let f2 = Fragment.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f3 = Fragment.mock(withName: "123", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "abc")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
    }

    // MARK: - Field

    func testField() {
        let f1 = Field.mock(withName: "abc")
        let f2 = Field.mock(withName: "abc")
        let f3 = Field.mock(withName: "def")
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
    }

    func testFieldWithMatchingSubfield() {
        let f1 = Field.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "def")])
        let f2 = Field.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "def")])
        let f3 = Field.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "xyz")])
        let f4 = Field.mock(withName: "123", fields: [Field.mockGraphQLField(withName: "def")])
        let f5 = Field.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "123"), Field.mockGraphQLField(withName: "def"), Field.mockGraphQLField(withName: "xyz")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
        expect(f1.matches(f5)) == true
    }

    func testFieldWithDirective() {
        let f1 = Field.mock(withName: "abc", directives: ["def"])
        let f2 = Field.mock(withName: "abc", directives: ["def"])
        let f3 = Field.mock(withName: "def", directives: ["def"])
        let f4 = Field.mock(withName: "abc", directives: ["123"])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
    }

    func testFieldWithDirectivePartialMatch() {
        let f1 = Field.mock(withName: "abc")
        let f2 = Field.mock(withName: "abc", directives: ["def"])
        expect(f1.matches(f2)) == true
    }

    func testFieldWithArguments() {
        let f1 = Field.mock(withName: "abc", arguments: [("def", 123)])
        let f2 = Field.mock(withName: "abc", arguments: [("def", 123)])
        let f3 = Field.mock(withName: "abc")
        let f4 = Field.mock(withName: "abc", arguments: [("def", "Hello world!")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
    }

    func testFieldWithArgumentsPartialMatch() {
        let f1 = Field.mock(withName: "abc")
        let f2 = Field.mock(withName: "abc", arguments: [("def", 123)])
        expect(f1.matches(f2)) == true
    }

    func testFieldWithFragmentReferences() {
        let f1 = Field.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f2 = Field.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        let f3 = Field.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "123")])
        let f4 = Field.mock(withName: "def", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
    }

    func testFieldWithFragmentReferencesPartialMatch() {
        let f1 = Field.mock(withName: "abc")
        let f2 = Field.mock(withName: "abc", fragmentReferences: [Field.mockGraphQLFragmentSpread(withName: "def")])
        expect(f1.matches(f2)) == true
    }

    func testFieldWithMatchingSubfieldPartialMatch() {
        let f1 = Field.mock(withName: "abc")
        let f2 = Field.mock(withName: "abc", fields: [Field.mockGraphQLField(withName: "def")])
        expect(f1.matches(f2)) == true
    }

    func testFieldWithMatchingSubfieldTree() {
        let f1ghi = Field.mockGraphQLField(withName: "ghi")
        let f1def = Field.mockGraphQLField(withName: "def", fields: [f1ghi])
        let f1 = Field.mock(withName: "abc", fields: [f1def])

        let f2ghi = Field.mockGraphQLField(withName: "ghi")
        let f2def = Field.mockGraphQLField(withName: "def", fields: [f2ghi])
        let f2 = Field.mock(withName: "abc", fields: [f2def])

        expect(f1.matches(f2)) == true
    }

    func testFieldAlias() {
        let f1 = Field.mock(withName: "abc", alias: "xyz")
        let f2 = Field.mock(withName: "abc", alias: "xyz")
        let f3 = Field.mock(withName: "def", alias: "xyz")
        let f4 = Field.mock(withName: "abc")
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == false
    }

    // MARK: - FragmentReferences

    func testFragmentReference() {
        let f1 = FragmentReference.mock(withName: "abc", directives: ["def"])
        let f2 = FragmentReference.mock(withName: "abc", directives: ["def"])
        let f3 = FragmentReference.mock(withName: "abc", directives: [])
        let f4 = FragmentReference.mock(withName: "abc", directives: ["123", "def", "xyz"])
        let f5 = FragmentReference.mock(withName: "def", directives: ["def"])
        expect(f1.matches(f2)) == true
        expect(f1.matches(f3)) == false
        expect(f1.matches(f4)) == true
        expect(f1.matches(f5)) == false
    }

    func testFragmentReferencePartialMatch() {
        let f1 = FragmentReference.mock(withName: "abc")
        let f2 = FragmentReference.mock(withName: "abc", directives: ["def"])
        expect(f1.matches(f2)) == true
    }

    // MARK: - Directives

    func testDirective() {
        let d1 = Directive.mock(withName: "abc", arguments: [("def", 5)])
        let d2 = Directive.mock(withName: "abc", arguments: [("def", 5)])
        let d3 = Directive.mock(withName: "abc", arguments: [("xyz", "Hellow world!"), ("def", 5), ("ghi", "Goodbye!")])
        let d4 = Directive.mock(withName: "abc")
        let d5 = Directive.mock(withName: "def", arguments: [("def", 5)])
        let d6 = Directive.mock(withName: "abc", arguments: [("def", "Hello world!")])
        expect(d1.matches(d2)) == true
        expect(d1.matches(d3)) == true
        expect(d1.matches(d4)) == false
        expect(d1.matches(d5)) == false
        expect(d1.matches(d6)) == false
    }

    func testDirectivePartialMatch() {
        let d1 = Directive.mock(withName: "abc")
        let d2 = Directive.mock(withName: "abc", arguments: [("def", 5)])
        expect(d1.matches(d2)) == true
    }

    // MARK: - Arguments

    func testArgument() {
        let a1 = Argument.mock(withName: "abc", value: "Hello world!")
        let a2 = Argument.mock(withName: "abc", value: "Hello world!")
        let a3 = Argument.mock(withName: "def", value: "Hello world!")
        let a4 = Argument.mock(withName: "def", value: "Goodbye!")
        let a5 = Argument.mock(withName: "def", value: nil)
        expect(a1.matches(a2)) == true
        expect(a1.matches(a3)) == false
        expect(a1.matches(a4)) == false
        expect(a1.matches(a5)) == false
    }

    func testArgumentPartialMatch() {
        let a1 = Argument.mock(withName: "abc")
        let a2 = Argument.mock(withName: "abc", value: "Hello world!")
        expect(a1.matches(a2)) == true
    }

    // MARK: - Variables

    func testVariable() {
        let v1 = Variable.mock(withName: "abc", type: "Int")
        let v2 = Variable.mock(withName: "abc", type: "Int")
        let v3 = Variable.mock(withName: "def", type: "Int")
        let v4 = Variable.mock(withName: "abc", type: "Float")
        expect(v1.matches(v2)) == true
        expect(v1.matches(v3)) == false
        expect(v1.matches(v4)) == true // Only matching on name at the moment.
    }
}
