
# Xcode integration guide

The initial development of Simulacra was to support Swift UI testing through a local server instead of an unreliable development or QA server.

## How does it work?

1. In the `setUp()` of your UI test suite you start and configure an instance of Simulacra.
2. From the running instance, get url the server is running on and...
3. Using a launch argument, pass the URL to your app. 
4. Finally in `teardown()` clear the Simulacra instance otherwise Simulacra and the port will stay allocated until the end of the test run. 

*Note that I said "test run" in step 4. XCTests do not deallocate until all the tests have finished so it's important to free up any ports that Simulacra is using so other tests can re-use them.*


## Adding mock endpoints

# Samples

## XC Test suite class:

```swift
/// Simple UI test suite base class that can be used to start a mock server instance before
/// running each test.
open class UITestCase: XCTestCase {

    /// The mock server.
    private(set) var server: Simulacra!

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
        server = try Simulacra(verbose: true, endpoints: endpoints)
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

## Simple tests with shared server

This example launches the server from the setup which means the same setup is used by all the tests.

```swift
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

## Individual test setup

This example allows each test to configure it's own setup before launching. This is most useful when doing things like testing feature flags which may vary from test to test in the same suite.

```swift
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

