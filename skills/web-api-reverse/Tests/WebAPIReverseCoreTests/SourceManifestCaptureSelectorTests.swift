import Testing

@testable import WebAPIReverseCore

@Suite("Source manifest capture selection")
struct SourceManifestCaptureSelectorTests {
  @Test("Persisted historical revisions do not reenter current inventory")
  func selectsOnlyDeclaredPersistedRevisions() {
    let current = receipt(sourceId: "provider-web", version: "v2")
    let historical = receipt(sourceId: "provider-web", version: "v1")
    let undeclared = receipt(sourceId: "provider-debug", version: "v1")
    let manifest = SourceManifest(
      brand: "fixture",
      market: "cn",
      sources: [
        ExpectedSource(
          sourceId: "provider-web",
          surface: .web,
          version: "v2"
        )
      ]
    )

    #expect(
      SourceManifestCaptureSelector.selectPersisted(
        [historical, undeclared, current],
        manifest: manifest
      ).map(\.captureId) == [current.captureId]
    )
  }

  @Test("Without a manifest persisted capture selection remains unchanged")
  func preservesReceiptsWithoutManifest() {
    let receipts = [
      receipt(sourceId: "provider-web", version: "v1"),
      receipt(sourceId: "provider-web", version: "v2"),
    ]

    #expect(
      SourceManifestCaptureSelector.selectPersisted(
        receipts,
        manifest: nil
      ) == receipts
    )
  }
}

private func receipt(sourceId: String, version: String) -> CaptureReceipt {
  CaptureReceipt(
    captureId: "cap_\(sourceId)_\(version)",
    capturedAt: "2026-08-01T00:00:00Z",
    brand: "fixture",
    market: "cn",
    source: CaptureSource(
      sourceId: sourceId,
      surface: .web,
      version: version,
      sha256: String(repeating: "a", count: 64)
    ),
    flow: "fixture",
    exchanges: []
  )
}
