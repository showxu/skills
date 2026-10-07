import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Published contract")
struct PublishedContractTests {
  @Test("Publisher creates and validates the exact five-file projection")
  func publisherCreatesFiveFileProjection() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    let result = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        publishedAt: "2026-07-29T00:00:00Z"
      )
    )

    #expect(Set(result.files.keys) == Set(PublishedContract.requiredPayloadFiles))
    let names = try FileManager.default.contentsOfDirectory(
      atPath: fixture.root.appending(path: "API/Published").path
    )
    #expect(Set(names) == Set(PublishedContract.allFiles))
    let validated = try ContractValidator().validate(providerRoot: fixture.root)
    #expect(validated.files == result.files)
    let lock = try DeterministicJSON.decode(
      PublishLock.self,
      from: Data(
        contentsOf: fixture.root.appending(
          path: "API/Published/publish-lock.json"
        )
      )
    )
    #expect(lock.publishedAt == "2026-07-29T00:00:00Z")
  }

  @Test(
    "A restart recovers every durable publication phase",
    arguments: [
      PublishedTransactionInterruptionPoint.afterReadyJournal,
      .afterDirectorySwap,
      .afterCommittedJournal,
    ]
  )
  func publisherRecoversInterruptedAtomicSwap(
    point: PublishedTransactionInterruptionPoint
  ) throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        publishedAt: "2026-07-29T00:00:00Z"
      )
    )

    #expect(throws: ContractError.self) {
      _ = try EvidencePublisher(
        interruptionPoint: point
      ).publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          publishedAt: "2026-07-30T00:00:00Z"
        )
      )
    }
    _ = try ContractValidator().validate(providerRoot: fixture.root)
    #expect(
      FileManager.default.fileExists(
        atPath: fixture.root.appending(path: "API/Published").path
      )
    )

    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        publishedAt: "2026-07-31T00:00:00Z"
      )
    )
    let lock = try DeterministicJSON.decode(
      PublishLock.self,
      from: Data(
        contentsOf: fixture.root.appending(
          path: "API/Published/publish-lock.json"
        )
      )
    )
    #expect(lock.publishedAt == "2026-07-31T00:00:00Z")
  }

  @Test(
    "Recovery never publishes a changed transaction candidate",
    arguments: [
      PublishedTransactionInterruptionPoint.afterReadyJournal,
      .afterDirectorySwap,
    ]
  )
  func publisherRejectsChangedInterruptedCandidate(
    point: PublishedTransactionInterruptionPoint
  ) throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn",
        publishedAt: "2026-07-29T00:00:00Z"
      )
    )
    #expect(throws: ContractError.self) {
      _ = try EvidencePublisher(
        interruptionPoint: point
      ).publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn",
          publishedAt: "2026-07-30T00:00:00Z"
        )
      )
    }
    let candidateDirectory =
      point == .afterReadyJournal ? ".Published.next" : "Published"
    try Data("unapproved-change\n".utf8).write(
      to: fixture.root.appending(
        path: "API/\(candidateDirectory)/openapi.yaml"
      )
    )

    #expect(throws: ContractError.self) {
      _ = try EvidencePublisher().publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn"
        )
      )
    }
    let restoredLock = try DeterministicJSON.decode(
      PublishLock.self,
      from: Data(
        contentsOf: fixture.root.appending(
          path: "API/Published/publish-lock.json"
        )
      )
    )
    #expect(restoredLock.publishedAt == "2026-07-29T00:00:00Z")
    _ = try ContractValidator().validate(providerRoot: fixture.root)
  }

  @Test("Concurrent publishers serialize without losing Published")
  func concurrentPublishersSerialize() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    let inputs = PublishInputs(
      providerRoot: fixture.root,
      provider: "fixture",
      market: "cn"
    )

    async let first = Task.detached {
      try EvidencePublisher().publish(inputs)
    }.value
    async let second = Task.detached {
      try EvidencePublisher().publish(inputs)
    }.value
    let results = try await [first, second]

    #expect(results[0].files == results[1].files)
    _ = try ContractValidator().validate(providerRoot: fixture.root)
  }

  @Test("Replacing API after the publish lock is acquired fails closed")
  func publisherRejectsAPIRootReplacementAfterLock() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    let api = fixture.root.appending(path: "API", directoryHint: .isDirectory)
    let displaced = fixture.root.appending(
      path: "API-displaced",
      directoryHint: .isDirectory
    )
    let replacementMarker = api.appending(path: "replacement-marker")
    let publisher = EvidencePublisher(afterLockAcquired: {
      try FileManager.default.moveItem(at: api, to: displaced)
      try FileManager.default.createDirectory(
        at: api,
        withIntermediateDirectories: false
      )
      try Data("replacement".utf8).write(to: replacementMarker)
    })

    #expect(throws: ContractError.self) {
      _ = try publisher.publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn"
        )
      )
    }
    #expect(try Data(contentsOf: replacementMarker) == Data("replacement".utf8))
    #expect(
      !FileManager.default.fileExists(
        atPath: api.appending(path: "Published").path
      )
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: api.appending(path: ".Published.next").path
      )
    )
  }

  @Test("Published projection rejects hidden files")
  func publishedProjectionRejectsHiddenFiles() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try Data("metadata".utf8).write(
      to: fixture.root.appending(path: "API/Published/.DS_Store")
    )

    #expect(throws: ContractError.unexpectedFile(".DS_Store")) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Identical approved inputs publish byte-identical output by default")
  func publisherUsesApprovalTimestampAsDeterministicDefault() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()

    let first = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    let firstBytes = try publishedBytes(in: fixture.root)

    let second = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    let secondBytes = try publishedBytes(in: fixture.root)
    let lock = try DeterministicJSON.decode(
      PublishLock.self,
      from: try #require(secondBytes[PublishedContract.lockFile])
    )

    #expect(firstBytes == secondBytes)
    #expect(first.publishLockSHA256 == second.publishLockSHA256)
    #expect(lock.publishedAt == "2026-07-29T00:00:00Z")
  }

  @Test("Published OpenAPI normalizes evidence-only schemas for Swift codegen")
  func publishedOpenAPINormalizesEvidenceOnlySchemas() throws {
    let source = JSONValue.object([
      "openapi": .string("3.1.0"),
      "paths": .object([
        "/region": .object([
          "get": .object([
            "responses": .object([
              "200": .object([
                "content": .object([
                  "application/json": .object([
                    "schema": .object([
                      "x-web-api-reverse-observed-null-only": .bool(true)
                    ])
                  ])
                ])
              ])
            ])
          ])
        ])
      ]),
      "components": .object([
        "schemas": .object([
          "Items": .object([
            "items": .object([:]),
            "type": .string("array"),
          ])
        ])
      ]),
    ])

    let projected = try DeterministicJSON.decode(
      JSONValue.self,
      from: PublishedOpenAPIProjection.project(
        try DeterministicJSON.encode(source)
      )
    )

    let nullSchema = try #require(
      jsonObject(
        at: [
          "paths", "/region", "get", "responses", "200", "content",
          "application/json", "schema",
        ],
        in: projected
      )
    )
    #expect(
      nullSchema["type"]
        == .array([.string("object"), .string("null")])
    )
    #expect(nullSchema["nullable"] == nil)
    #expect(nullSchema["additionalProperties"] == .bool(true))
    let itemSchema = try #require(
      jsonObject(
        at: ["components", "schemas", "Items", "items"],
        in: projected
      )
    )
    #expect(itemSchema["type"] == .string("object"))
    #expect(itemSchema["additionalProperties"] == .bool(true))
  }

  @Test("Non-platform semantic areas do not require source product receipts")
  func validatorPreservesNonPlatformProviders() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )

    _ = try ContractValidator().validate(providerRoot: fixture.root)
    #expect(
      FileManager.default.fileExists(
        atPath: fixture.root.appending(
          path: "API/Observed/source-verifications"
        ).path
      ) == false
    )
  }

  @Test("Validator rejects drift after publication")
  func validatorRejectsHashDrift() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try Data("changed\n".utf8).write(
      to: fixture.root.appending(path: "API/Published/openapi.yaml")
    )

    #expect(throws: ContractError.hashMismatch(file: "openapi.yaml")) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Validator rejects a resealed route-policy mutation")
  func validatorRejectsResealedRouteMutation() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeSessionValidatorInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try mutatePublishedPolicy(in: fixture.root) { operation in
      operation["routePolicy"] = [
        "kind": "fixed",
        "baseURL": "https://mutated.invalid",
      ]
    }

    #expect(
      throws: ContractError.projectionMismatch(
        file: "operation-policies.json"
      )
    ) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Validator rejects a resealed auth-policy mutation")
  func validatorRejectsResealedAuthMutation() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeSessionValidatorInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try mutatePublishedPolicy(in: fixture.root) { operation in
      operation["authPolicy"] = "none"
    }

    #expect(
      throws: ContractError.projectionMismatch(
        file: "operation-policies.json"
      )
    ) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Validator rejects a resealed OpenAPI schema mutation")
  func validatorRejectsResealedSchemaMutation() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeSessionValidatorInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    let openAPI = fixture.root.appending(
      path: "API/Published/openapi.yaml"
    )
    var data = try Data(contentsOf: openAPI)
    data.append(
      Data(
        """

        components:
          schemas:
            MutatedResponse:
              type: object
              properties:
                injected:
                  type: string
        """.utf8
      )
    )
    try data.write(to: openAPI)
    try resealPublishedLock(in: fixture.root)

    #expect(
      throws: ContractError.projectionMismatch(file: "openapi.yaml")
    ) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Validator rejects source manifest drift after publication")
  func validatorRejectsSourceLifecycleDrift() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try fixture.writeSourceLifecycle(
      coverageArea: "official-desktop",
      version: "2"
    )

    #expect(throws: (any Error).self) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Validator rejects drift in every declared approval input")
  func validatorRejectsDeclaredApprovalInputDrift() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try Data("changed\n".utf8).write(
      to: fixture.root.appending(path: "API/Config/trust-manifest.json")
    )

    #expect(
      throws: ContractError.invalidObservedEvidence(
        "API/Config/trust-manifest.json no longer matches the Published approval"
      )
    ) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Publisher rejects a stale declared approval input")
  func publisherRejectsDeclaredApprovalInputDrift() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    try Data("changed\n".utf8).write(
      to: fixture.root.appending(path: "API/Config/trust-manifest.json")
    )

    #expect(
      throws: ContractError.invalidObservedEvidence(
        "API/Config/trust-manifest.json no longer matches the Published approval"
      )
    ) {
      try EvidencePublisher().publish(
        PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
      )
    }
  }

  @Test("Publisher rejects noncanonical and Published approval inputs")
  func publisherRejectsDisallowedApprovalInputs() throws {
    for path in [
      "API/Config/extra.json",
      "API/Published/openapi.yaml",
    ] {
      let fixture = try Fixture()
      defer { fixture.remove() }

      try fixture.writeInputs()
      try fixture.addApprovalInput(
        path: path,
        hash: String(repeating: "a", count: 64)
      )

      #expect(
        throws: ContractError.invalidApproval(
          "input hash path is not canonical provider authority: \(path)"
        )
      ) {
        try EvidencePublisher().publish(
          PublishInputs(
            providerRoot: fixture.root,
            provider: "fixture",
            market: "cn"
          )
        )
      }
    }
  }

  @Test("Platform validation reports missing source receipt before stale lifecycle hashes")
  func platformValidationPrioritizesMissingSourceReceipt() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writePlatformInputsWithoutSourceReceipt()

    do {
      _ = try EvidencePublisher().publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn"
        )
      )
      Issue.record("Expected missing platform source evidence to fail publication.")
    } catch {
      #expect(
        error.localizedDescription.contains(
          "require a sanitized receipt in API/Observed/source-verifications"
        )
      )
      #expect(!error.localizedDescription.contains("source-manifest.json"))
    }
  }

  @Test("Validator reports the exact legacy publish-lock field")
  func validatorReportsLegacyPublishLockField() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
    )
    try Data(
      """
      {
        "schemaVersion": 1,
        "kind": "web-api-reverse.publish-lock",
        "provider": "fixture",
        "market": "cn",
        "publishedAt": "2026-07-29T00:00:00Z",
        "artifacts": []
      }
      """.utf8
    ).write(
      to: fixture.root.appending(path: "API/Published/publish-lock.json")
    )

    #expect(
      throws: ContractError.invalidLock(
        "publish-lock.json: missing files"
      )
    ) {
      try ContractValidator().validate(providerRoot: fixture.root)
    }
  }

  @Test("Publisher rejects secret-bearing durable input")
  func publisherRejectsSecrets() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    try Data(#"{"access_token":"raw-secret-token-value"}"#.utf8).write(
      to: fixture.root.appending(path: "API/Trusted/operation-policies.json")
    )

    #expect(throws: (any Error).self) {
      try EvidencePublisher().publish(
        PublishInputs(providerRoot: fixture.root, provider: "fixture", market: "cn")
      )
    }
  }

  @Test("Publisher rejects a legacy approval without semantic coverage proof")
  func publisherRejectsMissingCoverageProof() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try fixture.writeInputs()
    let approvalURL = fixture.root.appending(
      path: "API/Trusted/approval-receipt.json"
    )
    let current = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(contentsOf: approvalURL)
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "fixture",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: [],
        inputHashes: current.inputHashes,
        operations: []
      ),
      to: approvalURL
    )

    #expect(
      throws: ContractError.invalidApproval(
        "semantic source coverage proof is missing or incomplete"
      )
    ) {
      try EvidencePublisher().publish(
        PublishInputs(
          providerRoot: fixture.root,
          provider: "fixture",
          market: "cn"
        )
      )
    }
  }

  @Test("Session lifecycle classification does not require a mutation action")
  func sessionValidatorPublishesAsLifecycleEvidence() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeSessionValidatorInputs()

    let result = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn"
      )
    )

    #expect(result.files.keys.contains("approval-receipt.json"))
    #expect(result.publishLockSHA256.count == 64)
    #expect(
      result.publishLockSHA256
        == (try DeterministicJSON.canonicalSHA256(
          fileAt: fixture.root.appending(path: "API/Published/publish-lock.json")
        ))
    )
  }

  @Test("Non-platform validation ignores inactive source product policy")
  func validatorIgnoresInactiveSourceProductPolicy() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.writeInputs()
    _ = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: fixture.root,
        provider: "fixture",
        market: "cn"
      )
    )
    try DeterministicJSON.write(
      SourceProductVerificationPolicy(
        provider: "another-provider",
        market: "cn",
        sourceId: "fixture-jd-product",
        sourceVersion: "1",
        platformProvider: "jd",
        commercePlatform: "jd",
        acceptedGarmentBrands: ["Fixture"],
        acceptedSellerIDs: ["seller"],
        acceptedStorefronts: ["jd"],
        requiredProductCurrentFactFields: ["currentPrice"],
        requiredSKUCurrentFactFields: ["currentPrice"],
        requireCompleteSKUSet: true
      ),
      to: fixture.root.appending(
        path: "API/Config/jd-source-product-policy.json"
      )
    )

    _ = try ContractValidator().validate(providerRoot: fixture.root)
  }
}

