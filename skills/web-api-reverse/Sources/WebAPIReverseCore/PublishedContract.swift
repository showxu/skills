import CryptoKit
import Darwin
import Foundation

@_silgen_name("flock")
private func publishedContractFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

public enum PublishedContract {
  public static let requiredPayloadFiles = [
    "openapi.yaml",
    "operation-policies.json",
    "capability-claim.json",
    "approval-receipt.json",
  ]
  public static let lockFile = "publish-lock.json"
  public static let allFiles = requiredPayloadFiles + [lockFile]
}

public struct PublishLock: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let publishedAt: String
  public let files: [String: String]

  public init(
    provider: String,
    market: String,
    publishedAt: String,
    files: [String: String]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.publish-lock"
    self.provider = provider
    self.market = market
    self.publishedAt = publishedAt
    self.files = files
  }
}

public enum FileDigest {
  public static func sha256(data: Data) -> String {
    SHA256.hash(data: data)
      .map { String(format: "%02x", $0) }
      .joined()
  }

  public static func sha256(fileAt url: URL) throws -> String {
    try sha256(data: Data(contentsOf: url))
  }
}

enum ApprovalInputAuthority {
  static func validateCurrentInputs(
    snapshot: ProviderAPIAuthoritySnapshot,
    approval: ApprovalReceipt
  ) throws {
    try ApprovalInputPathPolicy.validate(approval.inputHashes.keys)
    for relativePath in approval.inputHashes.keys.sorted() {
      guard ApprovalInputPathPolicy.isAllowed(relativePath),
        let expected = approval.inputHashes[relativePath],
        expected.range(
          of: "^[a-f0-9]{64}$",
          options: .regularExpression
        ) != nil
      else {
        throw ContractError.invalidApproval(
          "input hash path or digest is invalid: \(relativePath)"
        )
      }
      let current = FileDigest.sha256(
        data: try snapshot.requiredData(relativePath)
      )
      guard current == expected else {
        throw ContractError.invalidObservedEvidence(
          "\(relativePath) no longer matches the Published approval"
        )
      }
    }
  }

}

public struct PublishInputs: Sendable {
  public let providerRoot: URL
  public let provider: String
  public let market: String
  public let publishedAt: String?

  public init(
    providerRoot: URL,
    provider: String,
    market: String,
    publishedAt: String? = nil
  ) {
    self.providerRoot = providerRoot
    self.provider = provider
    self.market = market
    self.publishedAt = publishedAt
  }
}

public struct PublishResult: Codable, Equatable, Sendable {
  public let publishedDirectory: String
  public let files: [String: String]
  public let publishLockSHA256: String
}

public enum ContractError: Error, LocalizedError, Equatable {
  case missingFile(String)
  case unexpectedFile(String)
  case hashMismatch(file: String)
  case projectionMismatch(file: String)
  case invalidLock(String)
  case secretMaterial(path: String, finding: String)
  case invalidDirectory(String)
  case scopeMismatch(String)
  case operationSetMismatch(String)
  case invalidApproval(String)
  case invalidObservedEvidence(String)
  case symbolicLink(String)
  case publicationIndeterminate(String)

  public var errorDescription: String? {
    switch self {
    case .missingFile(let file):
      "Missing required contract file: \(file)"
    case .unexpectedFile(let file):
      "Unexpected file in Published contract: \(file)"
    case .hashMismatch(let file):
      "Published hash does not match: \(file)"
    case .projectionMismatch(let file):
      "Published payload is not the approved deterministic projection: \(file)"
    case .invalidLock(let reason):
      "Invalid publish lock: \(reason)"
    case .secretMaterial(let path, let finding):
      "Sensitive material found in \(path): \(finding)"
    case .invalidDirectory(let path):
      "Expected a directory at \(path)"
    case .scopeMismatch(let reason):
      "Published provider scope mismatch: \(reason)"
    case .operationSetMismatch(let reason):
      "Published operation set mismatch: \(reason)"
    case .invalidApproval(let reason):
      "Invalid approval receipt: \(reason)"
    case .invalidObservedEvidence(let reason):
      "Invalid Observed evidence: \(reason)"
    case .symbolicLink(let path):
      "Symbolic links are not allowed in durable API artifacts: \(path)"
    case .publicationIndeterminate(let path):
      "Published transaction state is indeterminate and was left untouched: \(path)"
    }
  }
}

