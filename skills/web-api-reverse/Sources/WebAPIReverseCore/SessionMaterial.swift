import Foundation

public typealias SessionAliasMap = [String: [String]]
public typealias SessionDerivationMap = [String: SessionDerivation]

public enum BrowserSessionProfileLabelError:
  Error, Equatable, LocalizedError
{
  case invalidExplicitLabel(String)

  public var errorDescription: String? {
    switch self {
    case .invalidExplicitLabel(let label):
      "Invalid browser session profile label: \(label)"
    }
  }
}

public enum BrowserSessionProfileLabel {
  public static func resolve(
    explicitLabel: String?,
    browserProfile: String?
  ) throws -> String {
    guard let explicitLabel else {
      return browserProfile ?? "ephemeral"
    }
    let allowed = CharacterSet(
      charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
    )
    guard
      !explicitLabel.isEmpty,
      explicitLabel != ".",
      explicitLabel != "..",
      explicitLabel.unicodeScalars.allSatisfy(allowed.contains)
    else {
      throw BrowserSessionProfileLabelError.invalidExplicitLabel(
        explicitLabel
      )
    }
    return explicitLabel
  }
}

public enum SessionDerivation: Codable, Equatable, Sendable {
  case lookup(
    sourceField: String,
    values: [String: String],
    missingValue: String?
  )
  case unixExpirationMilliseconds(
    fetchedAtField: String,
    durationSecondsField: String
  )

  private enum CodingKeys: String, CodingKey {
    case kind
    case sourceField
    case values
    case missingValue
    case fetchedAtField
    case durationSecondsField
  }

  private enum Kind: String, Codable {
    case lookup
    case unixExpirationMilliseconds = "unix-expiration-milliseconds"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .lookup:
      self = .lookup(
        sourceField: try container.decode(String.self, forKey: .sourceField),
        values: try container.decode([String: String].self, forKey: .values),
        missingValue: try container.decodeIfPresent(
          String.self,
          forKey: .missingValue
        )
      )
    case .unixExpirationMilliseconds:
      self = .unixExpirationMilliseconds(
        fetchedAtField: try container.decode(
          String.self,
          forKey: .fetchedAtField
        ),
        durationSecondsField: try container.decode(
          String.self,
          forKey: .durationSecondsField
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .lookup(let sourceField, let values, let missingValue):
      try container.encode(Kind.lookup, forKey: .kind)
      try container.encode(sourceField, forKey: .sourceField)
      try container.encode(values, forKey: .values)
      try container.encodeIfPresent(missingValue, forKey: .missingValue)
    case .unixExpirationMilliseconds(
      let fetchedAtField,
      let durationSecondsField
    ):
      try container.encode(
        Kind.unixExpirationMilliseconds,
        forKey: .kind
      )
      try container.encode(fetchedAtField, forKey: .fetchedAtField)
      try container.encode(
        durationSecondsField,
        forKey: .durationSecondsField
      )
    }
  }
}

public struct PrivateSessionCookie: Codable, Equatable, Sendable {
  public let name: String
  public let value: String
  public let domain: String
  public let path: String
  public let expires: Double
  public let httpOnly: Bool
  public let secure: Bool
  public let sameSite: String

  public init(
    name: String,
    value: String,
    domain: String,
    path: String,
    expires: Double,
    httpOnly: Bool,
    secure: Bool,
    sameSite: String
  ) {
    self.name = name
    self.value = value
    self.domain = domain
    self.path = path
    self.expires = expires
    self.httpOnly = httpOnly
    self.secure = secure
    self.sameSite = sameSite
  }
}

public struct PrivateSessionOrigin: Codable, Equatable, Sendable {
  public let origin: String
  public let localStorage: [String: String]
  public let sessionStorage: [String: String]

  public init(
    origin: String,
    localStorage: [String: String],
    sessionStorage: [String: String]
  ) {
    self.origin = origin
    self.localStorage = localStorage
    self.sessionStorage = sessionStorage
  }
}

public struct PrivateSessionSeed: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let profile: String
  public let createdAt: String
  public let sourceURL: String
  public let cookies: [PrivateSessionCookie]
  public let origins: [PrivateSessionOrigin]

