//
//  File.swift
//
//
//  Created by Derek Clarkson on 17/9/2022.
//

import Foundation
import Hummingbird
import Nimble
import NIOCore
@testable import SimulcraCore
import XCTest

class AdminConsoleTests: XCTestCase {

    private var console: AdminConsole!
    private var mockResponder: MockResponder!

    override func setUp() {
        super.setUp()
        console = AdminConsole()
        mockResponder = MockResponder()
    }

    func testForwardsIfNotAdminPath() async {
        let mockRequest = HBRequest.mock()
        mockRequest.application.lifecycle.shutdown()
        let response = console.apply(to: mockRequest, next: mockResponder)
        expect(self.mockResponder.gotRequest) == true
        await assert(response: response, hasStatus: .ok)
    }

    func testShutdownRequest() async {
        let mockRequest = HBRequest.mock(.POST, path: "/_admin/shutdown")
        let response = console.apply(to: mockRequest, next: mockResponder)
        expect(self.mockResponder.gotRequest) == false
        await assert(response: response, hasStatus: .ok)
    }

    func testUnknownAdminRequest() async {
        let mockRequest = HBRequest.mock(path: "/_admin/xxx")
        let response = console.apply(to: mockRequest, next: mockResponder)
        expect(self.mockResponder.gotRequest) == false
        await assert(response: response, hasStatus: .notFound)
    }

    private func assert(response: EventLoopFuture<HBResponse>, hasStatus expectedStatus: HTTPResponseStatus) async {
        let response = try! await response.get()
        expect(response.status) == expectedStatus
    }
}
