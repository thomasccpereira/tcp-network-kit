import Foundation

public typealias HTTPHeaders = [String: String]
public typealias HTTPBody = [String: any Sendable]

public enum HTTPMethod: String, Sendable {
   case head = "HEAD"
   case get = "GET"
   case post = "POST"
   case put = "PUT"
   case delete = "DELETE"
   case patch = "PATCH"
}