  public init(
    brand: String,
    market: String,
    profile: String,
    createdAt: String,
    sourceURL: String,
    cookies: [PrivateSessionCookie],
    origins: [PrivateSessionOrigin],
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.private-session-seed"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.profile = profile
    self.createdAt = createdAt
    self.sourceURL = sourceURL
    self.cookies = cookies
    self.origins = origins
  }
}

public struct PrivateVerificationRequestSpec: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let safety: OperationSafety?
  public let url: String
  public let method: String?
  public let headers: [String: String]
  public let body: JSONValue?
  public let sessionAliases: SessionAliasMap?
  public let sessionDerivations: SessionDerivationMap
  public let responseExtraction: JSONValue?
  public let fixtureOmissionReason: String?

  public init(
    brand: String,
    market: String,
    safety: OperationSafety? = nil,
    url: String,
    method: String? = nil,
    headers: [String: String] = [:],
    body: JSONValue? = nil,
    sessionAliases: SessionAliasMap? = nil,
    sessionDerivations: SessionDerivationMap = [:],
    responseExtraction: JSONValue? = nil,
    fixtureOmissionReason: String? = nil,
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.private-verification-request"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.safety = safety
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
    self.sessionAliases = sessionAliases
    self.sessionDerivations = sessionDerivations
    self.responseExtraction = responseExtraction
    self.fixtureOmissionReason = fixtureOmissionReason
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    kind = try container.decode(String.self, forKey: .kind)
    brand = try container.decode(String.self, forKey: .brand)
    market = try container.decode(String.self, forKey: .market)
    safety = try container.decodeIfPresent(OperationSafety.self, forKey: .safety)
    url = try container.decode(String.self, forKey: .url)
    method = try container.decodeIfPresent(String.self, forKey: .method)
    headers = try container.decode([String: String].self, forKey: .headers)
    body = try container.decodeIfPresent(JSONValue.self, forKey: .body)
    sessionAliases = try container.decodeIfPresent(
      SessionAliasMap.self,
      forKey: .sessionAliases
    )
    sessionDerivations =
      try container.decodeIfPresent(
        SessionDerivationMap.self,
        forKey: .sessionDerivations
      ) ?? [:]
    responseExtraction = try container.decodeIfPresent(
      JSONValue.self,
      forKey: .responseExtraction
    )
    fixtureOmissionReason = try container.decodeIfPresent(
      String.self,
      forKey: .fixtureOmissionReason
    )
  }
}

public enum SessionMaterialError: Error, Equatable, LocalizedError {
  case sessionSeedRequired
  case aliasMapRequired
  case invalidFieldName(String)
  case emptyAliases(String)
  case missingField(String)
  case unmappedLookup(sourceField: String, targetField: String)
  case nonNumericField(String)

  public var errorDescription: String? {
    switch self {
    case .sessionSeedRequired:
      "Session-templated verification requires a private session seed."
    case .aliasMapRequired:
      "Session-templated verification requires an explicit sessionAliases mapping."
    case .invalidFieldName(let field):
      "Invalid session field name: \(field)"
    case .emptyAliases(let field):
      "Session field \(field) must declare at least one alias."
    case .missingField(let field):
      "Session material is missing required field \(field)."
    case .unmappedLookup(let sourceField, let targetField):
      "Session field \(sourceField) has no approved mapping for \(targetField)."
    case .nonNumericField(let field):
      "Session field \(field) is not numeric."
    }
  }
}

struct ResolvedVerificationRequest: Equatable, Sendable {
  let url: String
  let method: String?
  let headers: [String: String]
  let body: JSONValue?
}

enum SessionMaterialResolver {
  static func resolve(
    _ spec: PrivateVerificationRequestSpec,
    seed: PrivateSessionSeed?
  ) throws -> ResolvedVerificationRequest {
    let templated =
      containsTemplate(spec.url)
      || spec.headers.values.contains(where: containsTemplate)
      || spec.body.map(containsTemplate) == true
    guard templated else {
      return ResolvedVerificationRequest(
        url: spec.url,
        method: spec.method,
        headers: spec.headers,
        body: spec.body
      )
    }
    guard let seed else {
      throw SessionMaterialError.sessionSeedRequired
    }
    guard let aliases = spec.sessionAliases else {
      throw SessionMaterialError.aliasMapRequired
    }

    var material = try collect(seed: seed, aliases: aliases)
    try derive(
      material: &material,
      derivations: spec.sessionDerivations
    )
    return ResolvedVerificationRequest(
      url: try resolve(spec.url, material: material),
      method: spec.method,
      headers: try spec.headers.mapValues {
        try resolve($0, material: material)
      },
      body: try spec.body.map {
        try resolve($0, material: material)
      }
    )
  }

