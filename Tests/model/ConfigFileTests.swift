//
//  Created by Derek Clarkson on 11/10/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest
import Yams

extension ConfigFile {
    var httpEndpoints: [HTTPEndpoint] {
        endpoints.compactMap { $0 as? HTTPEndpoint }
    }

    var graphQLEndpoints: [GraphQLEndpoint] {
        endpoints.compactMap { $0 as? GraphQLEndpoint }
    }
}

class ConfigFileTests: XCTestCase {

    func testDecodeSingleEndpoint() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        http:
          api: get /abc
        response:
          status: 200
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml)
        expect(config.endpoints.count) == 1
        expect(config.httpEndpoints[0].method) == .GET
        expect(config.httpEndpoints[0].path) == "/abc"
        expect(config.httpEndpoints[0].response) == .ok()
    }

    func testDecodeArrayOfEndpoints() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        - http:
            api: get /abc
          response:
            status: 200
        - http:
            api: post /def
          response:
            status: 201
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml)
        expect(config.endpoints.count) == 2
        expect(config.httpEndpoints[0].method) == .GET
        expect(config.httpEndpoints[0].path) == "/abc"
        expect(config.httpEndpoints[0].response) == .ok()
        expect(config.httpEndpoints[1].method) == .POST
        expect(config.httpEndpoints[1].path) == "/def"
        expect(config.httpEndpoints[1].response) == .created()
    }

    func testDecodeMixed() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        - http:
            api: put /config
          response:
            status: 201
        - files/TestConfig1/get-config.yml
        - http:
            api: delete /config
          response:
            status: 200
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml, userInfo: [ConfigLoader.userInfoDirectoryKey: Bundle.testBundle])
        expect(config.endpoints.count) == 3
        expect(config.httpEndpoints[0].method) == .PUT
        expect(config.httpEndpoints[0].path) == "/config"
        expect(config.httpEndpoints[0].response) == .created()
        expect(config.httpEndpoints[1].method) == .GET
        expect(config.httpEndpoints[1].path) == "/config"
        expect(config.httpEndpoints[1].response) == .ok(body: .json(["version": 1.0]))
        expect(config.httpEndpoints[2].method) == .DELETE
        expect(config.httpEndpoints[2].path) == "/config"
        expect(config.httpEndpoints[2].response) == .ok()
    }
}
