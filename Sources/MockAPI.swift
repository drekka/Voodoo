//
//  Created by Derek Clarkson on 30/9/21.
//

import Swifter

/// The HTTP method for the mocked API.
public enum HTTPMethod {
    case all
    case get
    case put
    case post
    case delete

    func router(for server: HttpServer) -> HTTPRouter {
        switch self {
        case .all: return server
        case .get: return server.get
        case .put: return server.put
        case .post: return server.post
        case .delete: return server.delete
        }
    }
}

/// Defines a single mock endpoint to be registered on the server.
public struct MockAPI: RegisterableAPI {

    let method: HTTPMethod
    let pathTemplate: String
    let response: HTTPResponse
    
    public init(method: HTTPMethod, pathTemplate: String, response: HTTPResponse) {
        self.method = method
        self.pathTemplate = pathTemplate
        self.response = response
    }

    func register(onServer server: HttpServer, errorHandler: @escaping (HttpRequest, Error) -> HttpResponse) {
        register(onServer: server,
                 method: method,
                 pathTemplate: pathTemplate,
                 response: response,
                 errorHandler: errorHandler)
    }
}

/// Registers a stack of mock responses for an endpoint. When matching API calls come in, the responses are returned in order until the last one. Then any subsequent calls will receive the last response in the list.
public class MockAPIStack: RegisterableAPI {

    let method: HTTPMethod
    let pathTemplate: String
    var iterator: IndexingIterator<[HTTPResponse]>
    let lastResponse: HTTPResponse?

    public init(method: HTTPMethod, pathTemplate: String, stack: [HTTPResponse]) {
        self.method = method
        self.pathTemplate = pathTemplate
        iterator = stack.makeIterator()
        lastResponse = stack.last
    }

    func register(onServer server: HttpServer, errorHandler: @escaping (HttpRequest, Error) -> HttpResponse) {

        guard let lastResponse = lastResponse else {
            return
        }

        register(onServer: server,
                 method: method,
                 pathTemplate: pathTemplate,
                 response: self.iterator.next() ?? lastResponse,
                 errorHandler: errorHandler)
    }
}
