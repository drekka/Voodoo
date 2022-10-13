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
    * JSON generated from Encodable and other types.
    * Dynamic responses from Swift and JS.
* Can also serve files for non-API like resources.
* A fast in-memory cache for sharing data between requests. 
* Extra data supplied to Swift and JS code:
    * Parameters from REST like URLs.
    * Query arguments.
    * Form parameters. 
* Built in templating of responses via the Mustache template language.

# Quick guides

Because there are two main environments that you might want to use Simulcra in, I've created two seperate guides to keep things simple.

* [Xcode UI unit testing](Xcode.md)
* [Android/Linux](Linux.md)

# FAQ

## There's a bazillion mock servers out there, why do we need another?

For years I'd been looking for a mock server that addressed a variety of criteria:

* Runs locally so there's no dependencies on internet access or the risk of other processes and people interfering with it.
* Fast to start so it can be freshly started for each test to ensure a consistent state for each test.
* Easy to configure using simple configuration files and languages that most people know.
* Ability to start on a range of ports so I can run multiple servers in parallel for larger test suites.
* Ability to dynamically create responses using a commonly known language.
* Templating support for mixing and matching hard codes response payloads with dynamic data.

So after basically building servers with some of these features and a bunch of project specific ones, decided to sit down and write a more generic version that includes all of of the features I wanted, and could be used in any project.

## What dependencies does Simulcra have?

To build this project I used a number of 3rd party projects.

* [Hummingbird][hummingbird] - A very fast Swift NIO based server - This is the core that Simulcra is built around.
* [Yams][yams] - Yams provides the ability to read the YAML configuration files.
* [JXKit][jxkit] - Provides a facade to Swift's JavascriptCore and it's Linux equivalent so that Simulcra can run on both platforms. 
* [Nimble][nimble] - Simply the best assertion framework for unit testing.
* [Swift Argument Parser][swift-argument-parser] - Provides the API for the command line program.  

  
[hummingbird]: https://github.com/hummingbird-project/hummingbird
[swift-nio]: https://github.com/apple/swift-nio 
  
