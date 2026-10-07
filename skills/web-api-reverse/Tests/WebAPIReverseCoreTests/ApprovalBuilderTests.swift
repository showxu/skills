import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Approval builder")
struct ApprovalBuilderTests {
  @Test("Builds capability and approval from reviewed policies")
  func buildsReviewedProjection() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }

    let result = try ApprovalBuilder().build(
      ApprovalBuildInput(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        reviewer: "reviewer",
        approvedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true
      )
    )
    #expect(result.operationCount == 1)
    let claim = try DeterministicJSON.decode(
      CapabilityClaim.self,
      from: Data(
        contentsOf: fixture.root.appending(path: "API/Config/capability-claim.json")
      )
    )
    #expect(claim.operationIds == Set(["getProduct"]))
    let approval = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(
        contentsOf: fixture.root.appending(path: "API/Trusted/approval-receipt.json")
      )
    )
    #expect(approval.operations.first?.evidenceClass == .directReplay)
    #expect(
      approval.inputHashes.keys.contains("API/Observed/source-lock.json")
    )
    #expect(
      approval.inputHashes.keys.contains(
        "API/Config/source-manifest.json"
      )
    )
  }

  @Test("Refuses an implicit zero-unknown claim")
  func refusesImplicitCoverageClaim() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }
    #expect(throws: (any Error).self) {
      try ApprovalBuilder().build(
        ApprovalBuildInput(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          reviewer: "reviewer",
          zeroUnknown: false
        )
      )
    }
  }

  @Test("Refuses an approval when a required source area is not captured")
  func refusesIncompleteSemanticCoverage() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }
    try fixture.makeAccountAreaMissing()

    #expect(throws: (any Error).self) {
      try ApprovalBuilder().build(
        ApprovalBuildInput(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          reviewer: "reviewer",
          zeroUnknown: true
        )
      )
    }
  }

  @Test("Refuses Trusted evidence no longer proven by Observed")
  func refusesStaleVerificationEvidence() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }
    try fixture.removeObservedVerification()

    #expect(throws: (any Error).self) {
      try ApprovalBuilder().build(
        ApprovalBuildInput(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          reviewer: "reviewer",
          zeroUnknown: true
        )
      )
    }
  }

  @Test("Refuses a source lock built from a superseded manifest")
  func refusesSupersededSourceLifecycle() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }
    try fixture.replaceSourceRevisionWithoutInventory()

    #expect(throws: (any Error).self) {
      try ApprovalBuilder().build(
        ApprovalBuildInput(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          reviewer: "reviewer",
          zeroUnknown: true
        )
      )
    }
  }

  @Test("Accepts the legacy LifeWear source manifest kind")
  func acceptsLifeWearSourceManifestKind() throws {
    let fixture = try ApprovalFixture()
    defer { fixture.remove() }
    try fixture.useLifeWearSourceManifestKind()

    let result = try ApprovalBuilder().build(
      ApprovalBuildInput(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        reviewer: "reviewer",
        zeroUnknown: true
      )
    )

    #expect(result.operationCount == 1)
  }
}

@Test("Builds approval from separate response fixture and anonymous request proof")
func acceptsSplitAnonymousEvidence() throws {
  let fixture = try ApprovalFixture()
  defer { fixture.remove() }
  try fixture.enableSplitAnonymousEvidence()

  let result = try ApprovalBuilder().build(
    ApprovalBuildInput(
      providerRoot: fixture.root,
      provider: "fixture",
      market: "cn",
      reviewer: "reviewer",
      approvedAt: "2026-07-29T00:00:00Z",
      zeroUnknown: true
    )
  )

  #expect(result.operationCount == 1)
  let approval = try DeterministicJSON.decode(
    ApprovalReceipt.self,
    from: Data(
      contentsOf: fixture.root.appending(path: "API/Trusted/approval-receipt.json")
    )
  )
  #expect(
    approval.operations.first?.evidenceIds
      == ["cap_1", "ver_1", "ver_anonymous"]
  )
}

