import Foundation

public struct VerificationHTTPResponse: Equatable, Sendable {
  public let status: Int
  public let headers: [String: String]
  public let body: Data
  public let finalURL: URL?

  public init(
    status: Int,
    headers: [String: String],
    body: Data = Data(),
    finalURL: URL? = nil
  ) {
    self.status = status
    self.headers = headers
    self.body = body
    self.finalURL = finalURL
  }
}

public protocol VerificationHTTPExecuting: Sendable {
  func execute(_ request: URLRequest) async throws -> VerificationHTTPResponse
}

public final class URLSessionVerificationExecutor:
  VerificationHTTPExecuting,
  @unchecked Sendable
{
  public static let defaultMaximumResponseBytes = 16 * 1_024 * 1_024

  private let session: URLSession
  private let maximumResponseBytes: Int

  public init(
    configuration: URLSessionConfiguration? = nil,
    maximumResponseBytes: Int = defaultMaximumResponseBytes
  ) {
    let resolvedConfiguration =
      (configuration?.copy() as? URLSessionConfiguration)
      ?? .ephemeral
    resolvedConfiguration.httpCookieStorage = nil
    resolvedConfiguration.httpShouldSetCookies = false
    resolvedConfiguration.urlCredentialStorage = nil
    resolvedConfiguration.urlCache = nil
    resolvedConfiguration.requestCachePolicy =
      .reloadIgnoringLocalCacheData
    self.session = URLSession(configuration: resolvedConfiguration)
    self.maximumResponseBytes = max(0, maximumResponseBytes)
  }

  public func execute(
    _ request: URLRequest
  ) async throws -> VerificationHTTPResponse {
    let redirectDelegate = NativeVerificationRedirectDelegate()
    let (temporaryURL, response) = try await session.download(
      for: request,
      delegate: redirectDelegate
    )
    guard let response = response as? HTTPURLResponse else {
      throw NativeVerificationError.nonHTTPResponse
    }
    guard response.url == request.url else {
      throw NativeVerificationError.responseURLMismatch(
        expected: request.url?.absoluteString ?? "",
        actual: response.url?.absoluteString
      )
    }
    if response.expectedContentLength > maximumResponseBytes {
      throw NativeVerificationError.responseBodyTooLarge(
        maximumBytes: maximumResponseBytes
      )
    }
    let data = try Self.readBoundedResponse(
      at: temporaryURL,
      maximumBytes: maximumResponseBytes
    )
    let headers = response.allHeaderFields.reduce(
      into: [String: String]()
    ) { result, entry in
      result[String(describing: entry.key).lowercased()] = String(
        describing: entry.value
      )
    }
    return VerificationHTTPResponse(
      status: response.statusCode,
      headers: headers,
      body: data,
      finalURL: response.url
    )
  }

  static func readBoundedResponse(
    at url: URL,
    maximumBytes: Int
  ) throws -> Data {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var result = Data()
    result.reserveCapacity(min(maximumBytes, 64 * 1_024))
    while true {
      let remaining = maximumBytes - result.count
      let chunk = try handle.read(
        upToCount: min(64 * 1_024, remaining + 1)
      ) ?? Data()
      guard !chunk.isEmpty else {
        return result
      }
      guard chunk.count <= remaining else {
        throw NativeVerificationError.responseBodyTooLarge(
          maximumBytes: maximumBytes
        )
      }
      result.append(chunk)
    }
  }
}

private final class NativeVerificationRedirectDelegate:
  NSObject, URLSessionTaskDelegate, @unchecked Sendable
{
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}

public struct VerificationRequestEvidence: Codable, Equatable, Sendable {
  public let finalURLTemplate: String
  public let headerNames: [String]
  public let cookieNames: [String]
  public let bodySchema: JSONValue?
  public let requestVariantSHA256: String?

