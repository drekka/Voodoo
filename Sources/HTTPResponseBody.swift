//
//  Created by Derek Clarkson on 1/10/21.
//

import Swifter
import UIKit

/// Defines a range of sources where response bodies can be obtained.
public enum HTTPResponseBody {

    /// Loads the body by serializing a `Codable` object into JSON.
    case json(_ obj: Any)

    /// Loads the body from a file that contains JOSN.
    case jsonFile(_ url: URL)

    /// Loads the body from a raw piece of HTML.
    case html(_ html: String)

    /// Loads the body from a file containing HTML.
    case htmlFile(_ url: URL)

    /// Loads the body by embedding the passed HTML body inside a standard set of HTML tags.
    case htmlBody(_ htmlBody: String)

    /// Returns a piece of raw text.
    case text(_ text: String)

    /// Returns raw data as the specified content type.
    case data(_ data: Data, contentType: String? = nil)

    /// Returns the result of calling the closure.
    case custom((HttpRequest) -> HTTPResponseBody)

    func asSwifterResponseBody(forRequest request: HttpRequest) throws -> HttpResponseBody {
        switch self {

        case .json(let obj):
            return .json(obj)

        case .jsonFile(let url):
            let data = try contents(ofFileteUrl: url)
            do {
                let obj = try JSONSerialization.jsonObject(with: data)
                return .json(obj)
            } catch {
                throw SimulcraError.invalidFileContents(url.absoluteString)
            }

        case .html(let html):
            return .html(html)

        case .htmlFile(let url):
            let data = try contents(ofFileteUrl: url)
            if let html = String(data: data, encoding: .utf8) {
                return .html(html)
            }
            throw SimulcraError.invalidFileContents(url.absoluteString)

        case .htmlBody(let htmlBody):
            return .htmlBody(htmlBody)

        case .text(let text):
            return .text(text)

        case .data(let data, let contentType):
            return .data(data, contentType: contentType)

        case .custom(let closure):
            return try closure(request).asSwifterResponseBody(forRequest: request)
        }
    }

    private func contents(ofFileteUrl url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw SimulcraError.unableToReadFile(url.absoluteString)
        }
    }
}
