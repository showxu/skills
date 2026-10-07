import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Reversible write verification")
struct ReversibleVerificationTests {
  @Test("Proves one intended addition and exact reciprocal restoration")
  func verifiesSuccessfulSequence() async throws {
    let executor = WishlistVerificationExecutor(mode: .success)
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }

    let result = try await ReversibleOperationVerifier(
      executor: executor
    ).verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )

    #expect(
      await executor.paths() == [
        "/wishlist",
        "/wishlist/add",
        "/wishlist",
        "/wishlist/remove",
        "/wishlist",
      ]
    )
    #expect(await executor.identities() == ["existing-sku"])
    #expect(
      result.sequence.state.beforeSHA256
        == result.sequence.state.restoredSHA256
    )
    #expect(
      result.sequence.state.beforeSHA256
        != result.sequence.state.mutatedSHA256
    )
    #expect(result.sequence.state.changedIdentityCount == 1)
    #expect(result.sequence.state.beforeCount == 1)
    #expect(result.sequence.state.mutatedCount == 2)
    #expect(result.sequence.state.restoredCount == 1)
    #expect(result.receipts.add.restoration?.proven == true)
    #expect(result.receipts.remove.restoration?.proven == true)
    #expect(
      result.receipts.add.restoration?.receiptId
        == result.receipts.remove.verificationId
    )
    #expect(
      result.receipts.remove.restoration?.receiptId
        == result.receipts.add.verificationId
    )
    #expect(
      result.receipts.add.restoration
        == result.receipts.remove.restoration.map {
          TrustRestorationProof(
            required: $0.required,
            proven: $0.proven,
            receiptId: result.receipts.remove.verificationId,
            beforeStateSHA256: $0.beforeStateSHA256,
            mutatedStateSHA256: $0.mutatedStateSHA256,
            restoredStateSHA256: $0.restoredStateSHA256,
            changedIdentitySHA256: $0.changedIdentitySHA256,
            changedIdentityCount: $0.changedIdentityCount
          )
        }
    )

    let durable = String(
      decoding: try DeterministicJSON.encode(result),
      as: UTF8.self
    )
    #expect(!durable.contains("private-session-cookie"))
  }

  @Test("Projects an exact reversible collection from HTML")
  func verifiesServerRenderedHTMLSequence() async throws {
    let executor = HTMLFavoriteVerificationExecutor()
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let plan = ReversibleVerificationPlan(
      provider: fixture.plan.provider,
      market: fixture.plan.market,
      readBefore: fixture.plan.readBefore,
      add: fixture.plan.add,
      readMutated: fixture.plan.readMutated,
      remove: fixture.plan.remove,
      readRestored: fixture.plan.readRestored,
      stateProjection: ReversibleCollectionProjection(
        collectionPointer: "/",
        identityPointers: [
          ReversibleIdentityProjection(path: "/capture/1")
        ],
        intendedIdentity: [.string("probe-sku")],
        textCollection: ReversibleTextCollectionProjection(
          pattern:
            #"<a(?=[^>]*\bgid\s*=\s*["']([A-Za-z0-9-]+)["'])(?=[^>]*\bclass\s*=\s*["'][^"']*\bdel\b)[^>]*>"#,
          identityCaptureGroups: [1]
        )
      )
    )

    let result = try await ReversibleOperationVerifier(
      executor: executor
    ).verify(
      catalog: fixture.catalog,
      plan: plan,
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )

    #expect(result.sequence.state.beforeCount == 1)
    #expect(result.sequence.state.mutatedCount == 2)
    #expect(result.sequence.state.restoredCount == 1)
    #expect(
      result.sequence.state.beforeSHA256
        == result.sequence.state.restoredSHA256
    )
    #expect(result.sequence.textPatternSHA256 != nil)
    #expect(result.sequence.textIdentityCaptureGroups == [1])
    #expect(
      Set([
        result.sequence.verificationIds.readBefore,
        result.sequence.verificationIds.readMutated,
        result.sequence.verificationIds.readRestored,
      ]).count == 3
    )
    #expect(await executor.identities() == ["existing-sku"])
  }

  @Test("Rejects an add that changes more than the intended identity")
  func rejectsMutationMismatchAndRestores() async throws {
    let executor = WishlistVerificationExecutor(mode: .extraAddition)
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }

    await #expect(
      throws: ReversibleVerificationError.mutationIdentityMismatch
    ) {
      try await ReversibleOperationVerifier(
        executor: executor
      ).verify(
        catalog: fixture.catalog,
        plan: fixture.plan,
        allowRemoteWrite: true,
        verifiedAt: "2026-07-29T12:00:00Z",
        transactionStore: transaction.store
      )
    }

    #expect(
      await executor.paths() == [
        "/wishlist",
        "/wishlist/add",
        "/wishlist",
        "/wishlist/remove",
        "/wishlist",
      ]
    )
    #expect(await executor.identities() == ["existing-sku"])
  }

  @Test("Restoration runs after the mutated-state read throws")
  func restoresAfterMutationPhaseFailure() async throws {
    let executor = WishlistVerificationExecutor(
      mode: .failMutatedRead
    )
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }

    await #expect(throws: ReversibleFixtureError.mutatedReadFailed) {
      try await ReversibleOperationVerifier(
        executor: executor
      ).verify(
        catalog: fixture.catalog,
        plan: fixture.plan,
        allowRemoteWrite: true,
        verifiedAt: "2026-07-29T12:00:00Z",
        transactionStore: transaction.store
      )
    }

    #expect(
      await executor.paths() == [
        "/wishlist",
        "/wishlist/add",
        "/wishlist",
        "/wishlist/remove",
        "/wishlist",
      ]
    )
    #expect(await executor.identities() == ["existing-sku"])
  }

  @Test("Remote writes require approval and reversible safety")
  func rejectsUnsafePlansBeforeExecution() async throws {
    let executor = WishlistVerificationExecutor(mode: .success)
    let verifier = ReversibleOperationVerifier(executor: executor)
    let fixture = try reversibleFixture()

    await #expect(
      throws: ReversibleVerificationError.allowRemoteWriteRequired
    ) {
      try await verifier.verify(
        catalog: fixture.catalog,
        plan: fixture.plan
      )
    }
    let highRisk = try reversibleFixture(addSafety: .highRiskWrite)
    await #expect(
      throws: ReversibleVerificationError.highRiskMutationRejected(.add)
    ) {
      try await verifier.verify(
        catalog: highRisk.catalog,
        plan: highRisk.plan,
        allowRemoteWrite: true
      )
    }
    let nonReversible = try reversibleFixture(addSafety: .safeRead)
    await #expect(
      throws: ReversibleVerificationError.mutationMustBeReversible(.add)
    ) {
      try await verifier.verify(
        catalog: nonReversible.catalog,
        plan: nonReversible.plan,
        allowRemoteWrite: true
      )
    }

    #expect(await executor.paths().isEmpty)
  }

  @Test("Reports the exact reversible phase for stable request shape drift")
  func reportsRequestShapeMismatchPhase() async throws {
    let executor = WishlistVerificationExecutor(mode: .success)
    let fixture = try reversibleFixture()
    let request = fixture.plan.add.request
    var driftedHeaders = request.headers
    driftedHeaders["content-type"] = "text/plain"
    let driftedRequest = PrivateVerificationRequestSpec(
      brand: request.brand,
      market: request.market,
      safety: request.safety,
      url: request.url,
      method: request.method,
      headers: driftedHeaders,
      body: request.body
    )
    let driftedPlan = ReversibleVerificationPlan(
      provider: fixture.plan.provider,
      market: fixture.plan.market,
      readBefore: fixture.plan.readBefore,
      add: ReversibleVerificationStep(
        operationId: fixture.plan.add.operationId,
        request: driftedRequest
      ),
      readMutated: fixture.plan.readMutated,
      remove: fixture.plan.remove,
      readRestored: fixture.plan.readRestored,
      stateProjection: fixture.plan.stateProjection
    )

    do {
      _ = try await ReversibleOperationVerifier(
        executor: executor
      ).verify(
        catalog: fixture.catalog,
        plan: driftedPlan,
        allowRemoteWrite: true
      )
      Issue.record("Expected request fingerprint drift to fail.")
    } catch let error as ReversibleVerificationError {
      guard
        case .requestShapeMismatch(
          let phase,
          let fields
        ) = error
      else {
        Issue.record("Unexpected error: \(error)")
        return
      }
      #expect(phase == .add)
      #expect(fields == ["contentType"])
    }

    #expect(await executor.paths().isEmpty)
  }

  @Test("Browser-only headers and cookie churn do not invalidate native replay")
  func acceptsBrowserHeaderAndCookieChurn() async throws {
    let executor = WishlistVerificationExecutor(mode: .success)
    let fixture = try reversibleFixture(observedBrowserMetadata: true)
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }

    let result = try await ReversibleOperationVerifier(
      executor: executor
    ).verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )

    #expect(result.sequence.state.beforeCount == 1)
    #expect(result.sequence.state.restoredCount == 1)
    #expect(await executor.identities() == ["existing-sku"])
  }

  @Test("Missing operations and catalog scope drift fail before network")
  func rejectsCatalogOwnershipViolations() async throws {
    let executor = WishlistVerificationExecutor(mode: .success)
    let verifier = ReversibleOperationVerifier(executor: executor)
    let fixture = try reversibleFixture()
    let missingPlan = replacingAddOperationId(
      fixture.plan,
      with: "wishlist.missing"
    )

    await #expect(
      throws: ReversibleVerificationError.observedOperationMissing(
        "wishlist.missing"
      )
    ) {
      try await verifier.verify(
        catalog: fixture.catalog,
        plan: missingPlan,
        allowRemoteWrite: true
      )
    }
    let mismatchedCatalog = ObservedCatalog(
      schemaVersion: fixture.catalog.schemaVersion,
      kind: fixture.catalog.kind,
      brand: "other-provider",
      market: fixture.catalog.market,
      updatedAt: fixture.catalog.updatedAt,
      operations: fixture.catalog.operations
    )
    await #expect(
      throws: ReversibleVerificationError.scopeMismatch(
        "plan fixture/cn vs catalog other-provider/cn"
      )
    ) {
      try await verifier.verify(
        catalog: mismatchedCatalog,
        plan: fixture.plan,
        allowRemoteWrite: true
      )
    }

    #expect(await executor.paths().isEmpty)
  }

  @Test("Writes one exact atomic reversible evidence directory")
  func writesExactArtifactSet() async throws {
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let result = try await ReversibleOperationVerifier(
      executor: WishlistVerificationExecutor(mode: .success)
    ).verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )
    let root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-reversible-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: root)
    }

    let writer = ReversibleVerificationArtifactWriter()
    let first = try writer.write(result, under: root)
    let stale = URL(fileURLWithPath: first.directory)
      .appending(path: "stale.json")
    try Data("{}".utf8).write(to: stale)
    let second = try writer.write(result, under: root)

    #expect(first == second)
    #expect(
      try FileManager.default.contentsOfDirectory(
        atPath: second.directory
      ).sorted() == [
        "add.json",
        "read-before.json",
        "read-mutated.json",
        "read-restored.json",
        "remove.json",
        "sequence.json",
      ]
    )
    let persistedSequence = try DeterministicJSON.decode(
      ReversibleVerificationSequenceReceipt.self,
      from: Data(contentsOf: URL(fileURLWithPath: second.sequence))
    )
    let persistedAdd = try DeterministicJSON.decode(
      TrustVerificationReceipt.self,
      from: Data(contentsOf: URL(fileURLWithPath: second.add))
    )
    #expect(persistedSequence == result.sequence)
    #expect(persistedAdd == result.receipts.add)
    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test(
    "Reversible evidence replacement recovers every durable directory phase",
    arguments: [
      DurableDirectoryReplacementInterruptionPoint.afterReadyJournal,
      .afterDirectorySwap,
      .afterCommittedJournal,
    ]
  )
  func reversibleEvidenceRecoversInterruptedReplacement(
    point: DurableDirectoryReplacementInterruptionPoint
  ) async throws {
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let result = try await ReversibleOperationVerifier(
      executor: WishlistVerificationExecutor(mode: .success)
    ).verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )
    let root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-evidence-recovery-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    _ = try ReversibleVerificationArtifactWriter().write(result, under: root)

    #expect(throws: ReversibleVerificationArtifactError.self) {
      _ = try ReversibleVerificationArtifactWriter(
        interruptionPoint: point
      ).write(result, under: root)
    }
    let recovered = try ReversibleVerificationArtifactWriter().write(
      result,
      under: root
    )
    #expect(
      try FileManager.default.contentsOfDirectory(atPath: recovered.directory)
        .sorted() == [
          "add.json",
          "read-before.json",
          "read-mutated.json",
          "read-restored.json",
          "remove.json",
          "sequence.json",
        ]
    )
    let rootNames = try FileManager.default.contentsOfDirectory(atPath: root.path)
    #expect(rootNames == [result.sequence.sequenceId])
  }

  @Test("Reconciles a durable add-confirmed checkpoint before another write")
  func reconcilesInterruptedMutationBeforeNewVerification() async throws {
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let targetIdentity = try CanonicalEvidenceJSON.string(
      .array([.string("probe-sku")])
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    let beforeIdentity = try CanonicalEvidenceJSON.string(
      .array([.string("existing-sku")])
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    let beforeDigest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(
        .array([.string(beforeIdentity)])
      )
    )
    try transaction.store.save(
      ReversibleVerificationCheckpoint(
        phase: .addConfirmed,
        catalog: fixture.catalog,
        plan: fixture.plan,
        sessionSeed: privateSessionSeed(),
        verifiedAt: "2026-07-29T12:00:00Z",
        beforeIdentities: [beforeIdentity],
        beforeDigest: beforeDigest,
        targetIdentity: targetIdentity
      )
    )
    let executor = WishlistVerificationExecutor(
      mode: .success,
      initialIdentities: ["existing-sku", "probe-sku"]
    )

    await #expect(
      throws: ReversibleVerificationError.pendingTransactionReconciled
    ) {
      _ = try await ReversibleOperationVerifier(
        executor: executor
      ).verify(
        catalog: fixture.catalog,
        plan: fixture.plan,
        sessionSeed: privateSessionSeed(),
        allowRemoteWrite: true,
        verifiedAt: "2026-07-29T12:00:00Z",
        transactionStore: transaction.store
      )
    }

    #expect(await executor.identities() == ["existing-sku"])
    #expect(
      await executor.paths()
        == ["/wishlist", "/wishlist/remove", "/wishlist"]
    )
    #expect(try transaction.store.load() == nil)
  }

  @Test("Never deletes an unattributed target after an interrupted dispatch")
  func preservesExternalTargetForAmbiguousCheckpoints() async throws {
    let fixture = try reversibleFixture()
    let targetIdentity = try CanonicalEvidenceJSON.string(
      .array([.string("probe-sku")])
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    let beforeIdentity = try CanonicalEvidenceJSON.string(
      .array([.string("existing-sku")])
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    let beforeDigest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(
        .array([.string(beforeIdentity)])
      )
    )

    for phase in [
      ReversibleVerificationTransactionPhase.prepared,
      .addDispatchUnknown,
    ] {
      let transaction = try transactionStore()
      defer { try? FileManager.default.removeItem(at: transaction.root) }
      try transaction.store.save(
        ReversibleVerificationCheckpoint(
          phase: phase,
          catalog: fixture.catalog,
          plan: fixture.plan,
          sessionSeed: privateSessionSeed(),
          verifiedAt: "2026-07-29T12:00:00Z",
          beforeIdentities: [beforeIdentity],
          beforeDigest: beforeDigest,
          targetIdentity: targetIdentity
        )
      )
      let executor = WishlistVerificationExecutor(
        mode: .success,
        initialIdentities: ["existing-sku", "probe-sku"]
      )

      await #expect(throws: ReversibleVerificationError.self) {
        _ = try await ReversibleOperationVerifier(
          executor: executor
        ).verify(
          catalog: fixture.catalog,
          plan: fixture.plan,
          sessionSeed: privateSessionSeed(),
          allowRemoteWrite: true,
          verifiedAt: "2026-07-29T12:00:00Z",
          transactionStore: transaction.store
        )
      }

      #expect(
        await executor.identities()
          == ["existing-sku", "probe-sku"]
      )
      #expect(await executor.paths() == ["/wishlist"])
      #expect(try transaction.store.load()?.phase == phase)
    }
  }

  @Test("Completed evidence replays without repeating the remote write")
  func replaysCompletedResultUntilArtifactAcknowledgement() async throws {
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let executor = WishlistVerificationExecutor(mode: .success)
    let verifier = ReversibleOperationVerifier(executor: executor)
    let first = try await verifier.verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )
    let firstPaths = await executor.paths()

    let replayed = try await verifier.verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )

    #expect(replayed == first)
    #expect(await executor.paths() == firstPaths)
    try await transaction.store.acknowledgeCompletion(
      sequenceId: first.sequence.sequenceId
    )
    #expect(try transaction.store.load() == nil)
  }

  @Test("Completed evidence is bound to the exact verification input")
  func rejectsCompletedResultForDifferentSessionInput() async throws {
    let fixture = try reversibleFixture()
    let transaction = try transactionStore()
    defer { try? FileManager.default.removeItem(at: transaction.root) }
    let executor = WishlistVerificationExecutor(mode: .success)
    let verifier = ReversibleOperationVerifier(executor: executor)
    _ = try await verifier.verify(
      catalog: fixture.catalog,
      plan: fixture.plan,
      sessionSeed: privateSessionSeed(),
      allowRemoteWrite: true,
      verifiedAt: "2026-07-29T12:00:00Z",
      transactionStore: transaction.store
    )
    let pathsAfterFirstVerification = await executor.paths()
    let differentSeed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "different-profile",
      createdAt: "2026-07-29T00:00:00Z",
      sourceURL: "https://api.example.test/login",
      cookies: privateSessionSeed().cookies,
      origins: []
    )

    await #expect(
      throws: ReversibleVerificationError.transactionInputMismatch
    ) {
      _ = try await verifier.verify(
        catalog: fixture.catalog,
        plan: fixture.plan,
        sessionSeed: differentSeed,
        allowRemoteWrite: true,
        verifiedAt: "2026-07-29T12:00:00Z",
        transactionStore: transaction.store
      )
    }

    #expect(await executor.paths() == pathsAfterFirstVerification)
    #expect(try transaction.store.load()?.phase == .completed)
  }
}

