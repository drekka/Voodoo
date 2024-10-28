import Foundation

extension Bundle {

    /// Test bundle reference for locating test resources.
    static let testBundle = Bundle.module

    /// Path to the resources within the test bundle.
    static let resourcePath = Bundle.module.bundlePath
}
