import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Capture evidence models")
struct CaptureModelsTests {
  @Test("Capture receipt round-trips with the owned schema and kind")
  func captureReceiptRoundTrips() throws {
    let receipt = CaptureReceipt(
      captureId: "cap_1234567890abcdef",
      capturedAt: "2026-07-29T10:00:00.000Z",
      brand: "fixture",
      market: "cn",
      source: CaptureSource(
        sourceId: "fixture-cn-web",
        surface: .web,
        version: "web-1",
        sha256: String(repeating: "a", count: 64),
        entryURL: "https://example.test/"
      ),
      flow: "product-current-facts",
      captureContext: CaptureContext(
        browser: "chromium",
        browserVersion: "140.0",
        headless: true,
        device: "iPhone 15 Pro Max"
      ),
      captureSelection: CaptureSelection(
        patterns: ["example\\.test"],
        totalExchangeCount: 2,
        selectedExchangeCount: 1
      ),
      exchanges: []
    )

    let data = try DeterministicJSON.encode(receipt)
    let decoded = try DeterministicJSON.decode(CaptureReceipt.self, from: data)

    #expect(decoded == receipt)
    #expect(decoded.schemaVersion == 1)
    #expect(decoded.kind == "web-api-reverse.capture-receipt")
    #expect(data.last == 0x0A)
  }

  @Test("Config models use the package-owned artifact kinds")
  func configKindsAreStable() {
    let annotations = AnnotationFile(
      brand: "fixture",
      market: "cn",
      operations: []
    )
    let manifest = SourceManifest(
      brand: "fixture",
      market: "cn",
      sources: []
    )

    #expect(annotations.kind == "web-api-reverse.operation-annotations")
    #expect(manifest.kind == "web-api-reverse.source-manifest")
  }

  @Test("Provider-owned route policy round-trips without losing fields")
  func providerRoutePolicyRoundTrips() throws {
    let policy = RoutePolicy.provider(
      kind: "jdGateway",
      fields: [
        "appID": .string("item-v3"),
        "baseURL": .string("https://api.m.jd.com"),
        "functionID": .string("relsearch"),
        "staticQuery": .object(["rettype": .string("json")]),
      ]
    )

    let data = try DeterministicJSON.encode(policy)
    let decoded = try DeterministicJSON.decode(RoutePolicy.self, from: data)

    #expect(decoded == policy)
    #expect(decoded.baseURL == "https://api.m.jd.com")
    #expect(!decoded.isUnknown)
  }
}
