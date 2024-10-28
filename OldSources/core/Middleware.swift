import Foundation
import GraphQL
import Hummingbird

/// Logs all incoming requests.
public struct RequestLogger<Context: RequestContext>: RouterMiddleware {

    let verbose: Bool

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        if verbose { print("💀 Received \(request.method) \(request.uri)") }
        return try await next(request, context)
    }
}

/// Logs errors coming back from the routers.
public struct NoResponseFoundMiddleware<Context: RequestContext>: RouterMiddleware {

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        next( request, context)
            .flatMapError { error in
                switch error {
                case let error as GraphQLError:
                    print("💀 ⚠️ Voodoo GraphQL error: \(error)")
                    return request.failure(VoodooError.invalidGraphQLRequest(error.description))
                case let error as VoodooError:
                    print("💀 ⚠️ Voodoo error: \(error.localizedDescription)")
                case let error as HBHTTPError where error.status == .notFound:
                    let signature = "\(request.method) \(request.uri.path)"
                    print("💀 ⚠️ No endpoint registered for: \(signature)")
                    return request.failure(VoodooError.noHTTPEndpoint("No endpoint registered for: \(signature)"))
                default:
                    print("💀 ⚠️ Unexpected error: \(error.localizedDescription)")
                }
                return request.failure(error)
            }
    }
}
