import Foundation
import Testing
@testable import NetworkKit

@Suite("Network session manager tests", .serialized)
struct NetworkSessionManagingTests {
   @Test func networkSessionManagerDefault() async throws {
      let mockSessionManager = DefaultSessionManager()
      #expect(mockSessionManager.urlSession.configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
      #expect(mockSessionManager.urlSession.configuration.timeoutIntervalForRequest == 30.0)
      #expect(mockSessionManager.urlSession.configuration.timeoutIntervalForResource == 60.0)
   }
}