  public init(
    finalURLTemplate: String,
    headerNames: [String],
    cookieNames: [String],
    bodySchema: JSONValue? = nil,
    requestVariantSHA256: String? = nil
  ) {
    self.finalURLTemplate = finalURLTemplate
    self.headerNames = headerNames
    self.cookieNames = cookieNames
    self.bodySchema = bodySchema
    self.requestVariantSHA256 = requestVariantSHA256
  }
}

public struct PrivateVerificationResponse: Codable, Equatable, Sendable {
  public let status: Int
  public let headers: [String: String]
  public let body: JSONValue?

  public init(
    status: Int,
    headers: [String: String],
    body: JSONValue?
  ) {
    self.status = status
    self.headers = headers
    self.body = body
  }
}

public struct NativeVerificationResult: Sendable {
  public let receipt: TrustVerificationReceipt
  public let requestEvidence: VerificationRequestEvidence
  public let privateResponse: PrivateVerificationResponse

  public init(
    receipt: TrustVerificationReceipt,
    requestEvidence: VerificationRequestEvidence,
    privateResponse: PrivateVerificationResponse
  ) {
    self.receipt = receipt
    self.requestEvidence = requestEvidence
    self.privateResponse = privateResponse
  }
}

struct NativePreparedVerificationRequest: Sendable {
  let resolved: ResolvedVerificationRequest
  let method: String
  let request: URLRequest
}

private enum NativeReversibleTransactionContext {
  @TaskLocal static var isAuthorized = false
}

public enum NativeVerificationError: Error, Equatable, LocalizedError {
  case unsupportedSchema(Int)
  case invalidKind(String)
  case scopeMismatch(String)
  case unknownSafety
  case highRiskWriteRejected
  case reversibleWriteRequiresAllow
  case reversibleWriteRequiresTransaction
  case safetyMismatch
  case methodMismatch
  case invalidURL(String)
  case urlTemplateMismatch
  case fingerprintMismatch
  case requestShapeMismatch([String])
  case responseStatusMismatch(expected: [Int], actual: Int)
  case authenticatedTextFixtureRequiresOmissionReason
  case nonHTTPResponse
  case responseURLMismatch(expected: String, actual: String?)
  case responseBodyTooLarge(maximumBytes: Int)
  case durableSecretMaterial
  case captureRequiresUnauthenticated
  case captureRequiresSafeRead
  case captureSourceMismatch
  case captureOperationMissing
  case captureRequestNotReconstructable

  public var errorDescription: String? {
    switch self {
    case .unsupportedSchema(let version):
      "Unsupported verification request schema version: \(version)"
    case .invalidKind(let kind):
      "Invalid private verification request kind: \(kind)"
    case .scopeMismatch(let scope):
      "Verification scope does not match: \(scope)"
    case .unknownSafety:
      "Request safety must be classified before verification."
    case .highRiskWriteRejected:
      "High-risk operations cannot be live-verified."
    case .reversibleWriteRequiresAllow:
      "Reversible writes require an explicit allowRemoteWrite flag."
    case .reversibleWriteRequiresTransaction:
      "Reversible writes must run through the durable reversible verification transaction."
    case .safetyMismatch:
      "Verification request safety does not match the Observed operation."
    case .methodMismatch:
      "Verification request method does not match the Observed operation."
    case .invalidURL(let url):
      "Verification request URL is invalid: \(url)"
    case .urlTemplateMismatch:
      "Verification URL does not match the Observed operation template."
    case .fingerprintMismatch:
      "Verification request shape does not match the Observed operation fingerprint."
    case .requestShapeMismatch(let fields):
      "Verification request shape differs from Observed fields: "
        + fields.joined(separator: ", ")
    case .responseStatusMismatch(let expected, let actual):
      "Verification response status \(actual) is not an Observed successful status: "
        + expected.map(String.init).joined(separator: ", ")
    case .authenticatedTextFixtureRequiresOmissionReason:
      "Authenticated textual responses require an explicit fixtureOmissionReason; raw text must remain private."
    case .nonHTTPResponse:
      "Verification transport returned a non-HTTP response."
    case .responseURLMismatch(let expected, let actual):
      "Verification response URL does not match the approved request URL: "
        + "expected \(expected), received \(actual ?? "none")."
    case .responseBodyTooLarge(let maximumBytes):
      "Verification response exceeds the \(maximumBytes)-byte limit."
    case .durableSecretMaterial:
      "Sanitized verification evidence still contains secret or personal material."
    case .captureRequiresUnauthenticated:
      "Capture-derived verification is limited to unauthenticated operations."
    case .captureRequiresSafeRead:
      "Capture-derived verification is limited to safe reads."
    case .captureSourceMismatch:
      "Capture receipt is not source evidence for the Observed operation."
    case .captureOperationMissing:
      "Capture receipt does not contain the Observed operation."
    case .captureRequestNotReconstructable:
      "Capture-derived verification cannot reconstruct this request."
    }
  }
}

