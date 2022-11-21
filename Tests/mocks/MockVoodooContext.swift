//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import HummingbirdMustache
@testable import Voodoo

struct MockVoodooContext: VoodooContext {

    var delay: Double = 0.0

    let port = 8080

    let mustacheRenderer = HBMustacheLibrary()

    var cache: Cache = InMemoryCache()
}
