//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
@testable import SimulacraCore
import HummingbirdMustache

struct MockSimulacraContext: SimulacraContext {

    let port = 8080

    let mustacheRenderer = HBMustacheLibrary()

    var cache: Cache = InMemoryCache()

}
