import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Trusted contract builder")
struct TrustedContractBuilderTests {
  @Test("Builds an exact deterministic Trusted tree and removes stale files")
  func buildsExactTree() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    let second = root.appending(
      path: "Second/API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }

    try FileManager.default.createDirectory(
      at: trusted.appending(path: "fixtures/stale"),
      withIntermediateDirectories: true
    )
    try Data("{}\n".utf8).write(
      to: trusted.appending(path: "fixtures/stale/unexpected.json")
    )

    let first = try TrustedContractBuilder().build(
      fixture.input(includeUnacceptedVerification: true),
      trustedDirectory: trusted
    )
    let secondSummary = try TrustedContractBuilder().build(
      fixture.input(),
      trustedDirectory: second
    )
    let expectedFiles = [
      "fixtures/get.products/ver_products.json",
      "openapi.yaml",
      "operation-policies.json",
    ]

    #expect(first.kind == "web-api-reverse.trusted-contract-build")
    #expect(first.operationCount == 1)
    #expect(first.fixtureCount == 1)
    #expect(first.files == expectedFiles)
    #expect(first.sha256 == secondSummary.sha256)
    #expect(try regularFiles(under: trusted) == expectedFiles)
    #expect(
      !FileManager.default.fileExists(
        atPath: trusted.appending(
          path: "fixtures/stale/unexpected.json"
        ).path
      )
    )
    #expect(try ArtifactScanner().scan(root: trusted).isEmpty)

