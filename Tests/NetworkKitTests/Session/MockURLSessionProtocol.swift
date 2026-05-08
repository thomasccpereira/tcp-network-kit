import Testing
import Foundation

final class MockURLProtocol: URLProtocol {
   nonisolated(unsafe) static var responseData: Data?
   nonisolated(unsafe) static var response: URLResponse?
   nonisolated(unsafe) static var error: Error?
   
   override class func canInit(with request: URLRequest) -> Bool { true }
   override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
   
   override func startLoading() {
      if let error = Self.error {
         client?.urlProtocol(self, didFailWithError: error)
         client?.urlProtocolDidFinishLoading(self)
         return
      }
      
      if let response = Self.response {
         client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      
      if let data = Self.responseData {
         client?.urlProtocol(self, didLoad: data)
         
      } else {
         client?.urlProtocol(self, didLoad: Data())
      }
      
      client?.urlProtocolDidFinishLoading(self)
   }
   
   override func stopLoading() {}
}
