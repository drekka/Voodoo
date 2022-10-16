//
//  File.swift
//  
//
//  Created by Derek Clarkson on 11/10/2022.
//

import XCTest
import Yams
@testable import SimulcraCore
import Nimble
import Foundation

class EndPointReferenceTests: XCTestCase {

    func testDecodeEmbeddedEndpoint() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        signature: get /abc
        response:
          status: 200
        """#
        let endpoint = try decoder.decode(EndpointReference.self, from: yml)
        expect(endpoint.apis.count) == 1
        expect(endpoint.apis[0].method) == .GET
        expect(endpoint.apis[0].path) == "/abc"
        expect(endpoint.apis[0].response) == .ok()
    }

    func testDecodeFileReference() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        Test files/TestConfig1/get-config.yml
        """#

        let endpoint = try decoder.decode(EndpointReference.self, from: yml, userInfo: [ConfigLoader.userInfoDirectoryKey: Bundle.testBundle.resourceURL!])
        expect(endpoint.apis.count) == 1
        expect(endpoint.apis[0].method) == .GET
        expect(endpoint.apis[0].path) == "/config"
        expect(endpoint.apis[0].response) == .ok()
    }
}

class ConfigFileTests: XCTestCase {

    func testDecodeSingleEndpoint() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        signature: get /abc
        response:
          status: 200
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml)
        expect(config.apis.count) == 1
        expect(config.apis[0].method) == .GET
        expect(config.apis[0].path) == "/abc"
        expect(config.apis[0].response) == .ok()
    }

    func testDecodeArrayOfEndpoints() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        - signature: get /abc
          response:
            status: 200
        - signature: get /def
          response:
            status: 201
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml)
        expect(config.apis.count) == 2
        expect(config.apis[0].method) == .GET
        expect(config.apis[0].path) == "/abc"
        expect(config.apis[0].response) == .ok()
        expect(config.apis[1].method) == .GET
        expect(config.apis[1].path) == "/def"
        expect(config.apis[1].response) == .created()
    }

    func testDecodeMixed() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        - signature: put /config
          response:
            status: 201
        - Test files/TestConfig1/get-config.yml
        - signature: delete /config
          response:
            status: 200
        """#
        let config = try decoder.decode(ConfigFile.self, from: yml, userInfo: [ConfigLoader.userInfoDirectoryKey: Bundle.testBundle.resourceURL!])
        expect(config.apis.count) == 3
        expect(config.apis[0].method) == .GET
        expect(config.apis[0].path) == "/config"
        expect(config.apis[0].response) == .created()
        expect(config.apis[1].method) == .GET
        expect(config.apis[1].path) == "/config"
        expect(config.apis[1].response) == .ok()
        expect(config.apis[2].method) == .POST
        expect(config.apis[2].path) == "/config"
        expect(config.apis[2].response) == .accepted()
    }
}