public struct EvidencePublisher {
  private let fileManager: FileManager
  private let interruptionPoint: PublishedTransactionInterruptionPoint?
  private let afterLockAcquired: @Sendable () throws -> Void

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    interruptionPoint = nil
    afterLockAcquired = {}
  }

  init(
    fileManager: FileManager = .default,
    interruptionPoint: PublishedTransactionInterruptionPoint
  ) {
    self.fileManager = fileManager
    self.interruptionPoint = interruptionPoint
    afterLockAcquired = {}
  }

  init(
    fileManager: FileManager = .default,
    afterLockAcquired: @escaping @Sendable () throws -> Void
  ) {
    self.fileManager = fileManager
    interruptionPoint = nil
    self.afterLockAcquired = afterLockAcquired
  }

  public func publish(_ inputs: PublishInputs) throws -> PublishResult {
    let api = inputs.providerRoot.appending(path: "API", directoryHint: .isDirectory)
    let published = api.appending(
      path: "Published",
      directoryHint: .isDirectory
    )
    do {
      let replacement = try DurableDirectoryReplacement(
        destination: published,
        interruptionPoint: interruptionPoint.map {
          switch $0 {
          case .afterReadyJournal: .afterReadyJournal
          case .afterDirectorySwap: .afterDirectorySwap
          case .afterCommittedJournal: .afterCommittedJournal
          }
        }
      )
      return try replacement.replace(
        preparing: { apiDescriptor in
          try afterLockAcquired()
          return try preparePublishedPayloads(
            inputs,
            apiDescriptor: apiDescriptor,
            publishedDirectory: replacement.destinationURL.path
          )
        },
        validateFindings: { findings in
          if let finding = findings.first {
            throw ContractError.secretMaterial(
              path: finding.path,
              finding: finding.reason
            )
          }
        }
      )
    } catch is DurableDirectoryReplacementError {
      throw ContractError.publicationIndeterminate(api.path)
    }
  }

  private func preparePublishedPayloads(
    _ inputs: PublishInputs,
    apiDescriptor: Int32,
    publishedDirectory: String
  ) throws -> (payloads: [String: Data], result: PublishResult) {
    let snapshot = try ProviderAPIAuthoritySnapshot(
      apiDescriptor: apiDescriptor
    )
    let approval = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: snapshot.requiredData("API/Trusted/approval-receipt.json")
    )
    guard approval.provider == inputs.provider,
      approval.market == inputs.market
    else {
      throw ContractError.scopeMismatch(
        "approval \(approval.provider)/\(approval.market), expected "
          + "\(inputs.provider)/\(inputs.market)"
      )
    }

    let platformAreas = PlatformSourceEvidenceAuthority.platformAreas(
      in: approval.requiredCoverageAreas
    )
    if !platformAreas.isEmpty {
      let sourceLock = try DeterministicJSON.decode(
        SourceLock.self,
        from: snapshot.requiredData("API/Observed/source-lock.json")
      )
      let policies = try PlatformSourceEvidenceAuthority.loadPolicies(
        snapshot: snapshot,
        provider: inputs.provider,
        market: inputs.market
      )
      try PlatformSourceEvidenceAuthority.validateApprovalReceiptHashes(
        snapshot: snapshot,
        provider: inputs.provider,
        market: inputs.market,
        approval: approval,
        sourceLock: sourceLock,
        policies: policies
      )
      try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
        "API/Observed/source-lock.json",
        snapshot: snapshot,
        approval: approval
      )
    }
    if approval.requiredCoverageAreas != nil,
      approval.coveredCoverageAreas != nil
    {
      try SourceLifecycleAuthority.validateCurrentApproval(
        snapshot: snapshot,
        approval: approval
      )
    }
    let capabilityClaim = try DeterministicJSON.decode(
      CapabilityClaim.self,
      from: snapshot.requiredData("API/Config/capability-claim.json")
    )
    try PlatformCollectionEvidenceAuthority.validateApprovalReceiptHashes(
      snapshot: snapshot,
      provider: inputs.provider,
      market: inputs.market,
      capabilityClaim: capabilityClaim,
      approval: approval
    )
    try ApprovalInputAuthority.validateCurrentInputs(
      snapshot: snapshot,
      approval: approval
    )

    for path in [
      "API/Trusted/openapi.yaml",
      "API/Trusted/operation-policies.json",
      "API/Trusted/approval-receipt.json",
      "API/Config/capability-claim.json",
    ] {
      let findings = ArtifactScanner().scan(
        data: try snapshot.requiredData(path),
        path: path
      )
      if let finding = findings.first {
        throw ContractError.secretMaterial(
          path: finding.path,
          finding: finding.reason
        )
      }
    }

    var payloads = try PublishedPayloadProjection.payloads(
      snapshot: snapshot
    )
    var hashes: [String: String] = [:]
    for name in PublishedContract.requiredPayloadFiles {
      guard let payload = payloads[name] else {
        throw ContractError.missingFile(name)
      }
      guard
        payload.count
          <= ProviderAPIAuthoritySnapshot.maximumPublishedFileBytes
      else { throw ContractError.publicationIndeterminate(name) }
      hashes[name] = FileDigest.sha256(data: payload)
    }
    let lock = PublishLock(
      provider: inputs.provider,
      market: inputs.market,
      publishedAt: inputs.publishedAt ?? approval.approvedAt,
      files: hashes
    )
    payloads[PublishedContract.lockFile] = try DeterministicJSON.encode(lock)
    let validation = try ContractValidator()
      .validatePublishedPayloads(
        payloads,
        publishedDirectory: publishedDirectory
      )
    return (
      payloads,
      PublishResult(
        publishedDirectory: publishedDirectory,
        files: hashes,
        publishLockSHA256: validation.publishLockSHA256
      )
    )
  }

}

