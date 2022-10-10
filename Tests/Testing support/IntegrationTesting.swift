//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/9/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import SimulcraCore

/// Add this protocol to gain access to integration testing functions.
protocol IntegrationTesting: AnyObject {

    typealias ServerResponse = (data: Data?, response: HTTPURLResponse?, error: Error?)

    var server: Simulcra! { get set }

    func setUpServer() throws

    func tearDownServer()

    @discardableResult
    func assert(_ method: HTTPMethod, _ path: String, returns expectedStatus: HTTPResponseStatus, file: StaticString, line: UInt) async -> ServerResponse
}

extension IntegrationTesting {

    func setUpServer() throws {
        let templatePath = Bundle.testBundle.resourceURL!
        server = try Simulcra(templatePath: templatePath, verbose: true)
    }

    func tearDownServer() {
        server?.stop()
    }

    @discardableResult
    func assert(_ method: HTTPMethod, _ path: String, returns expectedStatus: HTTPResponseStatus, file: StaticString = #file, line: UInt = #line) async -> ServerResponse {
        var request = URLRequest(url: server.address.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        let response: ServerResponse
        do {
            let callResponse = try await URLSession.shared.data(for: request)
            response = ServerResponse(data: callResponse.0, response: callResponse.1 as? HTTPURLResponse, error: nil)
        } catch {
            response = ServerResponse(data: nil, response: nil, error: error)
        }

        expect(file: file, line: line, response.response!.statusCode) == Int(expectedStatus.code)
        expect(file: file, line: line, response.error).to(beNil())

        return response
    }
}
