import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Published semantic gate")
struct ApprovalContractTests {
  @Test("Reads canonical client operation IDs and JSON-form OpenAPI YAML")
  func readsCanonicalProjectionFormats() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "inspection-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: root) }
    let published = root.appending(path: "API/Published")
    try FileManager.default.createDirectory(
      at: published,
      withIntermediateDirectories: true
    )
    let policies: [String: Any] = [
      "operations": [
        [
          "operationId": "get.catalog.product",
          "clientOperationId": "getProduct",
          "serviceFamily": "catalog",
          "classification": "public-current-fact",
          "safety": "safe-read",
          "evidenceIds": ["ver_product"],
          "reversibleMutation": false,
        ]
      ]
    ]
    let policyData = try JSONSerialization.data(
      withJSONObject: policies,
      options: [.prettyPrinted, .sortedKeys]
    )
    try policyData.write(
      to: published.appending(path: "operation-policies.json")
    )
    let facts = try OperationPolicyReader.read(
      from: published.appending(path: "operation-policies.json")
    )
    #expect(facts.map(\.operationId) == ["getProduct"])

    let openAPI: [String: Any] = [
      "openapi": "3.1.0",
      "paths": [
        "/products/{id}": [
          "get": ["operationId": "getProduct"]
        ]
      ],
    ]
    let openAPIData = try JSONSerialization.data(
      withJSONObject: openAPI,
      options: [.prettyPrinted, .sortedKeys]
    )
    try openAPIData.write(to: published.appending(path: "openapi.yaml"))
    #expect(
      try OpenAPIInspection.operationIds(
        at: published.appending(path: "openapi.yaml")
      ) == ["getProduct"]
    )
  }

  @Test("Rejects inconsistent operation sets")
  func rejectsOperationSetMismatch() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: [],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"]
    )
    #expect(throws: (any Error).self) {
      try EvidencePublisher().publish(
        PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
      )
    }
  }

  @Test("Accepts one directly replayed operation across all files")
  func acceptsConsistentOperation() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: ["product.detail"],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"]
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    _ = try ContractValidator().validate(providerRoot: fixture.root)
  }

  @Test("Provider validation rejects missing current Observed receipts")
  func rejectsMissingCurrentVerificationReceipt() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: ["product.detail"],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"]
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try FileManager.default.removeItem(
      at: fixture.root.appending(path: "API/Observed/verifications")
    )

    #expect(throws: (any Error).self) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Provider validation rejects the legacy singular receipt directory")
  func rejectsLegacyVerificationDirectory() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: ["product.detail"],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"]
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try FileManager.default.moveItem(
      at: fixture.root.appending(path: "API/Observed/verifications"),
      to: fixture.root.appending(path: "API/Observed/verification")
    )

    do {
      _ = try ContractValidator().validate(providerRoot: fixture.root)
      Issue.record("Expected the legacy receipt directory to fail.")
    } catch {
      #expect(error.localizedDescription.contains("move its receipts"))
      #expect(error.localizedDescription.contains("rerun inventory"))
    }
  }

  @Test("Provider validation rejects anonymous policy backed only by cookie replay")
  func rejectsMissingAnonymousRequestEvidence() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: ["product.detail"],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"],
      observedCookieNames: ["account_session"]
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn"
      )
    )

    do {
      _ = try ContractValidator().validate(providerRoot: fixture.root)
      Issue.record("Expected unauthenticated request evidence to be required.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "does not prove an unauthenticated request shape"
        )
      )
    }
  }

  @Test("Provider validation accepts separate fixture and anonymous request receipts")
  func acceptsSplitAnonymousEvidence() throws {
    let fixture = try SemanticFixture()
    defer { fixture.remove() }
    try fixture.write(
      policyOperationIds: ["product.detail"],
      capabilityOperationIds: ["product.detail"],
      approvalOperationIds: ["product.detail"],
      openAPIOperationIds: ["product.detail"],
      observedCookieNames: ["account_session"],
      includeAnonymousRequestProof: true
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )

    _ = try ContractValidator().validate(providerRoot: fixture.root)
  }
}

