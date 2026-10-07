import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Native request capture")
struct NativeRequestCaptureTests {
  @Test("Captures a session-templated request without durable credentials")
  func capturesSanitizedRequest() async throws {
    let executor = RequestCaptureExecutor(
      response: VerificationHTTPResponse(
        status: 200,
        headers: ["content-type": "application/json"],
        body: Data(
          #"{"success":true,"userId":"private-user"}"#.utf8
        )
      )
    )
    let spec = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      safety: .safeRead,
      url: "https://api.example.test/product/{{session.productCode}}",
      method: "POST",
      headers: [
        "authorization": "Bearer {{session.accessToken}}",
        "content-type": "application/x-www-form-urlencoded",
      ],
      body: .object(["sku": .string("{{session.skuCode}}")]),
      sessionAliases: [
        "accessToken": ["access_token"],
        "productCode": ["product_code"],
        "skuCode": ["sku_code"],
      ]
    )
    let seed = requestCaptureSeed()
    let source = NativeRequestCaptureSource(
      surface: .web,
      sourceId: "fixture-web",
      sourceVersion: "v1"
    )

    let first = try await NativeRequestCapturer(
      executor: executor
    ).capture(
      requestSpec: spec,
      source: source,
      sessionSeed: seed,
      capturedAt: "2026-07-29T12:00:00Z"
    )
    let second = try await NativeRequestCapturer(
      executor: executor
    ).capture(
      requestSpec: spec,
      source: source,
      sessionSeed: seed,
      capturedAt: "2026-07-29T12:00:00Z"
    )

    let request = try #require(await executor.lastRequest())
    #expect(
      request.url?.absoluteString
        == "https://api.example.test/product/484203"
    )
    #expect(
      request.value(forHTTPHeaderField: "authorization")
        == "Bearer private-access"
    )
    #expect(
      request.value(forHTTPHeaderField: "cookie")
        == "session=private-cookie"
    )
    #expect(
      String(decoding: request.httpBody ?? Data(), as: UTF8.self)
        == "sku=484203-09-M")
    #expect(first.receipt == second.receipt)
    #expect(first.receipt.exchanges.count == 1)
    #expect(
      first.privateResponse.body
        == .object([
          "success": .bool(true),
          "userId": .string("private-user"),
        ]))
    let durable = String(
      decoding: try DeterministicJSON.encode(first.receipt),
      as: UTF8.self
    )
    for secret in [
      "private-access",
      "private-cookie",
      "private-user",
      "484203-09-M",
    ] {
      #expect(!durable.contains(secret))
    }
  }

  @Test("Rejects unknown, high-risk, and unapproved reversible requests")
  func rejectsUnsafeRequests() async throws {
    let executor = RequestCaptureExecutor(
      response: VerificationHTTPResponse(status: 204, headers: [:])
    )
    let capturer = NativeRequestCapturer(executor: executor)
    let source = NativeRequestCaptureSource(
      surface: .web,
      sourceId: "fixture-web",
      sourceVersion: "v1"
    )

    for safety in [
      OperationSafety.unknown,
      .highRiskWrite,
      .reversibleWrite,
    ] {
      let spec = PrivateVerificationRequestSpec(
        brand: "fixture",
        market: "cn",
        safety: safety,
        url: "https://api.example.test/mutation",
        method: "POST"
      )
      if safety == .unknown {
        await #expect(throws: NativeVerificationError.unknownSafety) {
          try await capturer.capture(requestSpec: spec, source: source)
        }
      } else if safety == .highRiskWrite {
        await #expect(
          throws: NativeVerificationError.highRiskWriteRejected
        ) {
          try await capturer.capture(
            requestSpec: spec,
            source: source,
            allowRemoteWrite: true
          )
        }
      } else {
        await #expect(
          throws: NativeVerificationError.reversibleWriteRequiresTransaction
        ) {
          try await capturer.capture(requestSpec: spec, source: source)
        }
        await #expect(
          throws: NativeVerificationError.reversibleWriteRequiresTransaction
        ) {
          try await capturer.capture(
            requestSpec: spec,
            source: source,
            allowRemoteWrite: true
          )
        }
      }
    }
    #expect(await executor.requestCount() == 0)
  }
}

private actor RequestCaptureExecutor: VerificationHTTPExecuting {
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

private func requestCaptureSeed() -> PrivateSessionSeed {
  PrivateSessionSeed(
    brand: "fixture",
    market: "cn",
    profile: "test",
    createdAt: "2026-07-29T00:00:00Z",
    sourceURL: "https://api.example.test/login",
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
        origin: "https://api.example.test",
        localStorage: [
          "account": """
          {
            "access_token":"private-access",
            "product_code":"484203",
            "sku_code":"484203-09-M"
          }
          """
        ],
        sessionStorage: [:]
      )
    ]
  )
}
