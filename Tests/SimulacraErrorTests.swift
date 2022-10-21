//
//  File.swift
//
//
//  Created by Derek Clarkson on 11/10/2022.
//

import Nimble
import SimulacraCore
import XCTest

class SimulacraErrorTests: XCTestCase {

    func testMessages() {
        expect(SimulacraError.directoryNotExists("/abc").headers.first(name: SimulacraError.headerKey)) == "Missing or URL was not a directory: /abc"
        expect(SimulacraError.templateRenderingFailure("xxx").headers.first(name: SimulacraError.headerKey)) == "xxx"
        expect(SimulacraError.noPortAvailable.headers.first(name: SimulacraError.headerKey)) == "All ports taken."
        expect(SimulacraError.unexpectedError(SimulacraError.noPortAvailable).headers.first(name: SimulacraError.headerKey)) == "The operation couldn’t be completed. (SimulacraCore.SimulacraError error 7.)"
        expect(SimulacraError.javascriptError("error").headers.first(name: SimulacraError.headerKey)) == "error"
        expect(SimulacraError.configLoadFailure("failed").headers.first(name: SimulacraError.headerKey)) == "failed"
        expect(SimulacraError.invalidConfigPath("/abc").headers.first(name: SimulacraError.headerKey)) == "Invalid config path /abc"
        expect(SimulacraError.directoryNotExists("/abc").headers.first(name: SimulacraError.headerKey)) == "Missing or URL was not a directory: /abc"
    }
}
