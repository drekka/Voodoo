//
//  Created by Derek Clarkson on 3/8/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

// Simulcra extensions to Hummingbird

extension HBApplication: SimulcraContext {

    public var port: Int {
        guard let port = configuration.address.port else {
            fatalError("💥💥💥 No port set on server 💥💥💥")
        }
        return port
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

extension HBApplication {

    /// Javascript execution support.
    var javascript: JavascriptExecutor {
        get { extensions.get(\.javascript) }
        set { extensions.set(\.javascript, value: newValue) }
    }
}

extension HBRouter {

    func add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        on(path, method: method) {
            try await response.hbResponse(for: $0.asHTTPRequest, inServerContext: $0.application)
        }
    }
}