private enum ReversibleFixtureMode {
  case success
  case extraAddition
  case failMutatedRead
}

private enum ReversibleFixtureError: Error, Equatable {
  case mutatedReadFailed
}

private actor WishlistVerificationExecutor: VerificationHTTPExecuting {
  private let mode: ReversibleFixtureMode
  private var remoteIdentities: Set<String>
  private var requestedPaths: [String] = []
  private var readCount = 0

  init(
    mode: ReversibleFixtureMode,
    initialIdentities: Set<String> = ["existing-sku"]
  ) {
    self.mode = mode
    remoteIdentities = initialIdentities
  }

  func execute(
    _ request: URLRequest
  ) async throws -> VerificationHTTPResponse {
    let path = request.url?.path ?? ""
    requestedPaths.append(path)
    switch path {
    case "/wishlist":
      readCount += 1
      if mode == .failMutatedRead, readCount == 2 {
        throw ReversibleFixtureError.mutatedReadFailed
      }
      return try response([
        "success": true,
        "data": [
          "items": remoteIdentities.sorted().map {
            ["sku": $0]
          }
        ],
      ], finalURL: request.url)
    case "/wishlist/add":
      remoteIdentities.insert("probe-sku")
      if mode == .extraAddition {
        remoteIdentities.insert("unexpected-sku")
      }
      return try response(["success": true], finalURL: request.url)
    case "/wishlist/remove":
      remoteIdentities.remove("probe-sku")
      if mode == .extraAddition {
        remoteIdentities.remove("unexpected-sku")
      }
      return try response(["success": true], finalURL: request.url)
    default:
      return try response(
        ["success": false],
        status: 404,
        finalURL: request.url
      )
    }
  }

  func paths() -> [String] {
    requestedPaths
  }

  func identities() -> [String] {
    remoteIdentities.sorted()
  }

  private func response(
    _ object: [String: Any],
    status: Int = 200,
    finalURL: URL?
  ) throws -> VerificationHTTPResponse {
    VerificationHTTPResponse(
      status: status,
      headers: ["content-type": "application/json"],
      body: try JSONSerialization.data(
        withJSONObject: object,
        options: [.sortedKeys]
      ),
      finalURL: finalURL
    )
  }
}

