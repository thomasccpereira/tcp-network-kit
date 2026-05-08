import Foundation
import Testing
@testable import NetworkKit

enum TestData {
   static let host = "https://example.com"
   static let path = "/test"
   static var url: URL? { URL(string: host + path) }
   static let headerKey = "Header"
   static let headerValue = "Value"
   static let headers = [headerKey: headerValue]
   static let model = TestModel(modelID: 1, name: "Ok")
   static let validator = StatusCodeValidator()
   static var data: Data { try! JSONEncoder().encode(model) }
   static let genericError = NSError(domain: "NetworkPackageErrorDomain", code: -1) as Error
}
