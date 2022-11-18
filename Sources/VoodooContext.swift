//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache

/// Provides access to the server's features.
public protocol VoodooContext {

    /// The port the server is running on.
    var port: Int { get }

    /// The delay to inject into the current request.
    var delay: Double { get }

    /// The current mustache render.
    var mustacheRenderer: HBMustacheLibrary { get }

    /// Local in-memory cache for storing data between requests.
    var cache: Cache { get }
}

extension VoodooContext {

    /// Called just before rendering a template, this combines the cache data and an individual request additional data
    /// into a single ``TemplateData`` instance for the render.
    ///
    /// This starts with the server's cache data and merges in any of the request's custom data. If there are duplicate keys
    /// detected in the merges then the new value will be used, overriding any prior data.
    ///
    /// - parameter request: The request the data is needed for.
    /// - parameter requestData: Additional data unique to the current request.
    func requestTemplateData(forRequest request: HTTPRequest, adding requestData: TemplateData? = nil) -> [String: Any] {
        var overlay: [String: Any?] = [:]
        if let hostAddress = request.headers["host"] {
            overlay["mockServer"] = hostAddress
        }
        if let requestData {
            overlay.merge(requestData) { $1 }
        }
        return cache.dictionaryRepresentation().merging(overlay.compactMapValues { $0 }) { $1 }
    }
}
