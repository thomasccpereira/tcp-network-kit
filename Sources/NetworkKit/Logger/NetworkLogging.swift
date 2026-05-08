import Foundation

// MARK: - Log - Protocol
public protocol NetworkLogging: Sendable {
   func logRequest(_ request: URLRequest)
   func logResponse(_ response: URLResponse, data: Data?)
   func logError(_ error: Error, for request: URLRequest)
   func logCacheHit(for request: URLRequest)
   func logCacheMiss(for request: URLRequest)
   func logCacheDecodeFailure(_ error: Error, for request: URLRequest)
}

// MARK: - Log - Concrete implementation
public final class DefaultNetworkLogger: NetworkLogging {
   public init() { }
   
   public func logRequest(_ request: URLRequest) {
      #if DEBUG
      print("-------------------------- NETWORK REQUEST START --------------------------")
      if let url = request.url, let httpMethod = request.httpMethod {
         print("\(httpMethod) \(url)")
      }
      if let headers = request.allHTTPHeaderFields {
         print("Headers: \(headers)")
      }
      if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
         print("Body: \(bodyString)")
      }
      print("--------------------------------------------------------------------------------")
      #endif
   }
   
   public func logResponse(_ response: URLResponse, data: Data?) {
      #if DEBUG
      print("--------------------------- NETWORK RESPONSE START ---------------------------")
      if let httpResponse = response as? HTTPURLResponse {
         print("Response - Status Code: \(httpResponse.statusCode)")
         print("Response URL: \(httpResponse.url?.absoluteString ?? "Unknown URL")")
      }
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
         print("Response Body: \(dataString)")
      }
      print("--------------------------- NETWORK RESPONSE END -----------------------------")
      #endif
   }
   
   public func logError(_ error: Error, for request: URLRequest) {
      #if DEBUG
      print("❌ [Error] \(error) for \(request.url?.absoluteString ?? "N/A")")
      #endif
   }
   
   // MARK: - Cache logging
   public func logCacheHit(for request: URLRequest) {
      #if DEBUG
      print("💾 [Cache] HIT for \(request.url?.absoluteString ?? "N/A")")
      #endif
   }
   
   public func logCacheMiss(for request: URLRequest) {
      #if DEBUG
      print("💾 [Cache] MISS for \(request.url?.absoluteString ?? "N/A")")
      #endif
   }
   
   public func logCacheDecodeFailure(_ error: Error, for request: URLRequest) {
      #if DEBUG
      print("💾 [Cache] DECODE FAILURE for \(request.url?.absoluteString ?? "N/A") – \(error)")
      #endif
   }
}