public struct NativeOperationVerifier: Sendable {
  private let executor: any VerificationHTTPExecuting

  public init(
    executor: any VerificationHTTPExecuting = URLSessionVerificationExecutor()
  ) {
    self.executor = executor
  }

  public func verify(
    operation: ObservedOperation,
    requestSpec: PrivateVerificationRequestSpec,
    sessionSeed: PrivateSessionSeed? = nil,
    allowRemoteWrite: Bool = false,
    verifiedAt: String = ISO8601DateFormatter().string(from: Date())
  ) async throws -> NativeVerificationResult {
    if operation.safety == .reversibleWrite,
      !NativeReversibleTransactionContext.isAuthorized
    {
      throw NativeVerificationError.reversibleWriteRequiresTransaction
    }
    if requestSpec.responseExtraction != nil {
      try ReviewedResponseExtractor.validatePolicy(
        requestSpec.responseExtraction
      )
    }
    let prepared = try prepare(
      operation: operation,
      requestSpec: requestSpec,
      sessionSeed: sessionSeed,
      allowRemoteWrite: allowRemoteWrite
    )
    let response = try await executor.execute(prepared.request)
    try NativeRequestExecution.validateResponseURL(
      response.finalURL,
      for: prepared.request
    )
    let successfulStatuses = Set(
      operation.responses
        .filter { $0.outcome == .success }
        .map(\.status)
    )
    guard successfulStatuses.contains(response.status) else {
      throw NativeVerificationError.responseStatusMismatch(
        expected: successfulStatuses.sorted(),
        actual: response.status
      )
    }
    let responseBody = NativeRequestExecution.parseResponseBody(
      response.body,
      contentType: NativeRequestExecution.headerValue(
        response.headers,
        name: "content-type"
      )
    )
    let requestHeaders = prepared.request.allHTTPHeaderFields ?? [:]
    let raw = RawExchange(
      method: prepared.method,
      url: prepared.resolved.url,
      requestHeaders: requestHeaders,
      requestBody: prepared.resolved.body,
      requestContentType: NativeRequestExecution.headerValue(
        requestHeaders,
        name: "content-type"
      ),
      responseStatus: response.status,
      responseHeaders: response.headers,
      responseBody: responseBody,
      responseContentType: NativeRequestExecution.headerValue(
        response.headers,
        name: "content-type"
      ),
      startedAt: verifiedAt
    )
    let normalized = try HARImporter.normalize(
      raw,
      routeDiscriminatorQueryNames:
        operation.routeDiscriminators?.keys.sorted() ?? [],
      urlTemplateOverride: operation.urlTemplate
    )
    let responseProjection = try ReviewedResponseExtractor.project(
      response: normalized.response,
      fixture: responseBody,
      policy: requestSpec.responseExtraction
    )
    let requestEvidence = VerificationRequestEvidence(
      finalURLTemplate: normalized.urlTemplate,
      headerNames: normalized.request.headers.map(\.name).sorted(),
      cookieNames: normalized.request.cookieNames.sorted(),
      bodySchema: normalized.request.bodySchema,
      requestVariantSHA256: try ReviewedRequestVariant.validateAndDigest(
        request: prepared.request,
        routePolicy: operation.routePolicy
      )
    )
    let restoration =
      operation.safety == .reversibleWrite
      ? TrustRestorationProof(required: true, proven: false)
      : nil
    let fixtureOmissionReason = requestSpec.fixtureOmissionReason?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let shouldOmitFixture = fixtureOmissionReason?.isEmpty == false
    if operation.authPolicy != .none,
      case .string? = responseBody,
      !shouldOmitFixture
    {
      throw NativeVerificationError
        .authenticatedTextFixtureRequiresOmissionReason
    }
    let receipt = TrustVerificationReceipt(
      brand: requestSpec.brand,
      market: requestSpec.market,
      verificationId: try verificationId(
        operation: operation,
        verifiedAt: verifiedAt,
        response: responseProjection.response
      ),
      verificationKind: verificationKind(for: operation),
      verifiedAt: verifiedAt,
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      sourceRefs: operation.sourceRefs,
      requestEvidence: requestEvidence,
      response: responseProjection.response,
      responseFixture:
        shouldOmitFixture
        ? nil
        : responseProjection.fixture.map {
          EvidenceRedactor.redact($0)
        },
      fixtureOmissionReason:
        shouldOmitFixture ? fixtureOmissionReason : nil,
      restoration: restoration
    )
    try assertDurableEvidenceIsSanitized(
      receipt: receipt,
      requestEvidence: requestEvidence
    )
    return NativeVerificationResult(
      receipt: receipt,
      requestEvidence: requestEvidence,
      privateResponse: PrivateVerificationResponse(
        status: response.status,
        headers: response.headers,
        body: responseBody
      )
    )
  }

