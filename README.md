
![Untitled](assets/Untitled.png)

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/drekka/Voodoo/graphs/commit-activity)
[![GitHub license](https://img.shields.io/github/license/drekka/Voodoo.svg)](https://github.com/drekka/Voodoo/blob/master/LICENSE)
[![GitHub tag](https://img.shields.io/github/tag/drekka/Voodoo.svg)](https://GitHub.com/drekka/Voodoo/tags/)

***Note: This document is intended as a quick introduction to Voodoo. Please refer to the [Voodoo's Github Wiki](https://github.com/drekka/Voodoo/wiki) for more details.***


Voodoo is a mock server specifically designed to support debugging and automated testing of applications with a particular emphasis on being run as part of a regression or automated UI test suite.

It primary features are:

* Fast checkout and build via the Swift Package Manager. 

* Direct integration into XCode test suites or to be run as a stand alone server (for Android or other non-Xcode environments).
 
* Fast startup. Typically < 1sec.

* Parallel test friendly via port ranges.

* Configurable via a Swift API (for XCTest), and/or YAML and Javascript (for command line).

* RESTful and GraphQL query support.

* Fixed and dynamically generated responses including raw text, JSON, YAML, and custom data with templating via {{mustache}} and a pan-query cache for shared data.

* General file serving of non-API resources.

# Installation

## iOS/OSX SPM package

Voodoo comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add `https://github.com/drekka/Voodoo.git` as a package to your test targets and...

```swift
import Voodoo
```

## Linux, Windows, Docker, etc

Note that there is a more [detailed install for other platforms here](wiki/Building-Voodoo).

Once cloned you can build Voodoo using this command:

```bash
cd Voodoo
swift build -c release
```

... which will build the `magic` command line executable here

```bash
.build/release/magic
```

`magic` has a variety of options for starting Voodoo. Here's an example:

```bash
.build/release/magic run --config Tests/files/TestConfig1 --template-dir tests/templates --file-dir tests/files
```

At a minimum you do need to give it the path to a directory or file where it can load end point configurations from, but the rest is optional.

## Endpoints

Voodoo uses the concept of **Endpoint** to configure how it will respond to incoming requests. Each endpoint is defined by two things, a way to identify an incoming request and the response to return.  

In an XCTest endpoints can be passed as part of Voodoo's initialiser or they can be added later. With `magic` on the command line endpoints are configured in YAML files.

Here is an example of an XCTest starting the server with some endpoints:

```swift
server = try VoodooServer {

            HTTPEndpoint(.GET, "/config", response: .json(["featureFlag": true])

            HTTPEndpoint(.POST, "/login", response: .dynamic { request, cache in
                cache.loggedIn = true
                cache.username = request.formParameters.username
                return .ok()
            })

            HTTPEndpoint(.GET, "/profile", response: .dynamic { request, cache in
                if cache.loggedIn ?? false {
                    return .unauthorised()
                }
                return .ok(body: .json(["username": cache.username]))
            })
        }

```

And here is an example YAML file with the same endpoints, (see the [YAML configuration guide](/drekka/Voodoo/wiki/YAML-configuration-guide)) for details:

```yaml
- http:
    api: get /config
    response:
      type: json
      data:
        featureFlag: true
      
- http:
    api: post /login
    javascript: |
      function response(request, cache) {
          cache.loggedIn = true;
          cache.username = request.formParameters.username;
          return Response.ok();
      }
      
- http:
    api: get /profile
    javascript: |
      function response(request, cache) {
          if cache.loggedIn ?? false {
              return Response.unauthorised();
          }
          return Response.ok(Body.json({
              username: cache.username 
          }));
      }          
``` 
