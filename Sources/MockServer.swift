//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/9/21.
//

import os
import Swifter
import UIKit

let log = Logger(subsystem: "au.com.derekclarkson.simulcra", category: "Mocking")

enum Mode {
    case testing
    case demo
}

@resultBuilder
enum MockEndpointSourceBuilder {
    static func buildBlock() -> [RegisterableAPI] { [] }
}

/// Wraps the swifter server and translates the Simulcra setup into a Swifter setup.
class MockServer {
    
    private static let unassignedPort = -1

    private let swifter: HttpServer
    private let mode: Mode

    /// The port that Swifter is currently bound to.
    private(set) var port = unassignedPort

    deinit {
        swifter.stop()
    }

    convenience init(mode: Mode = .demo,
                     port: UInt16 = 8080,
                     @MockEndpointSourceBuilder endpointSources: () -> [RegisterableAPI]) throws {
        try self.init(mode: mode, portRange: port ... port, endpointSources: endpointSources)
    }

    init(mode: Mode = .demo,
         portRange: ClosedRange<UInt16>,
         @MockEndpointSourceBuilder endpointSources: () -> [RegisterableAPI]) throws {

        self.mode = mode
        swifter = HttpServer()

        // Go find a port to bind to.
        for port in portRange where self.port == MockServer.unassignedPort {
            do {
                log.debug("🧞‍♂️ SwifterServer: Requesting port \(port) ...")
                try swifter.start(port)
                self.port = Int(port)
                log.debug("🧞‍♂️ SwifterServer: Bound \(port)")
            } catch {
                if case SocketError.bindFailed = error { continue }
                log.debug("🧞‍♂️ SwifterServer: Error \(error.localizedDescription) binding to port \(port)")
                throw SimulcraError.unexpectedError(error)
            }
        }

        // If by some chance we're not bound then throw.
        if swifter.state != .running {
            throw SimulcraError.noAvailablePort
        }

        registerMiddleware()
        registerEndpoints(inSources: endpointSources)
    }

    private func registerMiddleware() {
        swifter.middleware.append { request in
            log.debug("🧞‍♂️ SwifterServer: Processing \(request.method) \(request.path)")
            return nil
        }
    }

    private func registerEndpoints(inSources endpointSources: () -> [RegisterableAPI]) {
        endpointSources().forEach { mockAPI in
            mockAPI.register(onServer: swifter) { request, error in
                if self.mode == .testing {
                    fatalError("🧞‍♂️ SwifterServer: 💥💥💥 Error: \(error.localizedDescription) 💥💥💥")
                }
                return .raw(500, "Mock server error", nil) { bodyWriter in
                    try? bodyWriter.write("Error responding to: \(request.method) \(request.path)\n".data(using: .utf8) ?? Data())
                    try? bodyWriter.write("Error: \n".data(using: .utf8) ?? Data())
                }
            }
        }
    }
}
