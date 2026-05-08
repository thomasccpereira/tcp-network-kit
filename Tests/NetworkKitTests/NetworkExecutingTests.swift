import Foundation
import Testing
@testable import NetworkKit

// MARK: - Network executor tests
@Suite("Network executor tests", .serialized)
struct NetworkExecutingTests {
   // Reset MockURLProtocol static state to avoid bleed between tests
   private func resetMockProtocol() {
      MockURLProtocol.responseData = nil
      MockURLProtocol.response = nil
      MockURLProtocol.error = nil
   }
   
   // Build a URLRequest using the package builder
   private func makeRequest(host: String = TestData.host,
                            path: String = TestData.path,
                            method: HTTPMethod = .post,
                            headers: HTTPHeaders? = [TestData.headerKey: TestData.headerValue],
                            body: HTTPBody? = ["modelID": TestData.model.modelID, "name": TestData.model.name]) throws -> URLRequest {
      struct Config: NetworkRequestConfig {
         let host: String
         let path: String
         let method: HTTPMethod
         let headers: HTTPHeaders?
         let body: HTTPBody?
      }
      
      let config = Config(host: host, path: path, method: method, headers: headers, body: body)
      let builder = DefaultRequestBuilder()
      return try builder.makeRequest(with: config)
   }
   
   // Build a NetworkFactory with injectable URLProtocol(s) and an isolated cache
   private func makeFactory(protocols: [AnyClass],
                            memoryCapacityBytes: Int = 5_000_000) -> NetworkFactory {
      let config = URLSessionConfiguration.ephemeral
      config.requestCachePolicy = .reloadIgnoringLocalCacheData
      config.urlCache = nil
      config.protocolClasses = protocols
      
      // Fresh, per-factory URLCache for the package-level cache wrapper
      let urlCache = URLCache(memoryCapacity: memoryCapacityBytes, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      let dependencies = NetworkDependencies(sessionManager: DefaultSessionManager(configuration: config),
                                             requestBuilder: DefaultRequestBuilder(),
                                             cacher: cache,
                                             logger: DefaultNetworkLogger(),
                                             errorMapper: DefaultErrorMapper(),
                                             validator: StatusCodeValidator(),
                                             decoder: JSONResponseDecoder())
      
      return NetworkFactory(dependencies: dependencies)
   }
   
   @Test func networkExecutorSendsRequest() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      let urlResponse = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
      
      MockURLProtocol.responseData = TestData.data
      MockURLProtocol.response = urlResponse
      MockURLProtocol.error = nil
      
      // Use the factory to exercise the full pipeline (executor + validator + decoder)
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
         let method: HTTPMethod = .post
         var headers: HTTPHeaders? { [TestData.headerKey: TestData.headerValue] }
         var body: HTTPBody? { ["modelID": TestData.model.modelID, "name": TestData.model.name] }
      }
      
