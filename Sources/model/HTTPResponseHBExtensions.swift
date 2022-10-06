//
//  File.swift
//  
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache


// MARK: - Javascript types

// extension HTTPRequest {
//    var javascriptRequest: [String: Encodable] {
//
//
//
//    }
// }
//
// struct JavascriptHTTPRequest: Encodable {
//
//    let request: HTTPRequest
//
//    enum CodingKeys: String, CodingKey {
//        case method
//    }
//
//    var method: String { request.method.rawValue }
//    var headers: [String: Encodable] {
//        var results: [String: Encodable]? = nil
//        request.headers.forEach {
//            let values: [String] = self[$0.0]
//            switch values.endIndex {
//            case 0:
//                break
//            case 1:
//                results[$0] = values.first
//            default:
//                results[$0] = values
//            }
//        }
//        return results }
//    var path: String { request.path }
//    var pathComponents: [String] { request.pathComponents }
//    var pathParameters: PathParameters { request.pathParameters }
//    var query: String? { request.query }
//    var queryParameters: [String: Encodable] { request.queryParameters.encodable }
//    var body: Data? { request.body }
//    var bodyJSON: Any? { request.bodyJSON }
//    var formParameters: FormParameters { request.formParameters }
//
// }

//extension KeyedValues {
//    func encodable(allKeys: () -> [String]) -> [String: Encodable] {
//        var results: [String: Encodable] = [:]
//        allKeys().forEach {
//            let values: [String] = self[$0]
//            switch values.endIndex {
//            case 0:
//                break
//            case 1:
//                results[$0] = values.first
//            default:
//                results[$0] = values
//            }
//        }
//        return results
//    }
//}

// MARK: - Response bodies

