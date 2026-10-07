import Foundation

public struct OperationPolicyFacts: Equatable, Sendable {
  public let operationId: String
  public let observedOperationId: String
  public let family: String
  public let classification: String
  public let safety: OperationSafety
  public let sessionAction: String?
  public let reversibleMutation: Bool
  public let evidenceIds: [String]

  public init(
    operationId: String,
    observedOperationId: String,
    family: String,
    classification: String,
    safety: OperationSafety,
    sessionAction: String?,
    reversibleMutation: Bool,
    evidenceIds: [String]
  ) {
    self.operationId = operationId
    self.observedOperationId = observedOperationId
    self.family = family
    self.classification = classification
    self.safety = safety
    self.sessionAction = sessionAction
    self.reversibleMutation = reversibleMutation
    self.evidenceIds = evidenceIds
  }

  public var isSessionLifecycle: Bool {
    sessionAction != nil
      || classification == "sessionLifecycle"
      || classification == "session-lifecycle"
  }
}

public enum OperationPolicyReader {
  public static func read(from url: URL) throws -> [OperationPolicyFacts] {
    try read(data: Data(contentsOf: url))
  }

  public static func read(data: Data) throws -> [OperationPolicyFacts] {
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let operations = root["operations"] as? [[String: Any]]
    else {
      throw ContractError.operationSetMismatch(
        "operation-policies.json has no operations array"
      )
    }
    return try operations.map { operation in
      guard
        let operationId = firstString(
          operation,
          keys: [
            "clientOperationId",
            "clientOperationID",
            "operationId",
            "operationID",
          ]
        ), !operationId.isEmpty
      else {
        throw ContractError.operationSetMismatch(
          "operation policy is missing an operation identifier"
        )
      }
      let observedOperationId =
        firstString(
          operation,
          keys: [
            "operationId",
            "operationID",
          ]
        ) ?? operationId
      let rawSafety = firstString(operation, keys: ["safety"]) ?? "unknown"
      let safety: OperationSafety
      switch rawSafety {
      case "safeRead", "safe-read":
        safety = .safeRead
      case "reversibleWrite", "reversible-write":
        safety = .reversibleWrite
      case "highRiskWrite", "high-risk-write":
        safety = .highRiskWrite
      default:
        safety = .unknown
      }
      return OperationPolicyFacts(
        operationId: operationId,
        observedOperationId: observedOperationId,
        family: firstString(
          operation,
          keys: ["serviceFamily", "family"]
        ) ?? "unknown",
        classification: firstString(
          operation,
          keys: ["classification"]
        ) ?? "unknown",
        safety: safety,
        sessionAction: firstString(
          operation,
          keys: ["sessionAction"]
        ),
        reversibleMutation: operation["reversibleMutation"] as? Bool ?? false,
        evidenceIds: stringArray(
          operation,
          keys: ["evidenceIds", "evidenceIDs"]
        )
      )
    }.sorted { $0.operationId < $1.operationId }
  }

  private static func firstString(
    _ object: [String: Any],
    keys: [String]
  ) -> String? {
    for key in keys {
      if let value = object[key] as? String {
        return value
      }
    }
    return nil
  }

  private static func stringArray(
    _ object: [String: Any],
    keys: [String]
  ) -> [String] {
    for key in keys {
      if let values = object[key] as? [String] {
        return values.sorted()
      }
    }
    return []
  }
}
