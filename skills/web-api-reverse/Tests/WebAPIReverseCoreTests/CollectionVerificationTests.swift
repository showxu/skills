import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Brand-to-platform collection verification")
struct CollectionVerificationTests {
  @Test("SKU-grain collection succeeds with an exact SKU bound by a v2 source receipt")
  func verifiesExactRestoredTarget() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }

    let receipt = try fixture.verifyCollection()
    let output = fixture.collectionReceiptURL
    try CollectionVerificationReceiptWriter().write(
      receipt,
      to: output,
      providerRoot: fixture.providerRoot
    )

    #expect(receipt.provider == "peacebird")
    #expect(receipt.platformProvider == "jd")
    #expect(receipt.productExternalID == "sku-set-v1:peacebird")
    #expect(receipt.skuExternalID == "100259166590")
    #expect(receipt.restoration.proven)
    #expect(receipt.restoration.finalState == .absent)
    let sourceReceipt = try fixture.sourceReceipt()
    #expect(sourceReceipt.schemaVersion == 2)
    #expect(sourceReceipt.skuExternalIDs == ["100259166590"])
    #expect(try ArtifactScanner().scanFile(output).isEmpty)
    #expect(
      try Data(contentsOf: output)
        == DeterministicJSON.encode(receipt)
    )
  }

  @Test("Requires explicit remote-write acknowledgement")
  func requiresAcknowledgement() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }

    #expect(throws: CollectionVerificationError.allowRemoteWriteRequired) {
      try CollectionVerifier().verify(
        fixture.verificationInput(),
        allowRemoteWrite: false
      )
    }
  }

  @Test("Product-grain collection binds no SKU while retaining the source SKU graph")
  func verifiesProductGrainTarget() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.useV1SourceReceipt()
    try fixture.writeTranscript(
      action: .add,
      state: .present,
      targetGrain: .product,
      sku: nil,
      to: fixture.addTranscriptURL
    )
    try fixture.writeTranscript(
      action: .delete,
      state: .absent,
      targetGrain: .product,
      sku: nil,
      to: fixture.deleteTranscriptURL
    )

    let receipt = try fixture.verifyCollection()

    #expect(receipt.targetGrain == .product)
    #expect(receipt.skuExternalID == nil)
    let sourceReceipt = try fixture.sourceReceipt()
    #expect(sourceReceipt.schemaVersion == 1)
    #expect(sourceReceipt.skuExternalIDs == nil)
    #expect(sourceReceipt.skuCount == 1)
    #expect(sourceReceipt.hasCompleteSKUSet)

    try CollectionVerificationReceiptWriter().write(
      receipt,
      to: fixture.collectionReceiptURL,
      providerRoot: fixture.providerRoot
    )
    _ = try fixture.approve()
    try fixture.publish()
    _ = try ContractValidator().validate(providerRoot: fixture.providerRoot)
  }

  @Test("SKU-grain collection rejects a v1 source receipt")
  func rejectsV1SourceReceiptForSKUTarget() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.useV1SourceReceipt()

    #expect(
      throws: CollectionVerificationError.invalidSourceReceipt(
        "SKU-grain collection qualification requires a v2+ source-product receipt that binds the exact SKU"
      )
    ) {
      try fixture.verifyCollection()
    }
  }

  @Test(
    "Rejects wrong provider, platform, product, SKU, and cross-target delete",
    arguments: [
      TranscriptMutation.provider,
      .platform,
      .product,
      .sku,
      .deleteSKU,
      .deleteGrain,
      .productWithSKU,
      .skuWithoutSKU,
      .wrongCommand,
    ]
  )
  func rejectsWrongIdentity(_ mutation: TranscriptMutation) throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.apply(mutation)

    #expect(throws: CollectionVerificationError.self) {
      try fixture.verifyCollection()
    }
  }

  @Test(
    "Rejects no-change add and failed or non-restoring delete",
    arguments: [
      TranscriptMutation.addNoChange,
      .addAbsent,
      .deleteNoChange,
      .deletePresent,
      .deleteFailed,
    ]
  )
  func rejectsInvalidMutationOutcome(_ mutation: TranscriptMutation) throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.apply(mutation)

    #expect(throws: CollectionVerificationError.self) {
      try fixture.verifyCollection()
    }
  }

  @Test("Rejects malformed and sensitive transcripts")
  func rejectsUnsafeTranscripts() throws {
    for mutation in [
      TranscriptMutation.malformed,
      .sensitive,
    ] {
      let fixture = try CollectionFixture()
      defer { fixture.remove() }
      try fixture.apply(mutation)

      #expect(throws: CollectionVerificationError.self) {
        try fixture.verifyCollection()
      }
    }
  }

  @Test("Canonical transcript hashes ignore harmless JSON formatting")
  func acceptsNoncanonicalFormattingWithStableHash() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.apply(.nondeterministic)
    let noncanonicalData = try Data(contentsOf: fixture.addTranscriptURL)
    let canonicalTranscript = makeTranscript(
      action: .add,
      state: .present
    )
    let canonicalData = try DeterministicJSON.encode(canonicalTranscript)
    #expect(noncanonicalData != canonicalData)

    let noncanonicalReceipt = try fixture.verifyCollection()
    try canonicalData.write(to: fixture.addTranscriptURL)
    let canonicalReceipt = try fixture.verifyCollection()

    #expect(
      noncanonicalReceipt.addTranscriptSHA256
        == canonicalReceipt.addTranscriptSHA256
    )
    #expect(
      noncanonicalReceipt.evidenceFingerprint
        == canonicalReceipt.evidenceFingerprint
    )
  }

  @Test("Rejects symbolic input and durable receipt paths")
  func rejectsSymbolicLinks() throws {
    let inputFixture = try CollectionFixture()
    defer { inputFixture.remove() }
    let addLink = inputFixture.privateRoot.appending(path: "add-link.json")
    try FileManager.default.createSymbolicLink(
      at: addLink,
      withDestinationURL: inputFixture.addTranscriptURL
    )

    #expect(throws: ContractError.symbolicLink(addLink.path)) {
      try CollectionVerifier().verify(
        CollectionVerificationInput(
          providerRoot: inputFixture.providerRoot,
          provider: "peacebird",
          market: "cn",
          sourceProductReceiptURL: inputFixture.sourceReceiptURL,
          platformProviderRoot: inputFixture.platformRoot,
          addTranscriptURL: addLink,
          deleteTranscriptURL: inputFixture.deleteTranscriptURL,
          verifiedAt: CollectionFixture.verificationTime
        ),
        allowRemoteWrite: true
      )
    }

    let outputFixture = try CollectionFixture()
    defer { outputFixture.remove() }
    let receipt = try outputFixture.verifyCollection()
    try FileManager.default.createDirectory(
      at: outputFixture.collectionReceiptURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let target = outputFixture.privateRoot.appending(path: "target.json")
    try Data("{}\n".utf8).write(to: target)
    try FileManager.default.createSymbolicLink(
      at: outputFixture.collectionReceiptURL,
      withDestinationURL: target
    )

    #expect(
      throws: ContractError.symbolicLink(
        outputFixture.collectionReceiptURL.path
      )
    ) {
      try CollectionVerificationReceiptWriter().write(
        receipt,
        to: outputFixture.collectionReceiptURL,
        providerRoot: outputFixture.providerRoot
      )
    }
  }

  @Test("Rejects stale platform Published lock")
  func rejectsPlatformLockDrift() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try Data("changed\n".utf8).write(
      to: fixture.platformRoot.appending(
        path: "API/Published/openapi.yaml"
      )
    )

    #expect(throws: CollectionVerificationError.self) {
      try fixture.verifyCollection()
    }
  }

  @Test("Approval and Published validate one zero-operation capability")
  func approvesAndPublishesRemoteCollection() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.writeCollectionReceipt()

    let approval = try fixture.approve()
    let claim = try fixture.capabilityClaim()
    let remote = try #require(
      claim.capabilities.first { $0.id == "remote-collection" }
    )
    #expect(remote.availability == .supported)
    #expect(remote.operationIds.isEmpty)
    #expect(approval.operations.isEmpty)
    #expect(
      approval.inputHashes[
        "API/Observed/collection-verifications/collection.json"
      ] != nil
    )
    try fixture.publish()
    _ = try ContractValidator().validate(
      providerRoot: fixture.providerRoot
    )
  }

  @Test("Approval rejects duplicate collection receipts")
  func rejectsAmbiguousReceipts() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.writeCollectionReceipt()
    try FileManager.default.copyItem(
      at: fixture.collectionReceiptURL,
      to: fixture.collectionReceiptURL.deletingLastPathComponent()
        .appending(path: "duplicate.json")
    )

    #expect(throws: CollectionVerificationError.ambiguousReceipts) {
      _ = try fixture.approve()
    }
  }

  @Test("Published validation rejects current receipt and source hash drift")
  func rejectsDurableEvidenceDrift() throws {
    for target in [DurableMutation.collection, .source] {
      let fixture = try CollectionFixture()
      defer { fixture.remove() }
      try fixture.writeCollectionReceipt()
      _ = try fixture.approve()
      try fixture.publish()
      let url =
        target == .collection
        ? fixture.collectionReceiptURL : fixture.sourceReceiptURL
      var data = try Data(contentsOf: url)
      data.append(0x0A)
      try data.write(to: url, options: .atomic)

      #expect(throws: (any Error).self) {
        _ = try ContractValidator().validate(
          providerRoot: fixture.providerRoot
        )
      }
    }
  }

  @Test("A supported unrelated zero-operation capability remains invalid")
  func rejectsOtherZeroOperationCapability() throws {
    let fixture = try CollectionFixture()
    defer { fixture.remove() }
    try fixture.writeCollectionReceipt()
    _ = try fixture.approve()
    let claim = try fixture.capabilityClaim()
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: claim.provider,
        market: claim.market,
        claimedAt: claim.claimedAt,
        zeroUnknown: true,
        capabilities: claim.capabilities + [
          CapabilityClaimEntry(
            id: "unrelated",
            availability: .supported,
            operationIds: []
          )
        ]
      ),
      to: fixture.providerRoot.appending(
        path: "API/Config/capability-claim.json"
      )
    )

    #expect(throws: (any Error).self) {
      try fixture.publish()
    }
  }
}

