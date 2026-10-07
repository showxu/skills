import Foundation

enum ReviewedRequestVariant {
  static func digest(routePolicy: RoutePolicy) throws -> String? {
    guard let facts = facts(routePolicy: routePolicy) else {
      return nil
    }
    return FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(facts)
    )
  }

  static func validateAndDigest(
    request: URLRequest,
    routePolicy: RoutePolicy
  ) throws -> String? {
    guard case .provider(_, let fields) = routePolicy,
      let facts = facts(routePolicy: routePolicy)
    else {
      return nil
    }

    guard let requestURL = request.url else {
      throw NativeVerificationError.invalidURL("")
    }

    if case .object(let expectedQuery) = fields["staticQuery"] {
      let actualQuery = Dictionary(
        (URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?
          .queryItems ?? []).map { ($0.name, $0.value ?? "") },
        uniquingKeysWith: { first, _ in first }
      )
      for name in expectedQuery.keys.sorted() {
        let value = expectedQuery[name]!
        guard let expected = scalarString(value), actualQuery[name] == expected else {
          throw NativeVerificationError.requestShapeMismatch([
            "routePolicy.staticQuery.\(name)"
          ])
        }
      }
    }

    if case .object(let expectedHeaders) = fields["staticHeaders"] {
      let actualHeaders = Dictionary(
        (request.allHTTPHeaderFields ?? [:]).map {
          ($0.key.lowercased(), $0.value)
        },
        uniquingKeysWith: { first, _ in first }
      )
      for name in expectedHeaders.keys.sorted() {
        let value = expectedHeaders[name]!
        guard !EvidenceRedactor.isSensitiveHeaderName(name),
          let expected = scalarString(value),
          actualHeaders[name.lowercased()] == expected
        else {
          throw NativeVerificationError.requestShapeMismatch([
            "routePolicy.staticHeaders.\(name.lowercased())"
          ])
        }
      }
    }

    return FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(facts)
    )
  }

  private static func facts(routePolicy: RoutePolicy) -> JSONValue? {
    guard case .provider(let kind, let fields) = routePolicy else {
      return nil
    }
    let staticQuery = normalizedStringObject(fields["staticQuery"])
    let staticHeaders = normalizedHeaderObject(fields["staticHeaders"])
    guard !staticQuery.isEmpty || !staticHeaders.isEmpty else {
      return nil
    }
    return .object([
      "kind": .string(kind),
      "staticHeaders": .object(staticHeaders),
      "staticQuery": .object(staticQuery),
    ])
  }

  private static func normalizedStringObject(
    _ value: JSONValue?
  ) -> [String: JSONValue] {
    guard case .object(let object) = value else {
      return [:]
    }
    return object
  }

  private static func normalizedHeaderObject(
    _ value: JSONValue?
  ) -> [String: JSONValue] {
    Dictionary(
      uniqueKeysWithValues: normalizedStringObject(value).map {
        ($0.key.lowercased(), $0.value)
      }
    )
  }

  private static func scalarString(_ value: JSONValue) -> String? {
    switch value {
    case .string(let value):
      value
    case .number(let value) where value.rounded() == value:
      String(Int64(value))
    case .number(let value):
      String(value)
    case .bool(let value):
      value ? "true" : "false"
    case .null, .array, .object:
      nil
    }
  }
}
