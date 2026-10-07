public enum SourceManifestCaptureSelector {
  public static func selectPersisted(
    _ receipts: [CaptureReceipt],
    manifest: SourceManifest?
  ) -> [CaptureReceipt] {
    guard let manifest else {
      return receipts
    }
    let revisions = Set(
      manifest.sources.map {
        SourceRevision(sourceId: $0.sourceId, version: $0.version)
      }
    )
    return receipts.filter {
      revisions.contains(
        SourceRevision(
          sourceId: $0.source.sourceId,
          version: $0.source.version
        )
      )
    }
  }
}

private struct SourceRevision: Hashable {
  let sourceId: String
  let version: String
}