  func verifyReversibleTransactionStep(
    operation: ObservedOperation,
    requestSpec: PrivateVerificationRequestSpec,
    sessionSeed: PrivateSessionSeed?,
    verifiedAt: String
  ) async throws -> NativeVerificationResult {
    try await NativeReversibleTransactionContext.$isAuthorized.withValue(
      true
    ) {
      try await verify(
        operation: operation,
        requestSpec: requestSpec,
        sessionSeed: sessionSeed,
        allowRemoteWrite: true,
        verifiedAt: verifiedAt
      )
    }
  }

  func prepare(
    operation: ObservedOperation,
    requestSpec: PrivateVerificationRequestSpec,
    sessionSeed: PrivateSessionSeed?,
    allowRemoteWrite: Bool
  ) throws -> NativePreparedVerificationRequest {
    try validate(
      operation: operation,
      requestSpec: requestSpec,
      sessionSeed: sessionSeed,
      allowRemoteWrite: allowRemoteWrite
    )
    let resolved = try NativeRequestExecution.resolve(
      requestSpec,
      seed: sessionSeed
    )
    let inferredURLTemplate = try HARImporter.normalizeURLTemplate(resolved.url)
    guard
      HARImporter.urlTemplatesHaveEquivalentStructure(
        inferredURLTemplate,
        operation.urlTemplate
      )
    else {
      throw NativeVerificationError.urlTemplateMismatch
    }

    let method = (resolved.method ?? operation.method).uppercased()
    guard method == operation.method.uppercased() else {
      throw NativeVerificationError.methodMismatch
    }
    let request = try NativeRequestExecution.makeURLRequest(
      resolved,
      method: method,
      sessionSeed: sessionSeed
    )
    let requestHeaders = request.allHTTPHeaderFields ?? [:]
    let normalized = try HARImporter.normalize(
      RawExchange(
        method: method,
        url: resolved.url,
        requestHeaders: requestHeaders,
        requestBody: resolved.body,
        requestContentType: NativeRequestExecution.headerValue(
          requestHeaders,
          name: "content-type"
        ),
        responseStatus: 200,
        responseHeaders: ["content-type": "application/json"],
        responseBody: .object(["success": .bool(true)]),
        responseContentType: "application/json"
      ),
      routeDiscriminatorQueryNames:
        operation.routeDiscriminators?.keys.sorted() ?? [],
      urlTemplateOverride: operation.urlTemplate
    )
    let mismatches = requestShapeMismatches(
      normalized,
      operation: operation
    )
    guard mismatches.isEmpty else {
      throw NativeVerificationError.requestShapeMismatch(mismatches)
    }
    return NativePreparedVerificationRequest(
      resolved: resolved,
      method: method,
      request: request
    )
  }

