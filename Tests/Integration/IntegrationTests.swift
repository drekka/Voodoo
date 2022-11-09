//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import Voodoo
import XCTest

class IntegrationTests: XCTestCase, IntegrationTesting {

    var server: VoodooServer!
    let resourcesURL: URL = Bundle.testBundle.resourceURL!

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    // MARK: - Init

    func testInitWithMultipleServers() throws {
        let s1 = try VoodooServer()
        let s2 = try VoodooServer()
        expect(s2.url.host) == s1.url.host
        expect(s2.url.port) != s1.url.port
    }

    func testInitRunsOutOfPorts() throws {
        let s1 = try VoodooServer()
        let currentPort = s1.url.port!
        expect {
            try VoodooServer(portRange: currentPort ... currentPort)
        }
        .to(throwError(VoodooError.noPortAvailable(currentPort, currentPort)))
    }

    func testInitWithEndpoints() async throws {
        server = try VoodooServer {
            HTTPEndpoint(.GET, "/abc")
            HTTPEndpoint(.GET, "/def", response: .created())
        }
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
    }

    // MARK: - File serving.

    func testFileServing() async throws {

        let filesURL = resourcesURL.appendingPathComponent("files")
        server = try VoodooServer(filePaths: [filesURL])

        let response = await executeAPICall(.GET, "/Simple.html", andExpectStatusCode: 200)
        expect(String(data: response.data!, encoding: .utf8)) == "<html><body></body></html>\n"
        expect(response.response?.value(forHTTPHeaderField: "content-type")) == "text/html"
    }

    func testFileServingInvalidDirectory() async throws {

        let filesURL = resourcesURL.appendingPathComponent("XXXX")

        expect { try VoodooServer(filePaths: [filesURL]) }.to(throwError { (error: Error) in
            guard case VoodooError.directoryNotExists(let message) = error else {
                fail("Incorrect error \(error.localizedDescription)")
                return
            }
            expect(message).to(endWith("XXXX"))
        })
    }

    // MARK: - Mustache templates

    func testTemplateWithReferences() async throws {

        server = try VoodooServer(templatePath: resourcesURL.appendingPathComponent("files/templates"))
        server.add(.GET, "/", response: .ok(body: .template("books")))

        let response = await executeAPICall(.GET, "/", andExpectStatusCode: 200)
        let httpResponse = response.response! as HTTPURLResponse

        expect(httpResponse.value(forHTTPHeaderField: Header.contentType)) == Header.ContentType.applicationJSON
        let json = try JSONSerialization.jsonObject(with: response.data!) as! [[String: Any]]

        expect(json[0]["name"] as? String) == "Consider Phlebas"
        expect(json[1]["name"] as? String) == "Surface Detail"
        expect(json[2]["name"] as? String) == "The State of the Art"
    }

    func testDynamicTemplateIncludesReferencedTemplates() async throws {

        server = try VoodooServer(templatePath: resourcesURL.appendingPathComponent("files/templates"))
        server.add(.GET, "/", response: .ok(body: .json(
            #"""
            [
                {{> iab1 }},
                {{> iab2 }},
                {{> iab3 }},
            ]
            """#
        )))

        let response = await executeAPICall(.GET, "/", andExpectStatusCode: 200)
        let httpResponse = response.response! as HTTPURLResponse

        expect(httpResponse.value(forHTTPHeaderField: Header.contentType)) == Header.ContentType.applicationJSON
        let json = try JSONSerialization.jsonObject(with: response.data!) as! [[String: Any]]

        expect(json[0]["name"] as? String) == "Consider Phlebas"
        expect(json[1]["name"] as? String) == "Surface Detail"
        expect(json[2]["name"] as? String) == "The State of the Art"
    }

    // MARK: - Middleware

    func testNoResponseFoundMiddleware() async throws {
        server = try VoodooServer()
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 404)
    }

    // MARK: - Other tests

    // These tests are part of debugging errors that occured when trying to use Scenario 2.

    func testScenario2ConfigConversionError() async throws {
        let filesURL = resourcesURL.appendingPathComponent("files")
        let endpoints = try ConfigLoader(verbose: true).load(from: filesURL.appendingPathComponent("/TestConfig2/getConfig.yml"))
        server = try VoodooServer { endpoints }
        let response = await executeAPICall(.GET, "/app/config", andExpectStatusCode: 200)
        let payload = try JSONSerialization.jsonObject(with: response.data!) as! [String: Any]
        expect(payload["version"] as? Double) == 1.0
        expect(payload["featureFlag"] as? Bool) == true
    }
}
