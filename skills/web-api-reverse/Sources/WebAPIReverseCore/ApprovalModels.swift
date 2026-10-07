import Foundation

public enum CapabilityAvailability: String, Codable, Sendable {
  case supported
  case unsupported
}

public struct CapabilityClaimEntry: Codable, Equatable, Sendable {
  public let id: String
  public let availability: CapabilityAvailability
  public let operationIds: [String]
  public let rationale: String?

  public init(
    id: String,
    availability: CapabilityAvailability,
    operationIds: [String],
    rationale: String? = nil
  ) {
    self.id = id
    self.availability = availability
    self.operationIds = operationIds
    self.rationale = rationale
  }
}

public struct CapabilityClaim: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let claimedAt: String
  public let zeroUnknown: Bool
  public let capabilities: [CapabilityClaimEntry]

  public init(
    provider: String,
    market: String,
    claimedAt: String,
    zeroUnknown: Bool,
    capabilities: [CapabilityClaimEntry]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.capability-claim"
    self.provider = provider
    self.market = market
    self.claimedAt = claimedAt
    self.zeroUnknown = zeroUnknown
    self.capabilities = capabilities
  }

  public var operationIds: Set<String> {
    Set(
      capabilities
        .filter { $0.availability == .supported }
        .flatMap(\.operationIds)
    )
  }
}

public enum EvidenceClass: String, Codable, Sendable {
  case directReplay
  case lifecycleReplay
  case reversibleWriteReplay
}

public struct OperationApproval: Codable, Equatable, Sendable {
  public let operationId: String
  public let evidenceIds: [String]
  public let evidenceClass: EvidenceClass

  public init(
    operationId: String,
    evidenceIds: [String],
    evidenceClass: EvidenceClass
  ) {
    self.operationId = operationId
    self.evidenceIds = evidenceIds
    self.evidenceClass = evidenceClass
  }
}

public struct ApprovalReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let approvedAt: String
  public let reviewer: String
  public let sourceRevisions: [String]
  public let requiredCoverageAreas: [String]?
  public let coveredCoverageAreas: [String]?
  public let inputHashes: [String: String]
  public let operations: [OperationApproval]

  public init(
    provider: String,
    market: String,
    approvedAt: String,
    reviewer: String,
    sourceRevisions: [String],
    requiredCoverageAreas: [String]? = nil,
    coveredCoverageAreas: [String]? = nil,
    inputHashes: [String: String],
    operations: [OperationApproval]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.approval-receipt"
    self.provider = provider
    self.market = market
    self.approvedAt = approvedAt
    self.reviewer = reviewer
    self.sourceRevisions = sourceRevisions
    self.requiredCoverageAreas = requiredCoverageAreas
    self.coveredCoverageAreas = coveredCoverageAreas
    self.inputHashes = inputHashes
    self.operations = operations
  }
}

public struct OperationPolicySummary: Codable, Equatable, Sendable {
  public let operationId: String
  public let safety: OperationSafety
  public let sessionAction: String?
  public let reversibleMutation: Bool
}

public struct OperationPoliciesSummary: Codable, Equatable, Sendable {
  public let operations: [OperationPolicySummary]
}