private struct ApprovalFixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory
      .appending(path: "approval-\(UUID().uuidString)", directoryHint: .isDirectory)
    _ = try ProviderScaffolder().scaffold(providerRoot: root)
    try Data(
      """
      openapi: 3.1.0
      info:
        title: Fixture
        version: 1.0.0
      paths:
        /product:
          get:
            operationId: getProduct
            responses:
              '200':
                description: OK
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/openapi.yaml"))
    try Data(
      """
      {
        "operations": [
          {
            "operationId": "product.detail",
            "clientOperationId": "getProduct",
            "serviceFamily": "product",
            "classification": "public-current-fact",
            "safety": "safe-read",
            "reversibleMutation": false,
            "evidenceIds": ["cap_1", "ver_1"]
          }
        ]
      }
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/operation-policies.json"))
    try writeSourceManifest()
    try writeObservedContract()
  }

  private func writeSourceManifest(version: String = "1") throws {
    try DeterministicJSON.write(
      SourceManifest(
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: ["official-desktop"],
        sources: [
          ExpectedSource(
            sourceId: "desktop",
            surface: .web,
            version: version,
            coverageAreas: ["official-desktop"],
            coveragePolicy: .required,
            status: .captured
          )
        ]
      ),
      to: root.appending(path: "API/Config/source-manifest.json")
    )
  }

  private func writeObservedContract(
    requiredAreas: [String] = ["official-desktop"],
    sources: [SourceLockEntry]? = nil,
    verificationIDs: [String] = ["ver_1"],
    observedCookieNames: [String] = [],
    primaryCarriesRequestEvidence: Bool = true,
    includeAnonymousRequestProof: Bool = false
  ) throws {
    let operation = ObservedOperation(
      operationId: "product.detail",
      fingerprint: String(repeating: "f", count: 64),
      method: "GET",
      urlTemplate: "https://example.test/product",
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
      sourceRefs: [
        SourceReference(
          captureId: "cap_1",
          sourceId: "desktop",
          sourceVersion: "1"
        )
      ],
      verificationIds: verificationIDs
    )
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "fixture",
        market: "cn",
        updatedAt: "2026-07-29T00:00:00Z",
        operations: [operation]
      ),
      to: root.appending(path: "API/Observed/catalog.json")
    )
    try DeterministicJSON.write(
      SourceLock(
        schemaVersion: 1,
        kind: "web-api-reverse.source-lock",
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: requiredAreas,
        sources: sources
          ?? [
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
              operationFingerprints: [String(repeating: "f", count: 64)]
            )
          ]
      ),
      to: root.appending(path: "API/Observed/source-lock.json")
    )
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
        requestEvidence: primaryCarriesRequestEvidence
          ? VerificationRequestEvidence(
            finalURLTemplate: operation.urlTemplate,
            headerNames: [],
            cookieNames: [],
            bodySchema: nil
          )
          : nil,
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
            cookieNames: [],
            bodySchema: nil
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

  func enableSplitAnonymousEvidence() throws {
    try Data(
      """
      {
        "operations": [
          {
            "operationId": "product.detail",
            "clientOperationId": "getProduct",
            "serviceFamily": "product",
            "classification": "public-current-fact",
            "safety": "safe-read",
            "reversibleMutation": false,
            "evidenceIds": ["cap_1", "ver_1", "ver_anonymous"]
          }
        ]
      }
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/operation-policies.json"))
    try writeObservedContract(
      verificationIDs: ["ver_1", "ver_anonymous"],
      observedCookieNames: ["account_session"],
      primaryCarriesRequestEvidence: false,
      includeAnonymousRequestProof: true
    )
  }

  func makeAccountAreaMissing() throws {
    try writeObservedContract(
      requiredAreas: [
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
          operationFingerprints: [String(repeating: "f", count: 64)]
        ),
      ]
    )
  }

  func removeObservedVerification() throws {
    try writeObservedContract(verificationIDs: [])
  }

  func replaceSourceRevisionWithoutInventory() throws {
    try writeSourceManifest(version: "2")
  }

  func useLifeWearSourceManifestKind() throws {
    let url = root.appending(path: "API/Config/source-manifest.json")
    var document = try #require(
      try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        as? [String: Any]
    )
    document["kind"] = "lifeware.source-manifest"
    try JSONSerialization.data(
      withJSONObject: document,
      options: [.prettyPrinted, .sortedKeys]
    ).write(to: url)
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
