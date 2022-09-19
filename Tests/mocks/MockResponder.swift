//
//  Created by Derek Clarkson on 17/9/2022.
//

import Foundation
import Hummingbird
import NIOCore


class MockResponder: HBResponder {

    var gotRequest: Bool = false

    func respond(to request: Hummingbird.HBRequest) -> EventLoopFuture<Hummingbird.HBResponse> {
        gotRequest = true
        return request.success(HBResponse(status: .ok))
    }

}
