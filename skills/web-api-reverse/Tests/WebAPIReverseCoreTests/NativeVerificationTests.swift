import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Native operation verification")
struct NativeVerificationTests {
  @Test("Native transport binds the final URL and rejects insecure request URLs")
  func bindsTransportIdentityBeforeResponseProcessing() async throws {
    let expectedURL = URL(
      string: "https://api.example.test/products/current"
    )!
    #expect(
      throws: NativeVerificationError.responseURLMismatch(
        expected: expectedURL.absoluteString,
        actual: nil
      )
    ) {
      try NativeRequestExecution.validateResponseURL(
        nil,
        for: URLRequest(url: expectedURL)
      )
    }

    let operation = try observedOperation(
      url: expectedURL.absoluteString,
      method: "GET"
    )
    let redirected = RecordingVerificationExecutor(
      response: VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "application/json"],
        body: Data(#"{"success":true}"#.utf8),
        finalURL: URL(string: "https://untrusted.example/products/current")
      )
    )
    await #expect(
      throws: NativeVerificationError.responseURLMismatch(
        expected: "https://api.example.test/products/current",
        actual: "https://untrusted.example/products/current"
      )
    ) {
      _ = try await NativeOperationVerifier(executor: redirected).verify(
        operation: operation,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "https://api.example.test/products/current",
          method: "GET"
        )
      )
    }

    let insecure = try observedOperation(
      url: "http://api.example.test/products/current",
      method: "GET"
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )
    await #expect(
      throws: NativeVerificationError.invalidURL(
        "http://api.example.test/products/current"
      )
    ) {
      _ = try await NativeOperationVerifier(executor: executor).verify(
        operation: insecure,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "http://api.example.test/products/current",
          method: "GET"
        )
      )
    }
    #expect(await executor.requestCount() == 0)
  }

  @Test("Native transport reads response files only up to the configured limit")
  func boundsNativeResponseFiles() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: "native-response-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    let exactURL = root.appending(path: "exact.bin")
    let oversizedURL = root.appending(path: "oversized.bin")
    try Data(repeating: 0x41, count: 8).write(to: exactURL)
    try Data(repeating: 0x42, count: 9).write(to: oversizedURL)

    #expect(
      try URLSessionVerificationExecutor.readBoundedResponse(
        at: exactURL,
        maximumBytes: 8
      ) == Data(repeating: 0x41, count: 8)
    )
    #expect(
      throws: NativeVerificationError.responseBodyTooLarge(
        maximumBytes: 8
      )
    ) {
      _ = try URLSessionVerificationExecutor.readBoundedResponse(
        at: oversizedURL,
        maximumBytes: 8
      )
    }
  }

  @Test("Public Product identifiers are not treated as personal identity numbers")
  func preservesPublicIdentityShapedProductIdentifiers() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/products/current",
      method: "GET"
    )
    let productID = "110105194912310021"
    let executor = RecordingVerificationExecutor(
      response: jsonResponse([
        "description": "Reference 110105194912310021 is not account data.",
        "productId": productID,
      ])
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: "https://api.example.test/products/current",
        method: "GET"
      ),
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    #expect(
      result.receipt.responseFixture
        == .object([
          "description": .string("Reference [REDACTED] is not account data."),
          "productId": .string(productID),
        ])
    )
  }

  @Test("Executes a session-templated request and emits sanitized durable evidence")
  func verifiesTemplatedRequest() async throws {
    let seed = verificationSessionSeed()
    let resolvedBody: JSONValue = .object([
      "expiration": .string("1700003600000"),
      "refreshToken": .string("private-refresh-token"),
    ])
    let operation = try observedOperation(
      url: "https://i.example.test/p/favorites",
      method: "POST",
      headers: [
        "authorization": "Bearer private-access-token",
        "content-type": "application/json",
        "cookie": "session=private-cookie",
      ],
      body: resolvedBody,
      safety: .safeRead,
      authPolicy: .sessionHeadersAndCookies
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse([
        "success": true,
        "userId": "private-user-id",
      ])
    )
    let spec = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      safety: .safeRead,
      url: "https://{{session.apiHost}}/p/favorites",
      method: "POST",
      headers: [
        "authorization": "Bearer {{session.accessToken}}",
        "content-type": "application/json",
      ],
      body: .object([
        "expiration": .string("{{session.expiration}}"),
        "refreshToken": .string("{{session.refreshToken}}"),
      ]),
      sessionAliases: [
        "accessToken": ["access_token"],
        "duration": ["expires_in"],
        "environment": ["env"],
        "fetchedAt": ["fetched_at"],
        "refreshToken": ["refresh_token"],
      ],
      sessionDerivations: [
        "apiHost": .lookup(
          sourceField: "environment",
          values: ["idc": "i.example.test"],
          missingValue: nil
        ),
        "expiration": .unixExpirationMilliseconds(
          fetchedAtField: "fetchedAt",
          durationSecondsField: "duration"
        ),
      ]
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: spec,
      sessionSeed: seed,
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    let request = try #require(await executor.lastRequest())
    #expect(request.url?.absoluteString == "https://i.example.test/p/favorites")
    #expect(
      request.value(forHTTPHeaderField: "authorization")
        == "Bearer private-access-token"
    )
    #expect(
      request.value(forHTTPHeaderField: "cookie")
        == "session=private-cookie"
    )
    #expect(
      try JSONDecoder().decode(
        JSONValue.self,
        from: request.httpBody ?? Data()
      ) == resolvedBody
    )
    #expect(result.receipt.verificationKind == .directReplay)
    #expect(result.receipt.response.outcome == .success)
    #expect(result.requestEvidence.cookieNames == ["session"])
    #expect(
      result.receipt.responseFixture
        == .object([
          "success": .bool(true),
          "userId": .string("[REDACTED]"),
        ])
    )
    #expect(
      result.privateResponse.body
        == .object([
          "success": .bool(true),
          "userId": .string("private-user-id"),
        ])
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(result.receipt),
      as: UTF8.self
    )
    for secret in [
      "private-access-token",
      "private-refresh-token",
      "private-cookie",
      "private-user-id",
    ] {
      #expect(!durable.contains(secret))
    }
  }

  @Test("Session lifecycle operations emit lifecycle replay evidence")
  func emitsLifecycleReplayEvidence() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/session/refresh",
      method: "POST",
      classification: .sessionLifecycle,
      authPolicy: .refreshTokenOnly
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: "https://api.example.test/session/refresh",
        method: "POST"
      ),
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    #expect(result.receipt.verificationKind == .lifecycleReplay)
  }

  @Test("Explicit fixture omission retains only the private response body")
  func omitsDurableFixtureWhenRequested() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/account/favorites",
      method: "GET",
      authPolicy: .sessionHeadersAndCookies
    )
    let executor = RecordingVerificationExecutor(
      response: VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "text/html; charset=utf-8"],
        body: Data("<a data-sku=\"private-sku\">Favorite</a>".utf8)
      )
    )
    let reason = "Authenticated account HTML is intentionally not retained."

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: "https://api.example.test/account/favorites",
        method: "GET",
        fixtureOmissionReason: reason
      ),
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    #expect(result.receipt.responseFixture == nil)
    #expect(result.receipt.fixtureOmissionReason == reason)
    #expect(
      result.privateResponse.body
        == .string("<a data-sku=\"private-sku\">Favorite</a>")
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(result.receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("private-sku"))
  }

  @Test("Private dynamic JSONP retains schema after omitting response values")
  func projectsPrivateDynamicJSONPBeforeOmission() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/account/favorites?callback=fixture8",
      method: "GET",
      authPolicy: .sessionHeadersAndCookies
    )
    let executor = RecordingVerificationExecutor(
      response: VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "application/json;charset=UTF-8"],
        body: Data(
          #"fixture8({"data":{"items":[{"itemId":"private-item"}]},"ret":["SUCCESS::调用成功"]})"#
            .utf8
        )
      )
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url:
          "https://api.example.test/account/favorites?callback=fixture8",
        method: "GET",
        responseExtraction: .object([
          "callbackQueryName": .string("callback"),
          "kind": .string("jsonP"),
        ]),
        fixtureOmissionReason:
          "Authenticated Favorite values are intentionally private."
      ),
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    #expect(result.receipt.responseFixture == nil)
    #expect(result.receipt.response.contentType == "application/json")
    guard
      case .object(let schema)? = result.receipt.response.bodySchema,
      case .object(let properties)? = schema["properties"],
      case .object(let data)? = properties["data"]
    else {
      Issue.record("Expected the private JSONP object schema")
      return
    }
    #expect(data["type"] == .string("object"))
    guard case .string(let privateBody)? = result.privateResponse.body else {
      Issue.record("Expected the raw private JSONP response")
      return
    }
    #expect(privateBody.contains("private-item"))
    let durable = String(
      decoding: try DeterministicJSON.encode(result.receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("private-item"))
  }

  @Test("Authenticated textual responses cannot become durable fixtures implicitly")
  func rejectsAuthenticatedTextWithoutOmissionReason() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/account/favorites",
      method: "GET",
      authPolicy: .sessionHeadersAndCookies
    )
    let executor = RecordingVerificationExecutor(
      response: VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "text/html; charset=utf-8"],
        body: Data("<script>window.accountName='private-user'</script>".utf8)
      )
    )

    await #expect(
      throws: NativeVerificationError
        .authenticatedTextFixtureRequiresOmissionReason
    ) {
      _ = try await NativeOperationVerifier(executor: executor).verify(
        operation: operation,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "https://api.example.test/account/favorites",
          method: "GET"
        ),
        verifiedAt: "2026-07-29T10:00:00Z"
      )
    }
  }

  @Test("Business errors remain successful HTTP evidence but not successful outcomes")
  func assessesBusinessOutcome() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/p/products",
      method: "GET"
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse([
        "success": false,
        "message": "not available",
      ])
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: "https://api.example.test/p/products",
        method: "GET"
      ),
      verifiedAt: "2026-07-29T10:00:00Z"
    )

    #expect(result.receipt.response.status == 200)
    #expect(result.receipt.response.outcome == .businessError)
    #expect(
      result.receipt.response.businessErrorSignals
        == ["success=false"]
    )
  }

  @Test("Unobserved successful-range status cannot prove operation success")
  func rejectsUnobservedSuccessfulRangeStatus() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/account/wishlist",
      method: "GET",
      authPolicy: .sessionHeadersAndCookies
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(
        ["location": "https://api.example.test/login"],
        status: 278
      )
    )

    await #expect(
      throws: NativeVerificationError.responseStatusMismatch(
        expected: [200],
        actual: 278
      )
    ) {
      try await NativeOperationVerifier(executor: executor).verify(
        operation: operation,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "https://api.example.test/account/wishlist",
          method: "GET"
        ),
        verifiedAt: "2026-08-03T00:00:00Z"
      )
    }
  }

  @Test("URL template and stable request shape must match Observed before network")
  func rejectsRequestDrift() async throws {
    let operation = try observedOperation(
      url: "https://api.example.test/p/products",
      method: "GET"
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )
    let verifier = NativeOperationVerifier(executor: executor)

    await #expect(throws: NativeVerificationError.urlTemplateMismatch) {
      try await verifier.verify(
        operation: operation,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "https://api.example.test/p/other",
          method: "GET"
        )
      )
    }
    #expect(await executor.requestCount() == 0)

    await #expect(throws: NativeVerificationError.self) {
      try await verifier.verify(
        operation: operation,
        requestSpec: PrivateVerificationRequestSpec(
          brand: "fixture",
          market: "cn",
          safety: .safeRead,
          url: "https://api.example.test/p/products",
          method: "GET",
          body: .object(["unexpected": .bool(true)])
        )
      )
    }
    #expect(await executor.requestCount() == 0)
  }

  @Test("Semantic path placeholder names do not invalidate an exact replay")
  func acceptsSemanticPathPlaceholderNames() async throws {
    let raw = RawExchange(
      method: "GET",
      url: "https://api.example.test/products/123456.html",
      requestHeaders: [:],
      responseStatus: 200,
      responseHeaders: ["content-type": "application/json"],
      responseBody: .object(["success": .bool(true)]),
      responseContentType: "application/json"
    )
    let semanticTemplate =
      "https://api.example.test/products/{productID}.html"
    let normalized = try HARImporter.normalize(
      raw,
      urlTemplateOverride: semanticTemplate
    )
    let operation = ObservedOperation(
      operationId: "fixture.semantic-path",
      fingerprint: String(repeating: "a", count: 64),
      method: normalized.method,
      urlTemplate: semanticTemplate,
      protocol: normalized.protocol,
      serviceFamily: "fixture",
      productFamily: "fixture",
      classification: .publicCurrentFact,
      safety: .safeRead,
      authPolicy: .none,
      routePolicy: .fixed(baseURL: "https://api.example.test"),
      request: normalized.request,
      responses: [normalized.response],
      sourceRefs: [
        SourceReference(
          captureId: "cap_fixture",
          sourceId: "fixture-source",
          sourceVersion: "v1"
        )
      ],
      verificationIds: []
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: "https://api.example.test/products/123456.html",
        method: "GET"
      ),
      verifiedAt: "2026-08-01T00:00:00Z"
    )

    #expect(result.receipt.fingerprint == operation.fingerprint)
    #expect(result.receipt.fingerprint != normalized.fingerprint)
    #expect(result.requestEvidence.finalURLTemplate == semanticTemplate)
    #expect(await executor.requestCount() == 1)
  }

  @Test("Legacy empty-object schema metadata does not invalidate an exact replay")
  func acceptsLegacyEmptyObjectSchemaMetadata() async throws {
    let url = "https://api.example.test/gateway?body=%7B%7D"
    let headers = ["content-type": "application/x-www-form-urlencoded"]
    let normalized = try HARImporter.normalize(
      RawExchange(
        method: "GET",
        url: url,
        requestHeaders: headers,
        requestContentType: headers["content-type"],
        responseStatus: 200,
        responseHeaders: ["content-type": "application/json"],
        responseBody: .object(["success": .bool(true)]),
        responseContentType: "application/json"
      )
    )
    let legacyEmptyObjectSchema: JSONValue = .object([
      "additionalProperties": .bool(false),
      "properties": .object([:]),
      "required": .array([]),
      "type": .string("object"),
    ])
    let legacyRequest = RequestShape(
      contentType: normalized.request.contentType,
      queryNames: normalized.request.queryNames,
      headers: normalized.request.headers,
      cookieNames: normalized.request.cookieNames,
      bodySchema: normalized.request.bodySchema,
      encodedQuerySchemas: ["body": legacyEmptyObjectSchema],
      encodedBodySchemas: normalized.request.encodedBodySchemas
    )
    let operation = ObservedOperation(
      operationId: "fixture.legacy-empty-object",
      fingerprint: String(repeating: "b", count: 64),
      method: normalized.method,
      urlTemplate: normalized.urlTemplate,
      protocol: normalized.protocol,
      serviceFamily: "fixture",
      productFamily: "fixture",
      classification: .publicCurrentFact,
      safety: .safeRead,
      authPolicy: .none,
      routePolicy: .fixed(baseURL: "https://api.example.test"),
      request: legacyRequest,
      responses: [normalized.response],
      sourceRefs: [
        SourceReference(
          captureId: "cap_fixture",
          sourceId: "fixture-source",
          sourceVersion: "v1"
        )
      ],
      verificationIds: []
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )

    let result = try await NativeOperationVerifier(
      executor: executor
    ).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: url,
        method: "GET",
        headers: headers
      ),
      verifiedAt: "2026-08-01T00:00:00Z"
    )

    #expect(result.receipt.fingerprint == operation.fingerprint)
    #expect(await executor.requestCount() == 1)
  }

  @Test("Object openness metadata does not invalidate matching encoded fields")
  func acceptsMatchingEncodedObjectFieldsAcrossOpennessInference() async throws {
    let url =
      "https://api.example.test/gateway?data=%7B%22ids%22%3A%22%5B%5C%22123%5C%22%5D%22%2C%22type%22%3A%221%22%7D"
    let normalized = try HARImporter.normalize(
      RawExchange(
        method: "GET",
        url: url,
        requestHeaders: [:],
        responseStatus: 200,
        responseHeaders: ["content-type": "application/json"],
        responseBody: .object(["success": .bool(true)]),
        responseContentType: "application/json"
      )
    )
    let inferredSchema = try #require(
      normalized.request.encodedQuerySchemas?["data"]
    )
    guard case .object(var reviewedSchema) = inferredSchema else {
      Issue.record("Expected an inferred encoded object schema.")
      return
    }
    reviewedSchema["additionalProperties"] = JSONValue.bool(false)
    let operation = ObservedOperation(
      operationId: "fixture.encoded-object",
      fingerprint: String(repeating: "c", count: 64),
      method: normalized.method,
      urlTemplate: normalized.urlTemplate,
      protocol: normalized.protocol,
      serviceFamily: "fixture",
      productFamily: "fixture",
      classification: .publicCurrentFact,
      safety: .safeRead,
      authPolicy: .none,
      routePolicy: .fixed(baseURL: "https://api.example.test"),
      request: RequestShape(
        contentType: normalized.request.contentType,
        queryNames: normalized.request.queryNames,
        headers: normalized.request.headers,
        cookieNames: normalized.request.cookieNames,
        bodySchema: normalized.request.bodySchema,
        encodedQuerySchemas: ["data": .object(reviewedSchema)],
        encodedBodySchemas: normalized.request.encodedBodySchemas
      ),
      responses: [normalized.response],
      sourceRefs: [
        SourceReference(
          captureId: "cap_fixture",
          sourceId: "fixture-source",
          sourceVersion: "v1"
        )
      ],
      verificationIds: []
    )
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )

    _ = try await NativeOperationVerifier(executor: executor).verify(
      operation: operation,
      requestSpec: PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: .safeRead,
        url: url,
        method: "GET"
      )
    )

    #expect(await executor.requestCount() == 1)
  }

  @Test("Only the durable transaction may execute a reversible write")
  func enforcesWriteSafety() async throws {
    let executor = RecordingVerificationExecutor(
      response: jsonResponse(["success": true])
    )
    let highRisk = try observedOperation(
      url: "https://api.example.test/order",
      method: "POST",
      safety: .highRiskWrite
    )
    let highRiskSpec = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      safety: .highRiskWrite,
      url: "https://api.example.test/order",
      method: "POST"
    )
    await #expect(throws: NativeVerificationError.highRiskWriteRejected) {
      try await NativeOperationVerifier(executor: executor).verify(
        operation: highRisk,
        requestSpec: highRiskSpec,
        allowRemoteWrite: true
      )
    }

    let reversible = try observedOperation(
      url: "https://api.example.test/favorite",
      method: "POST",
      safety: .reversibleWrite
    )
    let reversibleSpec = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      safety: .reversibleWrite,
      url: "https://api.example.test/favorite",
      method: "POST"
    )
    await #expect(
      throws: NativeVerificationError.reversibleWriteRequiresTransaction
    ) {
      try await NativeOperationVerifier(executor: executor).verify(
        operation: reversible,
        requestSpec: reversibleSpec
      )
    }
    await #expect(
      throws: NativeVerificationError.reversibleWriteRequiresTransaction
    ) {
      try await NativeOperationVerifier(executor: executor).verify(
        operation: reversible,
        requestSpec: reversibleSpec,
        allowRemoteWrite: true
      )
    }
    let result = try await NativeOperationVerifier(executor: executor)
      .verifyReversibleTransactionStep(
        operation: reversible,
        requestSpec: reversibleSpec,
        sessionSeed: nil,
        verifiedAt: "2026-07-29T10:00:00Z"
      )
    #expect(result.receipt.verificationKind == .reversibleWriteReplay)
    #expect(result.receipt.restoration?.required == true)
    #expect(result.receipt.restoration?.proven == false)
    #expect(await executor.requestCount() == 1)
  }

  @Test("Capture-derived replay accepts only concrete unauthenticated GET or HEAD")
  func derivesOnlyReconstructableReads() throws {
    let fixture = try captureFixture(
      url: "https://api.example.test/p/products/123456",
      method: "GET"
    )

    let request = try NativeOperationVerifier.requestFromCapture(
      operation: fixture.operation,
      receipt: fixture.receipt
    )

    #expect(request.url == "https://api.example.test/p/products/123456")
    #expect(request.method == "GET")
    #expect(request.headers["accept"] == "application/json")

    let authenticated = copy(
      fixture.operation,
      authPolicy: .sessionHeadersAndCookies
    )
    #expect(
      throws: NativeVerificationError.captureRequiresUnauthenticated
    ) {
      try NativeOperationVerifier.requestFromCapture(
        operation: authenticated,
        receipt: fixture.receipt
      )
    }

    let parameterized = try captureFixture(
      url: "https://api.example.test/p/products?color=09",
      method: "GET"
    )
    #expect(
      throws: NativeVerificationError.captureRequestNotReconstructable
    ) {
      try NativeOperationVerifier.requestFromCapture(
        operation: parameterized.operation,
        receipt: parameterized.receipt
      )
    }
  }
}

