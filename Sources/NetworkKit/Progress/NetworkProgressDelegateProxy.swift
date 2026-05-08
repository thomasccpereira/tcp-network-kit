import Foundation

/// Delegate that reports upload/download progress while using async/await:
///   URLSession.data(for:delegate:) will drive these callbacks.
final class NetworkProgressDelegateProxy: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate, @unchecked Sendable {
   // MARK: - State
   private let progress: NetworkProgress?
   private let queue = DispatchQueue(label: "com.mitis.erp.app.iOS.network.progress.delegate.proxy")
   
   // Protected by `queue`
   private var expectedDownloadBytes: Int64 = NSURLSessionTransferSizeUnknown
   private var expectedUploadBytes: Int64 = NSURLSessionTransferSizeUnknown
   private var receivedBytes: Int64 = 0
   
   // MARK: - Init
   init(progress: NetworkProgress?) {
      self.progress = progress
   }
   
   // MARK: - URLSessionDataDelegate (download progress)
   func urlSession(_ session: URLSession,
                   dataTask: URLSessionDataTask,
                   didReceive response: URLResponse,
                   completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
      queue.sync {
         expectedDownloadBytes = response.expectedContentLength
      }
      
      completionHandler(.allow)
   }
   
   func urlSession(_ session: URLSession,
                   dataTask: URLSessionDataTask,
                   didReceive data: Data) {
      let snapshot: (received: Int64, expected: Int64) = queue.sync {
         receivedBytes += Int64(data.count)
         return (receivedBytes, expectedDownloadBytes)
      }
      
      progress?.onDownload?(snapshot.received, snapshot.expected)
   }
   
   // MARK: - URLSessionTaskDelegate (upload progress)
   func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didSendBodyData bytesSent: Int64,
                   totalBytesSent: Int64,
                   totalBytesExpectedToSend: Int64) {
      queue.sync {
         expectedUploadBytes = totalBytesExpectedToSend
      }
      
      progress?.onUpload?(totalBytesSent, totalBytesExpectedToSend)
   }
}
