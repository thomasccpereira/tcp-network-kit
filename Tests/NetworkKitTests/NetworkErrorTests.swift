import Foundation
import Testing
@testable import NetworkKit

@Suite("Network error equatable tests")
struct NetworkErrorEquatableTests {
   // MARK: - Simple no-payload cases
   @Test func testSimpleCasesAreEqual() {
      #expect(NetworkError.noInternetConnection == .noInternetConnection)
      #expect(NetworkError.cancelled == .cancelled)
      #expect(NetworkError.timedOut == .timedOut)
      #expect(NetworkError.networkBadRequest == .networkBadRequest)
      #expect(NetworkError.networkRequestBuildFailure == .networkRequestBuildFailure)
      #expect(NetworkError.networkInvalidResponse == .networkInvalidResponse)
   }
   
   @Test func testDifferentCasesAreNotEqual() {
      #expect(NetworkError.noInternetConnection != .cancelled)
      #expect(NetworkError.timedOut != .networkBadRequest)
      #expect(NetworkError.networkRequestBuildFailure != .networkInvalidResponse)
   }
   
   // MARK: - Status-code payload cases
   @Test func testClientFailureEqualWhenCodeAndURLMatch() {
      let a = NetworkError.networkClientFailure(code: 404, url: "https://ex.com/r")
      let b = NetworkError.networkClientFailure(code: 404, url: "https://ex.com/r")
      #expect(a == b)
   }
   
   @Test func testClientFailureNotEqualWhenCodeOrURLDiffers() {
      let a = NetworkError.networkClientFailure(code: 404, url: "https://ex.com/r")
      let b = NetworkError.networkClientFailure(code: 400, url: "https://ex.com/r")
      let c = NetworkError.networkClientFailure(code: 404, url: "https://ex.com/other")
      #expect(a != b)
      #expect(a != c)
   }
   
   @Test func testServerFailureEqualWhenCodeAndURLMatch() {
      let a = NetworkError.networkServerFailure(code: 500, url: "https://ex.com/r")
      let b = NetworkError.networkServerFailure(code: 500, url: "https://ex.com/r")
      #expect(a == b)
   }
   
   @Test func testServerFailureNotEqualWhenCodeOrURLDiffers() {
      let a = NetworkError.networkServerFailure(code: 500, url: "https://ex.com/r")
      let b = NetworkError.networkServerFailure(code: 501, url: "https://ex.com/r")
      let c = NetworkError.networkServerFailure(code: 500, url: "https://ex.com/other")
      #expect(a != b)
      #expect(a != c)
   }
   
   @Test func testInvalidStatusCodeAndUnknownStatusCodeFollowSameEquality() {
      let a = NetworkError.networkInvalidStatusCode(code: 599, url: "u")
      let b = NetworkError.networkInvalidStatusCode(code: 599, url: "u")
      let c = NetworkError.networkInvalidStatusCode(code: 598, url: "u")
      let d = NetworkError.networkUnknownStatusCode(code: 777, url: "u2")
      let e = NetworkError.networkUnknownStatusCode(code: 777, url: "u2")
      #expect(a == b)
      #expect(a != c)
      #expect(d == e)
   }
   
   // MARK: - Decoding payload cases
   @Test func testDecodingKeyNotFoundEquality() {
      let a = NetworkError.decodingKeyNotFoundFailure(message: "Key “modelID” not found when decoding the model “TestModel”.")
      let b = NetworkError.decodingKeyNotFoundFailure(message: "Key “modelID” not found when decoding the model “TestModel”.")
      let c = NetworkError.decodingKeyNotFoundFailure(message: "Key “name” not found when decoding the model “TestModel”.")
      #expect(a == b)
      #expect(a != c)
   }
   
   @Test func testDecodingValueNotFoundEquality() {
      let a = NetworkError.decodingValueNotFoundFailure(message: "Expected “String” value for “name” not found when decoding the model “TestModel”.")
      let b = NetworkError.decodingValueNotFoundFailure(message: "Expected “String” value for “name” not found when decoding the model “TestModel”.")
      let c = NetworkError.decodingValueNotFoundFailure(message: "Expected “String” value for “title” not found when decoding the model “OtherModel”.")
      #expect(a == b)
      #expect(a != c)
   }
   
   @Test func testDecodingTypeMismatchEquality() {
      let a = NetworkError.decodingTypeMismatchFailure(message: "Received unexpected type “Int” when decoding “modelID” of the model “TestModel”.")
      let b = NetworkError.decodingTypeMismatchFailure(message: "Received unexpected type “Int” when decoding “modelID” of the model “TestModel”.")
      let c = NetworkError.decodingTypeMismatchFailure(message: "Received unexpected type “String” when decoding “name” of the model “TestModel”.")
      #expect(a == b)
      #expect(a != c)
   }
   
   // MARK: - Generic error equality vs others
   @Test func testGenericErrorNotEqualToOtherCases() {
      let g = NetworkError.genericError(NSError(domain: "x", code: 0))
      #expect(g != .noInternetConnection)
      #expect(g != .networkBadRequest)
      #expect(g != .networkInvalidResponse)
   }
}

@Suite("Network error mapper tests")
struct NetworkErrorMapperTests {
   
   private var mapper: DefaultErrorMapper { DefaultErrorMapper() }
   
   // MARK: - Cancellation
   @Test func testCancellationErrorMapsToCancelled() {
      let e = CancellationError()
      #expect(mapper.map(e, url: nil) == .cancelled)
   }
   
   // MARK: - URLError mappings
   @Test func testNotConnectedToInternetMapsToNoInternetConnection() {
      let e = URLError(.notConnectedToInternet)
      #expect(mapper.map(e, url: nil) == .noInternetConnection)
   }
   
   @Test func testNetworkConnectionLostMapsToNoInternetConnection() {
      let e = URLError(.networkConnectionLost)
      #expect(mapper.map(e, url: nil) == .noInternetConnection)
   }
   
   @Test func testTimedOutMapsToTimedOut() {
      let e = URLError(.timedOut)
      #expect(mapper.map(e, url: nil) == .timedOut)
   }
   
   // MARK: - Pass-through of NetworkError
   @Test func testPassThroughExistingNetworkError() {
      let original: NetworkError = .networkClientFailure(code: 404, url: "u")
      let mapped = mapper.map(original, url: URL(string: "u"))
      #expect(mapped == original)
   }
   
   // MARK: - Fallback for unknown errors
   @Test func testunknownErrorMapsToGenericError() {
      struct Dummy: Error {}
      let mapped = mapper.map(Dummy(), url: nil)
      
      // We can't pattern-match associated value directly in Swift Testing's equality,
      // so use a helper: the mapper should NOT return a well-known NetworkError case.
      switch mapped {
      case .genericError: #expect(true)
      default: #expect(false, "Expected .genericError, got \(mapped)")
      }
   }
}
