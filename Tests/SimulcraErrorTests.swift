//
//  File.swift
//
//
//  Created by Derek Clarkson on 11/10/2022.
//

import Nimble
import SimulcraCore
import XCTest

class SimulcraErrorTests: XCTestCase {

    func testMessages() {
        expect(SimulcraError.directoryNotExists("/abc").headers.first(name: SimulcraError.headerKey)) == "Missing or URL was not a directory: /abc"
        expect(SimulcraError.templateRenderingFailure("xxx").headers.first(name: SimulcraError.headerKey)) == "xxx"
        expect(SimulcraError.noPortAvailable.headers.first(name: SimulcraError.headerKey)) == "All ports taken."
        expect(SimulcraError.unexpectedError(SimulcraError.noPortAvailable).headers.first(name: SimulcraError.headerKey)) == "The operation couldn’t be completed. (SimulcraCore.SimulcraError error 7.)"
        expect(SimulcraError.javascriptError("error").headers.first(name: SimulcraError.headerKey)) == "error"
        expect(SimulcraError.configLoadFailure("failed").headers.first(name: SimulcraError.headerKey)) == "failed"
        expect(SimulcraError.invalidConfigPath("/abc").headers.first(name: SimulcraError.headerKey)) == "Invalid config path /abc"
        expect(SimulcraError.directoryNotExists("/abc").headers.first(name: SimulcraError.headerKey)) == "Missing or URL was not a directory: /abc"
    }
}
