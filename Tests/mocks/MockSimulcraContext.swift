//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
@testable import SimulcraCore
import HummingbirdMustache

struct MockSimulcraContext: SimulcraContext {

    let port = 8080

    let mustacheRenderer = HBMustacheLibrary()

    var cache: Cache = InMemoryCache()

}