  private func requestShapeMismatches(
    _ exchange: SanitizedExchange,
    operation: ObservedOperation
  ) -> [String] {
    var mismatches: [String] = []
    if exchange.method != operation.method {
      mismatches.append("method")
    }
    if !HARImporter.urlTemplatesHaveEquivalentStructure(
      exchange.urlTemplate,
      operation.urlTemplate
    ) {
      mismatches.append("urlTemplate")
    }
    if exchange.protocol != operation.protocol {
      mismatches.append("protocol")
    }
    if exchange.routeDiscriminators != operation.routeDiscriminators {
      mismatches.append("routeDiscriminators")
    }
    if exchange.request.contentType != operation.request.contentType {
      mismatches.append("contentType")
    }
    if exchange.request.queryNames != operation.request.queryNames {
      mismatches.append("queryNames")
    }
    if !schemasAreVerificationEquivalent(
      exchange.request.bodySchema,
      operation.request.bodySchema
    ) {
      mismatches.append("bodySchema")
    }
    if !schemaMapsAreVerificationEquivalent(
      exchange.request.encodedQuerySchemas,
      operation.request.encodedQuerySchemas
    ) {
      mismatches.append("encodedQuerySchemas")
    }
    if !schemaMapsAreVerificationEquivalent(
      exchange.request.encodedBodySchemas,
      operation.request.encodedBodySchemas
    ) {
      mismatches.append("encodedBodySchemas")
    }
    return mismatches
  }

  private func schemaMapsAreVerificationEquivalent(
    _ lhs: [String: JSONValue]?,
    _ rhs: [String: JSONValue]?
  ) -> Bool {
    guard lhs?.keys.sorted() == rhs?.keys.sorted() else {
      return false
    }
    return (lhs ?? [:]).allSatisfy { key, schema in
      schemasAreVerificationEquivalent(schema, rhs?[key])
    }
  }

  private func schemasAreVerificationEquivalent(
    _ lhs: JSONValue?,
    _ rhs: JSONValue?
  ) -> Bool {
    canonicalVerificationSchema(lhs) == canonicalVerificationSchema(rhs)
  }

  private func canonicalVerificationSchema(
    _ value: JSONValue?
  ) -> JSONValue? {
    guard let value else {
      return nil
    }
    switch value {
    case .array(let values):
      return .array(
        values.compactMap(canonicalVerificationSchema)
      )
    case .object(let values):
      var normalized = values.mapValues {
        canonicalVerificationSchema($0) ?? .null
      }
      if normalized["type"] == .string("object"),
        case .object = normalized["properties"]
      {
        // Open/closed-object inference is not a wire-level request difference.
        // Explicit property and required-field sets remain part of the gate.
        normalized.removeValue(forKey: "additionalProperties")
      }
      return .object(normalized)
    case .bool, .null, .number, .string:
      return value
    }
  }

