import Foundation

public enum SourceSurface: String, Codable, Sendable {
  case documentation
  case web
  case h5
  case app
  case miniProgram = "mini-program"
  case simulatorWebView = "simulator-webview"
  case proxy
  case unknown
}

public enum OperationProtocol: String, Codable, Sendable {
  case rest
  case graphql
  case persistedQuery = "persisted-query"
  case form
  case multipart
  case `static`
  case unknown
}

public enum OperationClassification: String, Codable, Sendable {
  case publicCurrentFact = "public-current-fact"
  case remoteConfig = "remote-config"
  case sessionLifecycle = "session-lifecycle"
  case authenticatedBusiness = "authenticated-business"
  case storefrontClassifiedOnly = "storefront-classified-only"
  case ignoredTelemetry = "ignored-telemetry"
  case unknown

  public var isTrustEligible: Bool {
    switch self {
    case .publicCurrentFact, .remoteConfig, .sessionLifecycle, .authenticatedBusiness:
      true
    case .storefrontClassifiedOnly, .ignoredTelemetry, .unknown:
      false
    }
  }
}

public enum OperationSafety: String, Codable, Sendable {
  case safeRead = "safe-read"
  case reversibleWrite = "reversible-write"
  case highRiskWrite = "high-risk-write"
  case unknown
}

public enum AuthPolicy: String, Codable, Sendable {
  case none
  case bearerAccessToken = "bearer-access-token"
  case accessAndRefreshToken = "access-and-refresh-token"
  case sessionHeadersAndCookies = "session-headers-and-cookies"
  case refreshTokenOnly = "refresh-token-only"
  case unknown
}

public enum RoutePolicy: Codable, Equatable, Sendable {
  case fixed(baseURL: String)
  case sessionEnvironment(path: String)
  case provider(kind: String, fields: [String: JSONValue])
  case unknown

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    var object = try container.decode([String: JSONValue].self)
    guard case .string(let kind) = object.removeValue(forKey: "kind") else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Route policy requires a string kind."
      )
    }
    switch kind {
    case "fixed":
      guard case .string(let baseURL) = object["baseURL"] else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Fixed route policy requires baseURL."
        )
      }
      self = .fixed(baseURL: baseURL)
    case "session-environment":
      guard case .string(let path) = object["path"] else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Session-environment route policy requires path."
        )
      }
      self = .sessionEnvironment(path: path)
    case "unknown":
      self = .unknown
    default:
      self = .provider(kind: kind, fields: object)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    let object: [String: JSONValue]
    switch self {
    case .fixed(let baseURL):
      object = [
        "baseURL": .string(baseURL),
        "kind": .string("fixed"),
      ]
    case .sessionEnvironment(let path):
      object = [
        "kind": .string("session-environment"),
        "path": .string(path),
      ]
    case .provider(let kind, let fields):
      var values = fields
      values["kind"] = .string(kind)
      object = values
    case .unknown:
      object = ["kind": .string("unknown")]
    }
    try container.encode(object)
  }

  public var isUnknown: Bool {
    if case .unknown = self {
      return true
    }
    return false
  }

  public var baseURL: String? {
    switch self {
    case .fixed(let baseURL):
      baseURL
    case .provider(_, let fields):
      fields["baseURL"]?.stringValue
    case .sessionEnvironment, .unknown:
      nil
    }
  }
}

public struct HeaderPresence: Codable, Equatable, Sendable {
  public let name: String
  public let present: Bool
  public let sensitive: Bool
}

public struct RequestShape: Codable, Equatable, Sendable {
  public let contentType: String?
  public let queryNames: [String]
  public let headers: [HeaderPresence]
  public let cookieNames: [String]
  public let bodySchema: JSONValue?
  public let encodedQuerySchemas: [String: JSONValue]?
  public let encodedBodySchemas: [String: JSONValue]?

