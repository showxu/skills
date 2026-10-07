import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Private HAR request extraction")
struct PrivateHARRequestExtractionTests {
  @Test("Extracts the latest exact browser request for one Observed operation")
  func extractsLatestExactRequest() throws {
    let har = fixtureHAR()
    let receipt = try HARImporter.importHAR(
      data: har,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-authenticated-account",
        sourceVersion: "2026-07-31",
        flow: "authenticated-account"
      )
    )
    let exchange = try #require(receipt.exchanges.last)
    let operation = observedOperation(
      exchange: exchange,
      receipt: receipt
    )

    let result = try PrivateHARRequestExtractor().extract(
      harData: har,
      captureReceipt: receipt,
      operation: operation
    )

    #expect(result.matchedExchangeCount == 2)
    #expect(
      result.requestSpec.url
        == "https://api.example.test/member/favorite?page=1"
    )
    #expect(result.requestSpec.method == "POST")
    #expect(
      result.requestSpec.headers["authorization"]
        == "Bearer latest-private-token"
    )
    #expect(
      result.requestSpec.headers["cookie"]
        == "session=latest-private-cookie"
    )
    #expect(
      result.requestSpec.headers["content-length"] == nil
    )
    #expect(
      result.requestSpec.headers["accept-encoding"] == nil
    )
    #expect(
      result.requestSpec.headers["if-none-match"] == nil
    )
    #expect(
      result.requestSpec.body
        == .object([
          "page": .string("1"),
          "pageSize": .string("20"),
        ])
    )
  }

  @Test("Binds extraction to the exact private HAR and source receipt")
  func rejectsWrongHAROrSource() throws {
    let har = fixtureHAR()
    let receipt = try HARImporter.importHAR(
      data: har,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-authenticated-account",
        sourceVersion: "2026-07-31",
        flow: "authenticated-account"
      )
    )
    let exchange = try #require(receipt.exchanges.last)
    let operation = observedOperation(
      exchange: exchange,
      receipt: receipt
    )

    #expect(
      throws:
        PrivateHARRequestExtractionError
        .sourceDigestMismatch
    ) {
      try PrivateHARRequestExtractor().extract(
        harData: har + Data(" ".utf8),
        captureReceipt: receipt,
        operation: operation
      )
    }

    let unrelated = ObservedOperation(
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      method: operation.method,
      urlTemplate: operation.urlTemplate,
      protocol: operation.protocol,
      serviceFamily: operation.serviceFamily,
      productFamily: operation.productFamily,
      classification: operation.classification,
      safety: operation.safety,
      authPolicy: operation.authPolicy,
      routePolicy: operation.routePolicy,
      routeDiscriminators:
        operation.routeDiscriminators ?? [:],
      request: operation.request,
      responses: operation.responses,
      sourceRefs: [],
      verificationIds: []
    )
    #expect(
      throws:
        PrivateHARRequestExtractionError
        .operationSourceMismatch
    ) {
      try PrivateHARRequestExtractor().extract(
        harData: har,
        captureReceipt: receipt,
        operation: unrelated
      )
    }
  }
}

private func observedOperation(
  exchange: SanitizedExchange,
  receipt: CaptureReceipt
) -> ObservedOperation {
  ObservedOperation(
    operationId: exchange.operationId,
    fingerprint: exchange.fingerprint,
    method: exchange.method,
    urlTemplate: exchange.urlTemplate,
    protocol: exchange.protocol,
    serviceFamily: "remote-collection",
    productFamily: "wishlist",
    classification: .authenticatedBusiness,
    safety: .safeRead,
    authPolicy: .sessionHeadersAndCookies,
    routePolicy: .fixed(baseURL: "https://api.example.test"),
    routeDiscriminators:
      exchange.routeDiscriminators ?? [:],
    request: exchange.request,
    responses: [exchange.response],
    sourceRefs: [
      SourceReference(
        captureId: receipt.captureId,
        sourceId: receipt.source.sourceId,
        sourceVersion: receipt.source.version
      )
    ],
    verificationIds: []
  )
}

private func fixtureHAR() -> Data {
  Data(
    """
    {
      "log": {
        "version": "1.2",
        "creator": {"name": "fixture", "version": "1"},
        "entries": [
          {
            "startedDateTime": "2026-07-31T00:00:00Z",
            "time": 1,
            "request": {
              "method": "GET",
              "url": "blob:https://api.example.test/private-worker-resource",
              "headers": [],
              "cookies": []
            },
            "response": {
              "status": 200,
              "headers": [],
              "cookies": [],
              "content": {
                "mimeType": "application/octet-stream",
                "text": "private-browser-resource"
              }
            }
          },
          {
            "startedDateTime": "2026-07-31T00:00:00Z",
            "time": 10,
            "request": {
              "method": "POST",
              "url": "https://api.example.test/member/favorite?page=1",
              "headers": [
                {"name": "authorization", "value": "Bearer stale-private-token"},
                {"name": "content-length", "value": "22"},
                {"name": "content-type", "value": "application/x-www-form-urlencoded"}
              ],
              "cookies": [
                {"name": "session", "value": "stale-private-cookie"}
              ],
              "postData": {
                "mimeType": "application/x-www-form-urlencoded",
                "params": [
                  {"name": "page", "value": "1"},
                  {"name": "pageSize", "value": "20"}
                ]
              }
            },
            "response": {
              "status": 200,
              "headers": [{"name": "content-type", "value": "application/json"}],
              "content": {"mimeType": "application/json", "text": "{\\"success\\":true}"}
            }
          },
          {
            "startedDateTime": "2026-07-31T00:01:00Z",
            "time": 10,
            "request": {
              "method": "POST",
              "url": "https://api.example.test/member/favorite?page=1",
              "headers": [
                {"name": "authorization", "value": "Bearer latest-private-token"},
                {"name": "accept-encoding", "value": "gzip, br"},
                {"name": "content-length", "value": "22"},
                {"name": "content-type", "value": "application/x-www-form-urlencoded"},
                {"name": "if-none-match", "value": "private-cache-validator"}
              ],
              "cookies": [
                {"name": "session", "value": "latest-private-cookie"}
              ],
              "postData": {
                "mimeType": "application/x-www-form-urlencoded",
                "params": [
                  {"name": "page", "value": "1"},
                  {"name": "pageSize", "value": "20"}
                ]
              }
            },
            "response": {
              "status": 200,
              "headers": [{"name": "content-type", "value": "application/json"}],
              "content": {"mimeType": "application/json", "text": "{\\"success\\":true}"}
            }
          }
        ]
      }
    }
    """.utf8
  )
}