  public static func requestFromCapture(
    operation: ObservedOperation,
    receipt: CaptureReceipt
  ) throws -> PrivateVerificationRequestSpec {
    guard operation.authPolicy == .none else {
      throw NativeVerificationError.captureRequiresUnauthenticated
    }
    guard operation.safety == .safeRead else {
      throw NativeVerificationError.captureRequiresSafeRead
    }
    let expectedReference = SourceReference(
      captureId: receipt.captureId,
      sourceId: receipt.source.sourceId,
      sourceVersion: receipt.source.version
    )
    guard operation.sourceRefs.contains(expectedReference) else {
      throw NativeVerificationError.captureSourceMismatch
    }
    guard
      let exchange = receipt.exchanges.first(where: {
        $0.fingerprint == operation.fingerprint
      }), exchange.urlTemplate == operation.urlTemplate
    else {
      throw NativeVerificationError.captureOperationMissing
    }
    guard ["GET", "HEAD"].contains(exchange.method.uppercased()),
      exchange.request.bodySchema == nil,
      isConcreteReplayURL(exchange.sanitizedURL)
    else {
      throw NativeVerificationError.captureRequestNotReconstructable
    }
    return PrivateVerificationRequestSpec(
      brand: receipt.brand,
      market: receipt.market,
      safety: operation.safety,
      url: exchange.sanitizedURL,
      method: exchange.method,
      headers: [
        "accept": preferredAcceptHeader(
          exchange.response.contentType
        ),
        "user-agent":
          "Mozilla/5.0 (compatible; WebAPIReverseVerification/1.0)",
      ]
    )
  }

  private func validate(
    operation: ObservedOperation,
    requestSpec: PrivateVerificationRequestSpec,
    sessionSeed: PrivateSessionSeed?,
    allowRemoteWrite: Bool
  ) throws {
    try NativeRequestExecution.validateSpec(
      requestSpec,
      sessionSeed: sessionSeed,
      requireDeclaredSafety: false,
      allowRemoteWrite: allowRemoteWrite
    )
    switch operation.safety {
    case .unknown:
      throw NativeVerificationError.unknownSafety
    case .highRiskWrite:
      throw NativeVerificationError.highRiskWriteRejected
    case .reversibleWrite where !allowRemoteWrite:
      throw NativeVerificationError.reversibleWriteRequiresAllow
    case .safeRead, .reversibleWrite:
      break
    }
    if let safety = requestSpec.safety,
      safety.rawValue != operation.safety.rawValue
    {
      throw NativeVerificationError.safetyMismatch
    }
  }

  private func verificationId(
    operation: ObservedOperation,
    verifiedAt: String,
    response: ResponseShape
  ) throws -> String {
    var responseObject: [String: JSONValue] = [
      "status": .number(Double(response.status)),
      "outcome": .string(response.outcome.rawValue),
      "businessErrorSignals": .array(
        response.businessErrorSignals.sorted().map(JSONValue.string)
      ),
    ]
    if let contentType = response.contentType {
      responseObject["contentType"] = .string(contentType)
    }
    if let schema = response.bodySchema {
      responseObject["bodySchema"] = schema
    }
    if let responseHeaderNames = response.responseHeaderNames {
      responseObject["responseHeaderNames"] = .array(
        responseHeaderNames.sorted().map(JSONValue.string)
      )
    }
    if let setCookieNames = response.setCookieNames {
      responseObject["setCookieNames"] = .array(
        setCookieNames.sorted().map(JSONValue.string)
      )
    }
    let identity: JSONValue = .object([
      "operationId": .string(operation.operationId),
      "fingerprint": .string(operation.fingerprint),
      "verifiedAt": .string(verifiedAt),
      "response": .object(responseObject),
    ])
    let digest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(identity)
    )
    return "ver_\(digest.prefix(16))"
  }

  private func assertDurableEvidenceIsSanitized(
    receipt: TrustVerificationReceipt,
    requestEvidence: VerificationRequestEvidence
  ) throws {
    let receiptText = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    let requestText = String(
      decoding: try DeterministicJSON.encode(requestEvidence),
      as: UTF8.self
    )
    guard !EvidenceRedactor.containsRawSecrets(in: receiptText),
      !EvidenceRedactor.containsRawSecrets(in: requestText)
    else {
      throw NativeVerificationError.durableSecretMaterial
    }
  }

  private func verificationKind(
    for operation: ObservedOperation
  ) -> EvidenceClass {
    if operation.safety == .reversibleWrite {
      return .reversibleWriteReplay
    }
    if operation.classification == .sessionLifecycle {
      return .lifecycleReplay
    }
    return .directReplay
  }

  private static func preferredAcceptHeader(
    _ contentType: String?
  ) -> String {
    contentType?.lowercased().contains("json") == true
      ? "application/json"
      : "*/*"
  }

  private static func isConcreteReplayURL(_ value: String) -> Bool {
    let lowercased = value.lowercased()
    return !lowercased.contains("[redacted]")
      && !lowercased.contains("%5bredacted%5d")
      && !lowercased.contains("{")
      && !lowercased.contains("}")
      && !lowercased.contains("%7b")
      && !lowercased.contains("%7d")
  }
}

