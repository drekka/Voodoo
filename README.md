# Simulcra

A mock server built specifically to mock out server APIs for testing and debugging the apps that talk to them.

* Mock server for Swift unit and UI testing.
* Port range search for parallel testing.
* The ability to group API responses into scenarios for fast loading.
* Expectations and validations.
* Variety of response options including inline, local files, and external redirects.
* Pure Swift implementation. 
* Ability to pick information out of a request and pass it to other requests.

#FAQ

## There's a bazillion mock servers on GitHub, why do we need another?

Because after numerous searches I've not found one that has all the features I need. Most of the the ones I found handled simple serving. ie. matching an incoming request in some fashion and generating a response, but couldn't handle the more complex scenarios that come with larger and more complex apps. Nor could they handle things like parallel testing and dynamically changing responses.   

## How fast is Simulcra

First off, if you need a super fast mock server, you probably need to build a custom one of your own. In that respect I'd suggest looking at some of the [Swift NIO][swift-nio] servers such as [Hummingbird][hummingbird] (which is what Simulcra runs on :-). However Simulcra is built around [HummingBird][hummingbird] (why re-invent the wheel) so it should be reasonably performant.

## What dependencies does Simulcra have?

At the moment, just [Hummingbird][hummingbird]. I did toy with the idea of building a server from the ground up based on [Swift NIO][swift-nio] to minimise dependencies, but after looking at HummingBird I thought why re-invent the wheel when there is such a good implementation already done.

  
[hummingbird]: https://github.com/hummingbird-project/hummingbird
[swift-nio]: https://github.com/apple/swift-nio 
  
