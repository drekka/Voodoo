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
        expect(url.fileSystemStatus) == .isFile
    }

    func testFileExistsWithInValidFile() {
        let url = URL(fileURLWithPath: "/abc/def")
        expect(url.fileSystemStatus) == .notFound
    }

    func testFileExistsWithDirectory() {
        let url = Bundle.testBundle.url(forResource: "TestDir", withExtension: nil)!
        expect(url.fileSystemStatus) == .isDirectory
    }

}