private func jsonObject(
  at path: [String],
  in root: JSONValue
) -> [String: JSONValue]? {
  var current = root
  for component in path {
    guard case .object(let object) = current,
      let next = object[component]
    else {
      return nil
    }
    current = next
  }
  guard case .object(let object) = current else {
    return nil
  }
  return object
}

private func publishedBytes(in providerRoot: URL) throws -> [String: Data] {
  try Dictionary(
    uniqueKeysWithValues: PublishedContract.allFiles.map { name in
      (
        name,
        try Data(
          contentsOf: providerRoot.appending(path: "API/Published/\(name)")
        )
      )
    }
  )
}

private func mutatePublishedPolicy(
  in providerRoot: URL,
  mutation: (inout [String: Any]) throws -> Void
) throws {
  let policyURL = providerRoot.appending(
    path: "API/Published/operation-policies.json"
  )
  var document = try #require(
    try JSONSerialization.jsonObject(with: Data(contentsOf: policyURL))
      as? [String: Any]
  )
  var operations = try #require(
    document["operations"] as? [[String: Any]]
  )
  var operation = try #require(operations.first)
  try mutation(&operation)
  operations[0] = operation
  document["operations"] = operations
  try JSONSerialization.data(
    withJSONObject: document,
    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  ).write(to: policyURL)
  try resealPublishedLock(in: providerRoot)
}

