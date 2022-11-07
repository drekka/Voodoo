//
//  Created by Derek Clarkson on 3/8/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

// Voodoo extensions to Hummingbird

extension HBApplication: VoodooContext {

    public var port: Int {
        guard let port = configuration.address.port else {
            fatalError("💥💥💥 No port set on server 💥💥💥")
        }
        return port
    }

    public var host: String {
        guard let host = configuration.address.host else {
            fatalError("💥💥💥 No host set on server 💥💥💥")
        }
        return host
    }

    /// Stores a mustache rendering engine for payload templates.
    public var mustacheRenderer: HBMustacheLibrary {
        get { extensions.get(\.mustacheRenderer) }
        set { extensions.set(\.mustacheRenderer, value: newValue) }
    }

    /// An in-memory cache that is wiped when the server is shutdown.
    public var cache: Cache {
        get { extensions.get(\.cache) }
        set { extensions.set(\.cache, value: newValue) }
    }
}

extension HBRouter {

    func add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        on(path, method: method) {
            try await response.hbResponse(for: $0.asHTTPRequest, inServerContext: $0.application)
        }
    }
}

extension HBRequest {

    /// Convenience variable to obtain a wrapped request.
    var asHTTPRequest: HTTPRequest {
        HBRequestWrapper(request: self)
    }
}

/// Applies ``KeyedValues`` to the headers.
extension HTTPHeaders: KeyedValues {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.name.hashValue).inserted ? $0.name : nil }
    }

    public subscript(key: String) -> String? { first(name: key) }

    public subscript(dynamicMember key: String) -> String? { first(name: key) }

    public subscript(dynamicMember key: String) -> [String] { self[key] }
}

/// Applies ``KeyedValues`` to Hummingbird's parameters.
extension HBParameters: KeyedValues {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.key.hashValue).inserted ? String($0.key) : nil }
    }

    public subscript(key: String) -> [String] { getAll(key) }

    public subscript(dynamicMember key: String) -> String? { self[key] }

    public subscript(dynamicMember key: String) -> [String] { getAll(key) }
}