enum NativeRequestExecution {
  static func validateSpec(
    _ requestSpec: PrivateVerificationRequestSpec,
    sessionSeed: PrivateSessionSeed?,
    requireDeclaredSafety: Bool,
    allowRemoteWrite: Bool
  ) throws {
    guard requestSpec.schemaVersion == 1 else {
      throw NativeVerificationError.unsupportedSchema(
        requestSpec.schemaVersion
      )
    }
    guard
      [
        "lifewear.api-request-capture",
        "lifewear.verification-request",
        "web-api-reverse.private-verification-request",
      ].contains(requestSpec.kind)
    else {
      throw NativeVerificationError.invalidKind(requestSpec.kind)
    }
    if let sessionSeed {
      guard sessionSeed.schemaVersion == 1 else {
        throw NativeVerificationError.unsupportedSchema(
          sessionSeed.schemaVersion
        )
      }
      guard
        sessionSeed.kind == "lifewear.session-seed"
          || sessionSeed.kind
            == "web-api-reverse.private-session-seed"
      else {
        throw NativeVerificationError.invalidKind(sessionSeed.kind)
      }
      guard sessionSeed.brand == requestSpec.brand,
        sessionSeed.market == requestSpec.market
      else {
        throw NativeVerificationError.scopeMismatch(
          "session \(sessionSeed.brand)/\(sessionSeed.market) "
            + "vs request \(requestSpec.brand)/\(requestSpec.market)"
        )
      }
    }
    if requireDeclaredSafety, requestSpec.safety == nil {
      throw NativeVerificationError.unknownSafety
    }
    switch requestSpec.safety {
    case .unknown:
      throw NativeVerificationError.unknownSafety
    case .highRiskWrite:
      throw NativeVerificationError.highRiskWriteRejected
    case .reversibleWrite where !allowRemoteWrite:
      throw NativeVerificationError.reversibleWriteRequiresAllow
    case .safeRead, .reversibleWrite, .none:
      break
    }
  }

  static func resolve(
    _ spec: PrivateVerificationRequestSpec,
    seed: PrivateSessionSeed?
  ) throws -> ResolvedVerificationRequest {
    try SessionMaterialResolver.resolve(spec, seed: seed)
  }

  static func makeURLRequest(
    _ resolved: ResolvedVerificationRequest,
    method: String,
    sessionSeed: PrivateSessionSeed?
  ) throws -> URLRequest {
    guard let url = URL(string: resolved.url),
      let components = URLComponents(
        url: url,
        resolvingAgainstBaseURL: false
      ),
      components.scheme?.lowercased() == "https",
      components.host?.isEmpty == false,
      components.user == nil,
      components.password == nil,
      components.fragment == nil
    else {
      throw NativeVerificationError.invalidURL(resolved.url)
    }
    var request = URLRequest(url: url)
    request.httpMethod = method
    for name in resolved.headers.keys.sorted() {
      request.setValue(resolved.headers[name], forHTTPHeaderField: name)
    }
    if resolved.body != nil,
      headerValue(
        request.allHTTPHeaderFields ?? [:],
        name: "content-type"
      ) == nil
    {
      request.setValue(
        "application/json",
        forHTTPHeaderField: "content-type"
      )
    }
    if let body = resolved.body {
      request.httpBody = try requestBodyData(
        body,
        contentType: headerValue(
          request.allHTTPHeaderFields ?? [:],
          name: "content-type"
        )
      )
    }
    if headerValue(
      request.allHTTPHeaderFields ?? [:],
      name: "cookie"
    ) == nil {
      let cookies = matchingCookies(
        sessionSeed?.cookies ?? [],
        url: url
      )
      if !cookies.isEmpty {
        request.setValue(
          cookies.map { "\($0.name)=\($0.value)" }
            .joined(separator: "; "),
          forHTTPHeaderField: "cookie"
        )
      }
    }
    return request
  }