private actor HTMLFavoriteVerificationExecutor:
  VerificationHTTPExecuting
{
  private var remoteIdentities: Set<String> = ["existing-sku"]

  func execute(
    _ request: URLRequest
  ) async throws -> VerificationHTTPResponse {
    switch request.url?.path ?? "" {
    case "/wishlist":
      let items = remoteIdentities.sorted().map {
        #"<div class="item"><a gid ="\#($0)" class="del swiper-slide">Delete</a></div>"#
      }.joined()
      return VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "text/html; charset=utf-8"],
        body: Data("<html><body>\(items)</body></html>".utf8),
        finalURL: request.url
      )
    case "/wishlist/add":
      remoteIdentities.insert("probe-sku")
      return try jsonResponse(["success": true], finalURL: request.url)
    case "/wishlist/remove":
      remoteIdentities.remove("probe-sku")
      return try jsonResponse(["success": true], finalURL: request.url)
    default:
      return try jsonResponse(
        ["success": false],
        status: 404,
        finalURL: request.url
      )
    }
  }

  func identities() -> [String] {
    remoteIdentities.sorted()
  }

  private func jsonResponse(
    _ object: [String: Any],
    status: Int = 200,
    finalURL: URL?
  ) throws -> VerificationHTTPResponse {
    VerificationHTTPResponse(
      status: status,
      headers: ["content-type": "application/json"],
      body: try JSONSerialization.data(
        withJSONObject: object,
        options: [.sortedKeys]
      ),
      finalURL: finalURL
    )
  }
}

