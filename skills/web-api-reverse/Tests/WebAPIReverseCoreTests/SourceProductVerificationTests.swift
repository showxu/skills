import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Platform source product verification")
struct SourceProductVerificationTests {
  @Test("Verified platform product evidence closes a partial declared source")
  func verifiesAndLocksExternalSource() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy()
    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(),
        platformProviderRoot: fixture.root
      )
    )
    let bootstrap = CaptureReceipt(
      captureId: "cap_bootstrap",
      capturedAt: "2026-07-29T00:00:00Z",
      brand: "peacebird",
      market: "cn",
      source: CaptureSource(
        sourceId: "peacebird-bootstrap",
        surface: .documentation,
        version: "1",
        sha256: String(repeating: "a", count: 64)
      ),
      flow: "bootstrap",
      exchanges: []
    )
    let result = try InventoryBuilder.build(
      receipts: [bootstrap],
      sourceManifest: SourceManifest(
        brand: "peacebird",
        market: "cn",
        requiredCoverageAreas: ["selected-platform-current-facts"],
        sources: [
          ExpectedSource(
            sourceId: "peacebird-bootstrap",
            surface: .documentation,
            version: "1",
            coveragePolicy: .excluded,
            coverageRationale: "Inventory scope anchor only."
          ),
          ExpectedSource(
            sourceId: "peacebird-jd-product",
            surface: .web,
            version: "2026-07-29",
            coverageAreas: ["selected-platform-current-facts"],
            status: .partial
          ),
        ]
      ),
      sourceProductVerifications: [receipt]
    )
    let coverage = try CoverageCalculator.compute(
      catalog: result.catalog,
      sourceLock: result.sourceLock
    )
    let platformSource = try #require(
      result.sourceLock.sources.first {
        $0.sourceId == "peacebird-jd-product"
      }
    )

    #expect(result.catalog.operations.isEmpty)
    #expect(platformSource.status == .captured)
    #expect(platformSource.operationFingerprints.isEmpty)
    #expect(platformSource.evidenceFingerprints == [receipt.evidenceFingerprint])
    #expect(coverage.zeroUnknown)
    #expect(coverage.coveredCoverageAreas == ["selected-platform-current-facts"])
  }

  @Test("Provider-mapped projection keeps platform authority but requires brand ownership")
  func verifiesProviderMappedProjection() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy(sourceProjection: .providerMapped)

    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(
          sourceTool: "peacebird",
          providerBrand: "peacebird"
        ),
        platformProviderRoot: fixture.root
      )
    )

    #expect(receipt.provider == "peacebird")
    #expect(receipt.platformProvider == "jd")
    #expect(receipt.garmentBrand == "太平鸟")

    #expect(
      throws: SourceProductVerificationError.identityMismatch(
        "source jd/jd/cn does not match peacebird/jd/cn"
      )
    ) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: policy,
          sourceProductData: sourceProductData(),
          platformProviderRoot: fixture.root
        )
      )
    }
  }

  @Test("Provider-mapped source owner may differ from its domain brand ID")
  func verifiesProviderMappedSourceWithDistinctBrandID() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = SourceProductVerificationPolicy(
      provider: "ur",
      market: "cn",
      sourceId: "ur-jd-product",
      sourceVersion: "2026-08-16",
      platformProvider: "jd",
      commercePlatform: "jd",
      sourceProjection: .providerMapped,
      acceptedGarmentBrands: ["urban-revivo"],
      acceptedSellerIDs: ["1000457053"],
      acceptedStorefronts: ["jd"],
      requiredProductCurrentFactFields: ["currentPrice", "stockStatus"],
      requiredSKUCurrentFactFields: ["currentPrice", "stockStatus"],
      requireCompleteSKUSet: true
    )

    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(
          sourceTool: "ur",
          providerBrand: "urban-revivo",
          brand: "urban-revivo"
        ),
        platformProviderRoot: fixture.root
      )
    )

    #expect(receipt.provider == "ur")
    #expect(receipt.garmentBrand == "urban-revivo")
  }

  @Test("Policies without sourceProjection retain platform-raw behavior")
  func defaultsLegacyPolicyToPlatformRaw() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy()
    let encoded = try DeterministicJSON.encode(policy)

    #expect(policy.sourceProjection == nil)
    #expect(!String(decoding: encoded, as: UTF8.self).contains("sourceProjection"))
    _ = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(),
        platformProviderRoot: fixture.root
      )
    )
  }

  @Test("Garment, seller, and storefront identity fail closed")
  func rejectsWrongIdentity() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }

    #expect(
      throws: SourceProductVerificationError.identityMismatch(
        "seller is not allowlisted"
      )
    ) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: makePolicy(),
          sourceProductData: sourceProductData(seller: "other-seller"),
          platformProviderRoot: fixture.root
        )
      )
    }
    #expect(
      throws: SourceProductVerificationError.identityMismatch(
        "garment brand is not allowlisted"
      )
    ) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: makePolicy(),
          sourceProductData: sourceProductData(brand: "Other Brand"),
          platformProviderRoot: fixture.root
        )
      )
    }
  }

  @Test("A shop-constrained policy binds one reviewed Product shopId")
  func verifiesAndBindsShopIdentity() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy(acceptedShopIDs: ["1000457053"])

    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(shopID: "1000457053"),
        platformProviderRoot: fixture.root
      )
    )

    #expect(receipt.schemaVersion == 3)
    #expect(receipt.shopID == "1000457053")
    try SourceProductVerifier.validate(receipt, against: policy)
  }

  @Test("A shop-constrained policy rejects missing, duplicate, or foreign shopId")
  func rejectsUntrustedShopIdentity() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy(acceptedShopIDs: ["1000457053"])

    for data in [
      sourceProductData(),
      sourceProductData(shopID: "other-shop"),
      sourceProductData(
        shopID: "1000457053",
        duplicateShopAlias: true
      ),
    ] {
      #expect(throws: SourceProductVerificationError.self) {
        try SourceProductVerifier().verify(
          SourceProductVerificationInput(
            policy: policy,
            sourceProductData: data,
            platformProviderRoot: fixture.root
          )
        )
      }
    }
  }

  @Test("Current facts and complete SKU requirements fail closed")
  func rejectsMissingFactsAndIncompleteSet() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }

    #expect(
      throws: SourceProductVerificationError.missingCurrentFact(
        "product.currentPrice"
      )
    ) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: makePolicy(),
          sourceProductData: sourceProductData(includeProductPrice: false),
          platformProviderRoot: fixture.root
        )
      )
    }
    #expect(throws: SourceProductVerificationError.incompleteSKUSet) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: makePolicy(),
          sourceProductData: sourceProductData(completeSKUSet: false),
          platformProviderRoot: fixture.root
        )
      )
    }
  }

  @Test("Platform Published drift invalidates new verification")
  func rejectsPublishedDrift() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    try Data("changed\n".utf8).write(
      to: fixture.root.appending(path: "API/Published/openapi.yaml")
    )

    #expect(throws: ContractError.hashMismatch(file: "openapi.yaml")) {
      try SourceProductVerifier().verify(
        SourceProductVerificationInput(
          policy: makePolicy(),
          sourceProductData: sourceProductData(),
          platformProviderRoot: fixture.root
        )
      )
    }
  }

  @Test("Durable receipt validation returns the exact receipt byte hash")
  func validatesCurrentReceiptAndRejectsPublishedLockDrift() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let policy = makePolicy()
    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(),
        platformProviderRoot: fixture.root
      )
    )
    let receiptData = try DeterministicJSON.encode(receipt)
    let validation = try SourceProductVerifier().validateReceipt(
      receiptData: receiptData,
      policy: policy,
      platformProviderRoot: fixture.root
    )
    let canonicalReceiptSHA256 = try DeterministicJSON.canonicalSHA256(
      receiptData
    )

    #expect(validation.provider == "peacebird")
    #expect(validation.sourceId == "peacebird-jd-product")
    #expect(
      validation.platformPublishLockSHA256
        == receipt.platformPublishLockSHA256
    )
    #expect(validation.policySHA256 == receipt.policySHA256)
    #expect(
      validation.sourceProductReceiptSHA256
        == FileDigest.sha256(data: receiptData)
    )
    #expect(
      validation.sourceProductReceiptSHA256
        != canonicalReceiptSHA256
    )

    let publishedLock = fixture.root.appending(
      path: "API/Published/publish-lock.json"
    )
    var lock = try #require(
      JSONSerialization.jsonObject(
        with: Data(contentsOf: publishedLock)
      ) as? [String: Any]
    )
    lock["generatedAt"] = "2026-08-09T00:00:00Z"
    try JSONSerialization.data(
      withJSONObject: lock,
      options: [.sortedKeys]
    ).write(to: publishedLock)

    #expect(throws: (any Error).self) {
      try SourceProductVerifier().validateReceipt(
        receiptData: receiptData,
        policy: policy,
        platformProviderRoot: fixture.root
      )
    }
  }

  @Test("Tampered durable receipt is rejected")
  func rejectsTamperedReceipt() throws {
    let fixture = try PlatformFixture()
    defer { fixture.remove() }
    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: makePolicy(),
        sourceProductData: sourceProductData(),
        platformProviderRoot: fixture.root
      )
    )
    let tampered = SourceProductVerificationReceipt(
      provider: receipt.provider,
      market: receipt.market,
      verificationId: receipt.verificationId,
      evidenceFingerprint: receipt.evidenceFingerprint,
      verifiedAt: receipt.verifiedAt,
      sourceId: receipt.sourceId,
      sourceVersion: "tampered",
      platformProvider: receipt.platformProvider,
      commercePlatform: receipt.commercePlatform,
      platformPublishLockSHA256: receipt.platformPublishLockSHA256,
      policySHA256: receipt.policySHA256,
      sourceProductSHA256: receipt.sourceProductSHA256,
      garmentBrand: receipt.garmentBrand,
      sellerID: receipt.sellerID,
      storefront: receipt.storefront,
      productExternalID: receipt.productExternalID,
      skuCount: receipt.skuCount,
      hasCompleteSKUSet: receipt.hasCompleteSKUSet,
      productCurrentFactFields: receipt.productCurrentFactFields,
      commonSKUCurrentFactFields: receipt.commonSKUCurrentFactFields
    )

    #expect(
      throws: SourceProductVerificationError.invalidReceipt(
        "identifier does not match the bound evidence"
      )
    ) {
      try SourceProductVerifier.validate(tampered)
    }
  }

  @Test("Approval rejects platform semantic claims without a source receipt")
  func approvalRejectsMissingReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)

    for coverageArea in [
      "selected-platform-current-facts",
      "selected-platform-identity",
    ] {
      let provider = try PlatformBackedProviderFixture(
        receipt: receipt,
        receiptMode: .missing,
        coverageArea: coverageArea
      )
      defer { provider.remove() }

      do {
        _ = try provider.approve()
        Issue.record("Expected \(coverageArea) approval without a receipt to fail.")
      } catch {
        #expect(
          error.localizedDescription.contains(
            "require a sanitized receipt in API/Observed/source-verifications"
          )
        )
      }
    }
  }

  @Test("Approval hashes the exact required source receipt")
  func approvalHashesRequiredReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }

    let approval = try provider.approve()
    let receiptPath = "API/Observed/source-verifications/product.json"
    let receiptSHA256 = try FileDigest.sha256(
      fileAt: provider.root.appending(path: receiptPath)
    )
    #expect(
      approval.inputHashes[receiptPath] == receiptSHA256
    )
    #expect(
      Set(
        approval.inputHashes.keys.filter {
          $0.hasPrefix("API/Observed/source-verifications/")
        }
      ) == Set([receiptPath])
    )
  }

  @Test("Approval accepts a receipt-promoted partial platform source")
  func approvalAcceptsReceiptPromotedSource() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound,
      manifestStatus: .partial
    )
    defer { provider.remove() }

    _ = try provider.approve()
    try provider.publish()
    _ = try ContractValidator().validate(providerRoot: provider.root)
  }

  @Test("Approval rejects an unproven partial-to-captured transition")
  func approvalRejectsUnprovenSourcePromotion() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .missing,
      manifestStatus: .partial
    )
    defer { provider.remove() }

    do {
      _ = try provider.approve()
      Issue.record("Expected an unproven source promotion to fail.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "source manifest status partial differs from source lock status captured"
        )
      )
    }
  }

  @Test("Identity-only policy cannot close platform current facts")
  func identityOnlyPolicyProvesOnlyIdentity() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let policy = makePolicy(requiresCurrentFacts: false)
    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(
          includeProductPrice: false,
          includeSKUPrice: false
        ),
        platformProviderRoot: platform.root
      )
    )

    let identityProvider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound,
      coverageArea: "selected-platform-identity",
      policy: policy
    )
    defer { identityProvider.remove() }
    _ = try identityProvider.approve()

    let currentFactsProvider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound,
      coverageArea: "selected-platform-current-facts",
      policy: policy
    )
    defer { currentFactsProvider.remove() }
    do {
      _ = try currentFactsProvider.approve()
      Issue.record("Expected identity-only evidence to reject current-fact approval.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "is identity-only and cannot prove selected-platform-current-facts"
        )
      )
    }
  }

  @Test("Publication rejects a source receipt absent from the current lock")
  func publicationRejectsUnboundReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .unbound
    )
    defer { provider.remove() }

    do {
      try provider.publish()
      Issue.record("Expected the unbound platform source receipt to fail.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "has no bound source-verification fingerprint"
        )
      )
    }
  }

  @Test("Publication rejects platform Published-lock digest drift")
  func publicationRejectsPlatformLockDigestDrift() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .tamperedPlatformLock
    )
    defer { provider.remove() }

    do {
      try provider.publish()
      Issue.record("Expected platform Published-lock digest drift to fail.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "does not prove the current source product policy and exact platform Published lock"
        )
      )
    }
  }

  @Test("Canonical validation rejects source-lock drift after approval")
  func canonicalValidationRejectsCurrentSourceLockDrift() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }
    try provider.publish()
    let sourceLockURL = provider.root.appending(
      path: "API/Observed/source-lock.json"
    )
    var sourceLockData = try Data(contentsOf: sourceLockURL)
    sourceLockData.append(contentsOf: Data("\n".utf8))
    try sourceLockData.write(to: sourceLockURL, options: .atomic)

    #expect(
      throws: ContractError.invalidObservedEvidence(
        "API/Observed/source-lock.json no longer matches the Published approval"
      )
    ) {
      try ContractValidator().validate(providerRoot: provider.root)
    }
  }

  @Test("Canonical validation accepts exact bound platform source evidence")
  func canonicalValidationAcceptsBoundReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }

    try provider.publish()
    _ = try ContractValidator().validate(providerRoot: provider.root)
  }

  @Test("Publication rechecks an approved source receipt")
  func publicationRejectsRemovedApprovedReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }
    try provider.removeSourceReceipt()

    do {
      try provider.publish()
      Issue.record("Expected publication without the approved receipt to fail.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "require a sanitized receipt in API/Observed/source-verifications"
        )
      )
    }
  }

  @Test("Canonical validation rejects source receipt byte tampering")
  func canonicalValidationRejectsTamperedApprovedReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }
    try provider.publish()
    try provider.appendToSourceReceipt(Data("\n".utf8))

    #expect(
      throws: ContractError.invalidObservedEvidence(
        "API/Observed/source-verifications/product.json no longer matches the Published approval"
      )
    ) {
      try ContractValidator().validate(providerRoot: provider.root)
    }
  }

  @Test("Canonical validation requires the Published approval receipt hash")
  func canonicalValidationRejectsMissingApprovedReceiptHash() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }
    try provider.publish()

    let published = provider.root.appending(
      path: "API/Published",
      directoryHint: .isDirectory
    )
    let approvalURL = published.appending(path: "approval-receipt.json")
    let approval = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(contentsOf: approvalURL)
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: approval.provider,
        market: approval.market,
        approvedAt: approval.approvedAt,
        reviewer: approval.reviewer,
        sourceRevisions: approval.sourceRevisions,
        requiredCoverageAreas: approval.requiredCoverageAreas,
        coveredCoverageAreas: approval.coveredCoverageAreas,
        inputHashes: approval.inputHashes.filter {
          !$0.key.hasPrefix(
            "API/Observed/source-verifications/"
          )
        },
        operations: approval.operations
      ),
      to: approvalURL
    )
    let lockURL = published.appending(path: "publish-lock.json")
    let lock = try DeterministicJSON.decode(
      PublishLock.self,
      from: Data(contentsOf: lockURL)
    )
    var files = lock.files
    files["approval-receipt.json"] =
      try FileDigest.sha256(fileAt: approvalURL)
    try DeterministicJSON.write(
      PublishLock(
        provider: lock.provider,
        market: lock.market,
        publishedAt: lock.publishedAt,
        files: files
      ),
      to: lockURL
    )

    #expect(
      throws: ContractError.projectionMismatch(
        file: "approval-receipt.json"
      )
    ) {
      try ContractValidator().validate(providerRoot: provider.root)
    }
  }

  @Test("Canonical validation rejects source receipt removal")
  func canonicalValidationRejectsRemovedApprovedReceipt() throws {
    let platform = try PlatformFixture()
    defer { platform.remove() }
    let receipt = try verifiedReceipt(platformRoot: platform.root)
    let provider = try PlatformBackedProviderFixture(
      receipt: receipt,
      receiptMode: .bound
    )
    defer { provider.remove() }
    try provider.publish()
    try provider.removeSourceReceipt()

    #expect(
      throws: ContractError.missingFile(
        "API/Observed/source-verifications/product.json"
      )
    ) {
      try ContractValidator().validate(providerRoot: provider.root)
    }
  }
}

