import Foundation
import PathKit
import Stencil

protocol TemplateRenderer {

    func render(text: String, for request: HTTPRequest, withCachedData cache: Cache, responseData: TemplateData?) throws -> String

    func render(template: String, for request: HTTPRequest, withCachedData cache: Cache, responseData: TemplateData?) throws -> String
}

struct StencilTemplateRenderer: TemplateRenderer {

    private var environment: Environment

    init(paths: [Path]) {
        environment = Environment(loader: FileSystemLoader(paths: paths))
    }

    func render(text: String, for request: HTTPRequest, withCachedData cache: Cache, responseData: TemplateData?) throws -> String {
        let templateData = cache.templateData(forRequest: request, adding: responseData ?? [:])
        return try environment.renderTemplate(string: text, context: templateData)
    }

    func render(template: String, for request: HTTPRequest, withCachedData cache: Cache, responseData: TemplateData?) throws -> String {
        let templateData = cache.templateData(forRequest: request, adding: responseData ?? [:])
        return try environment.renderTemplate(name: template, context: templateData)
    }
}
