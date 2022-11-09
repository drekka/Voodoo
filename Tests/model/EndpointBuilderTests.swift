//
//  Created by Derek Clarkson on 15/9/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest

class EndpointBuilderTests: XCTestCase {

    func testSimpleEndpoints() {
        @EndpointBuilder func endpoints() -> [Endpoint] {
            HTTPEndpoint(.GET, "/abc")
            HTTPEndpoint(.GET, "/def")
        }
        expect(endpoints().map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def"]
    }

    func testIfEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool) -> [Endpoint] {
            HTTPEndpoint(.GET, "/abc")
            if addDef {
                HTTPEndpoint(.GET, "/def")
            }
            HTTPEndpoint(.GET, "/ghi")
        }
        expect(endpoints(addDef: true).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def", "/ghi"]
        expect(endpoints(addDef: false).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/ghi"]
    }

    func testIfIfEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool, addGhi: Bool) -> [Endpoint] {
            HTTPEndpoint(.GET, "/abc")
            if addDef {
                HTTPEndpoint(.GET, "/def")
                if addGhi {
                    HTTPEndpoint(.GET, "/ghi")
                }
            }
        }
        expect(endpoints(addDef: true, addGhi: true).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def", "/ghi"]
        expect(endpoints(addDef: true, addGhi: false).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def"]
        expect(endpoints(addDef: false, addGhi: false).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc"]
    }

    func testIfElseEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool) -> [Endpoint] {
            HTTPEndpoint(.GET, "/abc")
            if addDef {
                HTTPEndpoint(.GET, "/def")
            } else {
                HTTPEndpoint(.GET, "/ghi")
            }
        }
        expect(endpoints(addDef: true).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def"]
        expect(endpoints(addDef: false).map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/ghi"]
    }

    func testIncludingFunctionResults() {
        @EndpointBuilder func endpoints() -> [Endpoint] {
            HTTPEndpoint(.GET, "/abc")
            endpoints2()
        }

        @EndpointBuilder func endpoints2() -> [Endpoint] {
            HTTPEndpoint(.GET, "/def")
        }

        expect(endpoints().map { ($0 as? HTTPEndpoint)?.path }) == ["/abc", "/def"]
    }
}
