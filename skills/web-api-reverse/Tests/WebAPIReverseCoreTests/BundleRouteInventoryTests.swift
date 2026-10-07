import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Static bundle route candidate inventory")
struct BundleRouteInventoryTests {
  @Test("Inventories sanitized literals without promoting operation facts")
  func inventoriesSanitizedRouteCandidates() throws {
    let source = #"""
      const product = "/v1/products?sku=private-value&locale=zh_CN";
      const wishlist = `/buy/wishlists/v2/lists/${listId}/items?count=${count}`;
      const account = "https://api.example.test/v1/account?token=private-token";
      const escaped = "\/api\/v1\/products";
      const unicodeEscaped = "\u002Fapi\u002Fv2\u002Fproducts";
      // const ignored = "/api/comment-only";
      /* const alsoIgnored = "/api/block-comment-only"; */
      const asset = "/assets/main.js";
      const unrelated = "not/a/route";
      """#
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/assets/application.js?build=private",
        body: source
      )
    ])

    let receipt = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )

    #expect(receipt.kind == "web-api-reverse.bundle-route-candidates")
    #expect(receipt.bundles.count == 1)
    #expect(
      receipt.candidates.map(\.route) == [
        "https://api.example.test/v1/account?token={token}",
        "/api/v1/products",
        "/api/v2/products",
        "/buy/wishlists/v2/lists/{template}/items?count={count}",
        "/v1/products?locale={locale}&sku={sku}",
      ])
    #expect(
      receipt.candidates.allSatisfy {
        $0.bundleIds == [receipt.bundles[0].bundleId]
      }
    )

    let encoded = try DeterministicJSON.encode(receipt)
    let durable = String(decoding: encoded, as: UTF8.self)
    #expect(!durable.contains("private-value"))
    #expect(!durable.contains("private-token"))
    #expect(!durable.contains("comment-only"))
    #expect(!durable.contains("/assets/main.js"))

    do {
      _ = try DeterministicJSON.decode(CaptureReceipt.self, from: encoded)
      Issue.record("A route-candidate receipt must not decode as a capture receipt.")
    } catch {
      #expect(error is DecodingError)
    }
  }

  @Test("Base64 bundles are decoded and duplicate routes are deterministic")
  func base64AndDeterminism() throws {
    let source = #"const route="/v1/products?b=2&a=1";"#
    let encodedSource = Data(source.utf8).base64EncodedString()
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/a.js",
        body: encodedSource,
        encoding: "base64"
      ),
      entry(
        url: "https://www.example.test/b.js",
        body: encodedSource,
        encoding: "base64"
      ),
    ])

    let first = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )
    let second = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )

    #expect(first == second)
    #expect(first.bundles.count == 2)
    #expect(first.candidates.count == 1)
    #expect(first.candidates[0].route == "/v1/products?a={a}&b={b}")
    #expect(first.candidates[0].bundleIds.count == 2)
  }

  @Test("Escaped slashes in a minified regular expression do not hide routes")
  func escapedRegexSlashDoesNotStartComment() throws {
    let source =
      #"function f(v){return v.replace(/^#\//,"")}const allowed=/^[a-z0-9\s`~!]+$/;const route="/v1/users/refreshToken";"#
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/application.js",
        body: source
      )
    ])

    let receipt = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )

    #expect(
      receipt.candidates.map(\.route)
        == ["/v1/users/refreshToken"]
    )
  }

  @Test("A leading regex after whitespace does not consume later routes")
  func leadingRegexAfterWhitespaceDoesNotHideRoutes() throws {
    let source =
      #"   /^[a-z`]+$/.test(value);const route="/v1/account/status";"#
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/application.js",
        body: source
      )
    ])

    let receipt = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )

    #expect(
      receipt.candidates.map(\.route)
        == ["/v1/account/status"]
    )
  }

  @Test("Only successful embedded JavaScript responses are selected")
  func filtersNonJavaScriptResponses() throws {
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/index.html",
        body: #"const route="/ignored/html";"#,
        mimeType: "text/html"
      ),
      entry(
        url: "https://www.example.test/failed.js",
        body: #"const route="/ignored/failed";"#,
        status: 404
      ),
      entry(
        url: "https://www.example.test/application.js",
        body: #"const route="/selected/products";"#,
        mimeType: "text/plain"
      ),
    ])

    let receipt = try BundleRouteInventory.inventory(
      data: data,
      options: options()
    )

    #expect(receipt.bundles.count == 1)
    #expect(receipt.candidates.map(\.route) == ["/selected/products"])
  }

  @Test("Malformed base64 fails closed")
  func malformedBase64Fails() throws {
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/application.js",
        body: "not-valid-base64^",
        encoding: "base64"
      )
    ])

    #expect(
      throws: BundleRouteInventoryError.malformedBundle(
        "https://www.example.test/application.js"
      )
    ) {
      try BundleRouteInventory.inventory(data: data, options: options())
    }
  }

  @Test("Per-bundle and aggregate byte limits fail closed")
  func byteLimitsFail() throws {
    let oversized = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/application.js",
        body: #"const route="/a/route/that/is/too/large";"#
      )
    ])
    #expect(throws: BundleRouteInventoryError.self) {
      try BundleRouteInventory.inventory(
        data: oversized,
        options: options(maximumBundleBytes: 8, maximumTotalBytes: 8)
      )
    }

    let aggregate = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/a.js",
        body: #"const a="/route/a";"#
      ),
      entry(
        url: "https://www.example.test/b.js",
        body: #"const b="/route/b";"#
      ),
    ])
    #expect(throws: BundleRouteInventoryError.self) {
      try BundleRouteInventory.inventory(
        data: aggregate,
        options: options(maximumBundleBytes: 32, maximumTotalBytes: 32)
      )
    }
  }

  @Test("A HAR without embedded JavaScript fails closed")
  func emptySelectionFails() throws {
    let data = try makeHAR(entries: [
      entry(
        url: "https://www.example.test/index.html",
        body: "<html></html>",
        mimeType: "text/html"
      )
    ])

    #expect(throws: BundleRouteInventoryError.emptySelection) {
      try BundleRouteInventory.inventory(data: data, options: options())
    }
  }

  private func options(
    maximumBundleBytes: Int = 8 * 1_024 * 1_024,
    maximumTotalBytes: Int = 64 * 1_024 * 1_024
  ) -> BundleRouteInventoryOptions {
    BundleRouteInventoryOptions(
      brand: "fixture",
      market: "cn",
      surface: .web,
      sourceId: "fixture-cn-web",
      sourceVersion: "web-1",
      capturedAt: "2026-07-31T09:00:00.000Z",
      maximumBundleBytes: maximumBundleBytes,
      maximumTotalBytes: maximumTotalBytes
    )
  }

  private func entry(
    url: String,
    body: String,
    encoding: String? = nil,
    mimeType: String = "application/javascript",
    status: Int = 200
  ) -> [String: Any] {
    var content: [String: Any] = [
      "mimeType": mimeType,
      "text": body,
    ]
    if let encoding {
      content["encoding"] = encoding
    }
    return [
      "startedDateTime": "2026-07-31T09:00:00.000Z",
      "request": ["url": url],
      "response": [
        "status": status,
        "headers": [
          ["name": "content-type", "value": mimeType]
        ],
        "content": content,
      ],
    ]
  }

  private func makeHAR(entries: [[String: Any]]) throws -> Data {
    try JSONSerialization.data(
      withJSONObject: [
        "log": [
          "version": "1.2",
          "creator": ["name": "fixture", "version": "1"],
          "entries": entries,
        ]
      ],
      options: [.sortedKeys]
    )
  }
}