enum TranscriptMutation: Sendable {
  case provider
  case platform
  case product
  case sku
  case deleteSKU
  case deleteGrain
  case productWithSKU
  case skuWithoutSKU
  case wrongCommand
  case addNoChange
  case addAbsent
  case deleteNoChange
  case deletePresent
  case deleteFailed
  case malformed
  case nondeterministic
  case sensitive
}

private enum DurableMutation {
  case collection
  case source
}

private struct CollectionFixture {
  static let verificationTime = "2026-08-06T00:00:00Z"

  let root: URL
  let platformRoot: URL
  let providerRoot: URL
  let privateRoot: URL
  let sourceReceiptURL: URL
  let collectionReceiptURL: URL
  let addTranscriptURL: URL
  let deleteTranscriptURL: URL

  init() throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "collection-verification-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    platformRoot = root.appending(path: "platform")
    providerRoot = root.appending(path: "provider")
    privateRoot = root.appending(path: "private")
    sourceReceiptURL = providerRoot.appending(
      path: "API/Observed/source-verifications/product.json"
    )
    collectionReceiptURL = providerRoot.appending(
      path: "API/Observed/collection-verifications/collection.json"
    )
    addTranscriptURL = privateRoot.appending(path: "add.json")
    deleteTranscriptURL = privateRoot.appending(path: "delete.json")