private func resealPublishedLock(in providerRoot: URL) throws {
  let lockURL = providerRoot.appending(
    path: "API/Published/publish-lock.json"
  )
  let current = try DeterministicJSON.decode(
    PublishLock.self,
    from: Data(contentsOf: lockURL)
  )
  let hashes = try Dictionary(
    uniqueKeysWithValues: PublishedContract.requiredPayloadFiles.map { name in
      (
        name,
        try FileDigest.sha256(
          fileAt: providerRoot.appending(path: "API/Published/\(name)")
        )
      )
    }
  )
  try DeterministicJSON.write(
    PublishLock(
      provider: current.provider,
      market: current.market,
      publishedAt: current.publishedAt,
      files: hashes
    ),
    to: lockURL
  )
}

private struct Fixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory
      .appending(path: "web-api-reverse-\(UUID().uuidString)", directoryHint: .isDirectory)
    _ = try ProviderScaffolder().scaffold(providerRoot: root)
  }

  func writeInputs() throws {
    let files = [
      "API/Trusted/openapi.yaml":
        "openapi: 3.1.0\ninfo:\n  title: Fixture\n  version: 1.0.0\npaths: {}\n",
      "API/Trusted/operation-policies.json": "{\"operations\":[]}\n",
    ]
    for (path, content) in files {
      try Data(content.utf8).write(to: root.appending(path: path))
    }
    try Data("{\"operations\":[]}\n".utf8).write(
      to: root.appending(path: "API/Config/trust-manifest.json")
    )
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "fixture",
        market: "cn",
        claimedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true,
        capabilities: []
      ),
      to: root.appending(path: "API/Config/capability-claim.json")
    )
    var lifecycleHashes = try writeSourceLifecycle(
      coverageArea: "official-desktop"
    )
    lifecycleHashes["API/Config/trust-manifest.json"] = try FileDigest.sha256(
      fileAt: root.appending(path: "API/Config/trust-manifest.json")
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "fixture",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: [],
        requiredCoverageAreas: ["official-desktop"],
        coveredCoverageAreas: ["official-desktop"],
        inputHashes: lifecycleHashes,
        operations: []
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
  }

  func writeSessionValidatorInputs() throws {
    try Data(
      """
      openapi: 3.1.0
      info:
        title: Fixture
        version: 1.0.0
      paths:
        /session/user:
          get:
            operationId: getSessionUser
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
            "operationId": "getSessionUser",
            "serviceFamily": "session-status",
            "classification": "session-lifecycle",
            "safety": "safe-read",
            "reversibleMutation": false,
            "evidenceIds": ["cap_1", "ver_1"]
          }
        ]
      }
      """.utf8
    ).write(to: root.appending(path: "API/Trusted/operation-policies.json"))
    try DeterministicJSON.write(
      CapabilityClaim(
        provider: "fixture",
        market: "cn",
        claimedAt: "2026-07-29T00:00:00Z",
        zeroUnknown: true,
        capabilities: [
          CapabilityClaimEntry(
            id: "session-status",
            availability: .supported,
            operationIds: ["getSessionUser"]
          )
        ]
      ),
      to: root.appending(path: "API/Config/capability-claim.json")
    )
    let lifecycleHashes = try writeSourceLifecycle(
      coverageArea: "authenticated-account"
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "fixture",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: ["desktop@1"],
        requiredCoverageAreas: ["authenticated-account"],
        coveredCoverageAreas: ["authenticated-account"],
        inputHashes: lifecycleHashes,
        operations: [
          OperationApproval(
            operationId: "getSessionUser",
            evidenceIds: ["cap_1", "ver_1"],
            evidenceClass: .lifecycleReplay
          )
        ]
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
  }

  func addApprovalInput(path: String, hash: String) throws {
    let url = root.appending(path: "API/Trusted/approval-receipt.json")
    let approval = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: Data(contentsOf: url)
    )
    var hashes = approval.inputHashes
    hashes[path] = hash
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: approval.provider,
        market: approval.market,
        approvedAt: approval.approvedAt,
        reviewer: approval.reviewer,
        sourceRevisions: approval.sourceRevisions,
        requiredCoverageAreas: approval.requiredCoverageAreas,
        coveredCoverageAreas: approval.coveredCoverageAreas,
        inputHashes: hashes,
        operations: approval.operations
      ),
      to: url
    )
  }

  func writePlatformInputsWithoutSourceReceipt() throws {
    try writeInputs()
    _ = try writeSourceLifecycle(
      coverageArea: "selected-platform-current-facts"
    )
    try DeterministicJSON.write(
      SourceProductVerificationPolicy(
        provider: "fixture",
        market: "cn",
        sourceId: "desktop",
        sourceVersion: "1",
        platformProvider: "jd",
        commercePlatform: "jd",
        acceptedGarmentBrands: ["Fixture"],
        acceptedSellerIDs: ["seller"],
        acceptedStorefronts: ["jd"],
        requiredProductCurrentFactFields: ["currentPrice"],
        requiredSKUCurrentFactFields: ["currentPrice"],
        requireCompleteSKUSet: true
      ),
      to: root.appending(
        path: "API/Config/jd-source-product-policy.json"
      )
    )
    try DeterministicJSON.write(
      ApprovalReceipt(
        provider: "fixture",
        market: "cn",
        approvedAt: "2026-07-29T00:00:00Z",
        reviewer: "fixture-reviewer",
        sourceRevisions: ["desktop@1"],
        requiredCoverageAreas: ["selected-platform-current-facts"],
        coveredCoverageAreas: ["selected-platform-current-facts"],
        inputHashes: [
          "API/Observed/source-lock.json":
            String(repeating: "a", count: 64)
        ],
        operations: []
      ),
      to: root.appending(path: "API/Trusted/approval-receipt.json")
    )
  }

  @discardableResult
  func writeSourceLifecycle(
    coverageArea: String,
    version: String = "1"
  ) throws -> [String: String] {
    let trustManifestURL = root.appending(
      path: "API/Config/trust-manifest.json"
    )
    if !FileManager.default.fileExists(atPath: trustManifestURL.path) {
      try Data("{\"operations\":[]}\n".utf8).write(to: trustManifestURL)
    }
    let catalogURL = root.appending(path: "API/Observed/catalog.json")
    if !FileManager.default.fileExists(atPath: catalogURL.path) {
      try Data(
        """
        {
          "schemaVersion": 1,
          "kind": "web-api-reverse.observed-catalog",
          "brand": "fixture",
          "market": "cn",
          "updatedAt": "2026-07-29T00:00:00Z",
          "operations": []
        }
        """.utf8
      ).write(to: catalogURL)
    }
    let manifestURL = root.appending(
      path: "API/Config/source-manifest.json"
    )
    let sourceLockURL = root.appending(
      path: "API/Observed/source-lock.json"
    )
    try DeterministicJSON.write(
      SourceManifest(
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: [coverageArea],
        sources: [
          ExpectedSource(
            sourceId: "desktop",
            surface: .web,
            version: version,
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
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: [coverageArea],
        sources: [
          SourceLockEntry(
            sourceId: "desktop",
            surface: .web,
            version: version,
            coverageAreas: [coverageArea],
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
    return [
      "API/Config/source-manifest.json":
        try FileDigest.sha256(fileAt: manifestURL),
      "API/Config/trust-manifest.json":
        try FileDigest.sha256(fileAt: trustManifestURL),
      "API/Observed/catalog.json":
        try FileDigest.sha256(fileAt: catalogURL),
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
    ]
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
