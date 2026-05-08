import Foundation

// MARK: - Network executor - Protocol
public protocol NetworkExecuting: Sendable {
   func execute(request: URLRequest,
                progress: NetworkProgress?) async throws -> (data: Data, response: URLResponse)
}

public extension NetworkExecuting {
   func execute(request: URLRequest) async throws -> (data: Data, response: URLResponse) {
      try await execute(request: request,
                        progress: nil)
   }
}

// MARK: - Network executor - Concrete implementation
final class NetworkExecutor: NSObject, NetworkExecuting {
   // MARK: - Properties
   private let sessionManager: any NetworkSessionManaging
   
   // MARK: - Init
   init(sessionManager: any NetworkSessionManaging = DefaultSessionManager()) {
      self.sessionManager = sessionManager
   }
   
   // MARK: - NetworkExecutable methods
   func execute(request: URLRequest, progress: NetworkProgress?) async throws -> (data: Data, response: URLResponse) {
      let urlSession = sessionManager.urlSession
      
      if let progress {
         let delegate = NetworkProgressDelegateProxy(progress: progress)
         let (data, response) = try await urlSession.data(for: request, delegate: delegate)
         return (data, response)
      }
      
      let (data, response) = try await urlSession.data(for: request)
      return (data, response)
   }
}
