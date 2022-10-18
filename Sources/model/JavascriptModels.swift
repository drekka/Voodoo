//
//  File.swift
//
//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation

enum JavascriptModels {
    static let responseType = #"""
        class Response {

            static raw(code, body, headers) {
                return { status: code, body: body ?? Body.empty(), headers: headers };
            }

            static ok(body, headers) {
                return this.raw(200, body, headers);
            }

            static created(body, headers) {
                return this.raw(201, body, headers);
            }

            static accepted(body, headers) {
                return this.raw(202, body, headers);
            }

            static movedPermanently(url) {
                return { status: 301, url: url };
            }

            static temporaryRedirect(url) {
                return { status: 307, url: url };
            }

            static notFound() {
                return this.raw(404);
            }

            static notAcceptable() {
                return this.raw(406);
            }

            static tooManyRequests() {
                return this.raw(429);
            }

            static internalServerError(body, headers) {
                return this.raw(500, body, headers);
            }
        }
    """#

    static let responseBodyType = #"""
        class Body {

            static empty() {
                return { type: "empty" };
            }

            static text(text, templateData) {
                return { type: "text", text: text, templateData: templateData };
            }

            static json(data, templateData) {
                return { type: "json", data: data, templateData: templateData };
            }

            static yaml(data, templateData) {
                return { type: "yaml", data: data, templateData: templateData };
            }

            static file(url, contentType) {
                return { type: "file", url: url, contentType: contentType };
            }

            static template(name, contentType, templateData) {
                return { type: "template", name: name, templateData: templateData, contentType: contentType };
            }
        }
    """#
}
