//
//  File.swift
//
//
//  Created by Derek Clarkson on 21/11/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest

class MultiServerTests: XCTestCase, IntegrationTesting {

    var server: Voodoo.VoodooServer!

    func testCallForwarding() async throws {

        // Setup a Voodoo Server as a target.
        let server2 = try VoodooServer(verbose: true) {
            HTTPEndpoint(.GET, "/token", response: .ok(body: .json(["token": "abcd-1234"])))
        }

        // Setup another Voodoo server as an intermediary.
        let server1 = try VoodooServer(verbose: true) {
            HTTPEndpoint(.GET, "/token", response: .dynamic { _, _ in
                let server2Request = URLRequest(url: server2.url.appendingPathComponent("token"))
                let server2Results = await self.executeAPICall(server2Request, andExpectStatusCode: 200)
                let server2Payload = try! JSONSerialization.jsonObject(with: server2Results.data!) as! [String: Any]
                let token = server2Payload["token"] as! String
                return .ok(body: .json(["token": token]))
            })
        }

        // Make the call.
        let request = URLRequest(url: server1.url.appendingPathComponent("token"))
        let results = await executeAPICall(request, andExpectStatusCode: 200)
        let payload = try! JSONSerialization.jsonObject(with: results.data!) as! [String: Any]
        let token = payload["token"] as! String

        expect(token) == "abcd-1234"
    }
}