  private static func collect(
    seed: PrivateSessionSeed,
    aliases: SessionAliasMap
  ) throws -> [String: String] {
    let sources = sessionSources(seed)
    var material: [String: String] = [:]
    for field in aliases.keys.sorted() {
      guard isValidFieldName(field) else {
        throw SessionMaterialError.invalidFieldName(field)
      }
      let fieldAliases = aliases[field] ?? []
      guard !fieldAliases.isEmpty else {
        throw SessionMaterialError.emptyAliases(field)
      }
      if let value = firstValue(aliases: fieldAliases, sources: sources) {
        material[field] = value
      }
    }
    return material
  }

  private static func derive(
    material: inout [String: String],
    derivations: SessionDerivationMap
  ) throws {
    for field in derivations.keys.sorted() where material[field] == nil {
      guard let derivation = derivations[field] else {
        continue
      }
      switch derivation {
      case .lookup(let sourceField, let values, let missingValue):
        guard let source = material[sourceField] else {
          if let missingValue {
            material[field] = missingValue
          }
          continue
        }
        if let match = values.keys.sorted().first(where: {
          normalizeName($0) == normalizeName(source)
        }), let value = values[match] {
          material[field] = value
        } else {
          throw SessionMaterialError.unmappedLookup(
            sourceField: sourceField,
            targetField: field
          )
        }
      case .unixExpirationMilliseconds(
        let fetchedAtField,
        let durationSecondsField
      ):
        guard
          let fetchedAt = try numeric(
            material,
            field: fetchedAtField
          ),
          let duration = try numeric(
            material,
            field: durationSecondsField
          )
        else {
          continue
        }
        let fetchedAtSeconds =
          fetchedAt > 10_000_000_000
          ? fetchedAt / 1_000
          : fetchedAt
        let milliseconds = ((fetchedAtSeconds + duration) * 1_000).rounded()
        material[field] = String(Int64(milliseconds))
      }
    }
  }

  private static func numeric(
    _ material: [String: String],
    field: String
  ) throws -> Double? {
    guard let raw = material[field] else {
      return nil
    }
    guard let value = Double(raw), value.isFinite else {
      throw SessionMaterialError.nonNumericField(field)
    }
    return value
  }

  private static func sessionSources(
    _ seed: PrivateSessionSeed
  ) -> [[String: String]] {
    let sourceOrigin = origin(seed.sourceURL)
    let preferredOrigins = seed.origins.filter {
      $0.origin == sourceOrigin
    }
    let remainingOrigins = seed.origins.filter {
      $0.origin != sourceOrigin
    }
    let orderedOrigins = preferredOrigins + remainingOrigins
    let sourceHost = URLComponents(string: seed.sourceURL)?.host
    let preferredCookies = seed.cookies.filter {
      cookieDomain($0.domain, matches: sourceHost)
    }
    let remainingCookies = seed.cookies.filter {
      !cookieDomain($0.domain, matches: sourceHost)
    }
    var cookieValues: [String: String] = [:]
    for cookie in preferredCookies + remainingCookies
    where cookieValues[normalizeName(cookie.name)] == nil {
      cookieValues[normalizeName(cookie.name)] = cookie.value
    }
    return orderedOrigins.map {
      flattened($0.sessionStorage)
    }
      + orderedOrigins.map {
        flattened($0.localStorage)
      } + [cookieValues]
  }

  private static func flattened(
    _ values: [String: String]
  ) -> [String: String] {
    var result: [String: String] = [:]
    for name in values.keys.sorted() {
      guard let value = values[name], !value.isEmpty else {
        continue
      }
      result[normalizeName(name)] = value
      addEmbeddedJSON(value, to: &result)
    }
    return result
  }