  public init(
    contentType: String?,
    queryNames: [String],
    headers: [HeaderPresence],
    cookieNames: [String],
    bodySchema: JSONValue?,
    encodedQuerySchemas: [String: JSONValue]? = nil,
    encodedBodySchemas: [String: JSONValue]? = nil
  ) {
    self.contentType = contentType
    self.queryNames = queryNames
    self.headers = headers
    self.cookieNames = cookieNames
    self.bodySchema = bodySchema
    self.encodedQuerySchemas = encodedQuerySchemas
    self.encodedBodySchemas = encodedBodySchemas
  }
}

public enum ResponseOutcome: String, Codable, Sendable {
  case success
  case httpError = "http-error"
  case businessError = "business-error"
  case unknown
}

public struct ResponseShape: Codable, Equatable, Sendable {
  public let status: Int
  public let contentType: String?
  public let bodySchema: JSONValue?
  public let outcome: ResponseOutcome
  public let businessErrorSignals: [String]
  public let responseHeaderNames: [String]?
  public let setCookieNames: [String]?

  public init(
    status: Int,
    contentType: String?,
    bodySchema: JSONValue?,
    outcome: ResponseOutcome,
    businessErrorSignals: [String],
    responseHeaderNames: [String]? = nil,
    setCookieNames: [String]? = nil
  ) {
    self.status = status
    self.contentType = contentType
    self.bodySchema = bodySchema
    self.outcome = outcome
    self.businessErrorSignals = businessErrorSignals
    self.responseHeaderNames = responseHeaderNames
    self.setCookieNames = setCookieNames
  }
}

public struct SourceReference: Codable, Equatable, Hashable, Sendable {
  public let captureId: String
  public let sourceId: String
  public let sourceVersion: String
}

public struct ObservedOperation: Codable, Equatable, Sendable {
  public let operationId: String
  public let fingerprint: String
  public let method: String
  public let urlTemplate: String
  public let `protocol`: OperationProtocol
  public let serviceFamily: String
  public let productFamily: String
  public let classification: OperationClassification
  public let safety: OperationSafety
  public let authPolicy: AuthPolicy
  public let routePolicy: RoutePolicy
  public let routeDiscriminators: [String: String]?
  public let request: RequestShape
  public let responses: [ResponseShape]
  public let sourceRefs: [SourceReference]
  public let verificationIds: [String]

  public init(
    operationId: String,
    fingerprint: String,
    method: String,
    urlTemplate: String,
    protocol: OperationProtocol,
    serviceFamily: String,
    productFamily: String,
    classification: OperationClassification,
    safety: OperationSafety,
    authPolicy: AuthPolicy,
    routePolicy: RoutePolicy,
    routeDiscriminators: [String: String] = [:],
    request: RequestShape,
    responses: [ResponseShape],
    sourceRefs: [SourceReference],
    verificationIds: [String]
  ) {
    self.operationId = operationId
    self.fingerprint = fingerprint
    self.method = method
    self.urlTemplate = urlTemplate
    self.protocol = `protocol`
    self.serviceFamily = serviceFamily
    self.productFamily = productFamily
    self.classification = classification
    self.safety = safety
    self.authPolicy = authPolicy
    self.routePolicy = routePolicy
    self.routeDiscriminators =
      routeDiscriminators.isEmpty ? nil : routeDiscriminators
    self.request = request
    self.responses = responses
    self.sourceRefs = sourceRefs
    self.verificationIds = verificationIds
  }

  public var hasUnknownFacts: Bool {
    self.protocol == .unknown
      || classification == .unknown
      || safety == .unknown
      || authPolicy == .unknown
      || routePolicy.isUnknown
      || serviceFamily.isEmpty
      || serviceFamily == "unknown"
      || productFamily.isEmpty
      || productFamily == "unknown"
  }
}

public struct ObservedCatalog: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let updatedAt: String
  public let operations: [ObservedOperation]
}

public enum SourceCoveragePolicy: String, Codable, Sendable {
  case required
  case deferred
  case excluded
}

public enum SourceStatus: String, Codable, Sendable {
  case captured
  case partial
  case missing
}