      // No cacheTTL param → uses default .seconds(300)
      let result: TestModel = try await factory.fetch(requestConfig: Config())
      #expect(result == TestData.model)
   }
   
   @Test func networkExecutorSendsRequestAndReturnCachedData() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      // Dedicated URLCache + wrapper to avoid cross‑test bleed
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      // The SAME config the factory will receive (defaults: .get, no headers/body)
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
         // method -> .get (default)
         // headers/body -> nil (defaults)
      }
      
      // Build the request EXACTLY like the factory will do
      let builder = DefaultRequestBuilder()
      let prestoreRequest = try builder.makeRequest(with: Config())
      
      // Pre-store the payload for that exact request key (use default ttl via protocol ext)
      let ok = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
      await cache.store(TestData.data, response: ok, for: prestoreRequest)
      
      // Build a factory that uses the same cache
      let dependencies = NetworkDependencies(sessionManager: DefaultSessionManager(configuration: .ephemeral),
                                             requestBuilder: builder,
                                             cacher: cache,
                                             logger: DefaultNetworkLogger(),
                                             errorMapper: DefaultErrorMapper(),
                                             validator: StatusCodeValidator(),
                                             decoder: JSONResponseDecoder())
      let factory = NetworkFactory(dependencies: dependencies)
      
      // Default TTL is fine; should HIT the cache and skip network
      let result: TestModel = try await factory.fetch(requestConfig: Config())
      #expect(result == TestData.model)
   }
   
   @Test func networkExecutorDecodingKeyNotFoundError() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      MockURLProtocol.responseData = Data(#"{"name":"Test"}"#.utf8) // missing "modelID"
      MockURLProtocol.response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
      MockURLProtocol.error = nil
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      await #expect(throws: NetworkError.decodingKeyNotFoundFailure(message: "Key “modelID” not found when decoding the model “TestModel”.")) {
         let _: TestModel = try await factory.fetch(requestConfig: Config()) // default TTL
      }
   }
   
   @Test func networkExecutorDecodingValueFoundError() async throws {
      resetMockProtocol()
      let testPath = TestData.path + "/test-decoding-value-not-found"
      let testURLString = TestData.host + testPath
      let testURL = try #require(URL(string: testURLString))
      
      // 200 + payload with null for non-optional String -> valueNotFound
      let bad = Data(#"{ "modelID": 1, "name": null }"#.utf8)
      let http = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
      MockURLProtocol.response = http
      MockURLProtocol.responseData = bad
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         private(set) var host: String = TestData.host
         let path: String
      }
      
      // No explicit cacheTTL → default TTL, but we disabled session/url cache and use unique path, so no bleed
      await #expect(throws: NetworkError.decodingValueNotFoundFailure(message: "Expected “String” value for “name” not found when decoding the model “TestModel”.")) {
         let _: TestModel = try await factory.fetch(requestConfig: Config(path: testPath))
      }
   }
   
   @Test func networkExecutorDecodingTypeMismatchError() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      MockURLProtocol.responseData = Data(#"{ "name": "Test", "modelID": "A"}"#.utf8)
      MockURLProtocol.response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
      MockURLProtocol.error = nil
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      await #expect(throws: NetworkError.decodingTypeMismatchFailure(message: "Received unexpected type “Int” when decoding “modelID” of the model “TestModel”.")) {
         let _: TestModel = try await factory.fetch(requestConfig: Config())
      }
   }
   
   @Test func networkExecutorDecodingInvalidDataError() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      MockURLProtocol.responseData = Data(#"{"name":"Test""#.utf8) // malformed JSON
      MockURLProtocol.response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
      MockURLProtocol.error = nil
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      await #expect(throws: NetworkError.decodingGenericError) {
         let _: TestModel = try await factory.fetch(requestConfig: Config())
      }
   }
   
   @Test func networkExecutorHandlesErrors() async throws {
      resetMockProtocol()
      MockURLProtocol.error = URLError(.notConnectedToInternet) // mapped to .noInternetConnection
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      await #expect(throws: NetworkError.noInternetConnection) {
         let _: TestModel = try await factory.fetch(requestConfig: Config())
      }
   }
   
   @Test func cacheCorruptClearsThenFallsBackToNetwork() async throws {
      resetMockProtocol()
      // Fresh URLCache + wrapper
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
      let cache = DefaultNetworkResponseCache(urlCache: urlCache)
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path + "/test-cache"
      }
      
      // Build the SAME request the factory will build
      let builder = DefaultRequestBuilder()
      let request = try builder.makeRequest(with: Config())
      
      // Pre-store CORRUPT payload under that exact key (default ttl)
      let http = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      await cache.store(Data("not-json".utf8), response: http, for: request)
      
      // Configure network to return valid JSON afterwards
      MockURLProtocol.response = http
      MockURLProtocol.responseData = try JSONEncoder().encode(TestModel(modelID: 1, name: "Ok"))
      MockURLProtocol.error = nil
      
      let sessionConfig = URLSessionConfiguration.ephemeral
      sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
      sessionConfig.urlCache = nil
      sessionConfig.protocolClasses = [MockURLProtocol.self]
      
      let dependencies = NetworkDependencies(sessionManager: DefaultSessionManager(configuration: sessionConfig),
                                             requestBuilder: builder,
                                             cacher: cache, // same cache instance that holds corrupt entry
                                             logger: DefaultNetworkLogger(),
                                             errorMapper: DefaultErrorMapper(),
                                             validator: StatusCodeValidator(),
                                             decoder: JSONResponseDecoder())
      let factory = NetworkFactory(dependencies: dependencies)
      
      // Default TTL path: read cache → decode fails → clear → network fallback → store new
      let model: TestModel = try await factory.fetch(requestConfig: Config())
      #expect(model == TestModel(modelID: 1, name: "Ok"))
      
      // Optional: verify the corrupt entry was replaced
      let cached = await cache.cachedResponse(for: request)
      #expect(cached != nil)
   }
}
