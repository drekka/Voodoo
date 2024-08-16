import Foundation
import Hummingbird

extension VoodooServer {

    private static let adminRoot = "_admin"
    static let adminShutdown = "/\(adminRoot)/shutdown"
    static let adminDelay = "/\(adminRoot)/delay"

    func addAdminConsole() {

        add(.POST, VoodooServer.adminShutdown) { _, _ in
            print("💀 Received shutdown request, shutting down server ...")
            self.stop()
            return .ok()
        }

        add(.PUT, VoodooServer.adminDelay + "/:delay") { [weak self] request, _ in

            guard let self else { return .ok() }

            if let rawDelay = request.pathParameters.delay,
               let delay = Double(rawDelay) {
                if verbose { print("💀 Setting new request delay \(delay, decimalPlaces: 2) seconds") }
                self.delay = delay
                return .ok()
            }

            return .badRequest()
        }
    }
}
