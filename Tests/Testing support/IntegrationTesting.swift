//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/9/2022.
//

import Foundation
import Hummingbird
import Nimble
import NIOHTTP1
@testable import SimulacraCore

/// Add this protocol to gain access to integration testing functions.
protocol IntegrationTesting: AnyObject {

    typealias ServerResponse = (data: Data?, response: HTTPURLResponse?, error: Error?)

    var server: Simulacra! { get set }

    func setUpServer() throws

    func tearDownServer()

    @discardableResult
    func executeAPICall(_ method: HTTPMethod, _ path: String, andExpectStatusCode expectedStatusCode: Int, file: StaticString, line: UInt) async -> ServerResponse
}

extension IntegrationTesting {

    func setUpServer() throws {
        let templatePath = Bundle.testBundle.resourceURL!
        server = try Simulacra(templatePath: templatePath, verbose: true)
    }

    func tearDownServer() {
        server?.stop()
    }

    @discardableResult
    func executeAPICall(_ method: HTTPMethod, _ path: String, andExpectStatusCode expectedStatusCode: Int, file: StaticString = #file, line: UInt = #line) async -> ServerResponse {
        var request = URLRequest(url: server.url.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        let response: ServerResponse
        do {
            let callResponse = try await URLSession.shared.data(for: request)
            response = ServerResponse(data: callResponse.0, response: callResponse.1 as? HTTPURLResponse, error: nil)
        } catch {
            response = ServerResponse(data: nil, response: nil, error: error)
        }

        expect(file: file, line: line, response.response!.statusCode) == expectedStatusCode
        expect(file: file, line: line, response.error).to(beNil())

        return response
    }
}
