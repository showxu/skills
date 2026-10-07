import Foundation

public struct CaptureSource: Codable, Equatable, Sendable {
  public let sourceId: String
  public let surface: SourceSurface
  public let version: String
  public let sha256: String
  public let entryURL: String?

  public init(
    sourceId: String,
    surface: SourceSurface,
    version: String,
    sha256: String,
    entryURL: String? = nil
  ) {
    self.sourceId = sourceId
    self.surface = surface
    self.version = version
    self.sha256 = sha256
    self.entryURL = entryURL
  }
}

public struct CaptureContext: Codable, Equatable, Sendable {
  public let kind: String
  public let browser: String
  public let browserVersion: String
  public let headless: Bool
  public let device: String?

  public init(
    kind: String = "playwright",
    browser: String,
    browserVersion: String,
    headless: Bool,
    device: String? = nil
  ) {
    self.kind = kind
    self.browser = browser
    self.browserVersion = browserVersion
    self.headless = headless
    self.device = device
  }
}

public struct CaptureSelection: Codable, Equatable, Sendable {
  public let kind: String
  public let patterns: [String]
  public let totalExchangeCount: Int
  public let selectedExchangeCount: Int

  public init(
    kind: String = "include-url-regex",
    patterns: [String],
    totalExchangeCount: Int,
    selectedExchangeCount: Int
  ) {
    self.kind = kind
    self.patterns = patterns
    self.totalExchangeCount = totalExchangeCount
    self.selectedExchangeCount = selectedExchangeCount
  }
}

public struct RawExchange: Codable, Equatable, Sendable {
  public let method: String
  public let url: String
  public let requestHeaders: [String: String]
  public let requestBody: JSONValue?
  public let requestContentType: String?
  public let responseStatus: Int
  public let responseHeaders: [String: String]
  public let responseCookieNames: [String]?
  public let responseBody: JSONValue?
  public let responseContentType: String?
  public let startedAt: String?
  public let durationMs: Double?

  public init(
    method: String,
    url: String,
    requestHeaders: [String: String],
    requestBody: JSONValue? = nil,
    requestContentType: String? = nil,
    responseStatus: Int,
    responseHeaders: [String: String],
    responseCookieNames: [String]? = nil,
    responseBody: JSONValue? = nil,
    responseContentType: String? = nil,
    startedAt: String? = nil,
    durationMs: Double? = nil
  ) {
    self.method = method
    self.url = url
    self.requestHeaders = requestHeaders
    self.requestBody = requestBody
    self.requestContentType = requestContentType
    self.responseStatus = responseStatus
    self.responseHeaders = responseHeaders
    self.responseCookieNames = responseCookieNames
    self.responseBody = responseBody
    self.responseContentType = responseContentType
    self.startedAt = startedAt
    self.durationMs = durationMs
  }
}

public struct SanitizedExchange: Codable, Equatable, Sendable {
  public let exchangeId: String
  public let operationId: String
  public let fingerprint: String
  public let method: String
  public let sanitizedURL: String
  public let urlTemplate: String
  public let `protocol`: OperationProtocol
  public let routeDiscriminators: [String: String]?
  public let request: RequestShape
  public let response: ResponseShape
  public let startedAt: String?
  public let durationMs: Double?

  public init(
    exchangeId: String,
    operationId: String,
    fingerprint: String,
    method: String,
    sanitizedURL: String,
    urlTemplate: String,
    protocol: OperationProtocol,
    routeDiscriminators: [String: String] = [:],
    request: RequestShape,
    response: ResponseShape,
    startedAt: String? = nil,
    durationMs: Double? = nil
  ) {
    self.exchangeId = exchangeId
    self.operationId = operationId
    self.fingerprint = fingerprint
    self.method = method
    self.sanitizedURL = sanitizedURL
    self.urlTemplate = urlTemplate
    self.protocol = `protocol`
    self.routeDiscriminators =
      routeDiscriminators.isEmpty ? nil : routeDiscriminators
    self.request = request
    self.response = response
    self.startedAt = startedAt
    self.durationMs = durationMs
  }
}

public struct CaptureReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let captureId: String
  public let capturedAt: String
  public let brand: String
  public let market: String
  public let source: CaptureSource
  public let flow: String
  public let captureContext: CaptureContext?
  public let captureSelection: CaptureSelection?
  public let exchanges: [SanitizedExchange]

  public init(
    captureId: String,
    capturedAt: String,
    brand: String,
    market: String,
    source: CaptureSource,
    flow: String,
    captureContext: CaptureContext? = nil,
    captureSelection: CaptureSelection? = nil,
    exchanges: [SanitizedExchange]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.capture-receipt"
    self.captureId = captureId
    self.capturedAt = capturedAt
    self.brand = brand
    self.market = market
    self.source = source
    self.flow = flow
    self.captureContext = captureContext
    self.captureSelection = captureSelection
    self.exchanges = exchanges
  }
}

public struct OperationAnnotation: Codable, Equatable, Sendable {
  public let fingerprint: String
  public let operationId: String?
  public let serviceFamily: String
  public let productFamily: String
  public let classification: OperationClassification
  public let safety: OperationSafety
  public let authPolicy: AuthPolicy
  public let routePolicy: RoutePolicy

  public init(
    fingerprint: String,
    operationId: String? = nil,
    serviceFamily: String,
    productFamily: String,
    classification: OperationClassification,
    safety: OperationSafety,
    authPolicy: AuthPolicy,
    routePolicy: RoutePolicy
  ) {
    self.fingerprint = fingerprint
    self.operationId = operationId
    self.serviceFamily = serviceFamily
    self.productFamily = productFamily
    self.classification = classification
    self.safety = safety
    self.authPolicy = authPolicy
    self.routePolicy = routePolicy
  }
}

