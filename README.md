# Simulcra

A mock server built specifically for Swift Unit and UI testing.

* Mock server for Swift unit and UI testing.
* Testing orientated API.
* Randomised ports for parallel test suites.
* Scenarios for matching tests with multiple requests.
* Expectations and validations.
* Variety of response sources including inline, file and external.
* Mock or redirect to other servers.
* Pure Swift implementation. 

#FAQ

## There's a bazillion mock servers on GitHub, why do we need another?

Because after many rounds of searching for one to meet the needs of the projects I've worked on, I've never found one that had all the features I was looking for. All the mock and web servers I looked at based their interactions around simple serving. ie. matching incoming requests in some fashion and generating a response. Sure for simple testing that's all that's needed, but when dealing with server dependant apps such as those often found in the Enterprise world, something more is needed. And in that respect none of the servers I looked at communicated with the developers test suites in a fashion that addressed their needs.  

## How fast is Simulcra

First off, if you need a fast mock server, you're probably doing something wrong. Trying to write a unit test that would load a mock server heavily enough to matter is not something you really want to contemplate. 

But ... just in case (and because I wanted to try out the technology!) Simulcra is built using SwiftNIO for maximum performance. Pray you never need it.

## What dependencies does Simulcra have?

Honestly I wrestled with this a bit. I could for example, have built Simulcra on top of another server. [Swifter]() or [Vapor]() for example. But there where several reasons I didn't want to. One was that I wanted to reduce any downstream dependencies to as near zero as possible. The other was that I didn't want to have to deal with a bunch of technology I didn't need, or potentially have to work around ways they wanted to do things that I didn't. So Simulcra is built from the ground up using Apple only technologies.

  