enum PublishedTransactionInterruptionPoint: Equatable, Sendable {
  case afterReadyJournal
  case afterDirectorySwap
  case afterCommittedJournal
}

enum PublishedOpenAPIProjection {
  static func project(_ data: Data) throws -> Data {
    guard let document = try? JSONDecoder().decode(JSONValue.self, from: data)
    else {
      return data
    }
    return try DeterministicJSON.encode(projectDocument(document))
  }

  private static func projectDocument(_ value: JSONValue) -> JSONValue {
    switch value {
    case .object(let object):
      return .object(
        Dictionary(
          uniqueKeysWithValues: object.map { key, value in
            (
              key,
              key == "schema"
                ? projectSchema(value)
                : key == "schemas"
                  ? projectSchemaMap(value)
                  : projectDocument(value)
            )
          }
        )
      )
    case .array(let values):
      return .array(values.map(projectDocument))
    case .string, .number, .bool, .null:
      return value
    }
  }

  private static func projectSchemaMap(_ value: JSONValue) -> JSONValue {
    guard case .object(let schemas) = value else {
      return projectDocument(value)
    }
    return .object(schemas.mapValues(projectSchema))
  }

  private static func projectSchema(_ value: JSONValue) -> JSONValue {
    guard case .object(var object) = value else {
      return value
    }
    if case .object(let properties) = object["properties"] {
      object["properties"] = .object(properties.mapValues(projectSchema))
    }
    if let items = object["items"] {
      object["items"] = projectSchema(items)
    }
    if case .object = object["additionalProperties"] {
      object["additionalProperties"] = projectSchema(
        object["additionalProperties"]!
      )
    }
    for keyword in ["oneOf", "anyOf", "allOf", "prefixItems"] {
      if case .array(let candidates) = object[keyword] {
        object[keyword] = .array(candidates.map(projectSchema))
      }
    }
    let standardKeys = Set(object.keys.filter { !$0.hasPrefix("x-") })
    if standardKeys.isEmpty {
      object["additionalProperties"] = .bool(true)
      object["type"] =
        object["x-web-api-reverse-observed-null-only"] == .bool(true)
        ? .array([.string("object"), .string("null")])
        : .string("object")
      object["x-web-api-reverse-codegen-unconstrained"] = .bool(true)
    }
    normalizeOpenAPI31Nullable(in: &object)
    return .object(object)
  }

