import Foundation
import Testing
@testable import NetworkKit

@Suite("Network factory (integration) tests", .serialized)
struct NetworkFactoringTests {
   private func makeFactory(protocols: [AnyClass]) -> NetworkFactory {
      let config = URLSessionConfiguration.ephemeral
      config.requestCachePolicy = .reloadIgnoringLocalCacheData
      config.urlCache = nil
      config.protocolClasses = protocols

      // Fresh, per-factory URLCache to avoid bleed across tests
      let urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
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
   
   private func resetMockProtocol() {
      MockURLProtocol.responseData = nil
      MockURLProtocol.response = nil
      MockURLProtocol.error = nil
   }
   
   @Test func fetchDecodesModel() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      let response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
      MockURLProtocol.response = response
      MockURLProtocol.responseData = TestData.data
      MockURLProtocol.error = nil
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      let model: TestModel = try await factory.fetch(requestConfig: Config())
      #expect(model == TestData.model)
   }
   
   @Test func fetchPropagatesDecodingError() async throws {
      resetMockProtocol()
      let testURL = try #require(TestData.url)
      
      let response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
      MockURLProtocol.response = response
      MockURLProtocol.responseData = Data("{\"name\":\"Only\"}".utf8) // missing id
      MockURLProtocol.error = nil
      
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         // Use a unique path so no previous cache entry matches
         let path: String = TestData.path + "/decoding-key-missing-\(UUID().uuidString)"
      }
      
      let factory = makeFactory(protocols: [MockURLProtocol.self])
      await #expect(throws: NetworkError.decodingKeyNotFoundFailure(message: "Key “modelID” not found when decoding the model “TestModel”.")) {
         let _: TestModel = try await factory.fetch(requestConfig: Config())
      }
   }
}
