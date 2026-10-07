import Foundation

public enum TrustSessionAction: String, Codable, Sendable {
  case acquire
  case validate
  case refresh
  case logout
}

public struct TrustManifestOperation: Codable, Equatable, Sendable {
  public let operationId: String
  public let clientOperationId: String
  public let evidenceIds: [String]
  public let family: String
  public let authPolicy: AuthPolicy
  public let routePolicy: RoutePolicy
  public let safety: OperationSafety
  public let reversibleMutation: Bool
  public let sessionAction: TrustSessionAction?
  public let summary: String?
  public let publishedPath: String?
  public let runtimeManagedQueryNames: [String]?
  public let runtimeManagedHeaderNames: [String]?
  public let runtimeManagedCookieNames: [String]?
  public let pathParameterNames: [String]?
  public let useNamedComponents: Bool?
  public let responseContentTypeAliases: [String: String]?
  public let responseExtraction: JSONValue?
  public let opaqueResponsePointers: [String]?

  public init(
    operationId: String,
    clientOperationId: String,
    evidenceIds: [String],
    family: String,
    authPolicy: AuthPolicy,
    routePolicy: RoutePolicy,
    safety: OperationSafety,
    reversibleMutation: Bool,
    sessionAction: TrustSessionAction? = nil,
    summary: String? = nil,
    publishedPath: String? = nil,
    runtimeManagedQueryNames: [String] = [],
    runtimeManagedHeaderNames: [String] = [],
    runtimeManagedCookieNames: [String] = [],
    pathParameterNames: [String]? = nil,
    useNamedComponents: Bool = false,
    responseContentTypeAliases: [String: String] = [:],
    responseExtraction: JSONValue? = nil,
    opaqueResponsePointers: [String] = []
  ) {
    self.operationId = operationId
    self.clientOperationId = clientOperationId
    self.evidenceIds = evidenceIds
    self.family = family
    self.authPolicy = authPolicy
    self.routePolicy = routePolicy
    self.safety = safety
    self.reversibleMutation = reversibleMutation
    self.sessionAction = sessionAction
    self.summary = summary
    self.publishedPath = publishedPath
    self.runtimeManagedQueryNames =
      runtimeManagedQueryNames.isEmpty ? nil : runtimeManagedQueryNames.sorted()
    self.runtimeManagedHeaderNames =
      runtimeManagedHeaderNames.isEmpty ? nil : runtimeManagedHeaderNames.sorted()
    self.runtimeManagedCookieNames =
      runtimeManagedCookieNames.isEmpty ? nil : runtimeManagedCookieNames.sorted()
    self.pathParameterNames = pathParameterNames?.sorted()
    self.useNamedComponents = useNamedComponents ? true : nil
    self.responseContentTypeAliases =
      responseContentTypeAliases.isEmpty ? nil : responseContentTypeAliases
    self.responseExtraction = responseExtraction
    self.opaqueResponsePointers =
      opaqueResponsePointers.isEmpty ? nil : opaqueResponsePointers.sorted()
  }
}

public struct TrustManifest: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let reviewedAt: String
  public let operations: [TrustManifestOperation]

  public init(
    brand: String,
    market: String,
    reviewedAt: String,
    operations: [TrustManifestOperation],
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.trust-manifest"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.reviewedAt = reviewedAt
    self.operations = operations
  }
}

public struct TrustRestorationProof: Codable, Equatable, Sendable {
  public let required: Bool
  public let proven: Bool
  public let receiptId: String?
  public let beforeStateSHA256: String?
  public let mutatedStateSHA256: String?
  public let restoredStateSHA256: String?
  public let changedIdentitySHA256: String?
  public let changedIdentityCount: Int?

  public init(
    required: Bool,
    proven: Bool,
    receiptId: String? = nil,
    beforeStateSHA256: String? = nil,
    mutatedStateSHA256: String? = nil,
    restoredStateSHA256: String? = nil,
    changedIdentitySHA256: String? = nil,
    changedIdentityCount: Int? = nil
  ) {
    self.required = required
    self.proven = proven
    self.receiptId = receiptId
    self.beforeStateSHA256 = beforeStateSHA256
    self.mutatedStateSHA256 = mutatedStateSHA256
    self.restoredStateSHA256 = restoredStateSHA256
    self.changedIdentitySHA256 = changedIdentitySHA256
    self.changedIdentityCount = changedIdentityCount
  }
}

