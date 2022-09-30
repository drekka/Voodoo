//
//  Created by Derek Clarkson on 3/8/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

// Simulcra extensions to Hummingbird

extension HBApplication: MockServerContext {

    public var address: URL {
        let address = configuration.address
        var components = URLComponents()
        components.scheme = "http"
        components.host = address.host!
        components.port = address.port!
        return components.url!
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
            try await response.hbResponse(for: HBRequestWrapper(request: $0), inServerContext: $0.application)
        }
    }
}
