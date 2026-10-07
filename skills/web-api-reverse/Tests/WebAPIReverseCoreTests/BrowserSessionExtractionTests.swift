import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Browser session seed extraction")
struct BrowserSessionExtractionTests {
  @Test("Converts private Playwright storage into the native session schema")
  func extractsSessionSeed() throws {
    let capture = try DeterministicJSON.decode(
      PrivateBrowserCapture.self,
      from: Data(
        """
        {
          "capturedAt": "2026-07-29T10:00:00Z",
          "sessionSeed": {
            "storageState": {
              "cookies": [{
                "name": "session",
                "value": "private-cookie",
                "domain": ".example.test",
                "path": "/",
                "expires": -1,
                "httpOnly": true,
                "secure": true,
                "sameSite": "Lax"
              }],
              "origins": [{
                "origin": "https://example.test",
                "localStorage": [
                  {"name": "persisted", "value": "one"},
                  {"name": "overridden", "value": "old"}
                ]
              }]
            },
            "webStorage": {
              "origin": "https://example.test",
              "localStorage": {
                "overridden": "new",
                "current": "two"
              },
              "sessionStorage": {"transient": "three"}
            }
          }
        }
        """.utf8
      )
    )

    let seed = BrowserSessionSeedExtractor.extract(
      capture: capture,
      brand: "fixture",
      market: "cn",
      profile: "user-controlled",
      sourceURL: "https://example.test/login"
    )

    #expect(seed.brand == "fixture")
    #expect(seed.cookies.map(\.name) == ["session"])
    let origin = try #require(seed.origins.first)
    #expect(origin.localStorage["persisted"] == "one")
    #expect(origin.localStorage["overridden"] == "new")
    #expect(origin.localStorage["current"] == "two")
    #expect(origin.sessionStorage["transient"] == "three")
  }
}
