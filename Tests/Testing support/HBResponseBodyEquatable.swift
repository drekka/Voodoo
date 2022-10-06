//
//  File.swift
//  
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import NIOCore
@testable import SimulcraCore

extension HBResponseBody: Equatable {

    public static func == (lhs: HummingbirdCore.HBResponseBody, rhs: HummingbirdCore.HBResponseBody) -> Bool {
        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.byteBuffer(let lhsBuffer), .byteBuffer(let rhsBuffer)):
            return lhsBuffer.data == rhsBuffer.data

        default:
            return false
        }
    }
}

