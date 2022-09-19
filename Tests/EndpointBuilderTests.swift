//
//  Created by Derek Clarkson on 15/9/2022.
//

import Foundation
import Nimble
@testable import Simulcra
import XCTest

class EndpointBuilderTests: XCTestCase {

    func testSimpleEndpoints() {
        @EndpointBuilder func endpoints() -> [Endpoint] {
            Endpoint(.GET, "/abc")
            Endpoint(.GET, "/def")
        }
        expect(endpoints().map { $0.path }) == ["/abc", "/def"]
    }

    func testIfEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool) -> [Endpoint] {
            Endpoint(.GET, "/abc")
            if addDef {
                Endpoint(.GET, "/def")
            }
            Endpoint(.GET, "/ghi")
        }
        expect(endpoints(addDef: true).map { $0.path }) == ["/abc", "/def", "/ghi"]
        expect(endpoints(addDef: false).map { $0.path }) == ["/abc", "/ghi"]
    }

    func testIfIfEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool, addGhi: Bool) -> [Endpoint] {
            Endpoint(.GET, "/abc")
            if addDef {
                Endpoint(.GET, "/def")
                if addGhi {
                    Endpoint(.GET, "/ghi")
                }
            }
        }
        expect(endpoints(addDef: true, addGhi: true).map { $0.path }) == ["/abc", "/def", "/ghi"]
        expect(endpoints(addDef: true, addGhi: false).map { $0.path }) == ["/abc", "/def"]
        expect(endpoints(addDef: false, addGhi: false).map { $0.path }) == ["/abc"]
    }

    func testIfElseEndpoints() {
        @EndpointBuilder func endpoints(addDef: Bool) -> [Endpoint] {
            Endpoint(.GET, "/abc")
            if addDef {
                Endpoint(.GET, "/def")
            } else {
                Endpoint(.GET, "/ghi")
            }
        }
        expect(endpoints(addDef: true).map { $0.path }) == ["/abc", "/def"]
        expect(endpoints(addDef: false).map { $0.path }) == ["/abc", "/ghi"]
    }

    func testIncludingFunctionResults() {
        @EndpointBuilder func endpoints() -> [Endpoint] {
            Endpoint(.GET, "/abc")
            endpoints2()
        }

        @EndpointBuilder func endpoints2() -> [Endpoint] {
            Endpoint(.GET, "/def")
        }

        expect(endpoints().map { $0.path }) == ["/abc", "/def"]
    }
}
