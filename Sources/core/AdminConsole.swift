import Foundation

extension VoodooServer {

    private static let adminRoot = "_admin"
    static let adminShutdown = "/\(adminRoot)/shutdown"
    static let adminDelay = "/\(adminRoot)/delay"
    static let cache = "/\(adminRoot)/cache"

    func addAdminConsole() {

        add(.POST, VoodooServer.adminShutdown) { [weak self] _, _ in
            print("💀 Received shutdown request, shutting down server ...")
            self?.stop()
            return .ok()
        }

        add(.POST, VoodooServer.cache) { [weak self] request, _ in
            print("💀 Received cache update")
            guard let self, let json = request.bodyJSON, let keyVales = json as? [String: Any] else {
                return .badRequest()
            }
            if verbose { print("💀 Updating cache …") }
            keyVales.forEach {
                if self.verbose { print("💀   \($0): \($1)") }
                self.server.cache[$0] = $1
            }
            return .created()
        }

        add(.PUT, VoodooServer.adminDelay + "/:delay") { [weak self] request, _ in

            guard let self else { return .ok() }

            if let rawDelay = request.pathArguments.delay,
               let delay = Double(rawDelay) {
                if verbose { print("💀 Setting new request delay \(delay, decimalPlaces: 2) seconds") }
                self.delay = delay
                return .ok()
            }

            return .badRequest()
        }
    }
}