  private static func normalizeOpenAPI31Nullable(
    in object: inout [String: JSONValue]
  ) {
    guard object.removeValue(forKey: "nullable") == .bool(true) else { return }
    switch object["type"] {
    case .string(let type):
      object["type"] = .array([.string(type), .string("null")])
    case .array(let types):
      if !types.contains(.string("null")) {
        object["type"] = .array(types + [.string("null")])
      }
    case nil:
      object["anyOf"] = .array([
        .object(["type": .string("object")]),
        .object(["type": .string("null")]),
      ])
    default:
      break
    }
  }
}

enum PublishedPayloadProjection {
  private static let sourcePaths = [
    "openapi.yaml": "API/Trusted/openapi.yaml",
    "operation-policies.json": "API/Trusted/operation-policies.json",
    "capability-claim.json": "API/Config/capability-claim.json",
    "approval-receipt.json": "API/Trusted/approval-receipt.json",
  ]

  static func payloads(
    snapshot: ProviderAPIAuthoritySnapshot
  ) throws -> [String: Data] {
    try Dictionary(
      uniqueKeysWithValues: PublishedContract.requiredPayloadFiles.map { name in
        guard let sourcePath = sourcePaths[name] else {
          throw ContractError.missingFile(name)
        }
        let sourceData = try snapshot.requiredData(sourcePath)
        return (
          name,
          name == "openapi.yaml"
            ? try PublishedOpenAPIProjection.project(sourceData)
            : sourceData
        )
      }
    )
  }

  static func validate(
    snapshot: ProviderAPIAuthoritySnapshot,
    publishedPayloads: [String: Data]
  ) throws {
    for (name, expected) in try payloads(snapshot: snapshot) {
      guard publishedPayloads[name] == expected else {
        throw ContractError.projectionMismatch(file: name)
      }
    }
  }
}

public struct ContractValidator {
  public init() {}

  public func validate(providerRoot: URL) throws -> PublishResult {
    try withValidatedPublishedAuthority(
      providerRoot: providerRoot
    ) { result, _ in
      result
    }
  }

  public func withValidatedPublishedAuthority<Result>(
    providerRoot: URL,
    _ operation: (PublishResult, PublishLock) throws -> Result
  ) throws -> Result {
    try ProviderAPIAuthorityReader.withSharedSnapshot(
      providerRoot: providerRoot,
      includePublished: true
    ) { snapshot in
      let result = try validate(
        snapshot: snapshot,
        publishedDirectory: providerRoot.appending(
          path: "API/Published",
          directoryHint: .isDirectory
        ).path
      )
      let lock = try decodeContract(
        PublishLock.self,
        data: snapshot.requiredData("API/Published/publish-lock.json"),
        fileName: PublishedContract.lockFile,
        invalid: ContractError.invalidLock
      )
      return try operation(result, lock)
    }
  }