    for path in expectedFiles {
      #expect(
        try Data(contentsOf: trusted.appending(path: path))
          == Data(contentsOf: second.appending(path: path))
      )
    }
    let openAPI = try DeterministicJSON.decode(
      JSONValue.self,
      from: Data(contentsOf: trusted.appending(path: "openapi.yaml"))
    )
    #expect(openAPI["openapi"] == .string("3.1.0"))
    let fixtureValue = try DeterministicJSON.decode(
      JSONValue.self,
      from: Data(
        contentsOf: trusted.appending(
          path: "fixtures/get.products/ver_products.json"
        )
      )
    )
    #expect(fixtureValue == fixture.responseFixture)
  }

  @Test(
    "Trusted replacement recovers every durable directory phase",
    arguments: [
      DurableDirectoryReplacementInterruptionPoint.afterReadyJournal,
      .afterDirectorySwap,
      .afterCommittedJournal,
    ]
  )
  func recoversInterruptedDirectoryReplacement(
    point: DurableDirectoryReplacementInterruptionPoint
  ) throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    _ = try TrustedContractBuilder().build(
      fixture.input(),
      trustedDirectory: trusted
    )

    #expect(throws: TrustedContractBuildError.self) {
      _ = try TrustedContractBuilder(
        interruptionPoint: point
      ).build(
        fixture.input(),
        trustedDirectory: trusted
      )
    }
    let summary = try TrustedContractBuilder().build(
      fixture.input(),
      trustedDirectory: trusted
    )
    #expect(summary.operationCount == 1)
    #expect(
      try regularFiles(under: trusted) == [
        "fixtures/get.products/ver_products.json",
        "openapi.yaml",
        "operation-policies.json",
      ]
    )
    #expect(try temporaryReplacementPaths(beside: trusted).isEmpty)
  }

  @Test("Concurrent directory replacements serialize exact generations")
  func concurrentDirectoryReplacementsSerialize() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: "directory-replacement-concurrency-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    let destination = root.appending(
      path: "Trusted",
      directoryHint: .isDirectory
    )
    let install: @Sendable (String) throws -> Void = { value in
      let expected = Data(value.utf8)
      try DurableDirectoryReplacement(destination: destination).replace(
        payloads: ["generation.txt": expected]
      ) { findings in
        guard findings.isEmpty else {
          throw DurableDirectoryReplacementError.transactionIndeterminate(
            destination.path
          )
        }
      }
    }

    async let first: Void = Task.detached { try install("first") }.value
    async let second: Void = Task.detached { try install("second") }.value
    _ = try await (first, second)

    let persisted = try String(
      contentsOf: destination.appending(path: "generation.txt"),
      encoding: .utf8
    )
    #expect(persisted == "first" || persisted == "second")
    #expect(
      try FileManager.default.contentsOfDirectory(atPath: root.path)
        == ["Trusted"]
    )
  }

  @Test("A detached parent cannot report a successful replacement")
  func detachedParentFailsClosedBeforeCommit() throws {
    let parent = FileManager.default.temporaryDirectory
    let root = parent.appending(
      path: "directory-replacement-detach-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    let detached = parent.appending(
      path: root.lastPathComponent + "-detached",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: root)
      try? FileManager.default.removeItem(at: detached)
    }
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    let destination = root.appending(
      path: "Trusted",
      directoryHint: .isDirectory
    )
    try DurableDirectoryReplacement(destination: destination).replace(
      payloads: ["generation.txt": Data("old".utf8)]
    ) { findings in
      guard findings.isEmpty else {
        throw DurableDirectoryReplacementError.transactionIndeterminate(
          destination.path
        )
      }
    }

    let transaction = try DurableDirectoryReplacement(
      destination: destination
    ) { point in
      guard point == .beforeCommit else { return }
      try FileManager.default.moveItem(at: root, to: detached)
      try FileManager.default.createDirectory(
        at: root,
        withIntermediateDirectories: false
      )
    }
    #expect(throws: DurableDirectoryReplacementError.self) {
      try transaction.replace(
        payloads: ["generation.txt": Data("new".utf8)]
      ) { findings in
        guard findings.isEmpty else {
          throw DurableDirectoryReplacementError.transactionIndeterminate(
            destination.path
          )
        }
      }
    }

    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "Trusted").path
      )
    )
    #expect(
      try String(
        contentsOf: detached.appending(path: "Trusted/generation.txt"),
        encoding: .utf8
      ) == "old"
    )
    #expect(try temporaryReplacementPaths(beside: detached.appending(path: "Trusted")).isEmpty)
  }

  @Test("Parent path ABA still commits through the bound descriptor")
  func parentPathABAKeepsOneGeneration() throws {
    let parent = FileManager.default.temporaryDirectory
    let root = parent.appending(
      path: "directory-replacement-aba-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    let detached = parent.appending(
      path: root.lastPathComponent + "-detached",
      directoryHint: .isDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: root)
      try? FileManager.default.removeItem(at: detached)
    }
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    let destination = root.appending(
      path: "Trusted",
      directoryHint: .isDirectory
    )
    let transaction = try DurableDirectoryReplacement(
      destination: destination
    ) { point in
      guard point == .beforeCommit else { return }
      try FileManager.default.moveItem(at: root, to: detached)
      try FileManager.default.createDirectory(
        at: root,
        withIntermediateDirectories: false
      )
      try Data("untrusted".utf8).write(
        to: root.appending(path: "replacement.txt")
      )
      try FileManager.default.removeItem(at: root)
      try FileManager.default.moveItem(at: detached, to: root)
    }
    try transaction.replace(
      payloads: ["generation.txt": Data("bound".utf8)]
    ) { findings in
      guard findings.isEmpty else {
        throw DurableDirectoryReplacementError.transactionIndeterminate(
          destination.path
        )
      }
    }

    #expect(
      try String(
        contentsOf: destination.appending(path: "generation.txt"),
        encoding: .utf8
      ) == "bound"
    )
    #expect(!FileManager.default.fileExists(atPath: root.appending(path: "replacement.txt").path))
    #expect(try temporaryReplacementPaths(beside: destination).isEmpty)
  }

  @Test("A schema-proven JSON null response emits a null fixture")
  func emitsJSONNullFixture() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }

    let summary = try TrustedContractBuilder().build(
      fixture.input(
        bodySchema: .object(["type": .string("null")]),
        omitFixture: true
      ),
      trustedDirectory: trusted
    )
    let emitted = try DeterministicJSON.decode(
      JSONValue.self,
      from: Data(
        contentsOf: trusted.appending(
          path: "fixtures/get.products/ver_products.json"
        )
      )
    )

    #expect(summary.fixtureCount == 1)
    #expect(emitted == .null)
  }

  @Test("Authenticated response values never enter reusable contracts")
  func omitsAuthenticatedResponseValues() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }

    let summary = try TrustedContractBuilder().build(
      fixture.input(
        classification: .authenticatedBusiness,
        authPolicy: .sessionHeadersAndCookies
      ),
      trustedDirectory: trusted
    )
    let openAPI = try String(
      contentsOf: trusted.appending(path: "openapi.yaml"),
      encoding: .utf8
    )
    let policies = try DeterministicJSON.decode(
      ValidatedOperationPolicies.self,
      from: Data(
        contentsOf: trusted.appending(path: "operation-policies.json")
      )
    )

    #expect(summary.fixtureCount == 0)
    #expect(summary.files == ["openapi.yaml", "operation-policies.json"])
    #expect(!openAPI.contains("\"examples\""))
    #expect(policies.operations.first?.fixturePaths.isEmpty == true)
  }

  @Test("Secret-bearing fixtures fail before swap and preserve prior Trusted")
  func rejectsSecretsAndPreservesPriorTree() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(
      at: trusted,
      withIntermediateDirectories: true
    )
    let prior = trusted.appending(path: "prior.txt")
    try Data("prior\n".utf8).write(to: prior)

    let secretFixture: JSONValue = .object([
      "authorization": .string(
        "Bearer abcdefghijklmnopqrstuvwxyz"
      )
    ])

    #expect(throws: TrustedContractBuildError.self) {
      try TrustedContractBuilder().build(
        fixture.input(responseFixture: secretFixture),
        trustedDirectory: trusted
      )
    }
    #expect(try String(contentsOf: prior, encoding: .utf8) == "prior\n")
    #expect(try regularFiles(under: trusted) == ["prior.txt"])
    #expect(try temporaryReplacementPaths(beside: trusted).isEmpty)
  }

  @Test("Unsafe declared fixture paths are rejected without escaping output")
  func rejectsUnsafeFixturePath() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let trusted = root.appending(
      path: "API/Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(
      at: trusted,
      withIntermediateDirectories: true
    )
    let prior = trusted.appending(path: "prior.txt")
    try Data("prior\n".utf8).write(to: prior)

    #expect(throws: TrustedContractBuildError.self) {
      try TrustedContractBuilder().build(
        fixture.input(verificationId: "ver_../../escape"),
        trustedDirectory: trusted
      )
    }
    #expect(try String(contentsOf: prior, encoding: .utf8) == "prior\n")
    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "escape.json").path
      )
    )
  }

  @Test("A symbolic-link output root is rejected")
  func rejectsSymbolicLinkRoot() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let target = root.appending(path: "target", directoryHint: .isDirectory)
    let api = root.appending(path: "API", directoryHint: .isDirectory)
    let trusted = api.appending(path: "Trusted")
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(
      at: target,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: api,
      withIntermediateDirectories: true
    )
    try FileManager.default.createSymbolicLink(
      at: trusted,
      withDestinationURL: target
    )

    #expect(
      throws: TrustedContractBuildError.symbolicLink(trusted.path)
    ) {
      try TrustedContractBuilder().build(
        fixture.input(),
        trustedDirectory: trusted
      )
    }
    #expect(try regularFiles(under: target).isEmpty)
  }

  @Test("The public builder rejects output outside exact API/Trusted")
  func rejectsNonTrustedDestination() throws {
    let fixture = TrustedBuilderFixture()
    let root = fixture.temporaryRoot()
    let destination = root.appending(
      path: "Trusted",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(
      throws: EvidencePathError.nonTrustedWrite(destination.path)
    ) {
      try TrustedContractBuilder().build(
        fixture.input(),
        trustedDirectory: destination
      )
    }
    #expect(!FileManager.default.fileExists(atPath: destination.path))
  }
}