private struct ReversibleFixture {
  let catalog: ObservedCatalog
  let plan: ReversibleVerificationPlan
}

private struct ReversibleStepFixture {
  let operation: ObservedOperation
  let step: ReversibleVerificationStep
}

private func reversibleFixture(
  addSafety: OperationSafety = .reversibleWrite,
  observedBrowserMetadata: Bool = false
) throws -> ReversibleFixture {
  let readBefore = try reversibleStep(
    operationId: "wishlist.read-before",
    path: "/wishlist",
    method: "GET",
    safety: .safeRead,
    observedBrowserMetadata: observedBrowserMetadata
  )
  let readMutated = try reversibleStep(
    operationId: "wishlist.read-mutated",
    path: "/wishlist",
    method: "GET",
    safety: .safeRead,
    observedBrowserMetadata: observedBrowserMetadata
  )
  let readRestored = try reversibleStep(
    operationId: "wishlist.read-restored",
    path: "/wishlist",
    method: "GET",
    safety: .safeRead,
    observedBrowserMetadata: observedBrowserMetadata
  )
  let add = try reversibleStep(
    operationId: "wishlist.add",
    path: "/wishlist/add",
    method: "POST",
    safety: addSafety,
    body: .object(["sku": .string("probe-sku")]),
    observedBrowserMetadata: observedBrowserMetadata
  )
  let remove = try reversibleStep(
    operationId: "wishlist.remove",
    path: "/wishlist/remove",
    method: "POST",
    safety: .reversibleWrite,
    body: .object(["sku": .string("probe-sku")]),
    observedBrowserMetadata: observedBrowserMetadata
  )
  let plan = ReversibleVerificationPlan(
    provider: "fixture",
    market: "cn",
    readBefore: readBefore.step,
    add: add.step,
    readMutated: readMutated.step,
    remove: remove.step,
    readRestored: readRestored.step,
    stateProjection: ReversibleCollectionProjection(
      collectionPointer: "/data/items",
      identityPointers: [
        ReversibleIdentityProjection(path: "/sku")
      ],
      intendedIdentity: [.string("probe-sku")]
    )
  )
  let catalog = ObservedCatalog(
    schemaVersion: 1,
    kind: "web-api-reverse.observed-catalog",
    brand: "fixture",
    market: "cn",
    updatedAt: "2026-07-29T00:00:00Z",
    operations: [
      readBefore.operation,
      add.operation,
      readMutated.operation,
      remove.operation,
      readRestored.operation,
    ]
  )
  return ReversibleFixture(catalog: catalog, plan: plan)
}

