# Simulcra

Simulcra is a mock server specifically designed for debugging and automated testing of applications with a particular emphasis on being run as part of a regression or automated UI test suite.

It primary features are:

* Easy to configure with a fast startup with no external dependencies.

* No data preserved across restarts to ensure consistent state on startup.

* Support for parallel test suites with automatic scanning for frees port to start the sever on.

* Run via a Swift API or from a shell command.

* Multiple ways to configure:
    
    * Via a Swift API for Xcode test suites.
    
    * Via YAML and Javascript (JS) files for other (Android) test suites.

* A variety of programmable responses to cover most situations:
    
    * Raw text and data.
    
    * JSON/YAML generated from Encodable and other types.
    
    * Dynamic responses from Swift and JS.

* Can also serve files for non-API like resources.

* A fast in-memory cache for sharing data between requests. 

* Extra data supplied to Swift and JS code:
    
    * Parameters from REST like URLs.
    
    * Query arguments.
    
    * Form parameters. 

* Built in templating of responses via the Mustache template language.

# Index

- [Installation](#installation)
  - [iOS/OSX SPM package](#iososx-spm-package)
  - [Linux, Windows, Docker, etc](#linux-windows-docker-etc)
    - [Executing from the command line](#executing-from-the-command-line)
    - [Docker additional configuration](#docker-additional-configuration)
- [Configuration](#configuration)
    - [Templates](#templates)
    - [File sources](#file-sources)
  - [Endpoints](#endpoints)
    - [Endpoint path paramaters](#endpoint-path-paramaters)
    - [Endpoint responses](#endpoint-responses)
    - [Dynamic responses](#dynamic-responses)
    - [Response bodies](#response-bodies)
    - [The mustache engine](#the-mustache-engine)
  - [Xcode integration guide](#xcode-integration-guide)
    - [How does it work?](#how-does-it-work)
    - [Endpoints](#endpoints)
    - [Response types](#response-types)
    - [Response bodies](#response-bodies)
  - [Command line](#command-line)
    - [Endpoint files](#endpoint-files)
    - [Response types](#response-types)
    - [Response bodies](#response-bodies)
- [FAQ](#faq)
  - [When do I need a mock server?](#when-do-i-need-a-mock-server)
  - [How do I ensure my mock server is the same as my production server?](#how-do-i-ensure-my-mock-server-is-the-same-as-my-production-server)
  - [There's a bazillion mock servers out there, why do we need another?](#there-s-a-bazillion-mock-servers-out-there-why-do-we-need-another)
  - [What dependencies does Simulcra have?](#what-dependencies-does-simulcra-have)
- [Samples](#samples)
  - [XCTest suite class:](#xctest-suite-class)
  - [XCTest simple tests with shared server](#xctest-simple-tests-with-shared-server)
  - [XCTest individual test setup](#xctest-individual-test-setup)
  - [Simple YAML endpoint file](#simple-yaml-endpoint-file)
  - [YAML endpoint file with various inclusions](#yaml-endpoint-file-with-various-inclusions)
  - [Javascript response file](#javascript-response-file)

# Installation

## iOS/OSX SPM package

Simulcra comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add `https://github.com/drekka/Simulcra.git` as a package to your test targets.

## Linux, Windows, Docker, etc

If you don't already have a Swift compiler on your system there is an extensive installation guide to downloading and installing Swift on the [Swift org download page.](https://www.swift.org/download/)

Once installed, you can clone this repository:

```bash
git clone https://github.com/drekka/Simulcra.git
```

and build it:

```bash
cd Simulcra
swift build -c release
```

This will download all dependencies and build the command line program. On my 10 core M1Pro it takes around a minute to do the build.

The finished executable will be

```bash
.build/release/simulcra
```

Which you can move anywhere you like as it's a fully self contained command line program.

### Executing from the command line

The command line program has a number of options, but here is a minimal example:

```bash
.build/release/simulcra run --config Tests/files/TestConfig1 
```

Seeing as the command line is designed for a non-programmatic situation, at a minimum you need to give it a path to a directory or file where it can load end points from.

A more practical example might look like this:

```bash
.build/release/simulcra run --config Tests/files/TestConfig1 --template-dir tests/templates --file-dir tests/files
```

Not hugely different. Basically it's adding a directory where response templates can be looked up and another containing general files such as image and javascript sources for web pages. 

### Docker additional configuration

When launching Simulcra from within a [Docker container][docker] you will need to forwards Simulcra's ports if you app is not also running within the container.

Firstly you will have to tell Docker to publish the ports Simulcra will be listening on to the outside world. Usually by using something like `docker run -p 8080-8090`. The only issue with this is that Docker appears to automatically reserve the ports you specify even though Simulcra might not being listening on them. I don't know if it's possible to tell Docker to only open a port when something inside the container wants it to. Details on container networking can be found here: [https://docs.docker.com/config/containers/container-networking/](https://docs.docker.com/config/containers/container-networking/).

In addition Simulcra's default IP of `127.0.0.1` isn't accessible from outside the container, so you need to tell it to listen to all IP addresses. To do this, launch Simulcra with the **_`--use-any-addr`_** flag which tells Simulcra to listen on `0.0.0.0` instead of `127.0.0.1`.

# Configuration

The thing about Simulcra is that you have a variety of ways to configure the server which you can mix and match to suite your needs. For example an iOS only team might just programmatically set it up, where as a mixed team might use a YAML/Javascript setup. You could even do a bit of both.

### Templates

Simulcra has the ability to read templates of responses stored in a directory. This is most useful when you are mocking out a server that generates a lot of response in JSON or some other textural form. By specifying a template directory when initialising the server these templates can be automatically made available as response payloads for incoming requests. Here's an example from a Swift UI test setup:

```swift
let templatePath = Bundle.testBundle.resourceURL!
server = try Simulcra(templatePath: templatePath) {
    // Endpoints configured here.
}
```

Templates are managed by [The mustache engine](#the-mustache-engine) and keyed based on their file names excluding any extension. By default, the extension for a template is `.json` however that cane be changed to anything using the `templateExtension` argument. So if there is a template file called `accounts/list-accounts.json` then it's key is `accounts/list-accounts`.

### File sources

In addition to defined endpoints for API calls Simulcra can also serve files from one or more directories. Usually you'd use this for things like image files where the path of the incoming request can be directly mapped to a directory structure. 

For example, if the app requests a logo file on `http://127.0.0.1/8080/images/company/logo.jpg`, and you have the file `Tests/files/images/company/logo.jpg` then starting the server with the argument `filePaths: URL(string: "Tests/files")` or the command line with `--file-dir Tests/files` will serve the logo file without you having to setup an endpoint.

You can also specify multiple file directories if needed.

## Endpoints

In order to response to API requests Simulcra needs to be configured with *Endpoints*. An end point basically tells the server what to watch for and how to response. To do that you need 3 things:

* The HTTP method of the incoming request. ie. `GET`, `POST`, etc.
* The path of the incoming request. ie. `/login`, `/accounts/list`, etc.  
* The response which contains the HTTP status code, body, etc.

### Endpoint path paramaters

Apart from fixed paths such as `/login` and `/accounts`, end points can also pick out arguments from REST like paths. For example, if you want to query user's account using `/accounts/users/1234` where `1234` is the user's employee ID, then you can use the path `/accounts/users/:employeeId` and Simulcra will automatically match the incoming path and extract the employee's ID into a field called `employeeId` which is then available to the code that generates the response.

### Endpoint responses

Generally a response to a request contains these things:

* A response status code.
* Any additional headers to be returned.
* A response body.

There are some basic responses common to both the YAML/javascript and Swift configurations. Responses such as `ok`, `created`, `notFound`, `unauthorised`, etc. But they also have some unique features to each. Details of which will are in the relevant sections below.

### Dynamic responses

Dynamic responses are one of the more useful features of Simulcra. In Swift they are created using a closure, in YAML they are a javascript functions. Essentially when a dynamic response specified the corresponding closure/function is called when a request comes in. That closure/function is then expected to return the actual response to the request. Because they functions, all sorts of logic and processing can be included to determine the correct response.

Dynamic response closure/functions are passed two special objects when they are called. 

#### The cache

The first is a cache which exists whilst the server is running, but not saved. This cache is specifically to allow end points to transfer data between each other. For example, a `/login` end point might create and store a session token in the cache so that `/accounts` endpoints know which account is current.

In both the Swift closure and Javascript function this cache can be accessed and updated busing dynamic properties. For example

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

#### The incoming request data

The second things that is available to the dynamic closure/functions is a reference to the incoming request. This reference contains the following data:

* `method: HTTPMethod` - The HTTP method.
 
* `headers: Dictionary/Map<String, String>` - Any incoming headers.

* `path: String` - The path part of the incoming URL. ie. `/accounts/user`

* `pathComponents: Array<String>` - The path in components form. ie. `/`, `accounts`, `user`. This is most useful when functionality is layered in RESTful style APIs. 

* `pathParameters: Dictionary/Map<String, String>` - Any parameters extracted from the path. For example, if the endpoint path is `/accounts/:user` and an incoming request has the path `/accounts/1234` then this map to `["user":"1234"]`.

* `query: String?` - The untouched query string from the incoming URL. For example `?firstname=Derek&lastname=Clarkson`.

* `queryParameters: Dictionary/Map<String, String>` - The query parameters extracted into a map. For example, the above parameters would become `["firstname":"Derek", "lastname":"Clarkson"]`. Note that it is possible for query parameters to repeat with different values. For example `?search=books&search=airplanes`. Simulcra will identify duplicates like this and instead of returning a single value, will return an array with all the value in the order specified. ie. `["search":["books","airplanes"]]`.

* `body: Data?` - The body in a raw `Data` form.

* `bodyJSON: Any?` - If the `Content-Type` header specifies a payload of JSON, this will attempt to deserialise the body into it and return the resulting object. That object will usually be either a single value, array or dictionary/map. 

* `formParameters: Dictionary/Map<String, String>` -  - If the `Content-Type` header specifies that the body contains form data, this will attempt to deserialise it into a dictionary/map and return it. 
 
### Response bodies

The response body defines the content (if any) that will be returned in the body of the response. Simulcra has a number of options available:

* An empty body.

* Text.

* Hard coded JSON or YAML formatted content.

* Content generated from a template file.

* Content from some other file.

* Raw binary data.

Textural, JSON, YAML and template generated response also have the added feature of being run through a mustache templating engine which allows additional dynamic data to be injected. 

### The mustache engine

With response bodies that effective return text (JSON, YAML, text) the results are passed to a [mustache engine](https://hummingbird-project.github.io/hummingbird/current/hummingbird-mustache/mustache-syntax.html) before the response is returned. Mustache is a simple logic less templating system for injecting values into text. 

When processing the text for mustache tags, Simulcra assembles a variety of data to pass to it for injection:

* `mockServer` - The base URL of the server as sourced from the incoming request. So if the incoming request `Host` header specifies that you app had to call `192.168.0.4:8080` to reference Simulcra through a Docker container or something like that. Then this will be set as the `mockServer` value in the template data so it can be injected into response data containing server URLs. For example, URLS that reference image files.

* All the data currently residing in the cache. 

* And finally, any additional data added by the endpoint definition. Note this data can override anything in the cache by simply using the same key.

## Xcode integration guide

The initial development of Simulcra was to support Swift UI testing through a local server instead of an unreliable development or QA server.

### How does it work?

1. In the `setUp()` of your UI test suite you start and configure an instance of Simulcra.

2. From the running instance, get url the server is running on and...

3. Using a launch argument, pass the URL to your app. 

4. Finally in `teardown()` clear the Simulcra instance otherwise Simulcra and the port will stay allocated until the end of the test run. 

*Note that I said "test run" in step 4. XCTests do not deallocate until all the tests have finished so it's important to free up any ports that Simulcra is using so other tests can re-use them.*

### Endpoints

To help with building endpoints in Swift there is an `Endpoint` type that can be created like this:

```swift
let endpoint = Endpoint(.GET, "/accounts/:employeeId", .ok(body: .template("ccount-details")
```

And as you can see in the next section there are a variety of ways you can add them.

Simulcra has a variety of functions to make adding endpoints simple, but often the simplest is to just pass them to the initialiser via the [Swift Result Builder](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID633) `endpoints` argument like this:

```swift
server = try Simulcra {
            Endpoint(.POST, "/login")
            Endpoint(.GET, "/config", response: .ok(body: .json(["version: 1.0])))
        }
```

After that there are a number of functions which you can call after starting the server to add further endpoints:

* `add(@EndpointBuilder _ endpoints: () -> [Endpoint])` - Another result builder style convenience function.

* `add(_ endpoints: [Endpoint])` - Adds an array of end points.

* `add(_ endpoint: Endpoint)` - Adds a single endpoint.

* `add(_ method: HTTPMethod, _ path: String, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse)` - Adds a single dynamic endpoint using the passed closure. 

* `add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok())` - Adds a single simple endpoint using the method, path and response.

### Response types

In Swift there are two core response types:

* `raw(_: HTTPResponseStatus, headers: HeaderDictionary? = nil, body: Body = .empty)` - which is a fully configurable.

* `dynamic(_ handler: (HTTPRequest, Cache) async -> HTTPResponse)` - which is used to dynamically generate a response. See [Dynamic responses](#dynamic-responses) for more details.

In addition there are a number of convenience response types for commonly used HTTP Status codes (more will be added over time):

* `ok(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `created(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `accepted(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `movedPermanently(_ url: String)`

* `temporaryRedirect(_ url: String)`

* `badRequest(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `unauthorised(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `forbidden(headers: HeaderDictionary? = nil, body: Body = .empty)`

* `notFound`

* `notAcceptable`

* `tooManyRequests`

* `internalServerError(headers: HeaderDictionary? = nil, body: Body = .empty)`

### Response bodies

For each of the responses above, a `body` argument can return one of the following payload definitions:

* `empty` - The empty payload.

* `template(_ templateName: String, templateData: TemplateData? = nil, contentType: String = ContentType.applicationJSON)` - Searches the template directory for a template matching the passed name. This excludes the extension which defaults to `json`. However that can be overridden using the `templateExtension` argument when launching the server if you want to use a different extension name. 

* `json(_ payload: Any, templateData: TemplateData? = nil)` - Encodes the passed payload as JSON before passing it to the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `yaml(_ payload: Any, templateData: TemplateData? = nil)` - Encodes the passed payload as YAML before passing it to the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `text(_ text: String, templateData: TemplateData? = nil)` - Encodes the passed payload as plain text before passing it to the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `file(_ url: URL, contentType: String)` - Reads the contents of the passed file and returns it with the specified content type.

* `data(_ data: Data, contentType: String)`- Returns the passed `Data` with the specified content type.


In all of the above a `templateData` parameter is for any additional data (usually in the form of a dictionary) that you want to pass to the mustache engine.

## Command line

Generally when using Simulcra in an XCode test suite you would programmatically define the endpoints. However there is nothing to stop you from using a shared YAML/Javascript setup (for example when there is an Android team and you want to share the setup with them). Here we are going to outline how this works.

When launching Simulcra from a command line there is one required argument. The **_--config_** argument which specifies a directory from which the server's configuration will be read. This works by scanning the passed directory for any YAML files and reading then with the assumption that each defines one or more endpoints to be configured.

### Endpoint files

Each endpoint YAML file contains either a single endpoint or a list of endpoints. 

Each endpoint takes one of these forms:

* A simple endpoint
  ```yaml
  signature: <method> <path>
  response: <response>
  ```
  
  This is the simplest form where you specify the signature to match incoming requests and the response to return. Each response requires a HTTP status, optional headers, and a body. The type of body is detailed in
  
  Here's an example:
  
  ```yaml
  signature: get /config
  response:
    status: 200
    headers: { config-version: 1.0 }
    body:
      type: json
      data: {
        some-flag: true
      }
  ``` 
  
* An endpoint with an inline javascript function 

  ```yaml
  signature: <method> <path>
  javascript: |
    function response(request, cache) {
      // generate the response here
    }
  ```
  
  This is where you can execute more dynamic code like this:

  ```yaml  
    signature: get /config
    javascript: |
      function response(request, cache) {
          if request.headers.app-version == 1.0 {
              return Response.ok(
                  Body.json({
                      some-flag: true  
                  }),
                  { config-version: 1.0 })
          } else {
              return Response.ok(
                  Body.json({
                      some-flag: false  
                  }),
                  { config-version: 1.1 })
          }
      }
  ```

* An end point with a javascript file reference
  
  ```yaml
  signature: <method> <path>
  javascriptFile: <js-file-name>
  ```
  
  This form allows you to reference javascript saved in a seperate file. This is convenient when you have a number of endpoints listed in the YAML file, and also because it allows you to store the javascript in a file with a `js` extension so it can be edited by a javascript editor.  

  ```yaml
  signature: get /config
  javascriptFile: get-config.js
  ```
  
* A YAML file reference

  ```yaml
  <reference-to-another-YAML-file>
  ```

Mostly used for composing sets of endpoint configs, this allows you to effectively include one file within another.

  ```yaml
  - login.yaml
  - accounts.yaml
  - accounts/customer-accounts.yml
  ```

### Response types

There are a number of types available to the javascript code. 

`Response` is a type that has the following `static` factory methods for creating responses:

* `raw(code, body, headers)` - The base response that most of the others drive. `code` is the HTTP status code, `body` is the body of the response as per below and `headers` is an object containing the headers to be returned.

* `ok(body, headers)` - Convenience for a HTTP 200 status response.

* `created(body, headers)` - Convenience for a HTTP 201 status response.

* `accepted(body, headers)` - Convenience for a HTTP 202 status response.

* `movedPermanently(url)` - Convenience for a HTTP 301 status response.

* `temporaryRedirect(url)` - Convenience for a HTTP 307 status response.

* `notFound()` - Convenience for a HTTP 404 status response.

* `notAcceptable()` - Convenience for a HTTP 406 status response.

* `tooManyRequests()` - Convenience for a HTTP 429 status response.

* `internalServerError(body, headers)` - Convenience for a HTTP 500 status response.

### Response bodies
  
To create the body arguments you can use a number of `Body` `static` factory methods:

* `empty()` - Returns an empty body.

* `text(text, templateData)` - Returns the passed text as the body of the request after passing it through the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `json(data, templateData)` - Encodes the passed data as JSON before passing it to the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `yaml(data, templateData)` - Encodes the passed data as YAML before passing it to the mustache engine for data injection. This automatically adds the correct `Content-Type` header to the response.

* `file(url, contentType)` - Reads the contents of the passed file and returns it with the specified content type.

* `template(name, contentType, templateData)` - Searches the template directory for a template matching the passed name. This excludes the extension which defaults to `json`. However that can be overridden using the `templateExtension` argument when launching the server if you want to use a different extension name. 

# FAQ

## When do I need a mock server?

Whether you need a mock server or not very much comes down to the app you are testing, the networking code you have written and your individual testing philosophies. When you have networking code that's easy to inject into and aren't too worried about the networking code working or perhaps have a 3rd party API there, it may be simpler just to inject mocks which can pretend to talk to a server and avoid networking at all. But sometime's the code's old, or written by someone who hasn't considered testing, or you want the assurity that it works right out to the server.

Another scenario where a mock server becomes useful is when UI and integration testing. many people start out writing tests against development, QA and even production servers. But there are a number of issues with that such as reliabilily, repeatability, limited scope to create data scenarios and not to mention, other people and code interfering with the server. Any of these can make a stand alone mock server an attractive proposition.

## How do I ensure my mock server is the same as my production server?

You can't. Any mock server is only going to be as good as the setup you give it and that will only change when you change it. So taking on a mock server does mean an on-going tech debt in terms of maintaining it and it's configuration.

## There's a bazillion mock servers out there, why do we need another?

Simply because I've never found one that had all the featured I was looking for. Namely:

* That it's local so the test suites don't need internet access and there's no risk of other processes or people interfering with it.

* Ability to dynamically set a port so multiple parallel instances can be run for iOS suites.

* Fast to start so running a fresh instance for each test is not an issue.

* Easy to configure without having to recompile using simple files and languages that are commonly known.

* Able to serve files, fixed and dynamic responses with the ability to extract information from incoming requests and store it for subsequent requests.

* Response payload templating so we can dynamically modify what is returned.

All the servers I found failed to match this list and whilst I've built a number of custom mock servers for clients over the years, they were all hard coded for their particular needs. Simulcra is designed to take all the features I could never find and make them as easy to configure as possible.

## What dependencies does Simulcra have?

To build this project I used a number of 3rd party projects. However you don't need to worry about these as the build will download them as needed.

* [Hummingbird][hummingbird] - A very fast and well written Swift NIO based server - This is the core that Simulcra is built around.

* [Yams][yams] - An API to read YAML configuration files.

* [JXKit][jxkit] - A facade to Swift's JavascriptCore and it's Linux equivalent so that Simulcra can run on both platforms. 

* [Nimble][nimble] - Simply the best assertion framework for unit testing.

* [Swift Argument Parser][swift-argument-parser] - The API that the command line program is built on.  

* [AnyCodable][any-codable] - Allows `Any` to be `Codable`.  
  
[hummingbird]: https://github.com/hummingbird-project/hummingbird
[yams]: https://github.com/jpsim/Yams
[jxkit]: https://github.com/jectivex/JXKit
[nimble]: https://github.com/Quick/Nimble
[swift-argument-parser]: https://github.com/apple/swift-argument-parser
[any-codable]: https://github.com/Flight-School/AnyCodable
[docker]: https://www.docker.com
  
# Samples

Here are some sample files showing how various things can be done.

## XCTest suite class:

Cut-n-paste this to a swift file in you UI tests. It provides the core setup needed to run Simulcra in a XCTest UI test suite.

```swift
import XCTest
import SimulcraCore

/// Simple UI test suite base class that can be used to start a mock server instance before
/// running each test.
open class UITestCase: XCTestCase {

    /// The mock server.
    private(set) var server: Simulcra!

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
        server = try Simulcra(verbose: true, endpoints: endpoints)
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
signature: get /config
response:
  status: 200
  body:
    type: json
    data: {
      version: 1.0
    }
```

## YAML endpoint file with various inclusions

This file contains a number of responses and inclusions.

```yaml
# Endpoint with templated response
- signature: post /created/text
  response:
    status: 201
    body:
      type: text
      text: Hello {{name}}!
      templateData: 
        name: Derek

# Another YAML file inclusion
- TestConfig1/get-config.yml

# Endpoint with dynamic javascript response.
- signature: get /account/:accountId
  javascript: |
    function response(request, cache) {
      if request.parthParameter.accountId == "1234" {
        return Response.ok()
      } else {
        return Response.notFound
      }
    }

# Request with javascript file inclusion.
- signature: get /accounts
  javascriptFile: TestConfig1/list-accounts.js 
```

## Javascript response file

Javascript response file.

```javascript
function response(request, cache) {
    return Response.ok()
}
```