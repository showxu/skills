import Foundation

public struct PrivateHARRequestExtractionResult:
  Equatable, Sendable
{
  public let requestSpec: PrivateVerificationRequestSpec
  public let matchedExchangeCount: Int

  public init(
    requestSpec: PrivateVerificationRequestSpec,
    matchedExchangeCount: Int
  ) {
    self.requestSpec = requestSpec
    self.matchedExchangeCount = matchedExchangeCount
  }
}

public enum PrivateHARRequestExtractionError:
  Error, Equatable, LocalizedError
{
  case invalidHAR
  case sourceDigestMismatch
  case scopeMismatch
  case operationSourceMismatch
  case operationMissing

  public var errorDescription: String? {
    switch self {
    case .invalidHAR:
      "The private request source is not a valid HAR document."
    case .sourceDigestMismatch:
      "The private HAR does not match the selected capture receipt."
    case .scopeMismatch:
      "The capture receipt and Observed operation do not share a provider scope."
    case .operationSourceMismatch:
      "The capture receipt is not source evidence for the selected operation."
    case .operationMissing:
      "The private HAR does not contain the selected Observed operation."
    }
  }
}

public struct PrivateHARRequestExtractor: Sendable {
  public init() {}

  public func extract(
    harURL: URL,
    captureReceipt: CaptureReceipt,
    operation: ObservedOperation
  ) throws -> PrivateHARRequestExtractionResult {
    try extract(
      harData: Data(contentsOf: harURL),
      captureReceipt: captureReceipt,
      operation: operation
    )
  }

  public func extract(
    harData: Data,
    captureReceipt: CaptureReceipt,
    operation: ObservedOperation
  ) throws -> PrivateHARRequestExtractionResult {
    guard
      FileDigest.sha256(data: harData)
        == captureReceipt.source.sha256
    else {
      throw PrivateHARRequestExtractionError
        .sourceDigestMismatch
    }
    guard
      captureReceipt.brand.isEmpty == false,
      captureReceipt.market.isEmpty == false
    else {
      throw PrivateHARRequestExtractionError.scopeMismatch
    }
    let sourceReference = SourceReference(
      captureId: captureReceipt.captureId,
      sourceId: captureReceipt.source.sourceId,
      sourceVersion: captureReceipt.source.version
    )
    guard operation.sourceRefs.contains(sourceReference) else {
      throw PrivateHARRequestExtractionError
        .operationSourceMismatch
    }

    let document: HARDocument
    do {
      document = try JSONDecoder().decode(
        HARDocument.self,
        from: harData
      )
    } catch {
      throw PrivateHARRequestExtractionError.invalidHAR
    }
    let receiptExchangeIDs = Set(
      captureReceipt.exchanges
        .filter {
          $0.fingerprint == operation.fingerprint
            && $0.urlTemplate == operation.urlTemplate
            && $0.method.uppercased()
              == operation.method.uppercased()
        }
        .map(\.exchangeId)
    )
    let routeDiscriminatorNames =
      operation.routeDiscriminators?.keys.sorted() ?? []
    var matches: [(RawExchange, SanitizedExchange)] = []
    for entry in document.log.entries {
      guard
        let scheme = URLComponents(string: entry.request.url)?.scheme?
          .lowercased(),
        scheme == "http" || scheme == "https"
      else {
        continue
      }
      let raw = try HARImporter.rawExchange(entry)
      let normalized = try HARImporter.normalize(
        raw,
        routeDiscriminatorQueryNames:
          routeDiscriminatorNames
      )
      guard
        receiptExchangeIDs.contains(normalized.exchangeId),
        normalized.fingerprint == operation.fingerprint,
        normalized.urlTemplate == operation.urlTemplate,
        normalized.method.uppercased()
          == operation.method.uppercased()
      else {
        continue
      }
      matches.append((raw, normalized))
    }
    guard let selected = matches.last else {
      throw PrivateHARRequestExtractionError.operationMissing
    }

    let excludedHeaderNames =
      Self.transportManagedHeaderNames.union(
        operation.safety == .safeRead
          ? Self.safeReadCacheHeaderNames : []
      )
    var headers = selected.0.requestHeaders.filter {
      !excludedHeaderNames.contains($0.key.lowercased())
        && !$0.key.hasPrefix(":")
    }
    if headers.keys.contains(where: {
      $0.caseInsensitiveCompare("content-type") == .orderedSame
    }) == false,
      let contentType = selected.0.requestContentType
    {
      headers["content-type"] = contentType
    }
    return PrivateHARRequestExtractionResult(
      requestSpec: PrivateVerificationRequestSpec(
        brand: captureReceipt.brand,
        market: captureReceipt.market,
        safety: operation.safety,
        url: selected.0.url,
        method: selected.0.method.uppercased(),
        headers: headers,
        body: selected.0.requestBody
      ),
      matchedExchangeCount: matches.count
    )
  }

  private static let transportManagedHeaderNames: Set<String> = [
    "accept-encoding",
    "connection",
    "content-length",
    "host",
    "keep-alive",
    "proxy-connection",
    "transfer-encoding",
    "upgrade",
  ]

  private static let safeReadCacheHeaderNames: Set<String> = [
    "if-modified-since",
    "if-none-match",
    "if-range",
    "range",
  ]
}
