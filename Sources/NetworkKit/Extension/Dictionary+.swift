import Foundation

extension Dictionary {
   var data: Data? {
      return try? JSONSerialization.data(withJSONObject: self, options: [])
   }
}