private struct SemanticFixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory
      .appending(path: "semantic-\(UUID().uuidString)", directoryHint: .isDirectory)
    _ = try ProviderScaffolder().scaffold(providerRoot: root)
  }

  func write(
    policyOperationIds: [String],
    capabilityOperationIds: [String],
    approvalOperationIds: [String],
    openAPIOperationIds: [String],
    observedCookieNames: [String] = [],
    includeAnonymousRequestProof: Bool = false
  ) throws {
    let openAPIPaths = openAPIOperationIds.enumerated().map { index, id in
      """
        /fixture/\(index):
          get:
            operationId: \(id)
            responses:
              '200':
                description: OK
      """
    }.joined(separator: "\n")
    try Data(
      """
      openapi: 3.1.0
      info:
        title: Fixture
        version: 1.0.0
      paths:
      \(openAPIPaths)
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/openapi.yaml"))

    let policies = OperationPoliciesSummary(
      operations: policyOperationIds.map {
        OperationPolicySummary(
          operationId: $0,
          safety: .safeRead,
          sessionAction: nil,
          reversibleMutation: false
        )
      }
    )
    try DeterministicJSON.write(
      policies,
      to: root.appending(path: "API/Trusted/operation-policies.json")
    )
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "fixture",
        market: "cn",
        claimedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true,
        capabilities: [
          CapabilityClaimEntry(
            id: "product",
            availability: .supported,
            operationIds: capabilityOperationIds
          )
        ]
      ),
      to: root.appending(path: "API/Config/capability-claim.json")
    )
    let observedOperations = approvalOperationIds.map {
      ObservedOperation(
        operationId: $0,
        fingerprint: String(repeating: "f", count: 64),
        method: "GET",
        urlTemplate: "https://example.test/\($0)",
        protocol: .rest,
        serviceFamily: "product",
        productFamily: "current-facts",
        classification: .publicCurrentFact,
        safety: .safeRead,
        authPolicy: .none,
        routePolicy: .fixed(baseURL: "https://example.test"),
        request: RequestShape(
          contentType: nil,
          queryNames: [],
          headers: observedCookieNames.isEmpty
            ? []
            : [
              HeaderPresence(
                name: "cookie",
                present: true,
                sensitive: true
              )
            ],
          cookieNames: observedCookieNames,
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
        sourceRefs: [],
        verificationIds: includeAnonymousRequestProof
          ? ["ver_1", "ver_anonymous"]
          : ["ver_1"]
      )
    }
    let catalogURL = root.appending(path: "API/Observed/catalog.json")
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "fixture",
        market: "cn",
        updatedAt: "2026-07-29T00:00:00Z",
        operations: observedOperations
      ),
      to: catalogURL
    )
    try DeterministicJSON.write(
      TrustManifest(
        brand: "fixture",
        market: "cn",
        reviewedAt: "2026-07-29T00:00:00Z",
        operations: approvalOperationIds.map {
          TrustManifestOperation(
            operationId: $0,
            clientOperationId: $0,
            evidenceIds: includeAnonymousRequestProof
              ? ["ver_1", "ver_anonymous"]
              : ["ver_1"],
            family: "product",
            authPolicy: .none,
            routePolicy: .fixed(baseURL: "https://example.test"),
            safety: .safeRead,
            reversibleMutation: false
          )
        }
      ),
      to: root.appending(path: "API/Config/trust-manifest.json")
    )
    let sourceManifestURL = root.appending(
      path: "API/Config/source-manifest.json"
    )
    let sourceLockURL = root.appending(
      path: "API/Observed/source-lock.json"
    )
    try DeterministicJSON.write(
      SourceManifest(
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: ["official-desktop"],
        sources: [
          ExpectedSource(
            sourceId: "desktop",
            surface: .web,
            version: "1",
            coverageAreas: ["official-desktop"],
            coveragePolicy: .required,
            status: .captured
          )
        ]
      ),
      to: sourceManifestURL
    )
    try DeterministicJSON.write(
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
            status: .captured,
            capturedAt: "2026-07-29T00:00:00Z",
            captureIds: [],
            operationFingerprints: []
          )
        ]
      ),
      to: sourceLockURL
    )
    for operation in observedOperations {
      try DeterministicJSON.write(
        TrustVerificationReceipt(
          brand: "fixture",
          market: "cn",
          verificationId: "ver_1",
          verificationKind: .directReplay,
          verifiedAt: "2026-07-29T00:00:00Z",
          operationId: operation.operationId,
          fingerprint: operation.fingerprint,
          sourceRefs: operation.sourceRefs,
          response: operation.responses[0],
          responseFixture: .object(["success": .bool(true)])
        ),
        to: root.appending(path: "API/Observed/verifications/ver_1.json")
      )
      if includeAnonymousRequestProof {
        try DeterministicJSON.write(
          TrustVerificationReceipt(
            brand: "fixture",
            market: "cn",
            verificationId: "ver_anonymous",
            verificationKind: .directReplay,
            verifiedAt: "2026-07-29T00:00:00Z",
            operationId: operation.operationId,
            fingerprint: operation.fingerprint,
            sourceRefs: operation.sourceRefs,
            requestEvidence: VerificationRequestEvidence(
              finalURLTemplate: operation.urlTemplate,
              headerNames: ["accept"],
              cookieNames: []
            ),
            response: operation.responses[0],
            responseFixture: .object(["raw": .string("replayed")])
          ),
          to: root.appending(
            path: "API/Observed/verifications/ver_anonymous.json"
          )
        )
      }
    }
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "fixture",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: ["desktop@1"],
        requiredCoverageAreas: ["official-desktop"],
        coveredCoverageAreas: ["official-desktop"],
        inputHashes: try Dictionary(
          uniqueKeysWithValues: ApprovalInputPathPolicy.requiredPaths.map {
            path in
            (
              path,
              try FileDigest.sha256(
                fileAt: root.appending(path: path)
              )
            )
          }
        ),
        operations: approvalOperationIds.map {
          OperationApproval(
            operationId: $0,
            evidenceIds: includeAnonymousRequestProof
              ? ["ver_1", "ver_anonymous"]
              : ["ver_1"],
            evidenceClass: .directReplay
          )
        }
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
