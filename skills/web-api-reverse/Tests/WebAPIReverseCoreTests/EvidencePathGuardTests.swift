import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Evidence path ownership")
struct EvidencePathGuardTests {
  @Test("Discovery writes only to Observed when inside API")
  func observedWrites() throws {
    try EvidencePathGuard.requireObservedWrite(
      URL(fileURLWithPath: "/tmp/provider/API/Observed/catalog.json")
    )
    try EvidencePathGuard.requireObservedWrite(
      URL(fileURLWithPath: "/tmp/outside/catalog.json")
    )
    #expect(
      throws: EvidencePathError.nonObservedWrite(
        "/tmp/provider/API/Trusted/catalog.json"
      )
    ) {
      try EvidencePathGuard.requireObservedWrite(
        URL(fileURLWithPath: "/tmp/provider/API/Trusted/catalog.json")
      )
    }
    #expect(
      throws: EvidencePathError.nonObservedWrite(
        "/tmp/provider/API/Published/catalog.json"
      )
    ) {
      try EvidencePathGuard.requireObservedWrite(
        URL(fileURLWithPath: "/tmp/provider/API/Published/catalog.json")
      )
    }
  }

  @Test("Private browser state stays outside API")
  func privateState() throws {
    try EvidencePathGuard.requirePrivateStateOutsideAPI(
      URL(fileURLWithPath: "/tmp/web-api-reverse/private")
    )
    #expect(
      throws: EvidencePathError.privateStateInsideAPI(
        "/tmp/provider/API/private"
      )
    ) {
      try EvidencePathGuard.requirePrivateStateOutsideAPI(
        URL(fileURLWithPath: "/tmp/provider/API/private")
      )
    }
  }

  @Test("Trust projection owns the exact Trusted directory")
  func trustedDirectory() throws {
    try EvidencePathGuard.requireTrustedDirectory(
      URL(fileURLWithPath: "/tmp/provider/API/Trusted")
    )
    #expect(
      throws: EvidencePathError.nonTrustedWrite(
        "/tmp/provider/API/Trusted/nested"
      )
    ) {
      try EvidencePathGuard.requireTrustedDirectory(
        URL(fileURLWithPath: "/tmp/provider/API/Trusted/nested")
      )
    }
  }

  @Test("Symbolic aliases cannot cross private or authority boundaries")
  func rejectsSymbolicAliases() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: "evidence-path-alias-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let observed = root.appending(path: "provider/API/Observed")
    let trusted = root.appending(path: "provider/API/Trusted")
    try FileManager.default.createDirectory(
      at: observed,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: trusted,
      withIntermediateDirectories: true
    )
    let observedAlias = root.appending(path: "outside-observed")
    let trustedAlias = root.appending(path: "outside-trusted")
    try FileManager.default.createSymbolicLink(
      at: observedAlias,
      withDestinationURL: observed
    )
    try FileManager.default.createSymbolicLink(
      at: trustedAlias,
      withDestinationURL: trusted
    )

    #expect(throws: EvidencePathError.self) {
      try EvidencePathGuard.requirePrivateStateOutsideAPI(
        observedAlias.appending(path: "private-response.json")
      )
    }
    #expect(throws: EvidencePathError.self) {
      try EvidencePathGuard.requireObservedWrite(
        trustedAlias.appending(path: "catalog.json")
      )
    }
    #expect(throws: EvidencePathError.self) {
      try EvidencePathGuard.requireTrustedDirectory(observedAlias)
    }
  }
}