  func validate(
    snapshot: ProviderAPIAuthoritySnapshot,
    publishedDirectory: String
  ) throws -> PublishResult {
    let nestedDirectories = snapshot.directories.filter {
      $0.hasPrefix("API/Published/")
    }
    guard nestedDirectories.isEmpty else {
      throw ContractError.unexpectedFile(nestedDirectories.sorted()[0])
    }
    let publishedPayloads = Dictionary(
      uniqueKeysWithValues: snapshot.directFiles(
        in: "API/Published"
      ).map {
        (String($0.path.split(separator: "/").last ?? ""), $0.data)
      }
    )
    let result = try validatePublishedPayloads(
      publishedPayloads,
      publishedDirectory: publishedDirectory
    )
    let lock = try decodeContract(
      PublishLock.self,
      data: requirePayload(
        PublishedContract.lockFile,
        in: publishedPayloads
      ),
      fileName: PublishedContract.lockFile,
      invalid: ContractError.invalidLock
    )
    let approval = try decodeContract(
      ApprovalReceipt.self,
      data: requirePayload(
        "approval-receipt.json",
        in: publishedPayloads
      ),
      fileName: "approval-receipt.json",
      invalid: ContractError.invalidApproval
    )
    try ApprovalInputAuthority.validateCurrentInputs(
      snapshot: snapshot,
      approval: approval
    )
    try PublishedPayloadProjection.validate(
      snapshot: snapshot,
      publishedPayloads: publishedPayloads
    )
    try validatePlatformSourceEvidence(
      snapshot: snapshot,
      lock: lock,
      approval: approval
    )
    try SourceLifecycleAuthority.validateCurrentApproval(
      snapshot: snapshot,
      approval: approval
    )
    try validateObservedOperationEvidence(
      snapshot: snapshot,
      publishedPayloads: publishedPayloads,
      lock: lock,
      approval: approval
    )
    let capabilityClaim = try decodeContract(
      CapabilityClaim.self,
      data: requirePayload(
        "capability-claim.json",
        in: publishedPayloads
      ),
      fileName: "capability-claim.json",
      invalid: ContractError.invalidApproval
    )
    try PlatformCollectionEvidenceAuthority.validateApprovalReceiptHashes(
      snapshot: snapshot,
      provider: lock.provider,
      market: lock.market,
      capabilityClaim: capabilityClaim,
      approval: approval
    )
    return result
  }

  public func validatePublishedDirectory(_ published: URL) throws -> PublishResult {
    let payloads = try DescriptorBoundDirectorySnapshot(
      directory: published,
      maximumFileBytes:
        ProviderAPIAuthoritySnapshot.maximumPublishedFileBytes,
      maximumTreeBytes:
        ProviderAPIAuthoritySnapshot.maximumPublishedFileBytes
        * PublishedContract.allFiles.count,
      maximumEntries: PublishedContract.allFiles.count + 1
    ).payloads
    return try validatePublishedPayloads(
      payloads,
      publishedDirectory: published.path
    )
  }

  func validatePublishedPayloads(
    _ payloads: [String: Data],
    publishedDirectory: String
  ) throws -> PublishResult {
    let actualNames = Set(payloads.keys)
    let requiredNames = Set(PublishedContract.allFiles)
    if let missing = requiredNames.subtracting(actualNames).sorted().first {
      throw ContractError.missingFile(missing)
    }
    if let unexpected = actualNames.subtracting(requiredNames).sorted().first {
      throw ContractError.unexpectedFile(unexpected)
    }
    for (name, data) in payloads {
      guard
        data.count
          <= ProviderAPIAuthoritySnapshot.maximumPublishedFileBytes
      else { throw ContractError.publicationIndeterminate(name) }
    }
    let lockData = try requirePayload(
      PublishedContract.lockFile,
      in: payloads
    )
    let lock = try decodeContract(
      PublishLock.self,
      data: lockData,
      fileName: PublishedContract.lockFile,
      invalid: ContractError.invalidLock
    )
    guard lock.schemaVersion == 1,
      lock.kind == "web-api-reverse.publish-lock"
    else {
      throw ContractError.invalidLock("unsupported schema or kind")
    }
    guard Set(lock.files.keys) == Set(PublishedContract.requiredPayloadFiles) else {
      throw ContractError.invalidLock("file set does not match the contract")
    }

    for name in PublishedContract.requiredPayloadFiles {
      let data = try requirePayload(name, in: payloads)
      let path = URL(fileURLWithPath: publishedDirectory)
        .appending(path: name).path
      let findings = ArtifactScanner().scan(data: data, path: path)
      if let finding = findings.first {
        throw ContractError.secretMaterial(path: path, finding: finding.reason)
      }
      let currentHash = FileDigest.sha256(data: data)
      guard lock.files[name] == currentHash else {
        throw ContractError.hashMismatch(file: name)
      }
    }
    try validateSemanticContract(payloads: payloads, lock: lock)
    return PublishResult(
      publishedDirectory: publishedDirectory,
      files: lock.files,
      publishLockSHA256: try DeterministicJSON.canonicalSHA256(lockData)
    )
  }

