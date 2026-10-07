import Foundation

public enum EvidenceScopeError: Error, LocalizedError {
  case mismatch(String)
  case invalidKind(String)
  case unsupportedSchema(Int)

  public var errorDescription: String? {
    switch self {
    case .mismatch(let message):
      "Evidence scope mismatch: \(message)"
    case .invalidKind(let kind):
      "Invalid evidence artifact kind: \(kind)"
    case .unsupportedSchema(let version):
      "Unsupported evidence schema version: \(version)"
    }
  }
}

public enum CoverageCalculator {
  public static func compute(
    catalog: ObservedCatalog,
    sourceLock: SourceLock,
    verifications: [TrustVerificationReceipt]? = nil
  ) throws -> CoverageReport {
    let currentCatalog: ObservedCatalog
    if let verifications {
      currentCatalog = try InventoryBuilder.bindingCurrentVerifications(
        to: catalog,
        verifications: verifications
      )
    } else {
      currentCatalog = catalog
    }
    try validate(catalog: currentCatalog, sourceLock: sourceLock)
    let unknown = currentCatalog.operations
      .filter(\.hasUnknownFacts)
      .map(\.operationId)
      .sorted()
    let incomplete = sourceLock.sources
      .filter {
        $0.coveragePolicy == .required
          && ($0.status != .captured || !$0.hasLockedEvidence)
      }
      .map { "\($0.sourceId)@\($0.version)" }
      .sorted()
    let deferred = sourceLock.sources
      .filter { $0.coveragePolicy == .deferred }
      .map { "\($0.sourceId)@\($0.version)" }
      .sorted()
    let excluded = sourceLock.sources
      .filter { $0.coveragePolicy == .excluded }
      .map { "\($0.sourceId)@\($0.version)" }
      .sorted()
    let unverified = currentCatalog.operations
      .filter {
        $0.classification.isTrustEligible
          && ($0.safety == .safeRead || $0.safety == .reversibleWrite)
          && $0.verificationIds.isEmpty
      }
      .map(\.operationId)
      .sorted()
    let requiredAreas = try SourceCoverageContract.validate(
      requiredAreas: sourceLock.requiredCoverageAreas,
      sources: sourceLock.sources.map {
        SourceCoverageContract.Source(
          key: "\($0.sourceId)@\($0.version)",
          policy: $0.coveragePolicy,
          areas: $0.coverageAreas
        )
      }
    )
    let coveredAreas = Set(
      sourceLock.sources
        .filter {
          $0.coveragePolicy == .required
            && $0.status == .captured
            && $0.hasLockedEvidence
        }
        .flatMap { $0.coverageAreas ?? [] }
    ).intersection(requiredAreas)
    let missingAreas = requiredAreas.filter { !coveredAreas.contains($0) }

    return CoverageReport(
      schemaVersion: 1,
      kind: "web-api-reverse.coverage",
      brand: currentCatalog.brand,
      market: currentCatalog.market,
      zeroUnknown: unknown.isEmpty && incomplete.isEmpty && missingAreas.isEmpty,
      operationCount: currentCatalog.operations.count,
      classifiedCount: currentCatalog.operations.count - unknown.count,
      unknownOperationIds: unknown,
      incompleteSourceIds: incomplete,
      deferredSourceIds: deferred,
      excludedSourceIds: excluded,
      requiredCoverageAreas: requiredAreas,
      coveredCoverageAreas: coveredAreas.sorted(),
      missingCoverageAreas: missingAreas,
      unverifiedSafeOperationIds: unverified
    )
  }

  private static func validate(
    catalog: ObservedCatalog,
    sourceLock: SourceLock
  ) throws {
    guard catalog.schemaVersion == 1, sourceLock.schemaVersion == 1 else {
      throw EvidenceScopeError.unsupportedSchema(
        max(catalog.schemaVersion, sourceLock.schemaVersion)
      )
    }
    guard
      catalog.kind == "lifeware.observed-catalog"
        || catalog.kind == "web-api-reverse.observed-catalog"
    else {
      throw EvidenceScopeError.invalidKind(catalog.kind)
    }
    guard
      sourceLock.kind == "lifeware.source-lock"
        || sourceLock.kind == "web-api-reverse.source-lock"
    else {
      throw EvidenceScopeError.invalidKind(sourceLock.kind)
    }
    guard catalog.brand == sourceLock.brand,
      catalog.market == sourceLock.market
    else {
      throw EvidenceScopeError.mismatch(
        "\(catalog.brand)/\(catalog.market) vs \(sourceLock.brand)/\(sourceLock.market)"
      )
    }
  }
}