    try makePlatform()
    _ = try ProviderScaffolder().scaffold(providerRoot: providerRoot)
    try FileManager.default.createDirectory(
      at: privateRoot,
      withIntermediateDirectories: true
    )
    let policy = sourcePolicy()
    try DeterministicJSON.write(
      policy,
      to: providerRoot.appending(
        path: "API/Config/jd-source-product-policy.json"
      )
    )
    let sourceReceipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: sourceProductData(),
        platformProviderRoot: platformRoot
      )
    )
    try DeterministicJSON.write(sourceReceipt, to: sourceReceiptURL)
    try writeProviderContract(sourceReceipt: sourceReceipt)
    try writeTranscript(
      action: .add,
      state: .present,
      to: addTranscriptURL
    )
    try writeTranscript(
      action: .delete,
      state: .absent,
      to: deleteTranscriptURL
    )
  }

  func verificationInput() -> CollectionVerificationInput {
    CollectionVerificationInput(
      providerRoot: providerRoot,
      provider: "peacebird",
      market: "cn",
      sourceProductReceiptURL: sourceReceiptURL,
      platformProviderRoot: platformRoot,
      addTranscriptURL: addTranscriptURL,
      deleteTranscriptURL: deleteTranscriptURL,
      verifiedAt: Self.verificationTime
    )
  }

  func verifyCollection() throws -> CollectionVerificationReceipt {
    try CollectionVerifier().verify(
      verificationInput(),
      allowRemoteWrite: true
    )
  }

  func sourceReceipt() throws -> SourceProductVerificationReceipt {
    try DeterministicJSON.decode(
      SourceProductVerificationReceipt.self,
      from: Data(contentsOf: sourceReceiptURL)
    )
  }

  func useV1SourceReceipt() throws {
    let current = try sourceReceipt()
    let fingerprint = try sourceProductV1Fingerprint(current)
    let receipt = SourceProductVerificationReceipt(
      provider: current.provider,
      market: current.market,
      verificationId: "spv_\(fingerprint.prefix(16))",
      evidenceFingerprint: fingerprint,
      verifiedAt: current.verifiedAt,
      sourceId: current.sourceId,
      sourceVersion: current.sourceVersion,
      platformProvider: current.platformProvider,
      commercePlatform: current.commercePlatform,
      platformPublishLockSHA256: current.platformPublishLockSHA256,
      policySHA256: current.policySHA256,
      sourceProductSHA256: current.sourceProductSHA256,
      garmentBrand: current.garmentBrand,
      sellerID: current.sellerID,
      storefront: current.storefront,
      productExternalID: current.productExternalID,
      skuCount: current.skuCount,
      hasCompleteSKUSet: current.hasCompleteSKUSet,
      productCurrentFactFields: current.productCurrentFactFields,
      commonSKUCurrentFactFields: current.commonSKUCurrentFactFields,
      schemaVersion: 1
    )
    try SourceProductVerifier.validate(receipt)
    try DeterministicJSON.write(receipt, to: sourceReceiptURL)
    try writeProviderContract(sourceReceipt: receipt)
  }

  func writeCollectionReceipt() throws {
    try CollectionVerificationReceiptWriter().write(
      verifyCollection(),
      to: collectionReceiptURL,
      providerRoot: providerRoot
    )
  }

  func approve() throws -> ApprovalReceipt {
    _ = try ApprovalBuilder().build(
      ApprovalBuildInput(
        providerRoot: providerRoot,
        provider: "peacebird",
        market: "cn",
        reviewer: "fixture-reviewer",
        approvedAt: Self.verificationTime,
        zeroUnknown: true
      )
    )
    return try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(
        contentsOf: providerRoot.appending(
          path: "API/Trusted/approval-receipt.json"
        )
      )
    )
  }

  func capabilityClaim() throws -> CapabilityClaim {
    try DeterministicJSON.decode(
      CapabilityClaim.self,
      from: Data(
        contentsOf: providerRoot.appending(
          path: "API/Config/capability-claim.json"
        )
      )
    )
  }

  func publish() throws {
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: providerRoot,
        provider: "peacebird",
        market: "cn",
        publishedAt: Self.verificationTime
      )
    )
  }

  func apply(_ mutation: TranscriptMutation) throws {
    switch mutation {
    case .provider:
      try writeTranscript(
        action: .add,
        state: .present,
        provider: "other",
        to: addTranscriptURL
      )
    case .platform:
      try writeTranscript(
        action: .add,
        state: .present,
        platform: "taobao",
        to: addTranscriptURL
      )
    case .product:
      try writeTranscript(
        action: .add,
        state: .present,
        product: "other-product",
        to: addTranscriptURL
      )
    case .sku:
      try writeTranscript(
        action: .add,
        state: .present,
        sku: "other-sku",
        to: addTranscriptURL
      )
    case .deleteSKU:
      try writeTranscript(
        action: .delete,
        state: .absent,
        sku: "100259166591",
        to: deleteTranscriptURL
      )
    case .deleteGrain:
      try writeTranscript(
        action: .delete,
        state: .absent,
        targetGrain: .product,
        sku: nil,
        to: deleteTranscriptURL
      )
    case .productWithSKU:
      try writeTranscript(
        action: .add,
        state: .present,
        targetGrain: .product,
        sku: "100259166590",
        to: addTranscriptURL
      )
    case .skuWithoutSKU:
      let transcript = CollectionMutationTranscript(
        ok: true,
        command: "peacebird.wishlist.add",
        data: CollectionMutationTranscriptData(
          provider: "peacebird",
          market: "cn",
          platformProvider: "jd",
          productExternalID: "sku-set-v1:peacebird",
          targetGrain: .sku,
          skuExternalID: nil,
          action: .add,
          verificationCode: "platform-confirmed-change",
          remoteState: .present
        )
      )
      try DeterministicJSON.write(transcript, to: addTranscriptURL)
    case .wrongCommand:
      try DeterministicJSON.write(
        CollectionMutationTranscript(
          ok: true,
          command: "peacebird.product.add",
          data: makeTranscript(
            action: .add,
            state: .present
          ).data
        ),
        to: addTranscriptURL
      )
    case .addNoChange:
      try writeTranscript(
        action: .add,
        state: .present,
        code: "platform-already-in-state",
        to: addTranscriptURL
      )
    case .addAbsent:
      try writeTranscript(
        action: .add,
        state: .absent,
        to: addTranscriptURL
      )
    case .deleteNoChange:
      try writeTranscript(
        action: .delete,
        state: .absent,
        code: "platform-already-in-state",
        to: deleteTranscriptURL
      )
    case .deletePresent:
      try writeTranscript(
        action: .delete,
        state: .present,
        to: deleteTranscriptURL
      )
    case .deleteFailed:
      try DeterministicJSON.write(
        CollectionMutationTranscript(
          ok: false,
          command: "peacebird.wishlist.delete",
          error: CommandErrorPayload(
            code: "remote.failed",
            message: "Remote delete failed."
          )
        ),
        to: deleteTranscriptURL
      )
    case .malformed:
      try Data("{\"ok\":true}\n".utf8).write(to: addTranscriptURL)
    case .nondeterministic:
      let transcript = makeTranscript(action: .add, state: .present)
      let object = try JSONSerialization.jsonObject(
        with: DeterministicJSON.encode(transcript)
      )
      try JSONSerialization.data(withJSONObject: object).write(
        to: addTranscriptURL
      )
    case .sensitive:
      try Data(
        """
        {
          "command":"peacebird.wishlist.add",
          "data":{
            "action":"add",
            "authorization":"Bearer abcdefghijklmnopqrstuvwxyz",
            "market":"cn",
            "platformProvider":"jd",
            "productExternalID":"sku-set-v1:peacebird",
            "provider":"peacebird",
            "remoteState":"present",
            "skuExternalID":"100259166590",
            "targetGrain":"sku",
            "verificationCode":"platform-confirmed-change"
          },
          "ok":true,
          "schemaVersion":1
        }
        """.utf8
      ).write(to: addTranscriptURL)
    }
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }

  private func makePlatform() throws {
    _ = try ProviderScaffolder().scaffold(providerRoot: platformRoot)
    try Data(
      """
      openapi: 3.1.0
      info:
        title: JD fixture
        version: 1.0.0
      paths: {}
      """.utf8
    ).write(to: platformRoot.appending(path: "API/Trusted/openapi.yaml"))
    try Data(#"{"operations":[]}"#.utf8).write(
      to: platformRoot.appending(
        path: "API/Trusted/operation-policies.json"
      )
    )
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "jd",
        market: "cn",
        claimedAt: Self.verificationTime,
        zeroUnknown: true,
        capabilities: []
      ),
      to: platformRoot.appending(
        path: "API/Config/capability-claim.json"
      )
    )
    try DeterministicJSON.write(
      TrustManifest(
        brand: "jd",
        market: "cn",
        reviewedAt: Self.verificationTime,
        operations: []
      ),
      to: platformRoot.appending(path: "API/Config/trust-manifest.json")
    )
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "jd",
        market: "cn",
        updatedAt: Self.verificationTime,
        operations: []
      ),
      to: platformRoot.appending(path: "API/Observed/catalog.json")
    )
    let manifestURL = platformRoot.appending(
      path: "API/Config/source-manifest.json"
    )
    let lockURL = platformRoot.appending(
      path: "API/Observed/source-lock.json"
    )
    try writeSourceLifecycle(
      provider: "jd",
      coverageArea: "official-desktop",
      manifestURL: manifestURL,
      lockURL: lockURL,
      sourceID: "jd-desktop"
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "jd",
        market: "cn",
        approvedAt: Self.verificationTime,
        reviewer: "fixture-reviewer",
        sourceRevisions: ["jd-desktop@1"],
        requiredCoverageAreas: ["official-desktop"],
        coveredCoverageAreas: ["official-desktop"],
        inputHashes: try canonicalApprovalInputHashes(
          providerRoot: platformRoot
        ),
        operations: []
      ),
      to: platformRoot.appending(
        path: "API/Trusted/approval-receipt.json"
      )
    )
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: platformRoot,
        provider: "jd",
        market: "cn",
        publishedAt: Self.verificationTime
      )
    )
  }

  private func writeProviderContract(
    sourceReceipt: SourceProductVerificationReceipt
  ) throws {
    try Data(
      """
      openapi: 3.1.0
      info:
        title: Peacebird fixture
        version: 1.0.0
      paths: {}
      """.utf8
    ).write(to: providerRoot.appending(path: "API/Trusted/openapi.yaml"))
    try Data(#"{"operations":[]}"#.utf8).write(
      to: providerRoot.appending(
        path: "API/Trusted/operation-policies.json"
      )
    )
    try DeterministicJSON.write(
      TrustManifest(
        brand: "peacebird",
        market: "cn",
        reviewedAt: Self.verificationTime,
        operations: []
      ),
      to: providerRoot.appending(path: "API/Config/trust-manifest.json")
    )
    try DeterministicJSON.write(
      ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "peacebird",
        market: "cn",
        updatedAt: Self.verificationTime,
        operations: []
      ),
      to: providerRoot.appending(path: "API/Observed/catalog.json")
    )
    let manifestURL = providerRoot.appending(
      path: "API/Config/source-manifest.json"
    )
    let lockURL = providerRoot.appending(
      path: "API/Observed/source-lock.json"
    )
    try DeterministicJSON.write(
      SourceManifest(
        brand: "peacebird",
        market: "cn",
        requiredCoverageAreas: ["selected-platform-current-facts"],
        sources: [
          ExpectedSource(
            sourceId: sourceReceipt.sourceId,
            surface: .web,
            version: sourceReceipt.sourceVersion,
            coverageAreas: ["selected-platform-current-facts"],
            coveragePolicy: .required,
            status: .captured
          )
        ]
      ),
      to: manifestURL
    )
    try DeterministicJSON.write(
      SourceLock(
        schemaVersion: 1,
        kind: "web-api-reverse.source-lock",
        brand: "peacebird",
        market: "cn",
        requiredCoverageAreas: ["selected-platform-current-facts"],
        sources: [
          SourceLockEntry(
            sourceId: sourceReceipt.sourceId,
            surface: .web,
            version: sourceReceipt.sourceVersion,
            coverageAreas: ["selected-platform-current-facts"],
            coveragePolicy: .required,
            coverageRationale: nil,
            sha256: sourceReceipt.sourceProductSHA256,
            status: .captured,
            capturedAt: sourceReceipt.verifiedAt,
            captureIds: [],
            operationFingerprints: [],
            evidenceFingerprints: [sourceReceipt.evidenceFingerprint]
          )
        ]
      ),
      to: lockURL
    )
  }

  func writeTranscript(
    action: CollectionMutationAction,
    state: CollectionRemoteState,
    provider: String = "peacebird",
    platform: String = "jd",
    product: String = "sku-set-v1:peacebird",
    targetGrain: CollectionTargetGrain = .sku,
    sku: String? = "100259166590",
    code: String = "platform-confirmed-change",
    to url: URL
  ) throws {
    try DeterministicJSON.write(
      makeTranscript(
        action: action,
        state: state,
        provider: provider,
        platform: platform,
        product: product,
        targetGrain: targetGrain,
        sku: sku,
        code: code
      ),
      to: url
    )
  }
}

