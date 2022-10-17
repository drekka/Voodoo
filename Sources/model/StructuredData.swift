//
//  File.swift
//
//
//  Created by Derek Clarkson on 17/10/2022.
//

import Foundation

/// A codable friendly data structure that allows us to avoid trying to hack `Any` types when we don't know the
/// data in advance.
///
/// This is basically a version of https://github.com/iwill/generic-json-swift with additional types.

public indirect enum StructuredData {
    case `nil`
    case string(String)
    case boolean(Bool)
    case integer(Int)
    case double(Double)
    case date(Date)
    case array([StructuredData])
    case dictionary([String: StructuredData])
    case encodable(Encodable)

    /// Create a JSON value from anything.
    ///
    /// Argument has to be a valid JSON structure: A `Double`, `Int`, `String`,
    /// `Bool`, an `Array` of those types or a `Dictionary` of those types.
    ///
    /// You can also pass `nil` or `NSNull`, both will be treated as `.null`.
    public init(_ value: Any) throws {
        switch value {
        case let opt as Optional<Any> where opt == nil:
            self = .nil
        case let bool as Bool:
            self = .boolean(bool)
        case let int as Int:
            self = .integer(int)
        case let double as Double:
            self = .double(double)
        case let str as String:
            self = .string(str)
        case let array as [Any]:
            self = .array(try array.map(StructuredData.init))
        case let dict as [String: Any]:
            self = .dictionary(try dict.mapValues(StructuredData.init))
        case let encodable as Encodable:
            self = .encodable(encodable)
        default:
            throw SimulcraError.conversionError("Unable to convert \(value) to a StructureData item.")
        }
    }
}

extension Encodable {
    var structuredData: StructuredData {
        .encodable(self)
    }
}

extension StructuredData: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension StructuredData: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, StructuredData)...) {
        self = .dictionary(Dictionary(elements) { $1 })
    }
}

extension StructuredData: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: StructuredData...) {
        self = .array(elements)
    }
}

extension StructuredData: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

// MARK: - Codable

extension StructuredData: Codable {

    public func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()

        switch self {
        case .array(let array): try container.encode(array)
        case .dictionary(let dictionary): try container.encode(dictionary)
        case .string(let string): try container.encode(string)
        case .integer(let integer): try container.encode(integer)
        case .boolean(let bool): try container.encode(bool)
        case .nil: try container.encodeNil()
        case .double(let double): try container.encode(double)
        case .date(let date): try container.encode(date)
        case .encodable(let encodable): try container.encode(encodable)
        }
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()

        // Note in here we do not decode into `.encodable` because we do not know the type.

        if container.decodeNil() {
            self = .nil
        } else if let array = try? container.decode([StructuredData].self) { // Array has to come before dictionary as the container can also decode an array into a dictionary.
            self = .array(array)
        } else if let dictionary = try? container.decode([String: StructuredData].self) {
            self = .dictionary(dictionary)
        } else if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unexpected Payload value type.")
            )
        }
    }
}
