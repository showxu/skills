import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Verification receipt loader")
struct VerificationReceiptLoaderTests {
  @Test("Loads nested receipts and ignores adjacent sequence metadata")
  func loadsOnlyReceiptArtifacts() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-verifications-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: root)
    }
    let sequenceDirectory = root.appending(
      path: "rev_0123456789abcdef",
      directoryHint: .isDirectory
    )
    let receipt = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_fixture",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "wishlist.list",
      fingerprint: "fp_fixture",
      sourceRefs: [],
      response: ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["success": .bool(true)]),
        outcome: .success,
        businessErrorSignals: []
      )
    )
    try DeterministicJSON.write(
      receipt,
      to: sequenceDirectory.appending(path: "read-before.json")
    )
    try DeterministicJSON.write(
      JSONValue.object([
        "kind": .string(
          "web-api-reverse.reversible-verification-sequence"
        ),
        "sequenceId": .string("rev_0123456789abcdef"),
      ]),
      to: sequenceDirectory.appending(path: "sequence.json")
    )
    try DeterministicJSON.write(
      VerificationRequestEvidence(
        finalURLTemplate: "https://example.test/wishlist",
        headerNames: [],
        cookieNames: []
      ),
      to: root.appending(path: "request-evidence.json")
    )

    #expect(
      try VerificationReceiptLoader.load(from: root) == [receipt]
    )
  }

  @Test("Rejects the legacy singular Observed directory with migration guidance")
  func rejectsLegacyObservedDirectory() throws {
    let observed = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-observed-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: observed)
    }
    let legacy = observed.appending(
      path: VerificationReceiptLoader.legacyDirectoryName,
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: legacy,
      withIntermediateDirectories: true
    )

    do {
      _ = try VerificationReceiptLoader.loadObserved(from: observed)
      Issue.record("Expected the singular verification directory to fail.")
    } catch {
      #expect(error.localizedDescription.contains("legacy directory"))
      #expect(error.localizedDescription.contains("/verification"))
      #expect(error.localizedDescription.contains("/verifications"))
      #expect(error.localizedDescription.contains("rerun inventory"))
    }
  }

  @Test("Rejects duplicate receipt identifiers instead of crashing")
  func rejectsDuplicateReceiptIdentifiers() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-verifications-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: root)
    }
    let receipt = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_duplicate",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "wishlist.list",
      fingerprint: "fp_fixture",
      sourceRefs: [],
      response: ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["success": .bool(true)]),
        outcome: .success,
        businessErrorSignals: []
      )
    )
    try DeterministicJSON.write(
      receipt,
      to: root.appending(path: "first.json")
    )
    try DeterministicJSON.write(
      receipt,
      to: root.appending(path: "nested/second.json")
    )

    do {
      _ = try VerificationReceiptLoader.load(from: root)
      Issue.record("Expected duplicate receipt identifiers to fail.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "duplicate verification receipt ID ver_duplicate"
        )
      )
    }
  }
}
