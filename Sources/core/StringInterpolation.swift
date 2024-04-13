//
//  File.swift
//
//
//  Created by Derek Clarkson on 18/11/2022.
//

import Foundation

extension String.StringInterpolation {

    mutating func appendInterpolation(_ number: Double, decimalPlaces: Int? = nil) {

        guard let decimalPlaces else {
            appendLiteral(String(number))
            return
        }

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimalPlaces
        formatter.roundingMode = .halfUp
        if let result = formatter.string(from: number as NSNumber) {
            appendLiteral(result)
        }
    }
}
