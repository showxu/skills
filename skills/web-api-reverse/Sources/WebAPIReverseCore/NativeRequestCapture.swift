import Foundation

public struct NativeRequestCaptureSource: Codable, Equatable, Sendable {
  public let surface: SourceSurface
  public let sourceId: String
  public let sourceVersion: String
  public let flow: String

  public init(
    surface: SourceSurface,
    sourceId: String,
    sourceVersion: String,
    flow: String = "native-request-capture"
  ) {
    self.surface = surface
    self.sourceId = sourceId
    self.sourceVersion = sourceVersion
    self.flow = flow
  }
}

public struct NativeRequestCaptureResult: Sendable {
  public let receipt: CaptureReceipt
  public let privateResponse: PrivateVerificationResponse

  public init(
    receipt: CaptureReceipt,
    privateResponse: PrivateVerificationResponse
  ) {
    self.receipt = receipt
    self.privateResponse = privateResponse
  }
}

public struct NativeRequestCapturer: Sendable {
  private let executor: any VerificationHTTPExecuting

  public init(
    executor: any VerificationHTTPExecuting = URLSessionVerificationExecutor()
  ) {
    self.executor = executor
  }

  public func capture(
    requestSpec: PrivateVerificationRequestSpec,
    source: NativeRequestCaptureSource,
    sessionSeed: PrivateSessionSeed? = nil,
    allowRemoteWrite: Bool = false,
    routeDiscriminatorQueryNames: [String] = [],
    capturedAt: String = ISO8601DateFormatter().string(from: Date())
  ) async throws -> NativeRequestCaptureResult {
    if requestSpec.safety == .reversibleWrite {
      throw NativeVerificationError.reversibleWriteRequiresTransaction
    }
    try NativeRequestExecution.validateSpec(
      requestSpec,
      sessionSeed: sessionSeed,
      requireDeclaredSafety: true,
      allowRemoteWrite: allowRemoteWrite
    )
    let resolved = try NativeRequestExecution.resolve(
      requestSpec,
      seed: sessionSeed
    )
    let method = (resolved.method ?? "GET").uppercased()
    let request = try NativeRequestExecution.makeURLRequest(
      resolved,
      method: method,
      sessionSeed: sessionSeed
    )
    let response = try await executor.execute(request)
    try NativeRequestExecution.validateResponseURL(
      response.finalURL,
      for: request
    )
    let responseContentType = NativeRequestExecution.headerValue(
      response.headers,
      name: "content-type"
    )
    let responseBody = NativeRequestExecution.parseResponseBody(
      response.body,
      contentType: responseContentType
    )
    let requestHeaders = request.allHTTPHeaderFields ?? [:]
    let responseURL = response.finalURL?.absoluteString ?? resolved.url
    let raw = RawExchange(
      method: method,
      url: responseURL,
      requestHeaders: requestHeaders,
      requestBody: resolved.body,
      requestContentType: NativeRequestExecution.headerValue(
        requestHeaders,
        name: "content-type"
      ),
      responseStatus: response.status,
      responseHeaders: response.headers,
      responseBody: responseBody,
      responseContentType: responseContentType,
      startedAt: capturedAt
    )
    let normalized = try HARImporter.normalize(
      raw,
      routeDiscriminatorQueryNames: routeDiscriminatorQueryNames
    )
    let sourceHash = FileDigest.sha256(
      data: try DeterministicJSON.encode(normalized)
    )
    let captureSource = CaptureSource(
      sourceId: source.sourceId,
      surface: source.surface,
      version: source.sourceVersion,
      sha256: sourceHash,
      entryURL: try HARImporter.normalizeURLTemplate(responseURL)
    )
    let captureID = try HARImporter.makeCaptureId(
      brand: requestSpec.brand,
      market: requestSpec.market,
      source: captureSource,
      flow: source.flow,
      context: nil,
      selection: nil,
      exchanges: [normalized]
    )
    let receipt = CaptureReceipt(
      captureId: captureID,
      capturedAt: capturedAt,
      brand: requestSpec.brand,
      market: requestSpec.market,
      source: captureSource,
      flow: source.flow,
      exchanges: [normalized]
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    guard !EvidenceRedactor.containsRawSecrets(in: durable) else {
      throw CapturePipelineError.secretMaterialDetected
    }
    return NativeRequestCaptureResult(
      receipt: receipt,
      privateResponse: PrivateVerificationResponse(
        status: response.status,
        headers: response.headers,
        body: responseBody
      )
    )
  }
}
