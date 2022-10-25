//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import SimulacraCore
import XCTest

class IntegrationTests: XCTestCase, IntegrationTesting {

    var server: Simulacra!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpServer()
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    // MARK: - Init

    func testInitWithMultipleServers() throws {
        let s2 = try Simulacra()
        expect(s2.url.host) == server.url.host
        expect(s2.url.port) != server.url.port
    }

    func testInitRunsOutOfPorts() {
        let currentPort = server.url.port!
        expect {
            try Simulacra(portRange: currentPort ... currentPort)
        }
        .to(throwError(SimulacraError.noPortAvailable))
    }

    func testInitWithEndpoints() async throws {
        server = try Simulacra {
            Endpoint(.GET, "/abc")
            Endpoint(.GET, "/def", response: .created())
        }
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
    }

    // MARK: - File serving.

    func testFileServing() async throws {

        let resourcesURL = Bundle.testBundle.resourceURL!
        let filesURL = resourcesURL.appendingPathComponent("files")
        server = try Simulacra(filePaths: [filesURL])

        let response = await executeAPICall(.GET, "/Simple.html", andExpectStatusCode: 200)
        expect(String(data: response.data!, encoding: .utf8)) == "<html><body></body></html>\n"
        expect(response.response?.value(forHTTPHeaderField: "content-type")) == "text/html"
    }

    func testFileServingInvalidDirectory() async throws {

        let resourcesURL = Bundle.testBundle.resourceURL!
        let filesURL = resourcesURL.appendingPathComponent("XXXX")

        expect { try Simulacra(filePaths: [filesURL]) }.to(throwError { (error: Error) in
            guard case SimulacraError.directoryNotExists(let message) = error else {
                fail("Incorrect error \(error.localizedDescription)")
                return
            }
            expect(message).to(endWith("XXXX"))
        })
    }

    // MARK: - Middleware

    func testNoResponseFoundMiddleware() async {
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 404)
    }

    // MARK: - Other tests

    // These tests are part of debugging errors that occured when trying to use Scenario 2.

    func testScenario2ConfigConversionError() async throws {
        let resourcesURL = Bundle.testBundle.resourceURL!
        let filesURL = resourcesURL.appendingPathComponent("files")
        let endpoints = try ConfigLoader(verbose: true).load(from: filesURL.appendingPathComponent("/TestConfig2/core.yml"))
        server = try Simulacra { endpoints }
        let response = await executeAPICall(.GET, "/app/config", andExpectStatusCode: 200)
        let payload = try JSONSerialization.jsonObject(with: response.data!) as! [String: Any]
        expect(payload["version"] as? Double) == 1.0
        expect(payload["featureFlag"] as? Bool) == true
    }
}