public struct AnnotationFile: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let operations: [OperationAnnotation]

  public init(
    brand: String,
    market: String,
    operations: [OperationAnnotation]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.operation-annotations"
    self.brand = brand
    self.market = market
    self.operations = operations
  }
}

public struct ExpectedSource: Codable, Equatable, Sendable {
  public let sourceId: String
  public let surface: SourceSurface
  public let version: String
  public let coverageAreas: [String]?
  public let coveragePolicy: SourceCoveragePolicy?
  public let coverageRationale: String?
  public let status: SourceStatus?

  public init(
    sourceId: String,
    surface: SourceSurface,
    version: String,
    coverageAreas: [String]? = nil,
    coveragePolicy: SourceCoveragePolicy? = nil,
    coverageRationale: String? = nil,
    status: SourceStatus? = nil
  ) {
    self.sourceId = sourceId
    self.surface = surface
    self.version = version
    self.coverageAreas = coverageAreas
    self.coveragePolicy = coveragePolicy
    self.coverageRationale = coverageRationale
    self.status = status
  }
}

public struct SourceManifest: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let requiredCoverageAreas: [String]?
  public let sources: [ExpectedSource]

  public init(
    brand: String,
    market: String,
    requiredCoverageAreas: [String]? = nil,
    sources: [ExpectedSource]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.source-manifest"
    self.brand = brand
    self.market = market
    self.requiredCoverageAreas = requiredCoverageAreas
    self.sources = sources
  }
}

public struct InventoryResult: Codable, Equatable, Sendable {
  public let catalog: ObservedCatalog
  public let sourceLock: SourceLock

  public init(catalog: ObservedCatalog, sourceLock: SourceLock) {
    self.catalog = catalog
    self.sourceLock = sourceLock
  }
}

public enum CapturePipelineError: Error, Equatable, LocalizedError {
  case invalidHAR
  case invalidURL(String)
  case invalidIncludePattern(String)
  case emptySelection
  case emptyInventory
  case scopeMismatch(expectedBrand: String, expectedMarket: String)
  case duplicateAnnotation(String)
  case duplicateSourceRevision(String)
  case missingCoverageRationale(String)
  case missingRequiredCoverageAreas
  case invalidCoverageArea(String)
  case duplicateCoverageArea(scope: String, area: String)
  case missingSourceCoverageAreas(String)
  case unassignedRequiredCoverageArea(String)
  case undeclaredSourceRevision(String)
  case sourceSurfaceMismatch(
    source: String,
    expected: SourceSurface,
    actual: SourceSurface
  )
  case conflictingSourceSHA(String)
  case unsafeRouteDiscriminator(String)
  case secretMaterialDetected

  public var errorDescription: String? {
    switch self {
    case .invalidHAR:
      "The HAR document does not contain a valid log.entries array."
    case .invalidURL(let value):
      "Invalid absolute URL: \(value)"
    case .invalidIncludePattern(let value):
      "Invalid include URL regular expression: \(value)"
    case .emptySelection:
      "HAR selection did not match any exchanges."
    case .emptyInventory:
      "Inventory requires at least one capture receipt."
    case .scopeMismatch(let brand, let market):
      "Evidence does not match the expected scope \(brand)/\(market)."
    case .duplicateAnnotation(let value):
      "Duplicate operation annotation: \(value)"
    case .duplicateSourceRevision(let value):
      "Duplicate source revision: \(value)"
    case .missingCoverageRationale(let value):
      "Source \(value) requires a coverage rationale."
    case .missingRequiredCoverageAreas:
      "The source manifest must declare at least one required coverage area."
    case .invalidCoverageArea(let value):
      "Coverage area \(value) must use lowercase kebab-case."
    case .duplicateCoverageArea(let scope, let area):
      "Duplicate coverage area \(area) in \(scope)."
    case .missingSourceCoverageAreas(let value):
      "Required source \(value) must declare at least one coverage area."
    case .unassignedRequiredCoverageArea(let value):
      "Required coverage area \(value) is not assigned to a required source."
    case .undeclaredSourceRevision(let value):
      "Capture source revision \(value) is not declared in the source manifest."
    case .sourceSurfaceMismatch(let source, let expected, let actual):
      "Capture source \(source) uses surface \(actual.rawValue); expected \(expected.rawValue)."
    case .conflictingSourceSHA(let value):
      "Source revision \(value) has conflicting SHA-256 evidence."
    case .unsafeRouteDiscriminator(let value):
      "Route discriminator \(value) contains a value that is not safe durable evidence."
    case .secretMaterialDetected:
      "Sanitized capture evidence still contains secret or personal material."
    }
  }
}

enum CanonicalEvidenceJSON {
  static func data(_ value: JSONValue) throws -> Data {
    var data = try JSONSerialization.data(
      withJSONObject: value.foundationValue,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    data.append(0x0A)
    return data
  }

  static func string(_ value: JSONValue) throws -> String {
    String(decoding: try data(value), as: UTF8.self)
  }
}

extension JSONValue {
  var foundationValue: Any {
    switch self {
    case .object(let value):
      value.mapValues(\.foundationValue)
    case .array(let value):
      value.map(\.foundationValue)
    case .string(let value):
      value
    case .number(let value):
      value
    case .bool(let value):
      value
    case .null:
      NSNull()
    }
  }
}
