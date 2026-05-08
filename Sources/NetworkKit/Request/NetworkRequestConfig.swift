import Foundation

// MARK: - Request config - Protocol
public protocol NetworkRequestConfig: Sendable {
   var host: String { get }
   var path: String { get }
   var method: HTTPMethod { get }
   var headers: HTTPHeaders? { get }
   var queryItems: [URLQueryItem]? { get }
   var body: HTTPBody? { get }
   var xmlEnvelope: NetworkRequestXMLEnvelope? { get }
}

// MARK: - Request config - Default implementation
extension NetworkRequestConfig {
   public var method: HTTPMethod { .get }
   
   public var headers: HTTPHeaders? { [ "Content-Type": "application/json; charset=utf-8" ] }
   
   public var queryItems: [URLQueryItem]? { nil }
   
   public var body: HTTPBody? { nil }
   
   public var xmlEnvelope: NetworkRequestXMLEnvelope? { nil }
}
