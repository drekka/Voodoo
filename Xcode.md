
# Xcode integration guide

The initial development of Simulcra was to support Swift UI testing through a local server instead of an unreliable development or QA server.

## How does it work?

1. In the `setUp()` of your UI test suite you start and configure an instance of Simulcra.
2. From the running instance, get the port it's running on and create a `http://<host-ip>:<port>` URL.
3. Using a launch argument, pass this URL to your app. 
4. Finally in `teardown()` clear the Simulcra instance otherwise Simulcra and the port will stay allocated until the end of the test run. 

*Note that I said "test run" in step 4. XCTests do not deallocate until all the tests have finished so it's important to free up any ports that Simulcra is using so other tests can re-use them.*

## Setting up the server

In your `XCTestCase` you need to override `setUp() like this:

```swift
class MyUITests: XCTestCase {

    

}
```

## Adding mock endpoints



