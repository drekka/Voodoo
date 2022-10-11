//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

/// Defines various features of the server's context.
public protocol SimulcraContext {

    /// The port the server is running on.
    var port: Int { get }

    /// The current mustache render.
    var mustacheRenderer: HBMustacheLibrary { get }

    /// Local in-memory cache for storing data between requests.
    var cache: Cache { get }
}

extension SimulcraContext {

    /// Called just before rendering a template, this combines the cache data and an individual request additional data
    /// into a single ``TemplateData`` instance for the render.
    ///
    /// This starts with the server's cache data and merges in any of the request's custom data. If there are duplicate keys
    /// detected in the merges then the new value will be used, overriding any prior data.
    ///
    /// - parameter requestData: Additional data unique to the current request.
    func requestTemplateData(forRequest request: HTTPRequest, adding requestData: TemplateData? = nil) -> TemplateData {
        let host = request.headers["host"] ?? "127.0.0.1:\(port)"
        return cache.dictionaryRepresentation()
            .merging(["mockServer": host]) { $1 }
            .merging(requestData ?? [:]) { $1 }
    }
}
