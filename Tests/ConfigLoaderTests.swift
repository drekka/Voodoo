//
//  File.swift
//
//
//  Created by Derek Clarkson on 13/10/2022.
//

import Nimble
import NIOHTTP1
@testable import SimulacraCore
import XCTest

class ConfigLoaderTests: XCTestCase {

    private let resourcesURL = Bundle.testBundle.resourceURL!
    private let loader = ConfigLoader(verbose: true)

    func testLoadSingleEndpoint() throws {
        let endpoints = try loader.load(from: resourcesURL.appendingPathComponent("files/TestConfig1/get-config.yml"))
        expect(endpoints.count) == 1
        expectEndpoint(endpoints[0], mapsTo: .GET, "/config", returning: .ok(body: .json(["version": 1.0])))
    }

    func testEndpointList() throws {
        let endpoints = try loader.load(from: resourcesURL.appendingPathComponent("files/scenario 1.yml"))
        expect(endpoints.count) == 4
        expectEndpoint(endpoints[0], mapsTo: .POST, "/created/text", returning: .created(body: .text("Hello world!")))
        expectEndpoint(endpoints[1], mapsTo: .GET, "/config", returning: .ok(body: .json(["version": 1.0])))
        expectEndpoint(endpoints[2], mapsTo: .GET, "/javascript/inline",
                       returning: .javascript(
                           #"""
                           function response(request, cache) {
                               if request.parthParameter.accountId == "1234" {
                                   return Response.ok()
                               } else {
                                   return Response.notFound
                               }
                           }
                            \#n
                           """#
                       ))
        expectEndpoint(endpoints[3], mapsTo: .GET, "/javascript/file", returning: .javascript("function response(request, cache) {\n    return Response.ok()\n}\n"))
    }

    func testLoadDirectory() throws {
        let endpoints = try loader.load(from: resourcesURL.appendingPathComponent("files/TestConfig1"))

        expect(endpoints.count) == 3
        expectEndpoint(endpoints[0], mapsTo: .GET, "/config", returning: .ok(body: .json(["version": 1.0])))
        expectEndpoint(endpoints[1], mapsTo: .DELETE, "/email/:messageId", returning: .ok())
        expectEndpoint(endpoints[2], mapsTo: .POST, "/login", returning: .javascript("login.js"))
    }

    func testLoadFromInvalidURL() throws {
        do {
            _ = try loader.load(from: resourcesURL.appendingPathComponent("files/XXXX.yml"))
            fail("Error not thrown")
        } catch {
            guard case SimulacraError.invalidConfigPath(let message) = error else {
                fail("Incorrect error returned \(error)")
                return
            }
            expect(message).to(endWith("files/XXXX.yml"))
        }
    }

    func testLoadInvalidYAML() throws {
        do {
            _ = try loader.load(from: resourcesURL.appendingPathComponent("files/Invalid.yml"))
            fail("Error not thrown")
        } catch {
            guard case DecodingError.dataCorrupted(let context) = error else {
                fail("Incorrect error returned \(error)")
                return
            }
            expect(context.debugDescription) == "The given data was not valid YAML."
        }
    }

    // MARK: - Support

    private func expectEndpoint(file: StaticString = #file, line: UInt = #line, _ endpoint: Endpoint, mapsTo method: HTTPMethod, _ path: String, returning response: HTTPResponse) {
        expect(file: file, line: line, endpoint.method) == method
        expect(file: file, line: line, endpoint.path) == path
        expect(file: file, line: line, endpoint.response) == response
    }
}
