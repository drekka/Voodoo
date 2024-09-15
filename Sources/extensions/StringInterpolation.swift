import Foundation

extension String.StringInterpolation {

    /// Supports specifying decimal places when printing numbers.
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
