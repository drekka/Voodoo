import Foundation
import Stencil
@testable import Voodoo

/// SImple mock context for testing purposes.
struct MockVoodooContext: VoodooContext {

    var delay = 0.0

    let port = 4321

    var templateRenderer: any TemplateRenderer = StencilTemplateRenderer(paths: ["."])

    var cache: Cache = InMemoryCache()
}
