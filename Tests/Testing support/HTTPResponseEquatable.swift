//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

@testable import SimulcraCore

extension HTTPResponse: Equatable {

    public static func == (lhs: SimulcraCore.HTTPResponse, rhs: SimulcraCore.HTTPResponse) -> Bool {
        switch (lhs, rhs) {

        case (.ok(let lhsHeaders, let lhsBody), .ok(let rhsHeaders, let rhsBody)),
             (.created(let lhsHeaders, let lhsBody), .created(let rhsHeaders, let rhsBody)):

            guard lhsHeaders?.count == rhsHeaders?.count else {
                return false
            }

            return lhsHeaders == rhsHeaders && lhsBody == rhsBody

        default:
            return false
        }
    }
}