private struct TrustedBuilderFixture {
  let fingerprint = String(repeating: "f", count: 64)
  let responseFixture: JSONValue = .object([
    "items": .array([
      .object(["productCode": .string("484203")])
    ])
  ])

  func temporaryRoot() -> URL {
    FileManager.default.temporaryDirectory.appending(
      path: "trusted-builder-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
  }

  func input(
    verificationId: String = "ver_products",
    responseFixture: JSONValue? = nil,
    includeUnacceptedVerification: Bool = false,
    bodySchema: JSONValue? = nil,
    omitFixture: Bool = false,
    classification: OperationClassification = .publicCurrentFact,
    authPolicy: AuthPolicy = .none
  ) -> TrustValidationInput {
    let source = SourceReference(
      captureId: "cap_products",
      sourceId: "desktop-shell",
      sourceVersion: "v1"
    )
    let response = ResponseShape(
      status: 200,
      contentType: "application/json",
      bodySchema:
        bodySchema
        ?? .object([
          "properties": .object([
            "items": .object(["type": .string("array")])
          ]),
          "type": .string("object"),
        ]),
      outcome: .success,
      businessErrorSignals: []
    )
    let operation = ObservedOperation(
      operationId: "get.products",
      fingerprint: fingerprint,
      method: "GET",
      urlTemplate: "https://example.com/products",
      protocol: .rest,
      serviceFamily: "catalog",
      productFamily: "products",
      classification: classification,
      safety: .safeRead,
      authPolicy: authPolicy,
      routePolicy: .fixed(baseURL: "https://example.com"),
      request: RequestShape(
        contentType: nil,
        queryNames: [],
        headers: [],
        cookieNames: [],
        bodySchema: nil
      ),
      responses: [response],
      sourceRefs: [source],
      verificationIds: [verificationId]
    )
    let acceptedVerification = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: verificationId,
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "get.products",
      fingerprint: fingerprint,
      sourceRefs: [source],
      requestEvidence:
        authPolicy == .none
        ? nil
        : VerificationRequestEvidence(
          finalURLTemplate: "https://example.com/products",
          headerNames: ["accept"],
          cookieNames: []
        ),
      response: response,
      responseFixture:
        omitFixture ? nil : responseFixture ?? self.responseFixture
    )
    let unacceptedVerification = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_unaccepted",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "get.products",
      fingerprint: fingerprint,
      sourceRefs: [source],
      response: response,
      responseFixture: .object(["mustNotBeWritten": .bool(true)])
    )
    return TrustValidationInput(
      catalog: ObservedCatalog(
        schemaVersion: 1,
        kind: "web-api-reverse.observed-catalog",
        brand: "fixture",
        market: "cn",
        updatedAt: "2026-07-29T00:00:00Z",
        operations: [operation]
      ),
      sourceLock: SourceLock(
        schemaVersion: 1,
        kind: "web-api-reverse.source-lock",
        brand: "fixture",
        market: "cn",
        sources: [
          SourceLockEntry(
            sourceId: "desktop-shell",
            surface: .web,
            version: "v1",
            coveragePolicy: .required,
            coverageRationale: nil,
            sha256: String(repeating: "a", count: 64),
            status: .captured,
            capturedAt: "2026-07-29T00:00:00Z",
            captureIds: ["cap_products"],
            operationFingerprints: [fingerprint]
          )
        ]
      ),
      manifest: TrustManifest(
        brand: "fixture",
        market: "cn",
        reviewedAt: "2026-07-29T00:00:00Z",
        operations: [
          TrustManifestOperation(
            operationId: "get.products",
            clientOperationId: "getProducts",
            evidenceIds: ["cap_products", verificationId],
            family: "catalog",
            authPolicy: authPolicy,
            routePolicy: .fixed(baseURL: "https://example.com"),
            safety: .safeRead,
            reversibleMutation: false,
            summary: "Get products"
          )
        ]
      ),
      verifications: [acceptedVerification]
        + (includeUnacceptedVerification ? [unacceptedVerification] : [])
    )
  }
}

private func regularFiles(under root: URL) throws -> [String] {
  guard let subpaths = FileManager.default.subpaths(atPath: root.path) else {
    return []
  }
  return subpaths.filter { path in
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(
      atPath: root.appending(path: path).path,
      isDirectory: &isDirectory
    ) && !isDirectory.boolValue
  }.sorted()
}

private func temporaryReplacementPaths(beside trusted: URL) throws -> [String] {
  let parent = trusted.deletingLastPathComponent()
  let prefix = ".\(trusted.lastPathComponent)."
  return try FileManager.default.contentsOfDirectory(atPath: parent.path)
    .filter { $0.hasPrefix(prefix) }
    .sorted()
}

extension JSONValue {
  fileprivate subscript(key: String) -> JSONValue? {
    guard case .object(let object) = self else {
      return nil
    }
    return object[key]
  }
}
