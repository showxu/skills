import Foundation
import Testing

@testable import WebAPIReverseProviderMiddlewareExample

@Suite("Provider middleware example")
struct ProviderMiddlewareExampleTests {
  @Test("Resolves provider-owned environment and injects proven session facts")
  func resolvesSessionEnvironment() throws {
    let builder = ExampleProviderRequestBuilder { environment in
      environment == "prod" ? URL(string: "https://example.test") : nil
    }
    let request = try builder.request(
      method: "GET",
      routePolicy: .sessionEnvironment(path: "/api/me"),
      authPolicy: .sessionHeadersAndCookies,
      session: ExampleProviderSession(
        environment: "prod",
        accessToken: "fixture-token",
        cookies: ["session": "fixture-cookie"]
      )
    )
    #expect(request.url?.absoluteString == "https://example.test/api/me")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-token")
    #expect(request.value(forHTTPHeaderField: "Cookie") == "session=fixture-cookie")
  }

  @Test("Fails closed for an unknown environment")
  func failsClosedForUnknownEnvironment() {
    let builder = ExampleProviderRequestBuilder { _ in nil }
    #expect(throws: ExampleProviderError.unsupportedEnvironment("unknown")) {
      try builder.request(
        method: "GET",
        routePolicy: .sessionEnvironment(path: "/api/me"),
        authPolicy: .bearerAccessToken,
        session: ExampleProviderSession(
          environment: "unknown",
          accessToken: "fixture-token",
          cookies: [:]
        )
      )
    }
  }

  @Test("Applies Published gateway body and response media facts")
  func appliesPublishedWireFacts() throws {
    let builder = ExampleProviderRequestBuilder { _ in nil }
    var generated = URLRequest(
      url: URL(string: "https://example.test/__client/add")!
    )
    generated.httpMethod = "POST"
    generated.httpBody = Data(#"{"sku":"fixture"}"#.utf8)
    generated.setValue(
      "application/json",
      forHTTPHeaderField: "Content-Type"
    )
    let policy = ExampleOperationPolicy(
      clientPath: "/__client/add",
      wirePath: "/api",
      encodedQueryBodyNames: ["body"],
      responseContentTypeAliases: ["text/json": "application/json"]
    )

    let wire = try builder.applyingWirePolicy(
      to: generated,
      policy: policy
    )
    let wireURL = try #require(wire.url)
    let components = try #require(
      URLComponents(url: wireURL, resolvingAgainstBaseURL: false)
    )

    #expect(components.path == "/api")
    #expect(
      components.queryItems?.first(where: { $0.name == "body" })?.value
        == #"{"sku":"fixture"}"#
    )
    #expect(wire.httpBody == nil)
    #expect(wire.value(forHTTPHeaderField: "Content-Type") == nil)
    #expect(
      builder.canonicalResponseContentType(
        "text/json; charset=utf-8",
        policy: policy
      ) == "application/json"
    )
  }
}
