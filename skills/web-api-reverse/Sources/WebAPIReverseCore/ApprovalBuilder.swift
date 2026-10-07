import Foundation

public struct ApprovalBuildInput: Sendable {
  public let providerRoot: URL
  public let provider: String
  public let market: String
  public let reviewer: String
  public let approvedAt: String
  public let zeroUnknown: Bool

  public init(
    providerRoot: URL,
    provider: String,
    market: String,
    reviewer: String,
    approvedAt: String = ISO8601DateFormatter().string(from: Date()),
    zeroUnknown: Bool
  ) {
    self.providerRoot = providerRoot
    self.provider = provider
    self.market = market
    self.reviewer = reviewer
    self.approvedAt = approvedAt
    self.zeroUnknown = zeroUnknown
  }
}

public struct ApprovalBuildResult: Codable, Equatable, Sendable {
  public let capabilityClaimPath: String
  public let approvalReceiptPath: String
  public let operationCount: Int
}

public struct ApprovalBuilder: Sendable {
  public init() {}

  public func build(_ input: ApprovalBuildInput) throws -> ApprovalBuildResult {
    guard input.zeroUnknown else {
      throw ContractError.invalidApproval(
        "zero-unknown coverage must be explicitly confirmed"
      )
    }
    guard !input.reviewer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ContractError.invalidApproval("reviewer is empty")
    }
    let api = input.providerRoot.appending(path: "API", directoryHint: .isDirectory)
    let catalogURL = api.appending(path: "Observed/catalog.json")
    let sourceLockURL = api.appending(path: "Observed/source-lock.json")
    guard FileManager.default.fileExists(atPath: catalogURL.path),
      FileManager.default.fileExists(atPath: sourceLockURL.path)
    else {
      throw ContractError.missingFile(
        "Observed catalog or semantic source lock"
      )
    }
    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: catalogURL)
    )
    let sourceLock = try DeterministicJSON.decode(
      SourceLock.self,
      from: Data(contentsOf: sourceLockURL)
    )
    let sourceLifecycle = try SourceLifecycleAuthority.loadCurrentManifest(
      providerRoot: input.providerRoot
    )
    try SourceLifecycleAuthority.validate(
      manifest: sourceLifecycle.manifest,
      sourceLock: sourceLock
    )
    let coverage = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: sourceLock
    )
    guard coverage.zeroUnknown,
      coverage.missingCoverageAreas?.isEmpty == true
    else {
      throw ContractError.invalidApproval(
        "semantic source coverage is incomplete"
      )
    }
    let policiesURL = api.appending(path: "Trusted/operation-policies.json")
    let openAPIURL = api.appending(path: "Trusted/openapi.yaml")
    let policies = try OperationPolicyReader.read(from: policiesURL)
    let verifications = try VerificationReceiptLoader.loadObserved(
      from: api.appending(path: "Observed")
    )
    let verificationByID = Dictionary(
      uniqueKeysWithValues: verifications.map {
        ($0.verificationId, $0)
      }
    )
    let observedByOperationID = Dictionary(
      grouping: catalog.operations,
      by: \.operationId
    )
    for policy in policies {
      guard
        let matchingObserved = observedByOperationID[
          policy.observedOperationId
        ],
        matchingObserved.count == 1,
        let observed = matchingObserved.first
      else {
        throw ContractError.invalidApproval(
          "\(policy.operationId) does not resolve to one Observed operation"
        )
      }
      guard policy.safety != .unknown, observed.safety == policy.safety else {
        throw ContractError.invalidApproval(
          "\(policy.operationId) safety differs from Observed"
        )
      }
      let policyVerificationIDs = Set(
        policy.evidenceIds.filter { $0.hasPrefix("ver_") }
      )
      guard !policyVerificationIDs.isEmpty,
        policyVerificationIDs.isSubset(
          of: Set(observed.verificationIds)
        )
      else {
        throw ContractError.invalidApproval(
          "\(policy.operationId) cites verification evidence not proven by the current Observed catalog"
        )
      }
      if policy.safety == .reversibleWrite && !policy.reversibleMutation {
        throw ContractError.invalidApproval(
          "\(policy.operationId) lacks reversible mutation policy"
        )
      }
      var policyReceipts: [TrustVerificationReceipt] = []
      for verificationID in policyVerificationIDs.sorted() {
        guard let receipt = verificationByID[verificationID] else {
          throw ContractError.invalidApproval(
            "\(policy.operationId) cannot load current receipt \(verificationID)"
          )
        }
        policyReceipts.append(receipt)
      }
      if let reason = AuthenticationEvidenceContract.rejectionReason(
        operation: observed,
        receipts: policyReceipts
      ) {
        throw ContractError.invalidApproval(
          "\(policy.operationId): \(reason)"
        )
      }
    }

    let grouped = Dictionary(grouping: policies, by: \.family)
    var capabilities = grouped.keys.sorted().map { family in
      CapabilityClaimEntry(
        id: family,
        availability: .supported,
        operationIds: (grouped[family] ?? []).map(\.operationId).sorted()
      )
    }
    let inputFiles = [
      "API/Observed/catalog.json",
      "API/Observed/source-lock.json",
      sourceLifecycle.relativePath,
      "API/Config/trust-manifest.json",
      "API/Trusted/openapi.yaml",
      "API/Trusted/operation-policies.json",
    ]
    var inputHashes: [String: String] = [:]
    for path in inputFiles {
      let file = input.providerRoot.appending(path: path)
      if FileManager.default.fileExists(atPath: file.path) {
        inputHashes[path] = try FileDigest.sha256(fileAt: file)
      }
    }
    let sourceVerificationHashes: [String: String]
    if PlatformSourceEvidenceAuthority.platformAreas(
      in: coverage.requiredCoverageAreas
    ).isEmpty {
      sourceVerificationHashes = [:]
    } else {
      let sourceProductPolicies =
        try PlatformSourceEvidenceAuthority.loadPolicies(
          providerRoot: input.providerRoot,
          provider: input.provider,
          market: input.market
        )
      sourceVerificationHashes =
        try PlatformSourceEvidenceAuthority.collectRequiredReceiptHashes(
          providerRoot: input.providerRoot,
          provider: input.provider,
          market: input.market,
          requiredAreas: coverage.requiredCoverageAreas,
          sourceLock: sourceLock,
          policies: sourceProductPolicies
        )
    }
    inputHashes.merge(sourceVerificationHashes) { _, current in current }
    if !capabilities.contains(where: {
      $0.id == PlatformCollectionEvidenceAuthority.capabilityID
    }),
      let collectionAuthority =
        try PlatformCollectionEvidenceAuthority
        .collectCurrentAuthority(
          providerRoot: input.providerRoot,
          provider: input.provider,
          market: input.market,
          approvedSourceReceiptHashes: sourceVerificationHashes
        )
    {
      capabilities.append(
        CapabilityClaimEntry(
          id: PlatformCollectionEvidenceAuthority.capabilityID,
          availability: .supported,
          operationIds: []
        )
      )
      capabilities.sort { $0.id < $1.id }
      inputHashes[collectionAuthority.relativePath] =
        collectionAuthority.sha256
    }
    let capabilityClaim = CapabilityClaim(
      provider: input.provider,
      market: input.market,
      claimedAt: input.approvedAt,
      zeroUnknown: true,
      capabilities: capabilities
    )
    guard inputHashes["API/Trusted/openapi.yaml"] != nil,
      inputHashes["API/Trusted/operation-policies.json"] != nil
    else {
      throw ContractError.missingFile("Trusted OpenAPI or operation policies")
    }

    let approvalReceipt = ApprovalReceipt(
      provider: input.provider,
      market: input.market,
      approvedAt: input.approvedAt,
      reviewer: input.reviewer,
      sourceRevisions: try sourceRevisions(
        at: api.appending(path: "Observed/source-lock.json")
      ),
      requiredCoverageAreas: coverage.requiredCoverageAreas,
      coveredCoverageAreas: coverage.coveredCoverageAreas,
      inputHashes: inputHashes,
      operations: policies.map { policy in
        OperationApproval(
          operationId: policy.operationId,
          evidenceIds: policy.evidenceIds,
          evidenceClass: evidenceClass(for: policy)
        )
      }
    )

    let capabilityURL = api.appending(path: "Config/capability-claim.json")
    let approvalURL = api.appending(path: "Trusted/approval-receipt.json")
    try DeterministicJSON.write(capabilityClaim, to: capabilityURL)
    try DeterministicJSON.write(approvalReceipt, to: approvalURL)
    _ = try OpenAPIInspection.operationIds(at: openAPIURL)
    return ApprovalBuildResult(
      capabilityClaimPath: capabilityURL.path,
      approvalReceiptPath: approvalURL.path,
      operationCount: policies.count
    )
  }

  private func evidenceClass(
    for policy: OperationPolicyFacts
  ) -> EvidenceClass {
    if policy.safety == .reversibleWrite {
      return .reversibleWriteReplay
    }
    if policy.isSessionLifecycle {
      return .lifecycleReplay
    }
    return .directReplay
  }

  private func sourceRevisions(at url: URL) throws -> [String] {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return []
    }
    let data = try Data(contentsOf: url)
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let sources = root["sources"] as? [[String: Any]]
    else {
      return []
    }
    return sources.compactMap { source in
      let id = source["sourceId"] as? String ?? source["id"] as? String
      let version = source["version"] as? String
      guard let id, let version else {
        return nil
      }
      return "\(id)@\(version)"
    }.sorted()
  }

}
