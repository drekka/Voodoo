//
//  Created by Derek Clarkson on 3/8/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

// Simulcra extensions to Hummingbird

extension HBApplication {
    var address: URL? {
        let address = configuration.address
        if let host = address.host, let port = address.port {
            var components = URLComponents()
            components.host = host
            components.port = port
            return components.url
        }
        return nil
    }

    /// Stores a mustache rendering engine for payload templates.
    var mustacheRenderer: HBMustacheLibrary? {
        get { extensions.get(\.mustacheRenderer) }
        set { extensions.set(\.mustacheRenderer, value: newValue) }
    }

    /// An in-memory cache that is wiped when the server is shutdown.
    var cache: Cache {
        get { extensions.get(\.cache) }
        set { extensions.set(\.cache, value: newValue) }
    }
}

extension HBRouter {

    func add(_ endpoint: Endpoint) {
        on(endpoint.path, method: endpoint.method) {
            await endpoint.response.hbResponse(for: HBRequestWrapper(request: $0), cache: $0.application.cache)
        }
    }
}
