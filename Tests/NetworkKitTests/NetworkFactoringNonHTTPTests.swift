import Foundation
import Testing
@testable import NetworkKit

@Suite("Network factory rejects non-HTTP response")
struct NonHTTPResponseTests {
   private struct RequestConfig: NetworkRequestConfig {
      let host = "https://ex.com"
      let path = "/nonhttp"
   }
   
   final class NonHTTPProtocol: URLProtocol {
      override class func canInit(with request: URLRequest) -> Bool { true }
      
      override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
      
      override func startLoading() {
         let response = URLResponse(url: request.url!,
                                    mimeType: nil,
                                    expectedContentLength: 0,
                                    textEncodingName: nil)
         
         client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
         client?.urlProtocolDidFinishLoading(self)
      }
      
      override func stopLoading() {}
   }
   
   @Test func nonHTTPTriggersInvalidResponse() async {
      let sessionConfig = URLSessionConfiguration.ephemeral
      sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
      sessionConfig.urlCache = nil
      sessionConfig.protocolClasses = [NonHTTPProtocol.self]
      
      let dependencies = NetworkDependencies(sessionManager: DefaultSessionManager(configuration: sessionConfig),
                                             requestBuilder: DefaultRequestBuilder(),
                                             cacher: DefaultNetworkResponseCache(urlCache: URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)),
                                             logger: DefaultNetworkLogger(),
                                             errorMapper: DefaultErrorMapper(),
                                             validator: StatusCodeValidator(),
                                             decoder: JSONResponseDecoder())
      let factory = NetworkFactory(dependencies: dependencies)
      
      await #expect(throws: NetworkError.networkInvalidResponse) {
         let _: Data = try await factory.fetch(requestConfig: RequestConfig())
      }
   }
}
