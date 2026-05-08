import Foundation
import CoreResources

// MARK: - Request decoder - Protocol
public protocol NetworkResponseDecoding: Sendable {
   func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

// MARK: - Request decoder - Concrete implementation
public struct JSONResponseDecoder: NetworkResponseDecoding {
   private let decoder: JSONDecoder
   
   public init(_ decoder: JSONDecoder = JSONDecoder()) {
      self.decoder = decoder
   }
   
   public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
      do {
         return try decoder.decode(T.self, from: data)
         
      } catch let DecodingError.keyNotFound(key, _) {
         let entity = String(describing: T.self)
         let key = key.stringValue
         
         let message = localized("decoding_error_key_not_found", args: key, entity, bundle: .module)
         throw NetworkError.decodingKeyNotFoundFailure(message: message)
         
      } catch let DecodingError.valueNotFound(value, context) {
         let entity = String(describing: T.self)
         let infoTexts = context.codingPath.filter ({ !$0.stringValue.isEmpty && $0.intValue == nil }).map ({ $0.stringValue })
         let key = infoTexts.last ?? ""
         let value = String(describing: value)
         
         let message = localized("decoding_error_value_not_found", args:  value, key, entity, bundle: .module)
         throw NetworkError.decodingValueNotFoundFailure(message: message)
         
      } catch let DecodingError.typeMismatch(type, context) {
         let entity = String(describing: T.self)
         let infoTexts = context.codingPath.filter ({ !$0.stringValue.isEmpty && $0.intValue == nil }).map ({ $0.stringValue })
         let key = infoTexts.last ?? ""
         let type = String(describing: type)
         
         let message = localized("decoding_error_type_mismatch", args:  type, key, entity, bundle: .module)
         throw NetworkError.decodingTypeMismatchFailure(message: message)
         
      } catch {
         throw NetworkError.decodingGenericError
      }
   }
}
