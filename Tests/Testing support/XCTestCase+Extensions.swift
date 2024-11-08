import XCTest
@testable import Voodoo

extension XCTestCase {

    func mockUserInfo() -> [CodingUserInfoKey: Any] {
        let resourcesURL = Bundle.testBundle.resourceURL!
        return [
            ConfigLoader.userInfoDirectoryKey: resourcesURL,
            ConfigLoader.userInfoFilenameKey: "TestFilename",
        ]
    }



}
