import Foundation
import CoreResources

public extension String {
   var isValidURL: Bool {
      let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
      if let match = detector?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
         return match.range.length == self.utf16.count
      }
      return false
   }
   
   var sanitizedURL: String {
      let colonSlash = "://"
      let components = self.components(separatedBy: colonSlash).map { String($0).trimmed }
      
      if let httpPrefix = components.first,
         let endpoint = components.last {
         let sanitizedEndpoint = endpoint.replacingOccurrences(of: "//", with: "/")
         return String(httpPrefix) + colonSlash + sanitizedEndpoint
      }
      
      return self
   }
}
