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
        let loader = ConfigLoader(verbose: true)

        let ymlFile = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/TestConfig1/get-config.yml")
        let endpoints = try loader.load(from: ymlFile)

        expect(endpoints.count) == 1
        expectEndpoint(endpoints[0], mapsTo: .GET, "/config", returning: .ok(body: .structured(["version": 1.0])))
    }

    func testLoadDirectory() throws {
        let loader = ConfigLoader(verbose: false)

        let ymlDir = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/TestConfig1")
        let endpoints = try loader.load(from: ymlDir)

        expect(endpoints.count) == 3
        expectEndpoint(endpoints[0], mapsTo: .GET, "/config", returning: .ok(body: .structured(["version": 1.0])))
        // expectEndpoint(endpoints[1], mapsTo: .GET, "/def", returning: .ok())
        // expectEndpoint(endpoints[2], mapsTo: .POST, "/ghi", returning: .javascript("ok.js"))
    }

    func testLoadFromInvalidURL() throws {
        let loader = ConfigLoader(verbose: false)

        let ymlFile = Bundle.testBundle.resourceURL!.appendingPathComponent("Test files/XXXX.yml")
        expect { try loader.load(from: ymlFile) }.to(throwError(SimulcraError.invalidConfigPath("")))
    }

    // MARK: - Support

    private func expectEndpoint(file: StaticString = #file, line: UInt = #line, _ endpoint: Endpoint, mapsTo method: HTTPMethod, _ path: String, returning response: HTTPResponse) {
        expect(file: file, line: line, endpoint.method) == method
        expect(file: file, line: line, endpoint.path) == path
        expect(file: file, line: line, endpoint.response) == response
    }
}
