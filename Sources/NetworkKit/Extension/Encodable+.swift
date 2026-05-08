import Foundation

package extension Encodable {
   var dictionary: [String: any Sendable]? {
      guard let jsonData = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: any Sendable] else {
         return nil
      }
      return dictionary
   }
}