  private func validateSemanticContract(
    payloads: [String: Data],
    lock: PublishLock
  ) throws {
    let capabilityClaim = try decodeContract(
      CapabilityClaim.self,
      data: requirePayload("capability-claim.json", in: payloads),
      fileName: "capability-claim.json",
      invalid: ContractError.invalidApproval
    )
    let approvalReceipt = try decodeContract(
      ApprovalReceipt.self,
      data: requirePayload("approval-receipt.json", in: payloads),
      fileName: "approval-receipt.json",
      invalid: ContractError.invalidApproval
    )
    let policies = try OperationPolicyReader.read(
      data: requirePayload("operation-policies.json", in: payloads)
    )

    guard capabilityClaim.schemaVersion == 1,
      capabilityClaim.kind == "web-api-reverse.capability-claim"
    else {
      throw ContractError.invalidApproval("unsupported capability claim schema")
    }
    guard capabilityClaim.zeroUnknown else {
      throw ContractError.invalidApproval(
        "capability claim does not assert zero-unknown coverage"
      )
    }
    guard approvalReceipt.schemaVersion == 1,
      approvalReceipt.kind == "web-api-reverse.approval-receipt"
    else {
      throw ContractError.invalidApproval("unsupported approval receipt schema")
    }
    guard
      let requiredAreas = approvalReceipt.requiredCoverageAreas,
      let coveredAreas = approvalReceipt.coveredCoverageAreas,
      !requiredAreas.isEmpty,
      (try? SourceCoverageContract.validateAreas(
        requiredAreas,
        scope: "approval requiredCoverageAreas"
      )) == requiredAreas,
      (try? SourceCoverageContract.validateAreas(
        coveredAreas,
        scope: "approval coveredCoverageAreas"
      )) == coveredAreas,
      coveredAreas == requiredAreas
    else {
      throw ContractError.invalidApproval(
        "semantic source coverage proof is missing or incomplete"
      )
    }
    let scopes = [
      "\(lock.provider)/\(lock.market)",
      "\(capabilityClaim.provider)/\(capabilityClaim.market)",
      "\(approvalReceipt.provider)/\(approvalReceipt.market)",
    ]
    guard Set(scopes).count == 1 else {
      throw ContractError.scopeMismatch(scopes.joined(separator: ", "))
    }

    let capabilityGroups = Dictionary(
      grouping: capabilityClaim.capabilities,
      by: \.id
    )
    guard capabilityGroups.values.allSatisfy({ $0.count == 1 }) else {
      throw ContractError.invalidApproval(
        "capability claim contains duplicate ids"
      )
    }
    for capability in capabilityClaim.capabilities
    where capability.availability == .supported
      && capability.operationIds.isEmpty
      && capability.id != PlatformCollectionEvidenceAuthority.capabilityID
    {
      throw ContractError.invalidApproval(
        "supported zero-operation capability is limited to remote-collection: "
          + capability.id
      )
    }

    try ApprovalInputPathPolicy.validate(approvalReceipt.inputHashes.keys)
    for (name, hash) in approvalReceipt.inputHashes {
      guard !name.isEmpty, hash.range(of: #"^[a-f0-9]{64}$"#, options: .regularExpression) != nil
      else {
        throw ContractError.invalidApproval("input hash \(name) is not SHA-256")
      }
    }
    guard !approvalReceipt.reviewer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ContractError.invalidApproval("reviewer is empty")
    }

    let policyIds = Set(policies.map(\.operationId))
    let approvalIds = Set(approvalReceipt.operations.map(\.operationId))
    let capabilityIds = capabilityClaim.operationIds
    let openAPIIds = try OpenAPIInspection.operationIds(
      data: requirePayload("openapi.yaml", in: payloads)
    )
    guard policyIds == approvalIds else {
      throw ContractError.operationSetMismatch(
        "operation policies and approval receipt differ"
      )
    }
    guard policyIds == capabilityIds else {
      throw ContractError.operationSetMismatch(
        "operation policies and supported capability claims differ"
      )
    }
    guard policyIds == openAPIIds else {
      throw ContractError.operationSetMismatch(
        "operation policies and OpenAPI operationIds differ"
      )
    }

    let policyById = Dictionary(
      uniqueKeysWithValues: policies.map { ($0.operationId, $0) }
    )
    for approval in approvalReceipt.operations {
      guard !approval.evidenceIds.isEmpty else {
        throw ContractError.invalidApproval(
          "\(approval.operationId) has no evidence"
        )
      }
      guard let policy = policyById[approval.operationId] else {
        throw ContractError.operationSetMismatch(approval.operationId)
      }
      switch approval.evidenceClass {
      case .directReplay:
        guard policy.safety == .safeRead, policy.sessionAction == nil else {
          throw ContractError.invalidApproval(
            "\(approval.operationId) requires lifecycle or write evidence"
          )
        }
      case .lifecycleReplay:
        guard policy.isSessionLifecycle else {
          throw ContractError.invalidApproval(
            "\(approval.operationId) is not a session lifecycle operation"
          )
        }
      case .reversibleWriteReplay:
        guard policy.safety == .reversibleWrite,
          policy.reversibleMutation
        else {
          throw ContractError.invalidApproval(
            "\(approval.operationId) lacks reversible-write policy"
          )
        }
      }
    }
  }

