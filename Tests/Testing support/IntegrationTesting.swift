//
//  Created by Derek Clarkson on 30/9/2022.
//

import Foundation
import Hummingbird
import Nimble
import NIOHTTP1
@testable import Voodoo

/// Add this protocol to gain access to integration testing functions.
protocol IntegrationTesting: AnyObject {

    typealias ServerResponse = (data: Data?, response: HTTPURLResponse?, error: Error?)

    var server: VoodooServer! { get set }

    func tearDownServer()
}

extension IntegrationTesting {

    func tearDownServer() {
        server?.stop()
        server = nil
    }

    @discardableResult
    func executeAPICall(_ method: HTTPMethod,
                        _ path: String,
                        withHeaders headers: Voodoo.HTTPHeaders = [:],
                        body: Data? = nil,
                        andExpectStatusCode expectedStatusCode: Int? = nil,
                        file: FileString = #file, line: UInt = #line) async -> ServerResponse {
        var request = URLRequest(url: server.url.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach {
            request.addValue($1, forHTTPHeaderField: $0)
        }
        return await executeAPICall(request, andExpectStatusCode: expectedStatusCode, file: file, line: line)
    }

    @discardableResult
    func executeAPICall(_ request: URLRequest,
                        andExpectStatusCode expectedStatusCode: Int? = nil,
                        file: FileString = #file, line: UInt = #line) async -> ServerResponse {
        let response: ServerResponse
        do {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 2.0 // Fast timeout so tests don't wait too long when the server doesn't respond.
            let session = URLSession(configuration: configuration, delegate: RedirectStopper(), delegateQueue: nil)
            let callResponse = try await session.data(for: request)
            response = ServerResponse(data: callResponse.0, response: callResponse.1 as? HTTPURLResponse, error: nil)
        } catch {
            return ServerResponse(data: nil, response: nil, error: error)
        }

        if let expectedStatusCode {
            expect(file: file, line: line, response.response!.statusCode).to(equal(expectedStatusCode), description: "HTTP status code incorrect,")
            expect(file: file, line: line, response.error).to(beNil(), description: "Expected error to be 'nil',")
        }

        return response
    }

}

class RedirectStopper: NSObject, URLSessionTaskDelegate {
    func urlSession(_: URLSession,
                    task _: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest _: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        print("Stopping redirect to \(response.url?.absoluteString ?? "")")
        completionHandler(nil)
    }
}
