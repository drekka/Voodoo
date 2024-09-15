import Foundation
import Hummingbird

extension HBRouterBuilder {

    func add(_ endpoint: HTTPEndpoint) {
        on(endpoint.path, method: endpoint.method) {
            try await endpoint.response.hbResponse(for: $0, context: $0.application)
        }
    }
}