private func verifiedReceipt(
  platformRoot: URL
) throws -> SourceProductVerificationReceipt {
  try SourceProductVerifier().verify(
    SourceProductVerificationInput(
      policy: makePolicy(),
      sourceProductData: sourceProductData(),
      platformProviderRoot: platformRoot
    )
  )
}

private enum PlatformReceiptMode {
  case missing
  case unbound
  case tamperedPlatformLock
  case bound
}

private struct PlatformBackedProviderFixture {
  let root: URL

  init(
    receipt: SourceProductVerificationReceipt,
    receiptMode: PlatformReceiptMode,
    coverageArea: String = "selected-platform-current-facts",
    policy: SourceProductVerificationPolicy = makePolicy(),
    manifestStatus: SourceStatus = .captured
  ) throws {
    root = FileManager.default.temporaryDirectory
      .appending(
        path: "web-api-reverse-platform-provider-\(UUID().uuidString)",
        directoryHint: .isDirectory
      )
    _ = try ProviderScaffolder().scaffold(
      providerRoot: root,
      provider: "peacebird",
      market: "cn"
    )
    try Data(
      """
      openapi: 3.1.0
      info:
        title: Peacebird fixture
        version: 1.0.0
      paths: {}
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/openapi.yaml"))
    try Data(#"{"operations":[]}"#.utf8).write(
      to: root.appending(path: "API/Trusted/operation-policies.json")
    )
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "peacebird",
        market: "cn",
        claimedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true,
        capabilities: []
      ),
      to: root.appending(path: "API/Config/capability-claim.json")
    )
    try DeterministicJSON.write(
      policy,
      to: root.appending(path: "API/Config/jd-source-product-policy.json")
    )
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "peacebird",
        market: "cn",
        updatedAt: "2026-07-29T00:00:00Z",
        operations: []
      ),
      to: root.appending(path: "API/Observed/catalog.json")
    )

    let evidenceFingerprints: [String]?
    switch receiptMode {
    case .bound, .tamperedPlatformLock:
      evidenceFingerprints = [receipt.evidenceFingerprint]
    case .missing, .unbound:
      evidenceFingerprints = nil
    }
    let sourceLockURL = root.appending(
      path: "API/Observed/source-lock.json"
    )
    let sourceManifestURL = root.appending(
      path: "API/Config/source-manifest.json"
    )
    try DeterministicJSON.write(
      SourceManifest(
        brand: "peacebird",
        market: "cn",
        requiredCoverageAreas: [coverageArea],
        sources: [
          ExpectedSource(
            sourceId: receipt.sourceId,
            surface: .web,
            version: receipt.sourceVersion,
            coverageAreas: [coverageArea],
            coveragePolicy: .required,
            status: manifestStatus
          )
        ]
      ),
      to: sourceManifestURL
    )
    try DeterministicJSON.write(
      SourceLock(
        schemaVersion: 1,
        kind: "web-api-reverse.source-lock",
        brand: "peacebird",
        market: "cn",
        requiredCoverageAreas: [coverageArea],
        sources: [
          SourceLockEntry(
            sourceId: receipt.sourceId,
            surface: .web,
            version: receipt.sourceVersion,
            coverageAreas: [coverageArea],
            coveragePolicy: .required,
            coverageRationale: nil,
            sha256: receipt.sourceProductSHA256,
            status: .captured,
            capturedAt: receipt.verifiedAt,
            captureIds: [],
            operationFingerprints:
              evidenceFingerprints == nil ? ["claimed-platform-product"] : [],
            evidenceFingerprints: evidenceFingerprints
          )
        ]
      ),
      to: sourceLockURL
    )

    switch receiptMode {
    case .missing:
      break
    case .unbound, .bound:
      try DeterministicJSON.write(
        receipt,
        to: root.appending(
          path: "API/Observed/source-verifications/product.json"
        )
      )
    case .tamperedPlatformLock:
      try DeterministicJSON.write(
        SourceProductVerificationReceipt(
          provider: receipt.provider,
          market: receipt.market,
          verificationId: receipt.verificationId,
          evidenceFingerprint: receipt.evidenceFingerprint,
          verifiedAt: receipt.verifiedAt,
          sourceId: receipt.sourceId,
          sourceVersion: receipt.sourceVersion,
          platformProvider: receipt.platformProvider,
          commercePlatform: receipt.commercePlatform,
          platformPublishLockSHA256: String(repeating: "b", count: 64),
          policySHA256: receipt.policySHA256,
          sourceProductSHA256: receipt.sourceProductSHA256,
          garmentBrand: receipt.garmentBrand,
          sellerID: receipt.sellerID,
          storefront: receipt.storefront,
          productExternalID: receipt.productExternalID,
          skuCount: receipt.skuCount,
          hasCompleteSKUSet: receipt.hasCompleteSKUSet,
          productCurrentFactFields: receipt.productCurrentFactFields,
          commonSKUCurrentFactFields: receipt.commonSKUCurrentFactFields
        ),
        to: root.appending(
          path: "API/Observed/source-verifications/product.json"
        )
      )
    }

    let sourceReceiptPath =
      "API/Observed/source-verifications/product.json"
    var approvalInputHashes = [
      "API/Config/trust-manifest.json":
        try FileDigest.sha256(
          fileAt: root.appending(path: "API/Config/trust-manifest.json")
        ),
      "API/Observed/catalog.json":
        try FileDigest.sha256(
          fileAt: root.appending(path: "API/Observed/catalog.json")
        ),
      "API/Observed/source-lock.json":
        try FileDigest.sha256(fileAt: sourceLockURL),
      "API/Config/source-manifest.json":
        try FileDigest.sha256(fileAt: sourceManifestURL),
      "API/Trusted/openapi.yaml":
        try FileDigest.sha256(
          fileAt: root.appending(path: "API/Trusted/openapi.yaml")
        ),
      "API/Trusted/operation-policies.json":
        try FileDigest.sha256(
          fileAt: root.appending(
            path: "API/Trusted/operation-policies.json"
          )
        ),
    ]
    let sourceReceiptURL = root.appending(path: sourceReceiptPath)
    if FileManager.default.fileExists(atPath: sourceReceiptURL.path) {
      approvalInputHashes[sourceReceiptPath] =
        try FileDigest.sha256(fileAt: sourceReceiptURL)
    }
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "peacebird",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: [
          "\(receipt.sourceId)@\(receipt.sourceVersion)"
        ],
        requiredCoverageAreas: [coverageArea],
        coveredCoverageAreas: [coverageArea],
        inputHashes: approvalInputHashes,
        operations: []
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
  }

  func approve() throws -> ApprovalReceipt {
    _ = try ApprovalBuilder().build(
      ApprovalBuildInput(
        providerRoot: root,
        provider: "peacebird",
        market: "cn",
        reviewer: "fixture-reviewer",
        approvedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true
      )
    )
    return try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(
        contentsOf: root.appending(
          path: "API/Trusted/approval-receipt.json"
        )
      )
    )
  }

  func publish() throws {
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: root,
        provider: "peacebird",
        market: "cn",
        publishedAt: "2026-07-29T00:00:00Z"
      )
    )
  }

  func appendToSourceReceipt(_ data: Data) throws {
    let url = root.appending(
      path: "API/Observed/source-verifications/product.json"
    )
    var receiptData = try Data(contentsOf: url)
    receiptData.append(data)
    try receiptData.write(to: url, options: .atomic)
  }

  func removeSourceReceipt() throws {
    try FileManager.default.removeItem(
      at: root.appending(
        path: "API/Observed/source-verifications/product.json"
      )
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private func makePolicy(
  requiresCurrentFacts: Bool = true,
  sourceProjection: SourceProductProjection? = nil,
  acceptedShopIDs: [String]? = nil
) -> SourceProductVerificationPolicy {
  SourceProductVerificationPolicy(
    provider: "peacebird",
    market: "cn",
    sourceId: "peacebird-jd-product",
    sourceVersion: "2026-07-29",
    platformProvider: "jd",
    commercePlatform: "jd",
    sourceProjection: sourceProjection,
    acceptedGarmentBrands: ["太平鸟", "Peacebird"],
    acceptedSellerIDs: ["1000457053"],
    acceptedShopIDs: acceptedShopIDs,
    acceptedStorefronts: ["jd"],
    requiredProductCurrentFactFields:
      requiresCurrentFacts ? ["currentPrice", "stockStatus"] : [],
    requiredSKUCurrentFactFields:
      requiresCurrentFacts ? ["currentPrice", "stockStatus"] : [],
    minimumSKUCount: 1,
    requireCompleteSKUSet: true
  )
}

private func sourceProductData(
  sourceTool: String = "jd",
  providerBrand: String = "jd",
  brand: String = "太平鸟",
  seller: String = "1000457053",
  shopID: String? = nil,
  duplicateShopAlias: Bool = false,
  includeProductPrice: Bool = true,
  includeSKUPrice: Bool = true,
  completeSKUSet: Bool = true
) -> Data {
  let productPrice =
    includeProductPrice
    ? #""currentPrice":{"amount":499,"currency":"CNY"},"#
    : ""
  let skuPrice =
    includeSKUPrice
    ? #""currentPrice":{"amount":499,"currency":"CNY"},"#
    : ""
  let shopAliases =
    shopID.map {
      let alias = #"{"kind": "shopId", "value": "\#($0)"}"#
      return duplicateShopAlias ? "\(alias),\n            \(alias)," : "\(alias),"
    } ?? ""
  return Data(
    """
    {
      "schemaVersion": 1,
      "source": {
        "sourceTool": "\(sourceTool)",
        "commercePlatform": "jd",
        "providerID": {
          "brand": "\(providerBrand)",
          "market": "cn",
          "storefront": "jd"
        },
        "brand": "\(brand)",
        "market": "cn",
        "storefront": "jd",
        "seller": "\(seller)"
      },
      "product": {
        "externalID": "sku-set-v1:peacebird",
        "aliases": {
          "aliases": [
            \(shopAliases)
            {"kind": "skuId", "value": "100259166590"}
          ]
        },
        "name": "Peacebird sample",
        "imageURLs": [],
        "currentFacts": {
          "observedAt": "2026-07-29T12:00:00Z",
          \(productPrice)
          "stockStatus": "inStock"
        }
      },
      "skus": [
        {
          "externalID": "100259166590",
          "productExternalID": "sku-set-v1:peacebird",
          "aliases": {
            "aliases": [
              {"kind": "skuId", "value": "100259166590"}
            ]
          },
          "colorName": "Brown",
          "sizeName": "S",
          "currentFacts": {
            "observedAt": "2026-07-29T12:00:00Z",
            \(skuPrice)
            "stockStatus": "inStock"
          }
        }
      ],
      "observedAt": "2026-07-29T12:00:00Z",
      "hasCompleteSKUSet": \(completeSKUSet)
    }
    """.utf8
  )
}

private struct PlatformFixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory
      .appending(
        path: "web-api-reverse-platform-\(UUID().uuidString)",
        directoryHint: .isDirectory
      )
    _ = try ProviderScaffolder().scaffold(
      providerRoot: root,
      provider: "jd",
      market: "cn"
    )
    try Data(
      """
      openapi: 3.1.0
      info:
        title: JD fixture
        version: 1.0.0
      paths: {}
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/openapi.yaml"))
    try Data(#"{"operations":[]}"#.utf8).write(
      to: root.appending(path: "API/Trusted/operation-policies.json")
    )
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "jd",
        market: "cn",
        claimedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true,
        capabilities: []
      ),
      to: root.appending(path: "API/Config/capability-claim.json")
    )
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "jd",
        market: "cn",
        updatedAt: "2026-07-29T00:00:00Z",
        operations: []
      ),
      to: root.appending(path: "API/Observed/catalog.json")
    )
    let sourceManifestURL = root.appending(
      path: "API/Config/source-manifest.json"
    )
    let sourceLockURL = root.appending(
      path: "API/Observed/source-lock.json"
    )
    try DeterministicJSON.write(
      SourceManifest(
        brand: "jd",
        market: "cn",
        requiredCoverageAreas: ["official-desktop"],
        sources: [
          ExpectedSource(
            sourceId: "jd-desktop",
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
        brand: "jd",
        market: "cn",
        requiredCoverageAreas: ["official-desktop"],
        sources: [
          SourceLockEntry(
            sourceId: "jd-desktop",
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
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "jd",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: ["jd-desktop@1"],
        requiredCoverageAreas: ["official-desktop"],
        coveredCoverageAreas: ["official-desktop"],
        inputHashes: [
          "API/Config/trust-manifest.json":
            try FileDigest.sha256(
              fileAt: root.appending(path: "API/Config/trust-manifest.json")
            ),
          "API/Observed/catalog.json":
            try FileDigest.sha256(
              fileAt: root.appending(path: "API/Observed/catalog.json")
            ),
          "API/Config/source-manifest.json":
            try FileDigest.sha256(fileAt: sourceManifestURL),
          "API/Observed/source-lock.json":
            try FileDigest.sha256(fileAt: sourceLockURL),
          "API/Trusted/openapi.yaml":
            try FileDigest.sha256(
              fileAt: root.appending(path: "API/Trusted/openapi.yaml")
            ),
          "API/Trusted/operation-policies.json":
            try FileDigest.sha256(
              fileAt: root.appending(
                path: "API/Trusted/operation-policies.json"
              )
            ),
        ],
        operations: []
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: root,
        provider: "jd",
        market: "cn",
        publishedAt: "2026-07-29T00:00:00Z"
      )
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
