import Foundation

extension String.StringInterpolation {

    /// Adds support for a numeric interpolation with decimal pplaces.
    mutating func appendInterpolation(_ number: Double, decimalPlaces: Int? = nil) {

        guard let decimalPlaces else {
            appendLiteral(String(number))
            return
        }

        let formatted = number.formatted(.number.precision(.fractionLength(0...decimalPlaces)))
        appendLiteral(formatted)
    }
}