private actor RecordingVerificationExecutor: VerificationHTTPExecuting {
  private let response: VerificationHTTPResponse
  private var requests: [URLRequest] = []

  init(response: VerificationHTTPResponse) {
    self.response = response
  }

  func execute(
    _ request: URLRequest
  ) async throws -> VerificationHTTPResponse {
    requests.append(request)
    return VerificationHTTPResponse(
      status: response.status,
      headers: response.headers,
      body: response.body,
      finalURL: response.finalURL ?? request.url
    )
  }

  func lastRequest() -> URLRequest? {
    requests.last
  }

  func requestCount() -> Int {
    requests.count
  }
}

private func observedOperation(
  url: String,
  method: String,
  headers: [String: String] = [:],
  body: JSONValue? = nil,
  safety: OperationSafety = .safeRead,
  classification: OperationClassification? = nil,
  authPolicy: AuthPolicy = .none
) throws -> ObservedOperation {
  let normalized = try HARImporter.normalize(
    RawExchange(
      method: method,
      url: url,
      requestHeaders: headers,
      requestBody: body,
      requestContentType: header(
        headers,
        name: "content-type"
      ),
      responseStatus: 200,
      responseHeaders: ["content-type": "application/json"],
      responseBody: .object(["success": .bool(true)]),
      responseContentType: "application/json"
    )
  )
  return ObservedOperation(
    operationId: "fixture.operation",
    fingerprint: normalized.fingerprint,
    method: method.uppercased(),
    urlTemplate: normalized.urlTemplate,
    protocol: normalized.protocol,
    serviceFamily: "fixture",
    productFamily: "fixture",
    classification: classification
      ?? (authPolicy == .none
        ? .publicCurrentFact
        : .authenticatedBusiness),
    safety: safety,
    authPolicy: authPolicy,
    routePolicy: .fixed(baseURL: origin(url)),
    request: normalized.request,
    responses: [normalized.response],
    sourceRefs: [
      SourceReference(
        captureId: "cap_fixture",
        sourceId: "fixture-source",
        sourceVersion: "v1"
      )
    ],
    verificationIds: []
  )
}

