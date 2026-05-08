import Foundation

// MARK: - Session manager - Protocol
public protocol NetworkSessionManaging: Sendable {
   var urlSession: URLSession { get }
}

// MARK: - Session manager - Concrete implementation
public final class DefaultSessionManager: NetworkSessionManaging {
   public let urlSession: URLSession
   
   public convenience init() {
      self.init(configuration: nil)
   }
   
   public init(configuration: URLSessionConfiguration? = nil) {
      if let configuration {
         self.urlSession = URLSession(configuration: configuration)
         
      } else { // Default configuration
         let configuration = URLSessionConfiguration.default
         configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
         configuration.timeoutIntervalForRequest = 30.0
         configuration.timeoutIntervalForResource = 60.0
         self.urlSession = URLSession(configuration: configuration)
      }
   }
}
