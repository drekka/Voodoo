//
//  Created by Derek Clarkson on 16/9/2022.
//

import Hummingbird
import NIOEmbedded

struct MockHBRequestContext: HBRequestContext {
    let eventLoop: EventLoop = EmbeddedEventLoop()
    let allocator = ByteBufferAllocator()
    let remoteAddress: SocketAddress? = nil
}
