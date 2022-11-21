//
//  File.swift
//  
//
//  Created by Derek Clarkson on 18/11/2022.
//

import Foundation
import XCTest
@testable import Voodoo
import Nimble

class StringInterpolationTests: XCTestCase {

    func testInterpolation() {
        expect("\(1.234567890123456789)") == "1.2345678901234567"
        expect(String(1.234567890123456789)) == "1.2345678901234567"
        expect("\(1.0, decimalPlaces: 2)") == "1"
        expect("\(1.1, decimalPlaces: 2)") == "1.1"
        expect("\(1.12, decimalPlaces: 2)") == "1.12"
        expect("\(1.123, decimalPlaces: 2)") == "1.12"
        expect("\(1.1234, decimalPlaces: 2)") == "1.12"
        expect("\(1.124, decimalPlaces: 2)") == "1.12"
        expect("\(1.125, decimalPlaces: 2)") == "1.13"
        expect("\(1.126, decimalPlaces: 2)") == "1.13"
        expect("\(1.129, decimalPlaces: 2)") == "1.13"
    }
}