private func reversibleStep(
  operationId: String,
  path: String,
  method: String,
  safety: OperationSafety,
  body: JSONValue? = nil,
  observedBrowserMetadata: Bool = false
) throws -> ReversibleStepFixture {
  let url = "https://api.example.test\(path)"
  let headers =
    body == nil
    ? [:]
    : ["content-type": "application/json"]
  var observedHeaders = headers
  if observedBrowserMetadata {
    observedHeaders["cookie"] = "observed-session=redacted"
    observedHeaders["sec-fetch-site"] = "same-origin"
  }
  let normalized = try HARImporter.normalize(
    RawExchange(
      method: method,
      url: url,
      requestHeaders: observedHeaders,
      requestBody: body,
      requestContentType: headers["content-type"],
      responseStatus: 200,
      responseHeaders: ["content-type": "application/json"],
      responseBody: .object(["success": .bool(true)]),
      responseContentType: "application/json"
    )
  )
  let operation = ObservedOperation(
    operationId: operationId,
    fingerprint: normalized.fingerprint,
    method: method,
    urlTemplate: normalized.urlTemplate,
    protocol: normalized.protocol,
    serviceFamily: "wishlist",
    productFamily: "wishlist",
    classification: .authenticatedBusiness,
    safety: safety,
    authPolicy: .sessionHeadersAndCookies,
    routePolicy: .fixed(baseURL: "https://api.example.test"),
    request: normalized.request,
    responses: [normalized.response],
    sourceRefs: [
      SourceReference(
        captureId: "cap_fixture",
        sourceId: "fixture-source",
        sourceVersion: "v1"
      )
    ],
    verificationIds: []
  )
  let request = PrivateVerificationRequestSpec(
    brand: "fixture",
    market: "cn",
    safety: safety,
    url: url,
    method: method,
    headers: headers,
    body: body,
    fixtureOmissionReason:
      "Authenticated collection values remain private to the reversible probe."
  )
  return ReversibleStepFixture(
    operation: operation,
    step: ReversibleVerificationStep(
      operationId: operationId,
      request: request
    )
  )
}

