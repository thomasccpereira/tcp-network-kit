import Foundation
import Testing
@testable import NetworkKit

@Suite("Network response validator tests")
struct NetworkResponseValidatingTests {
   @Test func statusCodeValidatorAcceptsValidRange() throws {
      let testURL = try #require(TestData.url)
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: 200,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      try #require(try? TestData.validator.validate(response, data: Data()))
   }
   
   @Test func statusCodeValidator1XXMapsToUnknown() throws {
      let testURL = try #require(TestData.url)
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: 101,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      #expect(throws: NetworkError.networkUnknownStatusCode(code: 101, url: testURL.absoluteString)) {
         try TestData.validator.validate(response, data: Data())
      }
   }
   
   @Test func statusCodeValidator3XXMapsToUnknown() throws {
      let testURL = try #require(TestData.url)
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: 301,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      #expect(throws: NetworkError.networkUnknownStatusCode(code: 301, url: testURL.absoluteString)) {
         try TestData.validator.validate(response, data: Data())
      }
   }
   
   @Test func statusCodeValidatorNotFound() throws {
      let testURL = try #require(TestData.url)
      let statusCode = 404
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      #expect(throws: NetworkError.networkClientFailure(code: 404, url: testURL.absoluteString)) {
         try TestData.validator.validate(response, data: Data())
      }
   }
   
   @Test func statusCodeValidatorServerError() throws {
      let testURL = try #require(TestData.url)
      let statusCode = 500
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      #expect(throws: NetworkError.networkServerFailure(code: 500, url: testURL.absoluteString)) {
         try TestData.validator.validate(response, data: Data())
      }
   }
   
   @Test func statusCodeValidatorUnknownError() throws {
      let testURL = try #require(TestData.url)
      let statusCode = 601
      
      let response = HTTPURLResponse(url: testURL,
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)!
      
      #expect(throws: NetworkError.networkUnknownStatusCode(code: 601, url: testURL.absoluteString)) {
         try TestData.validator.validate(response, data: Data())
      }
   }
   
   @Test func statusCodeValidatorInvalidResponse() throws {
      let testURL = try #require(TestData.url)
      
      let urlResponse: URLResponse? = URLResponse(url: testURL,
                                                  mimeType: nil,
                                                  expectedContentLength: 1,
                                                  textEncodingName: nil)
      let response = try #require(urlResponse)
      
      #expect(throws: NetworkError.networkInvalidResponse) {
         try TestData.validator.validate(response, data: Data())
      }
   }
}