  private func validateObservedOperationEvidence(
    snapshot: ProviderAPIAuthoritySnapshot,
    publishedPayloads: [String: Data],
    lock: PublishLock,
    approval: ApprovalReceipt
  ) throws {
    let verifications = try VerificationReceiptLoader.loadObserved(
      snapshot: snapshot
    )
    guard !approval.operations.isEmpty else { return }

    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      "API/Observed/catalog.json",
      snapshot: snapshot,
      approval: approval
    )
    let catalog = try decodeContract(
      ObservedCatalog.self,
      data: snapshot.requiredData("API/Observed/catalog.json"),
      fileName: "catalog.json",
      invalid: ContractError.invalidObservedEvidence
    )
    guard catalog.brand == lock.provider, catalog.market == lock.market else {
      throw ContractError.scopeMismatch(
        "Observed catalog \(catalog.brand)/\(catalog.market), expected "
          + "\(lock.provider)/\(lock.market)"
      )
    }
    let currentCatalog = try InventoryBuilder.bindingCurrentVerifications(
      to: catalog,
      verifications: verifications
    )
    let policyFacts = try OperationPolicyReader.read(
      data: requirePayload(
        "operation-policies.json",
        in: publishedPayloads
      )
    )
    let policyByClientID = Dictionary(
      uniqueKeysWithValues: policyFacts.map { ($0.operationId, $0) }
    )
    let observedByID = Dictionary(
      grouping: currentCatalog.operations,
      by: \.operationId
    )
    let verificationByID = Dictionary(
      uniqueKeysWithValues: verifications.map {
        ($0.verificationId, $0)
      }
    )

