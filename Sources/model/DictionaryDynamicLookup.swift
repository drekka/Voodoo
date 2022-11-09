//
//  File.swift
//
//
//  Created by Derek Clarkson on 31/10/2022.
//

import Foundation

/// Allow dynamic lookup on dictionaries where the key is a string.
extension Dictionary: DictionaryDynamicLookup where Key == String {}

/// Apply to allow dynamic member lookup on a dictionary.
@dynamicMemberLookup
public protocol DictionaryDynamicLookup {
    associatedtype Key
    associatedtype Value
    subscript(_: Key) -> Value? { get }
}

public extension DictionaryDynamicLookup where Key == String {
    subscript(dynamicMember key: String) -> Value? {
        self[key]
    }
}