public struct TrustVerificationReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let verificationId: String
  public let verificationKind: EvidenceClass
  public let verifiedAt: String
  public let operationId: String
  public let fingerprint: String
  public let sourceRefs: [SourceReference]
  public let requestEvidence: VerificationRequestEvidence?
  public let response: ResponseShape
  public let responseFixture: JSONValue?
  public let fixtureOmissionReason: String?
  public let restoration: TrustRestorationProof?

  public init(
    brand: String,
    market: String,
    verificationId: String,
    verificationKind: EvidenceClass,
    verifiedAt: String,
    operationId: String,
    fingerprint: String,
    sourceRefs: [SourceReference],
    requestEvidence: VerificationRequestEvidence? = nil,
    response: ResponseShape,
    responseFixture: JSONValue? = nil,
    fixtureOmissionReason: String? = nil,
    restoration: TrustRestorationProof? = nil,
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.verification-receipt"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.verificationId = verificationId
    self.verificationKind = verificationKind
    self.verifiedAt = verifiedAt
    self.operationId = operationId
    self.fingerprint = fingerprint
    self.sourceRefs = sourceRefs
    self.requestEvidence = requestEvidence
    self.response = response
    self.responseFixture = responseFixture
    self.fixtureOmissionReason = fixtureOmissionReason
    self.restoration = restoration
  }

  public var effectiveResponseFixture: JSONValue? {
    if let responseFixture {
      return responseFixture
    }
    guard
      fixtureOmissionReason?
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
      case .object(let schema) = response.bodySchema,
      schema["type"] == .string("null")
    else {
      return nil
    }
    return .null
  }
}

public struct TrustValidationInput: Sendable {
  public let catalog: ObservedCatalog
  public let sourceLock: SourceLock
  public let manifest: TrustManifest
  public let verifications: [TrustVerificationReceipt]

  public init(
    catalog: ObservedCatalog,
    sourceLock: SourceLock,
    manifest: TrustManifest,
    verifications: [TrustVerificationReceipt]
  ) {
    self.catalog = catalog
    self.sourceLock = sourceLock
    self.manifest = manifest
    self.verifications = verifications
  }
}

public struct ValidatedOperationPolicy: Codable, Equatable, Sendable {
  public let operationId: String
  public let clientOperationId: String
  public let method: String
  public let path: String
  public let wirePath: String?
  public let classification: OperationClassification
  public let serviceFamily: String
  public let authPolicy: AuthPolicy
  public let routePolicy: RoutePolicy
  public let safety: OperationSafety
  public let sessionAction: TrustSessionAction?
  public let evidenceIds: [String]
  public let sourceRevisions: [String]
  public let reversibleMutation: Bool
  public let fixturePaths: [String]
  public let runtimeManagedQueryNames: [String]
  public let runtimeManagedHeaderNames: [String]
  public let runtimeManagedCookieNames: [String]
  public let encodedQueryBodyNames: [String]?
  public let encodedBodyFieldNames: [String]?
  public let responseContentTypeAliases: [String: String]?
  public let pathParameterNames: [String]?
  public let useNamedComponents: Bool?
  public let responseExtraction: JSONValue?
  public let opaqueResponsePointers: [String]?

  public init(
    operationId: String,
    clientOperationId: String,
    method: String,
    path: String,
    wirePath: String? = nil,
    classification: OperationClassification,
    serviceFamily: String,
    authPolicy: AuthPolicy,
    routePolicy: RoutePolicy,
    safety: OperationSafety,
    sessionAction: TrustSessionAction?,
    evidenceIds: [String],
    sourceRevisions: [String],
    reversibleMutation: Bool,
    fixturePaths: [String],
    runtimeManagedQueryNames: [String] = [],
    runtimeManagedHeaderNames: [String] = [],
    runtimeManagedCookieNames: [String] = [],
    encodedQueryBodyNames: [String] = [],
    encodedBodyFieldNames: [String] = [],
    responseContentTypeAliases: [String: String] = [:],
    pathParameterNames: [String]? = nil,
    useNamedComponents: Bool = false,
    responseExtraction: JSONValue? = nil,
    opaqueResponsePointers: [String] = []
  ) {
    self.operationId = operationId
    self.clientOperationId = clientOperationId
    self.method = method
    self.path = path
    self.wirePath = wirePath
    self.classification = classification
    self.serviceFamily = serviceFamily
    self.authPolicy = authPolicy
    self.routePolicy = routePolicy
    self.safety = safety
    self.sessionAction = sessionAction
    self.evidenceIds = evidenceIds
    self.sourceRevisions = sourceRevisions
    self.reversibleMutation = reversibleMutation
    self.fixturePaths = fixturePaths
    self.runtimeManagedQueryNames = runtimeManagedQueryNames.sorted()
    self.runtimeManagedHeaderNames = runtimeManagedHeaderNames.sorted()
    self.runtimeManagedCookieNames = runtimeManagedCookieNames.sorted()
    self.encodedQueryBodyNames =
      encodedQueryBodyNames.isEmpty ? nil : encodedQueryBodyNames.sorted()
    self.encodedBodyFieldNames =
      encodedBodyFieldNames.isEmpty ? nil : encodedBodyFieldNames.sorted()
    self.responseContentTypeAliases =
      responseContentTypeAliases.isEmpty ? nil : responseContentTypeAliases
    self.pathParameterNames = pathParameterNames?.sorted()
    self.useNamedComponents = useNamedComponents ? true : nil
    self.responseExtraction = responseExtraction
    self.opaqueResponsePointers =
      opaqueResponsePointers.isEmpty ? nil : opaqueResponsePointers.sorted()
  }
}

public struct ValidatedOperationPolicies: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let operations: [ValidatedOperationPolicy]

  public init(
    brand: String,
    market: String,
    operations: [ValidatedOperationPolicy],
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.operation-policies"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.operations = operations
  }
}
