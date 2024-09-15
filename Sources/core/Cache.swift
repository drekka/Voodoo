import Foundation

/// Used to define an in-memory cache for sharing data between calls.
public typealias Cache = [String: Any]

extension Cache {

    /// Called just before rendering a template, this combines the cache with data from the request and any additional enpoint data ready
    /// for use by a template.
    ///
    /// - parameter request: The request the data is needed for. This is checked for a `host` header and if found,
    /// it's value is set as the template data's `mockServer` value.
    /// - parameter responseData: Additional data specified with the response being returned.
    func templateData(forRequest request: HTTPRequest, adding responseData: TemplateData) -> TemplateData {
        let hostAddress = request.headers["host"].map { ["mockServer": $0] as TemplateData } ?? [:]
        return merging(responseData) { $1 }.merging(hostAddress) { $1 }
    }
}

