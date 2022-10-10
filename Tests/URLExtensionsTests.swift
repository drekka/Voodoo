//
//  File.swift
//
//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation
import Nimble
@testable import SimulcraCore
import XCTest

class URLExtensionsTests: XCTestCase {

    func testFileExistsWithValidFile() {
        let url = Bundle.testBundle.url(forResource: "Simple", withExtension: "json")!
        expect(url.fileExists) == true
    }

    func testFileExistsWithInValidFile() {
        let url = URL(fileURLWithPath: "/abc/def")
        expect(url.fileExists) == false
    }

    func testFileExistsWithDirectory() {
        let url = Bundle.testBundle.url(forResource: "TestDir", withExtension: nil)!
        expect(url.fileExists) == false
    }

    func testDirectoryExistsWithValidFile() {
        let url = Bundle.testBundle.url(forResource: "Simple", withExtension: "json")!
        expect(url.directoryExists) == false
    }

    func testDirectoryExistsWithInValidFile() {
        let url = URL(fileURLWithPath: "/abc/def")
        expect(url.directoryExists) == false
    }

    func testDirectoryExistsWithDirectory() {
        let url = Bundle.testBundle.url(forResource: "TestDir", withExtension: nil)!
        expect(url.directoryExists) == true
    }
}