private func canonicalApprovalInputHashes(
  providerRoot: URL
) throws -> [String: String] {
  try Dictionary(
    uniqueKeysWithValues: ApprovalInputPathPolicy.requiredPaths.map { path in
      (
        path,
        try FileDigest.sha256(fileAt: providerRoot.appending(path: path))
      )
    }
  )
}

private func makeTranscript(
  action: CollectionMutationAction,
  state: CollectionRemoteState,
  provider: String = "peacebird",
  platform: String = "jd",
  product: String = "sku-set-v1:peacebird",
  targetGrain: CollectionTargetGrain = .sku,
  sku: String? = "100259166590",
  code: String = "platform-confirmed-change"
) -> CollectionMutationTranscript {
  CollectionMutationTranscript(
    ok: true,
    command: "\(provider).wishlist.\(action.rawValue)",
    data: CollectionMutationTranscriptData(
      provider: provider,
      market: "cn",
      platformProvider: platform,
      productExternalID: product,
      targetGrain: targetGrain,
      skuExternalID: sku,
      action: action,
      verificationCode: code,
      remoteState: state
    )
  )
}

private func sourcePolicy() -> SourceProductVerificationPolicy {
  SourceProductVerificationPolicy(
    provider: "peacebird",
    market: "cn",
    sourceId: "peacebird-jd-product",
    sourceVersion: "2026-08-06",
    platformProvider: "jd",
    commercePlatform: "jd",
    acceptedGarmentBrands: ["Peacebird"],
    acceptedSellerIDs: ["seller-1"],
    acceptedStorefronts: ["jd"],
    requiredProductCurrentFactFields: ["currentPrice", "stockStatus"],
    requiredSKUCurrentFactFields: ["currentPrice", "stockStatus"],
    minimumSKUCount: 1,
    requireCompleteSKUSet: true
  )
}

