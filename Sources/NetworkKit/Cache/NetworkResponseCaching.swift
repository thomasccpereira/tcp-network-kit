import Foundation

// MARK: - Cache - Protocol
public protocol NetworkResponseCaching: Sendable {
   func cachedResponse(for request: URLRequest) async -> Data?
   func store(_ data: Data, response: URLResponse, for request: URLRequest, ttl: Duration) async
   func clearCache(for request: URLRequest) async
   func clearAll() async
}

// MARK: - Cache - Default implementation without passing cache ttl
extension NetworkResponseCaching {
   public func store(_ data: Data, response: URLResponse, for request: URLRequest) async {
      await store(data, response: response, for: request, ttl: .seconds(300))
   }
}

// MARK: - Cache - Concrete implementation
public actor DefaultNetworkResponseCache: NetworkResponseCaching {
   private let urlCache: URLCache
   private let expiresKey = "network.cache.expiresAt"
   
   public init(urlCache: URLCache = .shared) {
      self.urlCache = urlCache
   }
   
   public func cachedResponse(for request: URLRequest) async -> Data? {
      guard let cached = urlCache.cachedResponse(for: request) else { return nil }
      if let ts = (cached.userInfo?[expiresKey] as? Date), ts <= Date() {
         urlCache.removeCachedResponse(for: request)
         return nil
      }
      return cached.data
   }
   
   public func store(_ data: Data, response: URLResponse, for request: URLRequest, ttl: Duration) async {
      let expiresAt = Date().addingTimeInterval(ttl.timeInterval)
      let cached = CachedURLResponse(response: response,
                                     data: data,
                                     userInfo: [expiresKey: expiresAt],
                                     storagePolicy: .allowed)
      
      urlCache.storeCachedResponse(cached, for: request)
   }
   
   public func clearCache(for request: URLRequest) async {
      urlCache.removeCachedResponse(for: request)
   }
   
   public func clearAll() async {
      urlCache.removeAllCachedResponses()
   }
}

private extension Duration {
   var timeInterval: TimeInterval {
      let (s, attos) = components
      return TimeInterval(s) + TimeInterval(attos) / 1_000_000_000_000_000_000
   }
}
