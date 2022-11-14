
![Untitled](assets/Untitled.png)

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/drekka/Voodoo/graphs/commit-activity)
[![GitHub license](https://img.shields.io/github/license/drekka/Voodoo.svg)](https://github.com/drekka/Voodoo/blob/master/LICENSE)
[![GitHub tag](https://img.shields.io/github/tag/drekka/Voodoo.svg)](https://GitHub.com/drekka/Voodoo/tags/)

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

***Note: as this document is becoming too large to be practical because of all the features that Voodoo offers, it is being migrated/re-written into [Voodoo's Github Wiki](https://github.com/drekka/Voodoo/wiki), please refer there for updated information.***


# Installation

## iOS/OSX SPM package

Voodoo comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add `https://github.com/drekka/Voodoo.git` as a package to your test targets and

```swift
import Voodoo
```

## Linux, Windows, Docker, etc

If you don't already have a Swift compiler on your system there is an extensive installation guide to downloading and installing Swift on the [Swift org download page.](https://www.swift.org/download/)

Once installed, you can clone this repository:

```bash
git clone https://github.com/drekka/Voodoo.git
```

and build it:

```bash
cd Voodoo
swift build -c release
```

The finished executable will be

```bash
.build/release/magic
```

Which you can move anywhere you like as it's fully self contained.

### Executing from the command line

The command line program has a number of options, but here is a minimal example:

```bash
.build/release/magic run --config Tests/files/TestConfig1 
```

Seeing as the command line is designed for a non-programmatic situation, at a minimum you need to give it a path to a directory or file where it can load end points from.

However a more practical example might look like this:

```bash
.build/release/magic run --config Tests/files/TestConfig1 --template-dir tests/templates --file-dir tests/files
```

Which adds a directory of response templates and another containing general files such as images and javascript source for web pages. 

### Docker additional configuration

When launching Voodoo from within a [Docker container][docker] you will need to forwards Voodoo's ports if you app is not also running within the container.

Firstly you will have to tell Docker to publish the ports Voodoo will be listening on to the outside world. Usually by using something like 

```bash
docker run -p 8080-8090
```

The only issue with this is that Docker appears to automatically reserve the ports you specify even though Voodoo might not being listening on them. Details on container networking can be found here: [https://docs.docker.com/config/containers/container-networking/](https://docs.docker.com/config/containers/container-networking/).

Finally Voodoo's default IP of `127.0.0.1` isn't accessible from outside the container, so you need to tell it to listen to all IP addresses. To do this, launch Voodoo with the **_`--use-any-addr`_** flag which tells Voodoo to listen on `0.0.0.0` instead of `127.0.0.1`.

# Configuration

The thing about Voodoo is that you have a variety of ways to configure the server which you can mix and match to suite your needs. For example an iOS only team might just programmatically set it up, where as a mixed team might use a YAML/Javascript setup. You could even do a bit of both.

## Templates

Voodoo has the ability to read templates of responses stored in a directory. This is most useful when you are mocking out a server that generates a lot of response in JSON or some other textural form. By specifying a template directory when initialising the server these templates can be automatically made available as response payloads for incoming requests. Here's an example from a Swift UI test setup:

```swift
let templatePath = Bundle.testBundle.resourceURL!
server = try VoodooServer(templatePath: templatePath) {
    // Endpoints configured here.
}
```

Templates are managed by [The mustache engine](#the-mustache-engine) and keyed based on their file names excluding any extension. By default, the extension for a template is `.json` however that can be changed to anything using the `templateExtension` argument. So if there is a template file called `accounts/list-accounts.json` then it's key is `accounts/list-accounts`.

## File sources

In addition to serving responses from defined API endpoints Voodoo can also serve files from a directory based on the path. This is most useful for things like image files where the path of the incoming request can be directly mapped onto the directory structure. For example, `http://127.0.0.1/8080/images/company/logo.jpg` can be mapped to a file in `Tests/files/images/company/logo.jpg`. 

To do this you can add the initialiser argument `filePaths: URL(string: "Tests/files")` or add the command line argument `--file-dir Tests/files`. This can be done multiple times if you have multiple directories you want to search for files.

## Endpoints

### HTTP endpoints

In order to response to API requests Voodoo needs to be configured with *Endpoints*. An endpoint is basically a definition that Voodoo uses to define what requests response to and how. To do that it need 3 things:

* The HTTP method of the incoming request. ie. `GET`, `POST`, etc.
* The path of the incoming request. ie. `/login`, `/accounts/list`, etc.  
* The response to return. ie the HTTP status code, body, etc.

#### Path parameters

Apart from watching for fixed paths such as `/login` and `/accounts`, Voodoo can also extract arguments from REST like paths. For example, if you want to query user's account using `/accounts/users/1234` where `1234` is the user's employee ID, then you can specify the path as `/accounts/users/:employeeId` and Voodoo will automatically map incoming `/accounts/users/*` path, extracting the employee ID into a field which is then made available to the code that generates the response.

### GraphQL endpoints

## Responses

Generally a response to a request contains these things:

* The response status code.
* Additional headers.
* The body.

There are some basic responses common to both the YAML/javascript and Swift configurations. Responses such as `ok`, `created`, `notFound`, `unauthorised`, etc. But they also have some unique features to each. Details of which will are in the relevant sections below.

### Fixed responses

### Dynamic responses

Dynamic responses are one of the more useful features of Voodoo. Essentially they give you the ability to run code (Swift or Javascript) in response to an incoming request and for that code to decide how to respond.
In Swift a closure is called with this signature

```swift
(HTTPRequest, Cache) async -> HTTPResponse
```

in YAML it's a javascript function with this signature

```javascript
function response(request, cache) { ... }
``` 

Both of these are passed two special objects when they are called. 

#### The incoming request data

The first argument is a reference to the incoming request. This reference contains the following data:

* `method: HTTPMethod` - The HTTP method.
 
* `headers: Dictionary/Map<String, String>` - The incoming request headers.

* `path: String` - The path part of the incoming URL. ie. `/accounts/user`

* `pathComponents: Array<String>` - The path in components form. ie. `/`, `accounts`, `user`. This is most useful when functionality is layered in RESTful style APIs and you want to make decisions based on various path components. Note that the first component (`/`) is the root indicator as opposed to the component separator used for the rest of a path.

* `pathParameters: Dictionary/Map<String, String>` - Any parameters extracted from the path. For example, if the endpoint path is `/accounts/:user` and an incoming request has the path `/accounts/1234` then this map contains `["user":"1234"]`.

* `query: String?` - The untouched query string from the incoming URL. For example `?firstname=Derek&lastname=Clarkson`.

* `queryParameters: Dictionary/Map<String, String>` - The query parameters extracted into a map. The above example would map into `["firstname":"Derek", "lastname":"Clarkson"]`. Note that it is possible for query parameters to repeat with different values. For example `?search=books&search=airplanes`. If present, duplicates are mapped into a single array with all the value in the order specified. ie. `["search":["books","airplanes"]]`.

* `body: Data?` - The body in a raw `Data` form.

* `bodyJSON: Any?` - If the `Content-Type` header specifies a payload of JSON, this will attempt to deserialise the body into it and return the resulting object. That object will usually be either a single value, array or dictionary/map. 

* `formParameters: Dictionary/Map<String, String>` -  - If the `Content-Type` header specifies that the body contains form data, this will attempt to deserialise it into a dictionary/map and return it. 

#### The cache

The second argument is a cache which exists whilst the server is running, but is not saved. This allows dynamic end points to transfer data between each other. For example

```swift
// In a login dynamic response.

cache.firstname = "Derek"
cache.lastname = "Clarkson"

// And later in a dynamic response for user details.

let payload = [
    "first": cache.firstname,
    "last": cache.lastname
]
```

Using this cache allows all sorts of hard to manufacture responses to become much easier. One example is to place a simple array in the cache to simulate a shopping cart. That could reduce the number of endpoints required where as a non-cache setup would required many more to simulate all the different states.
 
### Response bodies

The response body defines the content (if any) that will be returned in the body of a response. Voodoo has a number of options available:

* An empty body.

* Text.

* Hard coded JSON or YAML formatted content.

* Content generated from a template file.

* Content from some other file.

* Raw binary data.

Textural, JSON, YAML and template generated response also have the added feature of being run through a mustache templating engine which allows additional dynamic data to be injected. 

### The mustache engine

With response bodies that effective return text (JSON, YAML, text) the results are passed to a [mustache engine](https://hummingbird-project.github.io/hummingbird/current/hummingbird-mustache/mustache-syntax.html) before the response is returned. Mustache is a simple logic less templating system for injecting values into text. 

When processing the text for mustache tags, Voodoo assembles a variety of data to pass to it for injection:

* `mockServer` - The base URL of the server as sourced from the incoming request. So if the incoming request `Host` header specifies that you app had to call `192.168.0.4:8080` to reference Voodoo through a Docker container or something like that. Then this will be set as the `mockServer` value in the template data so it can be injected into response data containing server URLs. For example, URLS that reference image files.

* All the data currently residing in the cache. 

* And finally, any additional data added by the endpoint definition. Note this data can override anything in the cache by simply using the same key.

# Xcode integration guide

The initial need for something like Voodoo was to support Swift UI testing through a local server instead of an unreliable development or QA server. This drove a lot of Voodoo's design.

## How does it work?

1. In the `setUp()` of your UI test suite you start and configure an instance of Voodoo.

2. Using a launch argument, pass Voodoo's URL to your app. 

3. Finally in `teardown()` clear the Voodoo instance otherwise Voodoo and the port will stay allocated until the end of the test run. 

*Note that I said "test run" in step 3. XCTests do not deallocate until all the tests have finished so it's important to free up any ports that Voodoo is using so other tests can re-use them.*

## Endpoints

To help with building endpoints in Swift there is an `Endpoint` type that can be created like this:

```swift
let endpoint = Endpoint(.GET, "/accounts/1234", .ok(body: .template("account-details-1234")
```

Voodoo has a variety of functions to make adding endpoints easy and flexible. The simplest however is to just pass them to the initialiser via the [Swift Result Builder](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID633) `endpoints` argument like this:

```swift
server = try Voodoo {
            Endpoint(.POST, "/login")
            Endpoint(.GET, "/config", response: .ok(body: .json(["version: 1.0])))
        }
```

You can also add endpoints after starting the server using these functions:

* `add(@EndpointBuilder _ endpoints: () -> [Endpoint])` - A [result builder](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID633) style convenience function.

* `add(_ endpoints: [Endpoint])` - Adds an array of end points.

* `add(_ endpoint: Endpoint)` - Adds a single endpoint.

* `add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok())` - Adds a single simple endpoint using the method, path and response.

* `add(_ method: HTTPMethod, _ path: String, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse)` - Adds a single dynamic endpoint using the passed closure. 

## Swift types

Voodoo uses a number of types to help define responses to APIs.


## Swift dynamic responses

Here is an example of a Dynamic response:

```swift
server = try Voodoo {
    Endpoint(.POST, "/login", response: .dynamic { request, cache in
        cache.userid = request.formParameters.userid
        return .json([
            "token": UUID().uuidString,
        ])
    })
}
```

It's pretty simple, just stashes the userid in the cache and generates some dynamic data for the response.

# Command line integration guide

If you are not using Voodoo in an XCode test suite then you will need to consider the command line option. This is based on a YAML configuration with Javascript as a dynamic language.

When launching Voodoo from a command line there is one required argument. **_--config_** specifies a directory or file from which the server's YAML configuration will be read. if it's a directory Voodoo will then scan it for any YAML files and read those files to build the endpoints it needs. If a reference to a file is passed then Voodoo assumes that all the endpoints are defined in that file.

## Endpoint files

Each YAML configuration file can contain either a single endpoint, or a list of endpoints. 

## Endpoint definitions

An endpoint definition can take one of 4 possible forms.

### Simple

```yaml
http:
  api: <method> <path>
response: <response>
```

The `signature` tells Voodoo how to match incoming requests. `response` tells it how to respond and provides the HTTP status, optional headers, and body. For example
  
```yaml
http: 
  api: get /config
response:
status: 200
headers: { config-version: 1.0 }
body:
  type: json
  data: {
    some-flag: true
  }
``` 
  
### Inline javascript

```yaml
http: 
  api:<method> <path>
javascript: |
  function response(request, cache) {
      // generate the response here
  }
```
  
This is the simplest form of a YAML configured dynamic response. For example

```yaml  
http:
  api: get /config
javascript: |
  function response(request, cache) {
      if request.headers.app-version == 1.0 {
          return Response.ok(
              Body.json({
                  some-flag: true  
              }),
              { config-version: 1.0 }
          );
      } else {
          return Response.ok(
              Body.json({
                  some-flag: false  
              }),
              { config-version: 1.1 }
          );
      }
  }
```

### Javascript file reference
  
```yaml
http:
  api: <method> <path>
javascriptFile: <js-file-name>
```
 
Also defining a dynamic response endpoint, this form references an external javascript file instead of have the code inline. This is convenient when you have a number of endpoints listed in the YAML file, or you want to store the javascript in a file with a `js` extension so it can be easy edited.  

```yaml
http:
  api: get /config
javascriptFile: get-config.js
```
  
## YAML file reference

```yaml
<reference-to-another-YAML-file>
```

Instead of a data structure with a `signature` value defining the endpoint, this references another YAML file, effectively including it. This is most useful for situations where you want to define endpoints and then include them in other configurations which define various scenarios you want to load.

```yaml
- login.yml
- accounts.yml
- accounts/customer-accounts.yml
```

## Javascript types


  
# Samples

Here are some sample files showing how various things can be done.

## XCTest suite class:

Cut-n-paste this to a swift file in you UI tests. It provides the core setup needed to run Voodoo in a XCTest UI test suite.

```swift
import XCTest
import Voodoo

/// Simple UI test suite base class that can be used to start a mock server instance before
/// running each test.
open class UITestCase: XCTestCase {

    /// The mock server.
    private(set) var server: Voodoo!

    /// Local app reference.
    private(set) var app: XCUIApplication!

    /// Launch arguments to be passed to your app. These can  be augmented
    /// in each test suite to control feature flags and other things for the test.
    open var launchArguments: [String] {
        [
            "--server", server.url.absoluteString,
        ]
    }

    // Overridden tear down that ensures the server is unloaded.
    override open func tearDown() {
        server = nil
        super.tearDown()
    }

    /// Call to launch the server. This should be done before ``launchApp()``
    ///
    /// - parameter endpoints: The end points needed by the server.
    func launchServer(@EndpointBuilder endpoints: () -> [Endpoint]) throws {
        server = try VoodooServer(verbose: true, endpoints: endpoints)
    }

    /// Launches your app, passing the common launch arguments and any additional
    /// arguments.
    ///
    /// - parameter additionalLaunchArguments: Allows you to add additional arguments
    /// to a launch. Note that if you specify an argument twice, the later argument will
    /// override any prior ones.
    func launchApp(additionalLaunchArguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = launchArguments + additionalLaunchArguments
        app.launch()
    }
}
```

## XCTest simple tests with shared server

This example launches the server from the setup which means the same setup is used by all the tests.

```swift
import XCTest
import Nimble

class SimpleUITests: UITestCase {

    override open func setUpWithError() throws {
        try super.setUpWithError()
        try launchServer {
            Endpoint(.GET, "/config", response: .ok(body: .json(["configVersion": 1.0])))
        }
        launchApp()
    }

    func testConfigIsLoaded() throws {
        let configText = app.staticTexts["config-message"].firstMatch
        _ = configText.waitForExistence(timeout: 5.0)
        expect(configText.label) == "Config version: 1.00"
    }
    
    // ... and other tests.
}
```

## XCTest individual test setup

This example allows each test to configure it's own setup before launching. This is most useful when doing things like testing feature flags which may vary from test to test in the same suite.

```swift
import XCTest
import Nimble

class IndividualUITests: UITestCase {

    func testConfigIsLoaded() throws {

        try launchServer {
            Endpoint(.GET, "/config", response: .ok(body: .json(["configVersion": 1.0])))
        }
        launchApp(additionalLaunchArguments: ["-someFeatureFlag", "YES"])

        let configText = app.staticTexts["config-message"].firstMatch
        _ = configText.waitForExistence(timeout: 5.0)
        expect(configText.label) == "Config version: 1.00"
    }
    
    // ... and other tests.
}
```

## Simple YAML endpoint file

Here is a simple file that returns a fixed response.

```yaml
http:
  api: get /config
response:
  status: 200
  body:
    type: json
    data: {
      version: 1.0
    }
```

## YAML endpoint file with various inclusions

This file contains a number of responses and inclusions. It's a good example of defining multiple responses in a single file.

```yaml
# Simple endpoint
- http:    api: post /created/text
  response:
    status: 201
    headers: ~
    body:
      type: text
      text: Hello world!
      templateData: ~

# Included YAML file
- TestConfig1/get-config.yml

# Inline javascript dynamic response
- http:    api: get /javascript/inline
  javascript: |
    function response(request, cache) {
        if request.parthParameter.accountId == "1234" {
            return Response.ok();
        } else {
            return Response.notFound();
        }
    }
    
# Referenced javascript file
- http:    api: get /javascript/file
  javascriptFile: TestConfig1/login.js 
```

## Javascript response file

Javascript response file.

```javascript
function response(request, cache) {
    return Response.ok(Body.text("hello world!"));
}
```
