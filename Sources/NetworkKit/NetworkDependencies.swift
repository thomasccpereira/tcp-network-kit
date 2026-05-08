import Foundation

// MARK: - Network dependencies
public struct NetworkDependencies: Sendable {
   let sessionManager: any NetworkSessionManaging
   let requestBuilder: any NetworkRequestBuilding
   let cacher: any NetworkResponseCaching
   let logger: any NetworkLogging
   let errorMapper: any NetworkErrorMapping
   let validator: any NetworkResponseValidating
   let decoder: any NetworkResponseDecoding
   
   public init(sessionManager: any NetworkSessionManaging = DefaultSessionManager(),
               requestBuilder: any NetworkRequestBuilding = DefaultRequestBuilder(),
               cacher: any NetworkResponseCaching = DefaultNetworkResponseCache(),
               logger: any NetworkLogging = DefaultNetworkLogger(),
               errorMapper: any NetworkErrorMapping = DefaultErrorMapper(),
               validator: any NetworkResponseValidating = StatusCodeValidator(),
               decoder: any NetworkResponseDecoding = JSONResponseDecoder()) {
      self.sessionManager = sessionManager
      self.requestBuilder = requestBuilder
      self.cacher = cacher
      self.logger = logger
      self.errorMapper = errorMapper
      self.validator = validator
      self.decoder = decoder
   }
}
