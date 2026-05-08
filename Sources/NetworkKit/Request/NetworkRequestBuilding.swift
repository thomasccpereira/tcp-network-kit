import Foundation

// MARK: - Request builder - Protocol
public protocol NetworkRequestBuilding: Sendable {
   func makeRequest(with config: NetworkRequestConfig) throws -> URLRequest
}

// MARK: - Request builder - Concrete implementation
public final class DefaultRequestBuilder: NetworkRequestBuilding {
   public init() { }
   
   public func makeRequest(with requestConfig: NetworkRequestConfig) throws -> URLRequest {
      let urlString = requestConfig.host + requestConfig.path
      
      var urlComponents = URLComponents(string: urlString.sanitizedURL)
      if let queryItems = requestConfig.queryItems {
         urlComponents?.queryItems = queryItems
      }
      
      guard let urlComponents,
            let url = urlComponents.url,
            url.absoluteString.isValidURL else {
         throw NetworkError.networkRequestBuildFailure
      }
      
      var request = URLRequest(url: url)
      request.httpMethod = requestConfig.method.rawValue
      request.allHTTPHeaderFields = requestConfig.headers
      
      // Build XML envelope if nedeed
      if let xmlEnvelope = requestConfig.xmlEnvelope {
         request.httpBody = xmlEnvelope.documentData
      } else {
         request.httpBody = httpBody(requestConfig)
      }
      
      request.timeoutInterval = 10
      
      return request
   }
   
   // Private method
   private func httpBody(_ requestConfig: NetworkRequestConfig) -> Data? {
      requestConfig.body?.data
   }
}