  private static func addEmbeddedJSON(
    _ raw: String,
    to values: inout [String: String]
  ) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("{") || trimmed.hasPrefix("["),
      let data = trimmed.data(using: .utf8),
      let value = try? JSONDecoder().decode(JSONValue.self, from: data)
    else {
      return
    }
    addJSON(value, to: &values)
  }

  private static func addJSON(
    _ value: JSONValue,
    to values: inout [String: String]
  ) {
    switch value {
    case .object(let object):
      for key in object.keys.sorted() {
        guard let child = object[key] else {
          continue
        }
        switch child {
        case .string(let value):
          if !value.isEmpty {
            values[normalizeName(key)] = value
            addEmbeddedJSON(value, to: &values)
          }
        case .number(let value):
          values[normalizeName(key)] = numberString(value)
        default:
          addJSON(child, to: &values)
        }
      }
    case .array(let array):
      for child in array {
        addJSON(child, to: &values)
      }
    case .string, .number, .bool, .null:
      break
    }
  }

  private static func firstValue(
    aliases: [String],
    sources: [[String: String]]
  ) -> String? {
    for alias in aliases {
      let normalized = normalizeName(alias)
      for source in sources {
        if let value = source[normalized], !value.isEmpty {
          return value
        }
      }
    }
    return nil
  }

  private static func resolve(
    _ value: JSONValue,
    material: [String: String]
  ) throws -> JSONValue {
    switch value {
    case .object(let object):
      return .object(
        try object.mapValues {
          try resolve($0, material: material)
        }
      )
    case .array(let array):
      return .array(
        try array.map {
          try resolve($0, material: material)
        }
      )
    case .string(let string):
      return .string(try resolve(string, material: material))
    case .number, .bool, .null:
      return value
    }
  }

  private static func resolve(
    _ value: String,
    material: [String: String]
  ) throws -> String {
    let expression = templateExpression
    let matches = expression.matches(
      in: value,
      range: NSRange(value.startIndex..<value.endIndex, in: value)
    )
    var result = value
    for match in matches.reversed() {
      guard let range = Range(match.range(at: 0), in: result),
        let fieldRange = Range(match.range(at: 1), in: value)
      else {
        continue
      }
      let field = String(value[fieldRange])
      guard let replacement = material[field] else {
        throw SessionMaterialError.missingField(field)
      }
      result.replaceSubrange(range, with: replacement)
    }
    return result
  }

  private static func containsTemplate(_ value: JSONValue) -> Bool {
    switch value {
    case .object(let object):
      object.values.contains(where: containsTemplate)
    case .array(let array):
      array.contains(where: containsTemplate)
    case .string(let string):
      containsTemplate(string)
    case .number, .bool, .null:
      false
    }
  }

  private static func containsTemplate(_ value: String) -> Bool {
    templateExpression.firstMatch(
      in: value,
      range: NSRange(value.startIndex..<value.endIndex, in: value)
    ) != nil
  }

  private static func isValidFieldName(_ value: String) -> Bool {
    value.range(
      of: #"^[A-Za-z][A-Za-z0-9_-]*$"#,
      options: .regularExpression
    ) != nil
  }

  private static func normalizeName(_ value: String) -> String {
    value.lowercased()
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "_", with: "")
  }

  private static func origin(_ value: String) -> String? {
    guard let components = URLComponents(string: value),
      let scheme = components.scheme,
      let host = components.host
    else {
      return nil
    }
    return "\(scheme)://\(host)\(components.port.map { ":\($0)" } ?? "")"
  }

  private static func cookieDomain(
    _ domain: String,
    matches host: String?
  ) -> Bool {
    guard let host else {
      return false
    }
    let normalized =
      domain.hasPrefix(".")
      ? String(domain.dropFirst())
      : domain
    return host == normalized || host.hasSuffix(".\(normalized)")
  }

  private static func numberString(_ value: Double) -> String {
    value.rounded() == value ? String(Int64(value)) : String(value)
  }

  private static let templateExpression = try! NSRegularExpression(
    pattern: #"\{\{session\.([A-Za-z][A-Za-z0-9_-]*)\}\}"#
  )
}
