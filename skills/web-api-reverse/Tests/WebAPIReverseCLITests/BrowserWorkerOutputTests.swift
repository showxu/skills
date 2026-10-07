import Foundation
import Testing

@testable import WebAPIReverseCLI

@Suite("Browser worker process output")
struct BrowserWorkerOutputTests {
  @Test("Accepts only the fixed artifact name under the canonical scratch root")
  func validatesCanonicalArtifactPath() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-worker-path-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: temporaryRoot,
      withIntermediateDirectories: false,
      attributes: [.posixPermissions: 0o700]
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    let reported = temporaryRoot.appending(path: "capture.json").path
    let canonical = temporaryRoot.resolvingSymlinksInPath().appending(
      path: "capture.json"
    ).path
    #expect(
      WebAPIReverseCLI.browserWorkerArtifactPathMatches(
        reported,
        expected: canonical
      )
    )
    #expect(
      !WebAPIReverseCLI.browserWorkerArtifactPathMatches(
        temporaryRoot.appending(path: "capture.har").path,
        expected: canonical
      )
    )
    #expect(
      !WebAPIReverseCLI.browserWorkerArtifactPathMatches(
        temporaryRoot.deletingLastPathComponent().appending(
          path: "capture.json"
        ).path,
        expected: canonical
      )
    )
  }

  @Test("Drains worker output before waiting for process exit")
  func drainsOutputBeforeExit() throws {
    let payloadBytes = 512 * 1_024
    let (process, pipe) = try makeOutputProcess(byteCount: payloadBytes)

    let output = try WebAPIReverseCLI.readBoundedWorkerOutput(
      from: pipe.fileHandleForReading,
      process: process,
      maximumBytes: payloadBytes
    )

    #expect(output.count == payloadBytes)
    #expect(process.terminationStatus == 0)
  }

  @Test("Terminates a worker whose output exceeds the response limit")
  func rejectsOversizedOutput() throws {
    let maximumBytes = 64 * 1_024
    let (process, pipe) = try makeOutputProcess(
      byteCount: maximumBytes * 4
    )

    do {
      _ = try WebAPIReverseCLI.readBoundedWorkerOutput(
        from: pipe.fileHandleForReading,
        process: process,
        maximumBytes: maximumBytes
      )
      Issue.record("Oversized worker output must fail closed.")
    } catch {
      #expect(
        WebAPIReverseCLI.errorCode(for: error)
          == "browser.output-too-large"
      )
    }
    #expect(!process.isRunning)
  }

  private func makeOutputProcess(
    byteCount: Int
  ) throws -> (Process, Pipe) {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(filePath: "/bin/sh")
    process.arguments = [
      "-c",
      "dd if=/dev/zero bs=1024 count=$1 2>/dev/null",
      "worker-output",
      String((byteCount + 1_023) / 1_024),
    ]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try process.run()
    return (process, pipe)
  }
}
