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

# Quick guides

Because there are several main environments that you might want to use Simulcra in, I've created two seperate guides to keep things simple.

* [Xcode UI testing](Xcode.md)
* [Android/Linux](Linux.md)
* Embedded

# Installation

## iOS/OSX SPM package

Simulcra comes as an SPM module which can be added using Xcode to add it as a package to your UI test targets. Simply add `https://github.com/drekka/Simulcra.git` as a package to your test targets.

## Linux, Windows, Docker, etc

If you don't already have a Swift compile on your system there is an extensive installation guide to downloading and installing Swift on the [Swift org download page.](https://www.swift.org/download/)

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

The `simulcra` command line program has a number of options, but here is a minimal example:

```bash
.build/release/simulcra run --config Tests/Test\ files/TestConfig1 
```

### Docker additional configuration

When launching Simulcra from within a [Docker container][docker] you will need to forwards Simulcra's ports if you app is not also running within the container.

Firstly you will have to tell Docker to publish the ports Simulcra will be listening on to the outside world. Usually by using something like `docker run -p 8080-8090`. The only issue with this is that Docker appears to automatically reserve the ports you specify even though Simulcra might not being listening on them. I don't know if it's possible to tell Docker to only open a port when something inside the container wants it to. Details on container networking can be found here: [https://docs.docker.com/config/containers/container-networking/](https://docs.docker.com/config/containers/container-networking/).

In addition Simulcra's default IP of `127.0.0.1` isn't accessible from outside the container, so you need to tell it to listen to all IP addresses. To do this, launch Simulcra with the **_`--use-any-addr`_** flag which tells Simulcra to listen on `0.0.0.0` instead of `127.0.0.1`.

# Configuration

The thing about Simulcra is that you have a variety of ways to configure the server which you can mix and match to suite your needs. For example an iOS only team might just programmatically set it up, where as a mixed team might use a YAML/Javascript setup. You could even do a bit of both.

### Programmatically configuring the server.

This really only applies when using 

### YAML/Javascript

Generally when using Simulcra in an XCode test suite you would programmatically define the endpoints. However there is nothing to stop you from using a shared YAML/Javacript setup (for example when there is an Android team and you want to share the setup with them).


# FAQ

## When do I need a mock server?

Whether you need a mock server or not very much comes down to the app you are testing, the networking code you have written and your individual testing philosophies. When you have networking code that's easy to inject into and aren't too worried about the networking code working or perhaps have a 3rd party API there, it may be simpler just to inject mocks which can pretend to talk to a server and avoid any issues with around networking at all. But sometime's the code's old and written by someone who hasn't considered testing, or you want the assurity that it works right out to the server.

Another scenario where a mock server becomes useful is when UI and integration testing. many people start out writing tests against development, QA and even production servers. But there are problems doing that such as reliabilily, repeatability, limited scope to create data scenarios and other people and code interfering. All these make a stand alone mock server an attractive proposition.

## How do I ensure my mock server is the same as my production server?

You can't. Any mock server is only going to be as good as the setup you do and will only change when you change it. Some mock servers can import things like postman files but you still have to set up the responses.

## There's a bazillion mock servers out there, why do we need another?

For years I'd been looking for a mock server that addressed a variety of criteria:

* Local so there's no dependencies on internet access or the risk of other processes and people interfering with it.
* Ability to dynamically set a port so multiple parallel instances can be run. 
* Fast to start so there can be a new instance for each test to ensure a consistent state to start with.
* Easy to configure using simple configuration files and languages that most people know.
* Both fixed and dynamic responses.
* Templating so hard codes response payloads can dynamically inject data.

All the servers I found failed to match this list and given I've built a number of custom mock servers over the years I decided to sit down and write a more generic version that includes all of of the features I wanted, and could be used in any project.

## What dependencies does Simulcra have?

To build this project I used a number of 3rd party projects.

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
  
