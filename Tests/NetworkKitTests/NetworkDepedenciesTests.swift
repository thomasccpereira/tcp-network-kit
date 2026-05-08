import Foundation
import Testing
@testable import NetworkKit

@Suite("Network depedencies tests", .serialized)
struct NetworkDepedenciesTests {
   @Test func defaultWiresExpectedConcreteTypes() {
      let depedencies = NetworkDependencies()
      
      // Types: we only check the *kind* of each dependency, not identity.
      #expect(depedencies.sessionManager is DefaultSessionManager)
      #expect(depedencies.requestBuilder is DefaultRequestBuilder)
      #expect(depedencies.cacher is DefaultNetworkResponseCache)
      #expect(depedencies.logger is DefaultNetworkLogger)
      #expect(depedencies.errorMapper is DefaultErrorMapper)
      #expect(depedencies.validator is StatusCodeValidator)
      #expect(depedencies.decoder is JSONResponseDecoder)
   }
   
   @Test func builderFromDefaultBuildsValidURL() throws {
      let depedencies = NetworkDependencies()
      
      struct RequestConfig: NetworkRequestConfig {
         let host: String = "https://example.com"
         let path: String = "/users"
      }
      
      let request = try depedencies.requestBuilder.makeRequest(with: RequestConfig())
      #expect(request.url?.absoluteString == "https://example.com/users")
      #expect(request.httpMethod == HTTPMethod.get.rawValue)
   }
   
   @Test func cacheFromDefault_canStoreAndRetrieve() async throws {
      let depedencies = NetworkDependencies()
      
      struct RequestConfig: NetworkRequestConfig {
         let host: String = "https://example.com"
         let path: String = "/cache-check"
      }
      
      // Build a request and a synthetic 200 response
      let req = try depedencies.requestBuilder.makeRequest(with: RequestConfig())
      let http = HTTPURLResponse(url: try #require(req.url),
                                 statusCode: 200,
                                 httpVersion: nil,
                                 headerFields: nil)!
      
      // Some payload
      let payload = Data(#"{"ok":true}"#.utf8)
      
      await depedencies.cacher.store(payload, response: http, for: req)
      let cached = await depedencies.cacher.cachedResponse(for: req)
      
      #expect(cached == payload)
   }
   
   @Test func validatorAndDecoderFromDefault_mapTypicalEdges() {
      let dependencies = NetworkDependencies()
      let validator = dependencies.validator
      let decoder = dependencies.decoder
      
      // Validator ok
      let okURL = URL(string: "https://example.com/ok")!
      let okResp = HTTPURLResponse(url: okURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
      try? validator.validate(okResp, data: Data()) // should not throw
      
      // Validator 404
      let notFound = HTTPURLResponse(url: okURL, statusCode: 404, httpVersion: nil, headerFields: nil)!
      #expect(throws: NetworkError.networkClientFailure(code: 404, url: okURL.absoluteString)) {
         try validator.validate(notFound, data: Data())
      }
      
      // Decoder: malformed -> generic decoding error
      #expect(throws: NetworkError.decodingGenericError) {
         let _ = try decoder.decode(TestModel.self, from: Data(#"{"id":1"#.utf8))
      }
   }
   
   @Test func errorMapperFromDefault_mapsCommonURLErrors() {
      let mapper = NetworkDependencies().errorMapper
      
      #expect(mapper.map(URLError(.notConnectedToInternet), url: nil) == .noInternetConnection)
      #expect(mapper.map(URLError(.timedOut), url: nil) == .timedOut)
      #expect(mapper.map(CancellationError(), url: nil) == .cancelled)
   }
}
