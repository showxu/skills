import Foundation

struct SourceLifecycleSelection: Sendable {
  let relativePath: String
  let manifest: SourceManifest
}

enum SourceLifecycleAuthority {
  private static let manifestPaths = [
    "API/Config/source-manifest.json",
    "API/Config/sources.json",
  ]

  static func loadCurrentManifest(
    providerRoot: URL,
    fileManager: FileManager = .default
  ) throws -> SourceLifecycleSelection {
    let existing = manifestPaths.filter {
      fileManager.fileExists(
        atPath: providerRoot.appending(path: $0).path
      )
    }
    guard existing.count == 1, let relativePath = existing.first else {
      if existing.isEmpty {
        throw ContractError.missingFile(
          "API/Config/source-manifest.json"
        )
      }
      throw ContractError.invalidApproval(
        "source lifecycle has multiple active manifests: "
          + existing.joined(separator: ", ")
      )
    }
    let manifest = try DeterministicJSON.decode(
      SourceManifest.self,
      from: Data(contentsOf: providerRoot.appending(path: relativePath))
    )
    let supportedKinds: Set<String> = [
      "lifeware.source-manifest",
      "web-api-reverse.source-manifest",
    ]
    guard manifest.schemaVersion == 1,
      supportedKinds.contains(manifest.kind)
    else {
      throw ContractError.invalidApproval(
        "unsupported source manifest schema or kind: "
          + "\(manifest.schemaVersion)/\(manifest.kind); "
          + "schemaSupported=\(manifest.schemaVersion == 1), "
          + "kindSupported=\(supportedKinds.contains(manifest.kind))"
      )
    }
    return SourceLifecycleSelection(
      relativePath: relativePath,
      manifest: manifest
    )
  }

  static func loadCurrentManifest(
    snapshot: ProviderAPIAuthoritySnapshot
  ) throws -> SourceLifecycleSelection {
    let existing = manifestPaths.filter {
      snapshot.optionalData($0) != nil
    }
    guard existing.count == 1, let relativePath = existing.first else {
      if existing.isEmpty {
        throw ContractError.missingFile(
          "API/Config/source-manifest.json"
        )
      }
      throw ContractError.invalidApproval(
        "source lifecycle has multiple active manifests: "
          + existing.joined(separator: ", ")
      )
    }
    let manifest = try decodeManifest(
      try snapshot.requiredData(relativePath)
    )
    return SourceLifecycleSelection(
      relativePath: relativePath,
      manifest: manifest
    )
  }

