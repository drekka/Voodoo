//
//  File.swift
//  
//
//  Created by Derek Clarkson on 30/9/21.
//

import Swifter

@resultBuilder
public enum MockAPIBuilder {
    static func buildBlock() -> [MockAPI] { [] }
}

/// Allows API mocks to be grouped.
public struct MockAPIGroup: RegisterableAPI {
        
    private let endpoints: () -> [MockAPI]
    
    public init(@MockAPIBuilder endpoints: @escaping () -> [MockAPI]) {
        self.endpoints = endpoints
    }
    
    func register(onServer server: HttpServer, errorHandler: @escaping (HttpRequest, Error) -> HttpResponse) {
        endpoints().forEach { $0.register(onServer: server, errorHandler: errorHandler) }
    }
}
