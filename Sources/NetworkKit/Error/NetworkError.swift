import Foundation

public enum NetworkError: Error, Equatable, Sendable {
   public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
      switch (lhs, rhs) {
      case (.genericError(let lError), .genericError(let rError)): lError.localizedDescription == rError.localizedDescription
      case (.noInternetConnection, .noInternetConnection): true
      case (.cancelled, .cancelled): true
      case (.timedOut, .timedOut): true
      case (.networkBadRequest, .networkBadRequest): true
      case (.networkRequestBuildFailure, .networkRequestBuildFailure): true
      case (.networkClientFailure(let lCode, let lUrl), .networkClientFailure(let rCode, let rUrl)): lCode == rCode && lUrl == rUrl
      case (.networkServerFailure(let lCode, let lUrl), .networkServerFailure(let rCode, let rUrl)): lCode == rCode && lUrl == rUrl
      case (.networkUnknownStatusCode(let lCode, let lUrl), .networkUnknownStatusCode(let rCode, let rUrl)): lCode == rCode && lUrl == rUrl
      case (.networkInvalidResponse, .networkInvalidResponse): true
      case (.networkInvalidStatusCode(let lCode, let lUrl), .networkInvalidStatusCode(let rCode, let rUrl)): lCode == rCode && lUrl == rUrl
      case (.decodingGenericError, .decodingGenericError): true
      case (.decodingKeyNotFoundFailure(let lMessage), .decodingKeyNotFoundFailure(let rMessage)): lMessage == rMessage
      case (.decodingValueNotFoundFailure(let lMessage), .decodingValueNotFoundFailure(let rMessage)): lMessage == rMessage
      case (.decodingTypeMismatchFailure(let lMessage), .decodingTypeMismatchFailure(let rMessage)): lMessage == rMessage
      default: false
      }
   }
   
   // Generic
   case genericError(Error)
   case noInternetConnection
   case cancelled
   case timedOut
   
   // Request
   case networkBadRequest
   case networkRequestBuildFailure
   
   // Client
   case networkClientFailure(code: Int, url: String)
   
   // Server
   case networkServerFailure(code: Int, url: String)
   case networkServerStatusError(message: String)
   case networkUnknownStatusCode(code: Int, url: String)
   
   // Response
   case networkInvalidResponse
   case networkInvalidStatusCode(code: Int, url: String)
   
   // Decoding
   case decodingGenericError
   case decodingKeyNotFoundFailure(message: String)
   case decodingValueNotFoundFailure(message: String)
   case decodingTypeMismatchFailure(message: String)
}
