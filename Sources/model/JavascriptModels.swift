//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation

enum JavascriptModels {
    static let responseType = #"""

        // Used to define function arguments that are required.
        //        Object.defineProperty(globalThis, 'REQUIRED', {
        //            configurable: false,
        //            get: function() {
        //                let err = new Error('');
        //                let trace = err.stack.split('\n');
        //                let msg = '';
        //                for (let i = 2; i < trace.length; i++) msg += trace[i] + '\n';
        //                throw 'Error : Missing required parameter\n' + msg;
        //            }
        //        });


        class Response {

            static raw(code, body, headers) {
                return { status: code, body: body, headers: headers };
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

            static permanentRedirect(url) {
                return { status: 308, url: url };
            }

            static badRequest(body, headers) {
                return this.raw(400, body, headers);
            }

            static unauthorised(body, headers) {
                return this.raw(401, body, headers);
            }

            static forbidden(body, headers) {
                return this.raw(403, body, headers);
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

            static text(text, templateData) {
                return { text: text, templateData: templateData };
            }

            static json(data, templateData) {
                return { json: data, templateData: templateData };
            }

            static yaml(data, templateData) {
                return { yaml: data, templateData: templateData };
            }

            static file(file, contentType) {
                return { file: file, contentType: contentType };
            }

            static template(name, contentType, templateData) {
                if (contentType == undefined) {
                    throw "Body.template(name, contentType, templateData) requires 'contentType' to be passed.";
                }
                return { template: name, templateData: templateData, contentType: contentType };
            }
        }
    """#
}
