import Foundation
import Testing
@testable import NetworkKit

@Suite("DefaultNetworkLogger prints")
struct DefaultNetworkLoggerTests {
   // MARK: - Helpers: capture stdout produced by `print(...)`
   private func captureStdout(_ work: () -> Void) -> String {
      // Redirect STDOUT to a pipe, run `work`, then restore and read.
      let pipe = Pipe()
      let original = dup(STDOUT_FILENO)
      
      dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
      work()
      fflush(stdout)
      
      // Close write end before reading to EOF
      pipe.fileHandleForWriting.closeFile()
      dup2(original, STDOUT_FILENO)
      close(original)
      
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8) ?? ""
   }
   
   @Test func logError_printsMessageAndURL() {
      let logger = DefaultNetworkLogger()
      var req = URLRequest(url: URL(string: "https://example.com/error-endpoint")!)
      req.httpMethod = "GET"
      
      let nsErr = NSError(domain: "UnitTest", code: 42, userInfo: [NSLocalizedDescriptionKey: "Boom"])
      
      let output = captureStdout {
         logger.logError(nsErr, for: req)
      }
      
      // Expect the standard prefix and the URL + error description to appear.
      #expect(output.contains("[Error]"))
      #expect(output.contains("https://example.com/error-endpoint"))
      #expect(output.localizedCaseInsensitiveContains("Boom"))
   }
   
   @Test func logCacheMiss_printsMarkerAndURL() {
      let logger = DefaultNetworkLogger()
      let req = URLRequest(url: URL(string: "https://example.com/cache-miss")!)
      
      let output = captureStdout {
         logger.logCacheMiss(for: req)
      }
      
      // Expect the cache miss marker and the request URL.
      #expect(output.contains("[Cache] MISS"))
      #expect(output.contains("https://example.com/cache-miss"))
   }
}
