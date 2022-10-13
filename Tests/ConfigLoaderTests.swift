//
//  File.swift
//
//
//  Created by Derek Clarkson on 13/10/2022.
//

import Nimble
import NIOHTTP1
@testable import SimulcraCore
import XCTest

class ConfigLoaderTests: XCTestCase {

    func testLoadFile() throws {
        let loader = ConfigLoader(verbose: false)

        let ymlFile = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/TestConfig1/get-def-ok.yml")
        let endpoints = try loader.load(from: ymlFile)

        expect(endpoints.count) == 1
        expectEndpoint(endpoints[0], mapsTo: .GET, "/def", returning: .ok())
    }

    func testLoadDirectory() throws {
        let loader = ConfigLoader(verbose: false)

        let ymlDir = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/TestConfig1")
        let endpoints = try loader.load(from: ymlDir)

        expect(endpoints.count) == 4
        expectEndpoint(endpoints[0], mapsTo: .GET, "/abc", returning: .ok(body: .text("Hello world!")))
        expectEndpoint(endpoints[1], mapsTo: .GET, "/def", returning: .ok())
        expectEndpoint(endpoints[2], mapsTo: .POST, "/ghi", returning: .javascript("ok.js"))
        expectEndpoint(endpoints[3], mapsTo: .DELETE, "/jkl", returning: .notFound)
    }

    func testLoadFromInvalidURL() throws {
        let loader = ConfigLoader(verbose: false)

        let ymlFile = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/XXXX.yml")
        expect { try loader.load(from: ymlFile) }.to(throwError(SimulcraError.invalidConfigPath("")))
    }

    // MARK: - Support

    private func expectEndpoint(_ endpoint: Endpoint, mapsTo method: HTTPMethod, _ path: String, returning response: HTTPResponse) {
        expect(endpoint.method) == method
        expect(endpoint.path) == path
        expect(endpoint.response) == response
    }
}
