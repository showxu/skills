import Foundation

public enum BundleRouteForm: String, Codable, Equatable, Sendable {
  case absolute
  case rootRelative
}

public struct BundleRouteAsset: Codable, Equatable, Sendable {
  public let bundleId: String
  public let sanitizedURL: String
  public let sha256: String
  public let byteCount: Int
  public let contentType: String?

  public init(
    bundleId: String,
    sanitizedURL: String,
    sha256: String,
    byteCount: Int,
    contentType: String? = nil
  ) {
    self.bundleId = bundleId
    self.sanitizedURL = sanitizedURL
    self.sha256 = sha256
    self.byteCount = byteCount
    self.contentType = contentType
  }
}

public struct BundleRouteCandidate: Codable, Equatable, Sendable {
  public let candidateId: String
  public let route: String
  public let form: BundleRouteForm
  public let queryNames: [String]
  public let bundleIds: [String]

  public init(
    candidateId: String,
    route: String,
    form: BundleRouteForm,
    queryNames: [String],
    bundleIds: [String]
  ) {
    self.candidateId = candidateId
    self.route = route
    self.form = form
    self.queryNames = queryNames
    self.bundleIds = bundleIds
  }
}

public struct BundleRouteInventoryReceipt:
  Codable, Equatable, Sendable
{
  public let schemaVersion: Int
  public let kind: String
  public let receiptId: String
  public let capturedAt: String
  public let brand: String
  public let market: String
  public let source: CaptureSource
  public let bundles: [BundleRouteAsset]
  public let candidates: [BundleRouteCandidate]

  public init(
    receiptId: String,
    capturedAt: String,
    brand: String,
    market: String,
    source: CaptureSource,
    bundles: [BundleRouteAsset],
    candidates: [BundleRouteCandidate]
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.bundle-route-candidates"
    self.receiptId = receiptId
    self.capturedAt = capturedAt
    self.brand = brand
    self.market = market
    self.source = source
    self.bundles = bundles
    self.candidates = candidates
  }
}

public struct BundleRouteInventoryOptions: Equatable, Sendable {
  public let brand: String
  public let market: String
  public let surface: SourceSurface
  public let sourceId: String
  public let sourceVersion: String
  public let capturedAt: String?
  public let maximumBundleBytes: Int
  public let maximumTotalBytes: Int

  public init(
    brand: String,
    market: String,
    surface: SourceSurface,
    sourceId: String,
    sourceVersion: String,
    capturedAt: String? = nil,
    maximumBundleBytes: Int = 8 * 1_024 * 1_024,
    maximumTotalBytes: Int = 64 * 1_024 * 1_024
  ) {
    self.brand = brand
    self.market = market
    self.surface = surface
    self.sourceId = sourceId
    self.sourceVersion = sourceVersion
    self.capturedAt = capturedAt
    self.maximumBundleBytes = maximumBundleBytes
    self.maximumTotalBytes = maximumTotalBytes
  }
}

public enum BundleRouteInventoryError: Error, Equatable, LocalizedError {
  case invalidHAR
  case invalidLimits
  case emptySelection
  case malformedBundle(String)
  case oversizedBundle(String, Int)
  case oversizedInventory(Int)
  case secretMaterialDetected

  public var errorDescription: String? {
    switch self {
    case .invalidHAR:
      "The private HAR is not a valid HAR 1.x document."
    case .invalidLimits:
      "Bundle inventory byte limits must be positive and total must not be smaller than one bundle."
    case .emptySelection:
      "The private HAR contains no successful embedded JavaScript responses."
    case .malformedBundle(let url):
      "The JavaScript response body is malformed or not UTF-8: \(url)"
    case .oversizedBundle(let url, let byteCount):
      "The JavaScript response exceeds the per-bundle limit (\(byteCount) bytes): \(url)"
    case .oversizedInventory(let byteCount):
      "The selected JavaScript responses exceed the total inventory limit (\(byteCount) bytes)."
    case .secretMaterialDetected:
      "The sanitized bundle-route receipt still contains sensitive material."
    }
  }
}