private func sourceProductData() -> Data {
  Data(
    """
    {
      "hasCompleteSKUSet": true,
      "observedAt": "2026-08-06T00:00:00Z",
      "product": {
        "aliases": {"aliases": [{"kind": "style", "value": "peacebird"}]},
        "currentFacts": {
          "currentPrice": {"amount": 499, "currency": "CNY"},
          "observedAt": "2026-08-06T00:00:00Z",
          "stockStatus": "inStock"
        },
        "externalID": "sku-set-v1:peacebird",
        "imageURLs": []
      },
      "schemaVersion": 1,
      "skus": [
        {
          "aliases": {"aliases": [{"kind": "skuId", "value": "100259166590"}]},
          "currentFacts": {
            "currentPrice": {"amount": 499, "currency": "CNY"},
            "observedAt": "2026-08-06T00:00:00Z",
            "stockStatus": "inStock"
          },
          "externalID": "100259166590",
          "productExternalID": "sku-set-v1:peacebird"
        }
      ],
      "source": {
        "brand": "Peacebird",
        "commercePlatform": "jd",
        "market": "cn",
        "providerID": {"brand": "jd", "market": "cn", "storefront": "jd"},
        "seller": "seller-1",
        "sourceTool": "jd",
        "storefront": "jd"
      }
    }
    """.utf8
  )
}