private func replacingAddOperationId(
  _ plan: ReversibleVerificationPlan,
  with operationId: String
) -> ReversibleVerificationPlan {
  ReversibleVerificationPlan(
    provider: plan.provider,
    market: plan.market,
    readBefore: plan.readBefore,
    add: ReversibleVerificationStep(
      operationId: operationId,
      request: plan.add.request
    ),
    readMutated: plan.readMutated,
    remove: plan.remove,
    readRestored: plan.readRestored,
    stateProjection: plan.stateProjection,
    schemaVersion: plan.schemaVersion,
    kind: plan.kind
  )
}

private func privateSessionSeed() -> PrivateSessionSeed {
  PrivateSessionSeed(
    brand: "fixture",
    market: "cn",
    profile: "test",
    createdAt: "2026-07-29T00:00:00Z",
    sourceURL: "https://api.example.test/login",
    cookies: [
      PrivateSessionCookie(
        name: "session",
        value: "private-session-cookie",
        domain: ".example.test",
        path: "/",
        expires: -1,
        httpOnly: true,
        secure: true,
        sameSite: "Lax"
      )
    ],
    origins: []
  )
}

private func transactionStore() throws -> (
  root: URL,
  store: ReversibleVerificationTransactionStore
) {
  let root = FileManager.default.temporaryDirectory.appending(
    path: "web-api-reverse-transaction-\(UUID().uuidString)",
    directoryHint: .isDirectory
  )
  return (
    root,
    try ReversibleVerificationTransactionStore(privateRoot: root)
  )
}
