
![Untitled](assets/Untitled.png)

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/drekka/Voodoo/graphs/commit-activity)
[![GitHub license](https://img.shields.io/github/license/drekka/Voodoo.svg)](https://github.com/drekka/Voodoo/blob/master/LICENSE)
[![GitHub tag](https://img.shields.io/github/tag/drekka/Voodoo.svg)](https://GitHub.com/drekka/Voodoo/tags/)

***Note: This document is intended as a quick introduction to Voodoo. As Voodoo has a large number of features, please refer to [Voodoo's Github Wiki](../../wiki) for detailed information on how to use Voodoo.***


# Intro

Voodoo is a mock server specifically designed to support debugging and automated testing of applications with a particular emphasis on being run as part of a regression or automated UI test suite.

It primary features are:

* Fast checkout and build via the Swift Package Manager. 

* Direct integration into XCode test suites or to be run as a stand alone server (for Android or other non-Xcode environments).
 
* Fast startup. Typically < 1sec.

* Parallel test friendly via port ranges.

* Configurable via a Swift API (for XCTest), and/or YAML and Javascript (for command line).

* RESTful and GraphQL query support.

* Fixed and dynamic response definitions that can return raw text, JSON, YAML, or custom data.

* Response templating via {{mustache}} with a pan-query cache for sharing data between endpoints.

* General file serving of non-API resources.

# Installation

## iOS/OSX SPM package

Voodoo comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add [`https://github.com/drekka/Voodoo`](https://github.com/drekka/Voodoo) as a package to your test targets and...

```swift
import Voodoo
```

## Linux, Windows, Docker, etc

Note that there is a more [detailed install guide for other platforms here](../../wiki/Building-Voodoo).

You will need to have a working Swift environment. Then clone [`https://github.com/drekka/Voodoo`](https://github.com/drekka/Voodoo) and build Voodoo:

```bash
cd Voodoo
swift build -c release
```

Once finished you will find the `magic` command line executable in `.build/release/magic` which has a variety of options for starting Voodoo. For example:

```bash
.build/release/magic run --config Tests/files/TestConfig1 --template-dir tests/templates --file-dir tests/files
```

At a minimum you have to specify the `run` and `--config` arguments so Voodoo knows which directory or YAML file to load the endpoint configurations from, but the rest is optional.

## Endpoints

Voodoo uses the concept of **Endpoint** to configure how it will respond to incoming requests. Each endpoint is defined by two things, a way to identify an incoming request and the response to return.  

In a XCTest suite endpoints can be passed as part of the `VoodooServer` initialiser. They can also be added later. Here is a Swift example of starting Voodoo with some endpoints *(see the [Xcode configuration guide](../../wiki/XCode-configuration-guide))* for more details:

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

On the command line `magic` loads the endpoints from YAML files. For example, here is a YAML file with the same endpoints, *(see the [YAML configuration guide](../../wiki/YAML-configuration-guide))* for details:

*Sample.yml*
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

And here is how we would start Voodoo via `magic`:

```bash
$ magic -c Sample.yml
```

`magic` has a variety of options and there are many ways to setup the YAML configuration files. *See the [YAML endpoint setup](../../wiki/YAML-endpoint-setup) guide for details.*  

# Getting the URL

On starting Voodoo will automatically scan the configured port range for a free port (8080...8090 by default). When it finds an unused port it starts the server on it. 

To get the URL (including the port) of the server in Swift:

```
server.url.absoluteString
```

On the command line, `magic` outputs the server URL which means you can do something like this:

```bash
export VOODOO=`magic -c Sample.yml`