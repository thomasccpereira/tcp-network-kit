import Foundation
import Testing
@testable import NetworkKit

@Suite("Network cache manager tests", .serialized)
struct NetworkCacheManagingTests {
   // MARK: - Local helpers (self-contained)
   private enum TD {
      static let host = "https://example.com"
      static let path = "/cache-tests"
      static var url: URL { URL(string: host + path)! }
      static let payload = Data("{ \"ok\": true }".utf8)
   }

   // MARK: - Build a URLRequest using the package builder
   private func makeRequest(host: String = TestData.host,
                            path: String = TestData.path,
                            method: HTTPMethod = .get,
                            headers: HTTPHeaders? = nil,
                            body: HTTPBody? = nil) throws -> URLRequest {
      struct Config: NetworkRequestConfig {
         let host: String
         let path: String
         let method: HTTPMethod
         let headers: HTTPHeaders?
         let body: HTTPBody?
      }
      
      let config = Config(host: host,
                          path: path,
                          method: method,
                          headers: headers,
                          body: body)
      
      let builder = DefaultRequestBuilder()
      return try builder.makeRequest(with: config)
   }
   
   @Test func cacheStoresAndRetrievesWithinTTL() async throws {
      // Fresh cache per test
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      let request = try makeRequest()
      let response = HTTPURLResponse(url: TD.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      
      // Store with a comfortable TTL
      await cache.store(TD.payload, response: response, for: request, ttl: .seconds(30))
      
      // Should be immediately retrievable
      let cached = await cache.cachedResponse(for: request)
      #expect(cached == TD.payload)
   }
   
   @Test func cacheExpiresAfterTTL() async throws {
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      // Use a unique path to avoid any cross-test bleed
      let uniquePath = TD.path + "-expire-\(UUID().uuidString)"
      let request = try makeRequest(path: uniquePath)
      let response = HTTPURLResponse(url: URL(string: TD.host + uniquePath)!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      
      // Very short TTL
      await cache.store(TD.payload, response: response, for: request, ttl: .milliseconds(5))
      
      // Let it expire
      try? await Task.sleep(for: .milliseconds(10))
      
      // Now it should be gone
      let cached = await cache.cachedResponse(for: request)
      #expect(cached == nil)
   }
   
   @Test func clearCacheRemovesEntryRegardlessOfTTL() async throws {
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      let uniquePath = TD.path + "-clear-\(UUID().uuidString)"
      let request = try makeRequest(path: uniquePath)
      let response = HTTPURLResponse(url: URL(string: TD.host + uniquePath)!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      
      // Long TTL so expiry wouldn't be the reason it disappears
      await cache.store(TD.payload, response: response, for: request, ttl: .seconds(3600))
      
      // Sanity check it’s there
      let before = await cache.cachedResponse(for: request)
      #expect(before == TD.payload)
      
      // Clear and verify it's gone
      await cache.clearCache(for: request)
      let after = await cache.cachedResponse(for: request)
      #expect(after == nil)
   }
}