  static func validate(
    manifest: SourceManifest,
    sourceLock: SourceLock
  ) throws {
    guard manifest.brand == sourceLock.brand,
      manifest.market == sourceLock.market
    else {
      throw ContractError.scopeMismatch(
        "source manifest \(manifest.brand)/\(manifest.market), source lock "
          + "\(sourceLock.brand)/\(sourceLock.market)"
      )
    }
    let manifestAreas = try SourceCoverageContract.validateAreas(
      manifest.requiredCoverageAreas ?? [],
      scope: "source manifest requiredCoverageAreas"
    )
    let lockAreas = try SourceCoverageContract.validateAreas(
      sourceLock.requiredCoverageAreas ?? [],
      scope: "source lock requiredCoverageAreas"
    )
    guard manifestAreas == lockAreas else {
      throw ContractError.invalidApproval(
        "source manifest and source lock required coverage areas differ"
      )
    }

    let expectedGroups = Dictionary(
      grouping: manifest.sources,
      by: { sourceKey($0.sourceId, $0.version) }
    )
    let lockedGroups = Dictionary(
      grouping: sourceLock.sources,
      by: { sourceKey($0.sourceId, $0.version) }
    )
    guard expectedGroups.values.allSatisfy({ $0.count == 1 }),
      lockedGroups.values.allSatisfy({ $0.count == 1 })
    else {
      throw ContractError.invalidApproval(
        "source manifest or source lock contains duplicate revisions"
      )
    }
    let expected = expectedGroups.compactMapValues(\.first)
    let locked = lockedGroups.compactMapValues(\.first)
    guard Set(expected.keys) == Set(locked.keys) else {
      let missing = Set(expected.keys).subtracting(locked.keys).sorted()
      let obsolete = Set(locked.keys).subtracting(expected.keys).sorted()
      throw ContractError.invalidApproval(
        "source manifest and source lock revisions differ; missing: "
          + list(missing) + "; obsolete: " + list(obsolete)
      )
    }

    for key in expected.keys.sorted() {
      guard let declared = expected[key], let current = locked[key] else {
        continue
      }
      let declaredAreas = try SourceCoverageContract.validateAreas(
        declared.coverageAreas ?? [],
        scope: "source manifest \(key)"
      )
      let currentAreas = try SourceCoverageContract.validateAreas(
        current.coverageAreas ?? [],
        scope: "source lock \(key)"
      )
      guard declared.surface == current.surface,
        declaredAreas == currentAreas,
        declared.coveragePolicy ?? .required == current.coveragePolicy,
        declared.coverageRationale == current.coverageRationale
      else {
        throw ContractError.invalidApproval(
          "source manifest metadata differs from source lock for \(key)"
        )
      }
      if let declaredStatus = declared.status,
        declaredStatus != current.status
      {
        let receiptPromotedPlatformSource =
          declaredStatus == .partial
          && current.status == .captured
          && !Set(currentAreas).isDisjoint(
            with: SourceCoverageContract.sourceProductVerificationAreas
          )
          && !(current.evidenceFingerprints ?? []).isEmpty
        guard receiptPromotedPlatformSource else {
          throw ContractError.invalidApproval(
            "source manifest status \(declaredStatus.rawValue) differs from "
              + "source lock status \(current.status.rawValue) for \(key)"
          )
        }
      }
    }
  }

  static func validateCurrentApproval(
    providerRoot: URL,
    approval: ApprovalReceipt,
    fileManager: FileManager = .default
  ) throws {
    let selection = try loadCurrentManifest(
      providerRoot: providerRoot,
      fileManager: fileManager
    )
    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      selection.relativePath,
      providerRoot: providerRoot,
      approval: approval,
      fileManager: fileManager
    )
    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      "API/Observed/source-lock.json",
      providerRoot: providerRoot,
      approval: approval,
      fileManager: fileManager
    )
    let sourceLock = try DeterministicJSON.decode(
      SourceLock.self,
      from: Data(
        contentsOf: providerRoot.appending(
          path: "API/Observed/source-lock.json"
        )
      )
    )
    try validate(manifest: selection.manifest, sourceLock: sourceLock)
  }

  static func validateCurrentApproval(
    snapshot: ProviderAPIAuthoritySnapshot,
    approval: ApprovalReceipt
  ) throws {
    let selection = try loadCurrentManifest(snapshot: snapshot)
    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      selection.relativePath,
      snapshot: snapshot,
      approval: approval
    )
    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      "API/Observed/source-lock.json",
      snapshot: snapshot,
      approval: approval
    )
    let sourceLock = try DeterministicJSON.decode(
      SourceLock.self,
      from: snapshot.requiredData("API/Observed/source-lock.json")
    )
    try validate(manifest: selection.manifest, sourceLock: sourceLock)
  }

  private static func decodeManifest(_ data: Data) throws -> SourceManifest {
    let manifest = try DeterministicJSON.decode(
      SourceManifest.self,
      from: data
    )
    let supportedKinds: Set<String> = [
      "lifeware.source-manifest",
      "web-api-reverse.source-manifest",
    ]
    guard manifest.schemaVersion == 1,
      supportedKinds.contains(manifest.kind)
    else {
      throw ContractError.invalidApproval(
        "unsupported source manifest schema or kind: "
          + "\(manifest.schemaVersion)/\(manifest.kind); "
          + "schemaSupported=\(manifest.schemaVersion == 1), "
          + "kindSupported=\(supportedKinds.contains(manifest.kind))"
      )
    }
    return manifest
  }

  private static func sourceKey(_ id: String, _ version: String) -> String {
    "\(id)@\(version)"
  }

  private static func list(_ values: [String]) -> String {
    values.isEmpty ? "none" : values.joined(separator: ", ")
  }
}
