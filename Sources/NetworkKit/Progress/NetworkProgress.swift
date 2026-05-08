import Foundation

public struct NetworkProgress: Sendable {
   public var onDownload: (@Sendable (_ received: Int64, _ expected: Int64) -> Void)?
   public var onUpload: (@Sendable (_ sent: Int64, _ expected: Int64) -> Void)?
   
   public init(onDownload: (@Sendable (Int64, Int64) -> Void)? = nil,
               onUpload: (@Sendable (Int64, Int64) -> Void)? = nil) {
      self.onDownload = onDownload
      self.onUpload = onUpload
   }
}