  static func validateResponseURL(
    _ responseURL: URL?,
    for request: URLRequest
  ) throws {
    guard let responseURL else {
      throw NativeVerificationError.responseURLMismatch(
        expected: request.url?.absoluteString ?? "",
        actual: nil
      )
    }
    guard responseURL == request.url else {
      throw NativeVerificationError.responseURLMismatch(
        expected: request.url?.absoluteString ?? "",
        actual: responseURL.absoluteString
      )
    }
  }

  static func parseResponseBody(
    _ data: Data,
    contentType: String?
  ) -> JSONValue? {
    guard !data.isEmpty else {
      return nil
    }
    let text = String(decoding: data, as: UTF8.self)
    let trimmed = text.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    if contentType?.lowercased().contains("json") == true
      || trimmed.hasPrefix("{")
      || trimmed.hasPrefix("[")
    {
      return (try? JSONDecoder().decode(JSONValue.self, from: data))
        ?? .string(text)
    }
    return .string(text)
  }

  static func headerValue(
    _ headers: [String: String],
    name: String
  ) -> String? {
    headers.first {
      $0.key.caseInsensitiveCompare(name) == .orderedSame
    }?.value
  }

  private static func requestBodyData(
    _ body: JSONValue,
    contentType: String?
  ) throws -> Data {
    if contentType?.lowercased().contains(
      "application/x-www-form-urlencoded"
    ) == true, case .object(let object) = body {
      var components = URLComponents()
      components.queryItems = object.keys.sorted().map {
        URLQueryItem(
          name: $0,
          value: scalarString(object[$0])
        )
      }
      return Data((components.percentEncodedQuery ?? "").utf8)
    }
    if case .string(let value) = body,
      contentType?.lowercased().contains("json") != true
    {
      return Data(value.utf8)
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(body)
  }

  private static func matchingCookies(
    _ cookies: [PrivateSessionCookie],
    url: URL
  ) -> [PrivateSessionCookie] {
    guard let host = url.host else {
      return []
    }
    let path = url.path.isEmpty ? "/" : url.path
    let now = Date().timeIntervalSince1970
    return cookies.filter { cookie in
      let domain =
        cookie.domain.hasPrefix(".")
        ? String(cookie.domain.dropFirst())
        : cookie.domain
      let domainMatches =
        host == domain
        || host.hasSuffix(".\(domain)")
      let pathMatches = path.hasPrefix(
        cookie.path.isEmpty ? "/" : cookie.path
      )
      let unexpired = cookie.expires < 0 || cookie.expires > now
      let secureMatches = !cookie.secure || url.scheme == "https"
      return domainMatches
        && pathMatches
        && unexpired
        && secureMatches
    }.sorted {
      ($0.name, $0.domain, $0.path)
        < ($1.name, $1.domain, $1.path)
    }
  }

  private static func scalarString(_ value: JSONValue?) -> String {
    switch value {
    case .string(let value):
      return value
    case .number(let value):
      if value.rounded() == value {
        return String(Int64(value))
      } else {
        return String(value)
      }
    case .bool(let value):
      return value ? "true" : "false"
    case .null, .none:
      return ""
    case .array, .object:
      return (try? CanonicalEvidenceJSON.string(value ?? .null))
        .map {
          $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        ?? ""
    }
  }
}
