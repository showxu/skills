import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Reviewed request variant")
struct ReviewedRequestVariantTests {
  @Test("Exact static query and headers produce the reviewed digest")
  func exactVariantProducesDigest() throws {
    let policy = routePolicy()
    var request = URLRequest(
      url: URL(string: "https://example.com/h5/api?appKey=12574478&type=json")!
    )
    request.setValue("https://example.com/account", forHTTPHeaderField: "Referer")

    let actual = try ReviewedRequestVariant.validateAndDigest(
      request: request,
      routePolicy: policy
    )
    let expected = try ReviewedRequestVariant.digest(routePolicy: policy)

    #expect(actual == expected)
  }

  @Test("A different static query value is rejected before replay")
  func differentVariantIsRejected() {
    let request = URLRequest(
      url: URL(string: "https://example.com/h5/api?appKey=other&type=json")!
    )

    #expect(
      throws: NativeVerificationError.requestShapeMismatch([
        "routePolicy.staticQuery.appKey"
      ])
    ) {
      try ReviewedRequestVariant.validateAndDigest(
        request: request,
        routePolicy: routePolicy()
      )
    }
  }

  @Test("Standard client hints can be reviewed static headers")
  func clientHintVariantProducesDigest() throws {
    let policy = RoutePolicy.provider(
      kind: "fixtureGateway",
      fields: [
        "baseURL": .string("https://example.com"),
        "staticHeaders": .object([
          "Sec-CH-UA-Mobile": .string("?0")
        ]),
      ]
    )
    var request = URLRequest(url: URL(string: "https://example.com/h5/api")!)
    request.setValue("?0", forHTTPHeaderField: "Sec-CH-UA-Mobile")

    let actual = try ReviewedRequestVariant.validateAndDigest(
      request: request,
      routePolicy: policy
    )
    let expected = try ReviewedRequestVariant.digest(routePolicy: policy)

    #expect(actual == expected)
  }

  private func routePolicy() -> RoutePolicy {
    .provider(
      kind: "fixtureGateway",
      fields: [
        "baseURL": .string("https://example.com"),
        "staticHeaders": .object([
          "Referer": .string("https://example.com/account")
        ]),
        "staticQuery": .object([
          "appKey": .string("12574478"),
          "type": .string("json"),
        ]),
      ]
    )
  }
}
