import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Evidence coverage")
struct CoverageTests {
  @Test("Unknown facts and incomplete required sources block zero unknown")
  func unknownFactsBlockCoverage() throws {
    let catalog = fixtureCatalog(
      operations: [fixtureOperation(classification: .unknown, verificationIds: [])]
    )
    let sourceLock = fixtureSourceLock(status: .partial)

    let report = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: sourceLock
    )

    #expect(report.zeroUnknown == false)
    #expect(report.unknownOperationIds == ["product.detail"])
    #expect(report.incompleteSourceIds == ["desktop@1"])
    #expect(report.missingCoverageAreas == ["official-desktop"])
  }

  @Test("Verified classified operation passes strict coverage")
  func verifiedOperationPassesStrictCoverage() throws {
    let catalog = fixtureCatalog(
      operations: [
        fixtureOperation(
          classification: .publicCurrentFact,
          verificationIds: ["ver_1"]
        )
      ]
    )
    let report = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: fixtureSourceLock(status: .captured)
    )
    #expect(report.zeroUnknown)
    #expect(report.passesStrict)
    #expect(report.requiredCoverageAreas == ["official-desktop"])
    #expect(report.coveredCoverageAreas == ["official-desktop"])
    #expect(report.missingCoverageAreas == [])
  }

  @Test("Strict coverage derives verification status from current receipts")
  func strictCoverageReconcilesCurrentReceipts() throws {
    let operation = fixtureOperation(verificationIds: ["ver_stale"])
    let receipt = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_current",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      sourceRefs: operation.sourceRefs,
      response: ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["type": .string("object")]),
        outcome: .success,
        businessErrorSignals: []
      ),
      responseFixture: .object(["success": .bool(true)])
    )

    let current = try CoverageCalculator.compute(
      catalog: fixtureCatalog(operations: [operation]),
      sourceLock: fixtureSourceLock(status: .captured),
      verifications: [receipt]
    )
    let missing = try CoverageCalculator.compute(
      catalog: fixtureCatalog(operations: [operation]),
      sourceLock: fixtureSourceLock(status: .captured),
      verifications: []
    )

    #expect(current.passesStrict)
    #expect(current.unverifiedSafeOperationIds.isEmpty)
    #expect(missing.passesStrict == false)
    #expect(missing.unverifiedSafeOperationIds == ["product.detail"])
  }

  @Test("A missing required source area blocks zero unknown")
  func missingRequiredAreaBlocksCoverage() throws {
    let catalog = fixtureCatalog(
      operations: [
        fixtureOperation(
          classification: .publicCurrentFact,
          verificationIds: ["ver_1"]
        )
      ]
    )
    let sourceLock = SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: "fixture",
      market: "cn",
      requiredCoverageAreas: [
        "authenticated-account",
        "official-desktop",
      ],
      sources: [
        SourceLockEntry(
          sourceId: "account",
          surface: .web,
          version: "1",
          coverageAreas: ["authenticated-account"],
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: "",
          status: .missing,
          capturedAt: nil,
          captureIds: [],
          operationFingerprints: []
        ),
        SourceLockEntry(
          sourceId: "desktop",
          surface: .web,
          version: "1",
          coverageAreas: ["official-desktop"],
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: String(repeating: "a", count: 64),
          status: .captured,
          capturedAt: "2026-07-29T00:00:00Z",
          captureIds: ["cap_1"],
          operationFingerprints: ["abc"]
        ),
      ]
    )

    let report = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: sourceLock
    )

    #expect(report.zeroUnknown == false)
    #expect(report.incompleteSourceIds == ["account@1"])
    #expect(report.coveredCoverageAreas == ["official-desktop"])
    #expect(report.missingCoverageAreas == ["authenticated-account"])
    #expect(report.passesStrict == false)
  }

  @Test("A legacy source lock cannot claim semantic source completeness")
  func missingCoverageContractFailsClosed() {
    let catalog = fixtureCatalog(
      operations: [fixtureOperation(verificationIds: ["ver_1"])]
    )
    let sourceLock = SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: "fixture",
      market: "cn",
      sources: [
        SourceLockEntry(
          sourceId: "desktop",
          surface: .web,
          version: "1",
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: String(repeating: "a", count: 64),
          status: .captured,
          capturedAt: "2026-07-29T00:00:00Z",
          captureIds: ["cap_1"],
          operationFingerprints: ["abc"]
        )
      ]
    )

    #expect(throws: CapturePipelineError.missingRequiredCoverageAreas) {
      try CoverageCalculator.compute(catalog: catalog, sourceLock: sourceLock)
    }
  }

  @Test("A required source without an observed operation is incomplete")
  func emptyRequiredSourceFailsCoverage() throws {
    let catalog = fixtureCatalog(
      operations: [fixtureOperation(verificationIds: ["ver_1"])]
    )
    let sourceLock = SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: "fixture",
      market: "cn",
      requiredCoverageAreas: ["selected-platform-current-facts"],
      sources: [
        SourceLockEntry(
          sourceId: "platform-product",
          surface: .h5,
          version: "1",
          coverageAreas: ["selected-platform-current-facts"],
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: String(repeating: "a", count: 64),
          status: .captured,
          capturedAt: "2026-07-29T00:00:00Z",
          captureIds: ["cap_risk_page"],
          operationFingerprints: []
        )
      ]
    )

    let report = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: sourceLock
    )

    #expect(report.zeroUnknown == false)
    #expect(report.incompleteSourceIds == ["platform-product@1"])
    #expect(
      report.missingCoverageAreas == ["selected-platform-current-facts"]
    )
  }

  @Test("Catalog diff is stable and operation keyed")
  func catalogDiffIsOperationKeyed() throws {
    let old = fixtureCatalog(
      updatedAt: "2026-07-28T00:00:00Z",
      operations: [fixtureOperation(verificationIds: ["ver_1"])]
    )
    let new = fixtureCatalog(
      updatedAt: "2026-07-29T00:00:00Z",
      operations: [fixtureOperation(verificationIds: ["ver_2"])]
    )
    let result = try CatalogDiffer.diff(from: old, to: new)
    #expect(result.changedOperationIds == ["product.detail"])
    #expect(result.unchangedCount == 0)
  }
}

