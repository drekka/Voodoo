//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import HummingbirdMustache

/// Defines various features of the server's context.
protocol MockServerContext {

    /// The address of the server.
    var address: URL { get }

    /// The current mustache render.
    var mustacheRenderer: HBMustacheLibrary { get }

    /// Local in-memory cache for storing data between requests.
    var cache: Cache { get }

    /// Called just before rendering a template, this combines all the server template data, cache data and an individual request additional data
    /// into a single ``TemplateData`` instance for the render.
    ///
    /// This starts with the server's ``address`` then adds all the cache data and finally the passed requests custom data. If there are duplicate keys
    /// detected in the merges then the new value will be used, overriding any prior data.
    ///
    /// - parameter requestData: Additional data unique to the current request.
    func requestTemplateData(adding requestData: TemplateData) -> TemplateData
}

extension MockServerContext {

    func requestTemplateData(adding requestData: TemplateData = [:]) -> TemplateData {
        ["mockServer": address.absoluteString].merging(cache.dictionaryRepresentation()) { $1 }.merging(requestData) { $1 }
    }
}
