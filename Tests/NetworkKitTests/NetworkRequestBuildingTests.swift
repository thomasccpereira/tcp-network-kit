import Foundation
import Testing
@testable import NetworkKit

@Suite("Network request builder tests")
struct NetworkRequestBuildingTests {
   @Test func buildsGETByDefault() throws {
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
      }
      
      let builder = DefaultRequestBuilder()
      let request = try builder.makeRequest(with: Config())
      #expect(request.url == TestData.url)
      #expect(request.httpMethod == HTTPMethod.get.rawValue)
      #expect(request.allHTTPHeaderFields?["Content-Type"]?.contains("application/json") == true)
      #expect(request.httpBody == nil)
   }
   
   @Test func buildsPOSTWithHeadersAndBody() throws {
      struct Config: NetworkRequestConfig {
         let host: String = TestData.host
         let path: String = TestData.path
         let method: HTTPMethod = .post
         var headers: HTTPHeaders? { TestData.headers }
         var body: HTTPBody? { ["modelID": TestData.model.modelID, "name": TestData.model.name] }
      }
      
      let builder = DefaultRequestBuilder()
      let request = try builder.makeRequest(with: Config())
      #expect(request.url == TestData.url)
      #expect(request.httpMethod == HTTPMethod.post.rawValue)
      #expect(request.allHTTPHeaderFields?["Header"] == "Value")
      #expect(request.httpBody != nil)
   }
   
   @Test func invalidURLThrowsNetworkRequestBuildFailure() {
      struct BadConfig: NetworkRequestConfig {
         let host: String = "😅 not-a-url"
         let path: String = " also bad"
      }
      
      let builder = DefaultRequestBuilder()
      #expect(throws: NetworkError.networkRequestBuildFailure) {
         _ = try builder.makeRequest(with: BadConfig())
      }
   }
   
   // MARK: - Request configs
   private struct RequestConfig: NetworkRequestConfig {
      let host: String
      let path: String
      var queryItems: [URLQueryItem]?
      init(host: String, path: String, queryItems: [URLQueryItem]? = nil) {
         self.host = host; self.path = path; self.queryItems = queryItems
      }
   }
   
   @Test func leadingTrailingSlashesAreHandled() throws {
      let requestBuilder = DefaultRequestBuilder()
      let request1 = try requestBuilder.makeRequest(with: RequestConfig(host: "https://ex.com",   path: "/users"))
      let request2 = try requestBuilder.makeRequest(with: RequestConfig(host: "https://ex.com/",  path: "users"))
      let request3 = try requestBuilder.makeRequest(with: RequestConfig(host: "https://ex.com/",  path: "/users"))
      #expect(request1.url?.absoluteString == "https://ex.com/users")
      #expect(request2.url?.absoluteString == "https://ex.com/users")
      #expect(request3.url?.absoluteString == "https://ex.com/users")
   }
   
   @Test func queryItemsDuplicateAndEncoding() throws {
      let requestBuilder = DefaultRequestBuilder()
      let request = try requestBuilder.makeRequest(with: RequestConfig(
         host: "https://ex.com", path: "/q",
         queryItems: [
            .init(name: "tag", value: "a b"), // space -> %20
            .init(name: "tag", value: "c"),
            .init(name: "emoji", value: "☕️") // unicode
         ])
      )
      
      let url = try #require(request.url?.absoluteString)
      #expect(url.contains("tag=a%20b"))
      #expect(url.contains("tag=c"))
      #expect(url.contains("emoji=%E2%98%95%EF%B8%8F") || url.contains("emoji=%E2%98%95")) // lenient
   }
   
   @Test func invalidURLStillThrowsBuildFailure() {
      let requestBuilder = DefaultRequestBuilder()
      let badRequest = RequestConfig(host: "😅 not-a-url", path: " /bad")
      #expect(throws: NetworkError.networkRequestBuildFailure) {
         _ = try requestBuilder.makeRequest(with: badRequest)
      }
   }
}
