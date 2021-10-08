//
//  File.swift
//  
//
//  Created by Derek Clarkson on 5/10/21.
//

import Swifter

/// A cutom protocol defining router features based on Swifters singature.
protocol HTTPRouter {
    mutating func addRoute(path: String, responseGenerator: ((HttpRequest) -> HttpResponse)?)
}

/// Apply `Router` to method routes for specific HTTPMethods.
extension HttpServer.MethodRoute: HTTPRouter {
    mutating func addRoute(path: String, responseGenerator: ((HttpRequest) -> HttpResponse)?) {
        self[path] = responseGenerator
    }
}
/// Apply `Router` to the server for registering global routes.
extension HttpServer: HTTPRouter {
    func addRoute(path: String, responseGenerator: ((HttpRequest) -> HttpResponse)?) {
        self[path] = responseGenerator
    }
}