private func verificationSessionSeed() -> PrivateSessionSeed {
  PrivateSessionSeed(
    brand: "fixture",
    market: "cn",
    profile: "test",
    createdAt: "2026-07-29T00:00:00Z",
    sourceURL: "https://i.example.test/login",
    cookies: [
      PrivateSessionCookie(
        name: "session",
        value: "private-cookie",
        domain: ".example.test",
        path: "/",
        expires: -1,
        httpOnly: true,
        secure: true,
        sameSite: "Lax"
      )
    ],
    origins: [
      PrivateSessionOrigin(
        origin: "https://i.example.test",
        localStorage: [
          "account": """
          {
            "access_token":"private-access-token",
            "refresh_token":"private-refresh-token",
            "env":"idc",
            "fetched_at":1700000000,
            "expires_in":3600
          }
          """
        ],
        sessionStorage: [:]
      )
    ]
  )
}

private func jsonResponse(
  _ object: [String: Any],
  status: Int = 200
) -> VerificationHTTPResponse {
  VerificationHTTPResponse(
    status: status,
    headers: ["content-type": "application/json"],
    body: try! JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys]
    )
  )
}

private func captureFixture(
  url: String,
  method: String
) throws -> (operation: ObservedOperation, receipt: CaptureReceipt) {
  let normalized = try HARImporter.normalize(
    RawExchange(
      method: method,
      url: url,
      requestHeaders: [:],
      responseStatus: 200,
      responseHeaders: ["content-type": "application/json"],
      responseBody: .object(["success": .bool(true)]),
      responseContentType: "application/json"
    )
  )
  let source = CaptureSource(
    sourceId: "fixture-source",
    surface: .web,
    version: "v1",
    sha256: String(repeating: "a", count: 64),
    entryURL: url
  )
  let receipt = CaptureReceipt(
    captureId: "cap_fixture",
    capturedAt: "2026-07-29T00:00:00Z",
    brand: "fixture",
    market: "cn",
    source: source,
    flow: "fixture",
    exchanges: [normalized]
  )
  let operation = ObservedOperation(
    operationId: "fixture.operation",
    fingerprint: normalized.fingerprint,
    method: method,
    urlTemplate: normalized.urlTemplate,
    protocol: normalized.protocol,
    serviceFamily: "fixture",
    productFamily: "fixture",
    classification: .publicCurrentFact,
    safety: .safeRead,
    authPolicy: .none,
    routePolicy: .fixed(baseURL: origin(url)),
    request: normalized.request,
    responses: [normalized.response],
    sourceRefs: [
      SourceReference(
        captureId: receipt.captureId,
        sourceId: source.sourceId,
        sourceVersion: source.version
      )
    ],
    verificationIds: []
  )
  return (operation, receipt)
}

private func copy(
  _ operation: ObservedOperation,
  authPolicy: AuthPolicy
) -> ObservedOperation {
  ObservedOperation(
    operationId: operation.operationId,
    fingerprint: operation.fingerprint,
    method: operation.method,
    urlTemplate: operation.urlTemplate,
    protocol: operation.protocol,
    serviceFamily: operation.serviceFamily,
    productFamily: operation.productFamily,
    classification: operation.classification,
    safety: operation.safety,
    authPolicy: authPolicy,
    routePolicy: operation.routePolicy,
    request: operation.request,
    responses: operation.responses,
    sourceRefs: operation.sourceRefs,
    verificationIds: operation.verificationIds
  )
}

private func header(
  _ headers: [String: String],
  name: String
) -> String? {
  headers.first {
    $0.key.caseInsensitiveCompare(name) == .orderedSame
  }?.value
}

private func origin(_ url: String) -> String {
  let components = URLComponents(string: url)!
  return "\(components.scheme!)://\(components.host!)"
}