private struct SourceProductV1Fingerprint: Codable {
  let provider: String
  let market: String
  let sourceId: String
  let sourceVersion: String
  let platformProvider: String
  let platformPublishLockSHA256: String
  let policySHA256: String
  let sourceProductSHA256: String
}

private func sourceProductV1Fingerprint(
  _ receipt: SourceProductVerificationReceipt
) throws -> String {
  FileDigest.sha256(
    data: try DeterministicJSON.encode(
      SourceProductV1Fingerprint(
        provider: receipt.provider,
        market: receipt.market,
        sourceId: receipt.sourceId,
        sourceVersion: receipt.sourceVersion,
        platformProvider: receipt.platformProvider,
        platformPublishLockSHA256: receipt.platformPublishLockSHA256,
        policySHA256: receipt.policySHA256,
        sourceProductSHA256: receipt.sourceProductSHA256
      )
    )
  )
}

private func writeSourceLifecycle(
  provider: String,
  coverageArea: String,
  manifestURL: URL,
  lockURL: URL,
  sourceID: String
) throws {
  try DeterministicJSON.write(
    SourceManifest(
      brand: provider,
      market: "cn",
      requiredCoverageAreas: [coverageArea],
      sources: [
        ExpectedSource(
          sourceId: sourceID,
          surface: .web,
          version: "1",
          coverageAreas: [coverageArea],
          coveragePolicy: .required,
          status: .captured
        )
      ]
    ),
    to: manifestURL
  )
  try DeterministicJSON.write(
    SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: provider,
      market: "cn",
      requiredCoverageAreas: [coverageArea],
      sources: [
        SourceLockEntry(
          sourceId: sourceID,
          surface: .web,
          version: "1",
          coverageAreas: [coverageArea],
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: String(repeating: "a", count: 64),
          status: .captured,
          capturedAt: CollectionFixture.verificationTime,
          captureIds: [],
          operationFingerprints: []
        )
      ]
    ),
    to: lockURL
  )
}
