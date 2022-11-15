
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

Voodoo comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add `https://github.com/drekka/Voodoo.git` as a package to your test targets and

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

... and the finished executable will be

```bash
.build/release/magic
```

### Executing from the command line

The command line program has a number of options, heres an example:

```bash
.build/release/magic run --config Tests/files/TestConfig1 --template-dir tests/templates --file-dir tests/files
```

Seeing as the command line is designed for a non-programmatic situation, at a minimum you do need to give it the path to a directory or file where it can load end point configurations from.

## Endpoints

Voodoo uses the concept of **Endpoint** to configure how it will respond to incoming requests. Each endpoint is defined by two things, a way to identify an incoming request and the response to return.  

### HTTP endpoints

[HTTP RESTful style endpoints](wiki/HTTP-Endpoints) need

* The HTTP method of the incoming request. ie. `GET`, `POST`, etc.
* The path of the incoming request. ie. `/login`, `/accounts/list`, etc.  
* The response to return. ie the HTTP status code, body, etc.

### GraphQL endpoints

[Graph QL endpoints](wiki/GraphQL-Endpoints) are slightly different in that the path selector is replaced with a GraphQL operations or query selector.

## Responses

Generally a response to a request contains these things:

* The response status code.
* Additional headers.
* The body.

### Fixed responses

Fixed responses are hard coded

### Dynamic responses

Dynamic responses are one of the more useful features of Voodoo. Essentially they give you the ability to run code (Swift or Javascript) in response to an incoming request and for that code to decide how to respond.
In Swift a closure is called with this signature

# Samples

Here are some sample files showing how various things can be done.


## Simple YAML endpoint file

