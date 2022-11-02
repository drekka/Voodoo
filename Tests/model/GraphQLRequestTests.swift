//
//  File.swift
//
//
//  Created by Derek Clarkson on 28/10/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import SimulacraCore
import XCTest

class GraphQLParserTests: XCTestCase {

    let queryWithArgs = """
        query ($preview: Boolean) {
      hero(limit:10) {
        name
        friends {
          name
          homeWorld {
            name
            climate
          }
          species {
            name
            lifespan
            origin {
              name
            }
          }
        }
      }
    }
    """
    let queryWithFragments = """
    query {
      leftComparison: hero(episode: EMPIRE) {
        ...comparisonFields
      }
      rightComparison: hero(episode: JEDI) {
        ...comparisonFields
      }
    }

    fragment comparisonFields on Character {
      name
      appearsIn
      friends {
        name
      }
    }
    """

    let queryWithFragmentArg = """
        query HeroComparison($first: Int = 3) {
          leftComparison: hero(episode: EMPIRE) {
            ...comparisonFields
          }
          rightComparison: hero(episode: JEDI) {
            ...comparisonFields
          }
        }

        fragment comparisonFields on Character {
          name
          friendsConnection(first: $first) {
            totalCount
            edges {
              node {
                name
              }
            }
          }
        }
    """

    func testParseSimpleQuery() throws {

        let query = "query {hero{name}}"
        let request = try parse(query: query)

        validate(request: request, hasQuery: query, operations: 1)

        let requestQuery = request.defaultOperation!
        expect(requestQuery.name) == nil
        expect(requestQuery.type) == .query

        validate(field: requestQuery.hero, hasName: "hero", fields: 1)
        validate(field: requestQuery.hero?.name, hasName: "name")
    }

    func testParseQueryWithAliasedFields() throws {
        let query = """
        query {
            empireHero: hero(episode: EMPIRE) {
                name
            }
            jediHero: hero(episode: JEDI) {
                name
            }
        }
        """
        let request = try parse(query: query)

        validate(request: request, hasQuery: query, operations: 1)

        let requestQuery = request.defaultOperation!
        expect(requestQuery.name) == nil
        expect(requestQuery.type) == .query

        validate(field: requestQuery.empireHero, hasName: "hero", alias: "empireHero", fields: 1, arguments: 1)
        expect(requestQuery.empireHero?.arguments[0].name) == "episode"
        expect(requestQuery.empireHero?.arguments[0].value as? String) == "EMPIRE"

        validate(field: requestQuery.jediHero, hasName: "hero", alias: "jediHero", fields: 1, arguments: 1)
        expect(requestQuery.jediHero?.arguments[0].name) == "episode"
        expect(requestQuery.jediHero?.arguments[0].value as? String) == "JEDI"
    }

    // MARK: Test support

    func validate(file: StaticString = #file, line: UInt = #line,
                  request: GraphQLRequest,
                  hasQuery expectedQuery: String,
                  selectedOperation expectedSelectedOperation: String? = nil,
                  operations expectedOperationsCount: Int = 0,
                  variables expectedVariablesCount: Int = 0,
                  fragments expectedFragmentsCount: Int = 0) {
        expect(file: file, line: line, request.rawQuery).to(equal(expectedQuery), description: "Query does not match")
        if let expectedSelectedOperation {
            expect(file: file, line: line, request.selectedOperation).to(equal(expectedSelectedOperation), description: "Selected operation incorrect")
        } else {
            expect(file: file, line: line, request.selectedOperation).to(beNil(), description: "Selected operation not nil")
        }
        expect(file: file, line: line, request.operations.count).to(equal(expectedOperationsCount), description: "Operation count incorrect")
        expect(file: file, line: line, request.variables.count).to(equal(expectedVariablesCount), description: "Variables count incorrect")
        expect(file: file, line: line, request.fragments.count).to(equal(expectedFragmentsCount), description: "Fragments count incorrect")
    }

    func validate(file: StaticString = #file, line: UInt = #line,
                  field: Field?,
                  hasName expectedName: String,
                  alias expectedAlias: String? = nil,
                  fields expectedFieldCount: Int = 0,
                  directives expectedDirectiveCount: Int = 0,
                  arguments expectedArgumentsCount: Int = 0,
                  fragments expectedFragmentCount: Int = 0) {
        guard let field else {
            fail("Field \(expectedName) not found", file: file, line: line)
            return
        }
        expect(file: file, line: line, field.fieldName).to(equal(expectedName), description: "Fieldname incorrect")
        if let expectedAlias {
            expect(file: file, line: line, field.alias).to(equal(expectedAlias), description: "Alias incorrect")
        } else {
            expect(file: file, line: line, field.alias).to(beNil(), description: "Alias expected to be nil")
        }
        expect(file: file, line: line, field.directives.count).to(equal(expectedDirectiveCount), description: "Directive count incorrect")
        expect(file: file, line: line, field.fields.count).to(equal(expectedFieldCount), description: "Field count incorrect")
        expect(file: file, line: line, field.arguments.count).to(equal(expectedArgumentsCount), description: "argument count incorrect")
        expect(file: file, line: line, field.fragmentReferences.count).to(equal(expectedFragmentCount), description: "Fragment reference incorrect")
    }

    func parse(query: String, variables: String? = nil, operation: String? = nil) throws -> GraphQLRequest {
        var queryString = "query=\(query)"
        if let variables {
            queryString += "&variables=\(variables)"
        }
        if let operation {
            queryString += "&operation=\(operation)"
        }
        let httpRequest = HBRequest.mock(query: queryString).asHTTPRequest
        return try GraphQLRequest(request: httpRequest)!
    }
}