public struct SourceLockEntry: Codable, Equatable, Sendable {
  public let sourceId: String
  public let surface: SourceSurface
  public let version: String
  public let coverageAreas: [String]?
  public let coveragePolicy: SourceCoveragePolicy
  public let coverageRationale: String?
  public let sha256: String
  public let status: SourceStatus
  public let capturedAt: String?
  public let captureIds: [String]
  public let operationFingerprints: [String]
  public let evidenceFingerprints: [String]?

  public init(
    sourceId: String,
    surface: SourceSurface,
    version: String,
    coverageAreas: [String]? = nil,
    coveragePolicy: SourceCoveragePolicy,
    coverageRationale: String?,
    sha256: String,
    status: SourceStatus,
    capturedAt: String?,
    captureIds: [String],
    operationFingerprints: [String],
    evidenceFingerprints: [String]? = nil
  ) {
    self.sourceId = sourceId
    self.surface = surface
    self.version = version
    self.coverageAreas = coverageAreas
    self.coveragePolicy = coveragePolicy
    self.coverageRationale = coverageRationale
    self.sha256 = sha256
    self.status = status
    self.capturedAt = capturedAt
    self.captureIds = captureIds
    self.operationFingerprints = operationFingerprints
    self.evidenceFingerprints =
      evidenceFingerprints?.isEmpty == false ? evidenceFingerprints : nil
  }

  public var hasLockedEvidence: Bool {
    !operationFingerprints.isEmpty
      || evidenceFingerprints?.isEmpty == false
  }
}

public struct SourceLock: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let requiredCoverageAreas: [String]?
  public let sources: [SourceLockEntry]

  public init(
    schemaVersion: Int,
    kind: String,
    brand: String,
    market: String,
    requiredCoverageAreas: [String]? = nil,
    sources: [SourceLockEntry]
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.requiredCoverageAreas = requiredCoverageAreas
    self.sources = sources
  }
}

public struct CoverageReport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let zeroUnknown: Bool
  public let operationCount: Int
  public let classifiedCount: Int
  public let unknownOperationIds: [String]
  public let incompleteSourceIds: [String]
  public let deferredSourceIds: [String]
  public let excludedSourceIds: [String]
  public let requiredCoverageAreas: [String]?
  public let coveredCoverageAreas: [String]?
  public let missingCoverageAreas: [String]?
  public let unverifiedSafeOperationIds: [String]

  public init(
    schemaVersion: Int,
    kind: String,
    brand: String,
    market: String,
    zeroUnknown: Bool,
    operationCount: Int,
    classifiedCount: Int,
    unknownOperationIds: [String],
    incompleteSourceIds: [String],
    deferredSourceIds: [String],
    excludedSourceIds: [String],
    requiredCoverageAreas: [String]? = nil,
    coveredCoverageAreas: [String]? = nil,
    missingCoverageAreas: [String]? = nil,
    unverifiedSafeOperationIds: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.zeroUnknown = zeroUnknown
    self.operationCount = operationCount
    self.classifiedCount = classifiedCount
    self.unknownOperationIds = unknownOperationIds
    self.incompleteSourceIds = incompleteSourceIds
    self.deferredSourceIds = deferredSourceIds
    self.excludedSourceIds = excludedSourceIds
    self.requiredCoverageAreas = requiredCoverageAreas
    self.coveredCoverageAreas = coveredCoverageAreas
    self.missingCoverageAreas = missingCoverageAreas
    self.unverifiedSafeOperationIds = unverifiedSafeOperationIds
  }

  public var passesStrict: Bool {
    zeroUnknown
      && missingCoverageAreas?.isEmpty == true
      && unverifiedSafeOperationIds.isEmpty
  }
}

public struct CatalogIdentity: Codable, Equatable, Sendable {
  public let brand: String
  public let market: String
  public let updatedAt: String
}

public struct CatalogDiff: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let from: CatalogIdentity
  public let to: CatalogIdentity
  public let addedOperationIds: [String]
  public let removedOperationIds: [String]
  public let changedOperationIds: [String]
  public let unchangedCount: Int
}