private func fixtureCatalog(
  updatedAt: String = "2026-07-29T00:00:00Z",
  operations: [ObservedOperation]
) -> ObservedCatalog {
  ObservedCatalog(
    schemaVersion: 1,
    kind: "web-api-reverse.observed-catalog",
    brand: "fixture",
    market: "cn",
    updatedAt: updatedAt,
    operations: operations
  )
}

private func fixtureOperation(
  classification: OperationClassification = .publicCurrentFact,
  verificationIds: [String]
) -> ObservedOperation {
  ObservedOperation(
    operationId: "product.detail",
    fingerprint: "abc",
    method: "GET",
    urlTemplate: "https://example.test/product/{id}",
    protocol: .rest,
    serviceFamily: "product",
    productFamily: "product",
    classification: classification,
    safety: classification == .unknown ? .unknown : .safeRead,
    authPolicy: classification == .unknown ? .unknown : .none,
    routePolicy: classification == .unknown
      ? .unknown
      : .fixed(baseURL: "https://example.test"),
    request: RequestShape(
      contentType: nil,
      queryNames: [],
      headers: [],
      cookieNames: [],
      bodySchema: nil
    ),
    responses: [
      ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["type": .string("object")]),
        outcome: .success,
        businessErrorSignals: []
      )
    ],
    sourceRefs: [
      SourceReference(
        captureId: "cap_1",
        sourceId: "desktop",
        sourceVersion: "1"
      )
    ],
    verificationIds: verificationIds
  )
}

private func fixtureSourceLock(status: SourceStatus) -> SourceLock {
  SourceLock(
    schemaVersion: 1,
    kind: "web-api-reverse.source-lock",
    brand: "fixture",
    market: "cn",
    requiredCoverageAreas: ["official-desktop"],
    sources: [
      SourceLockEntry(
        sourceId: "desktop",
        surface: .web,
        version: "1",
        coverageAreas: ["official-desktop"],
        coveragePolicy: .required,
        coverageRationale: nil,
        sha256: String(repeating: "a", count: 64),
        status: status,
        capturedAt: "2026-07-29T00:00:00Z",
        captureIds: ["cap_1"],
        operationFingerprints: ["abc"]
      )
    ]
  )
}