    for operationApproval in approval.operations {
      let requiredVerificationIDs = Set(
        operationApproval.evidenceIds.filter {
          $0.hasPrefix("ver_")
        }
      )
      guard !requiredVerificationIDs.isEmpty else {
        throw ContractError.invalidObservedEvidence(
          "\(operationApproval.operationId) has no verification receipt ID"
        )
      }
      guard let policy = policyByClientID[operationApproval.operationId],
        let operations = observedByID[policy.observedOperationId],
        operations.count == 1,
        let operation = operations.first
      else {
        throw ContractError.invalidObservedEvidence(
          "\(operationApproval.operationId) does not resolve to one current "
            + "Observed operation"
        )
      }
      let provenIDs = Set(operation.verificationIds)
      guard requiredVerificationIDs.isSubset(of: provenIDs) else {
        let missing = requiredVerificationIDs.subtracting(provenIDs).sorted()
        throw ContractError.invalidObservedEvidence(
          "\(operationApproval.operationId) is missing current receipts in "
            + "API/Observed/verifications: \(missing.joined(separator: ", "))"
        )
      }
      var approvalReceipts: [TrustVerificationReceipt] = []
      for verificationID in requiredVerificationIDs.sorted() {
        guard let receipt = verificationByID[verificationID] else {
          throw ContractError.invalidObservedEvidence(
            "\(operationApproval.operationId) cannot load current receipt \(verificationID)"
          )
        }
        approvalReceipts.append(receipt)
      }
      if let reason = AuthenticationEvidenceContract.rejectionReason(
        operation: operation,
        receipts: approvalReceipts
      ) {
        throw ContractError.invalidObservedEvidence(
          "\(operationApproval.operationId): \(reason)"
        )
      }
    }
  }

  private func validatePlatformSourceEvidence(
    snapshot: ProviderAPIAuthoritySnapshot,
    lock: PublishLock,
    approval: ApprovalReceipt
  ) throws {
    let platformAreas = PlatformSourceEvidenceAuthority.platformAreas(
      in: approval.requiredCoverageAreas
    )
    guard !platformAreas.isEmpty else { return }

    let sourceLock = try decodeContract(
      SourceLock.self,
      data: snapshot.requiredData("API/Observed/source-lock.json"),
      fileName: "source-lock.json",
      invalid: ContractError.invalidObservedEvidence
    )
    let policies = try PlatformSourceEvidenceAuthority.loadPolicies(
      snapshot: snapshot,
      provider: lock.provider,
      market: lock.market
    )
    try PlatformSourceEvidenceAuthority.validateApprovalReceiptHashes(
      snapshot: snapshot,
      provider: lock.provider,
      market: lock.market,
      approval: approval,
      sourceLock: sourceLock,
      policies: policies
    )
    try PlatformSourceEvidenceAuthority.requireCurrentApprovalInput(
      "API/Observed/source-lock.json",
      snapshot: snapshot,
      approval: approval
    )
  }

  private func decodeContract<Value: Decodable>(
    _ type: Value.Type,
    from url: URL,
    invalid: (String) -> ContractError
  ) throws -> Value {
    do {
      return try DeterministicJSON.decode(
        type,
        from: Data(contentsOf: url)
      )
    } catch let error as DecodingError {
      throw invalid(
        "\(url.lastPathComponent): \(Self.describe(error))"
      )
    }
  }

  private func decodeContract<Value: Decodable>(
    _ type: Value.Type,
    data: Data,
    fileName: String,
    invalid: (String) -> ContractError
  ) throws -> Value {
    do {
      return try DeterministicJSON.decode(type, from: data)
    } catch let error as DecodingError {
      throw invalid("\(fileName): \(Self.describe(error))")
    }
  }

  private func requirePayload(
    _ name: String,
    in payloads: [String: Data]
  ) throws -> Data {
    guard let data = payloads[name] else {
      throw ContractError.missingFile(name)
    }
    return data
  }

  private static func describe(_ error: DecodingError) -> String {
    switch error {
    case .keyNotFound(let key, let context):
      "missing \(path(context.codingPath + [key]))"
    case .typeMismatch(_, let context):
      "type mismatch at \(path(context.codingPath)): "
        + context.debugDescription
    case .valueNotFound(_, let context):
      "missing value at \(path(context.codingPath)): "
        + context.debugDescription
    case .dataCorrupted(let context):
      "invalid value at \(path(context.codingPath)): "
        + context.debugDescription
    @unknown default:
      error.localizedDescription
    }
  }

  private static func path(_ codingPath: [any CodingKey]) -> String {
    let components = codingPath.map(\.stringValue)
    return components.isEmpty
      ? "<root>"
      : components.joined(separator: ".")
  }
}
