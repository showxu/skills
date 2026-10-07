import Foundation

public enum BrowserWorkerError: Error, LocalizedError {
  case missingResource

  public var errorDescription: String? {
    switch self {
    case .missingResource:
      "The bundled Playwright worker could not be located."
    }
  }
}

public enum BrowserSessionScopeError: Error, LocalizedError {
  case invalidDomain(String)
  case sourceOutsideScope(String)
  case noSessionState

  public var errorDescription: String? {
    switch self {
    case .invalidDomain(let domain):
      "Invalid session domain: \(domain)"
    case .sourceOutsideScope(let sourceURL):
      "Session source URL is outside the requested domain scope: \(sourceURL)"
    case .noSessionState:
      "No cookies or Web storage matched the requested session domain scope."
    }
  }
}

public enum BrowserWorker {
  public static func resourceURL() throws -> URL {
    guard
      let url = Bundle.module.url(
        forResource: "worker",
        withExtension: "mjs",
        subdirectory: "Resources/PlaywrightWorker"
      )
    else {
      throw BrowserWorkerError.missingResource
    }
    return url
  }

  public static func extractSessionSeed(
    capture: BrowserWorkerPrivateCapture,
    brand: String,
    market: String,
    profile: String,
    sourceURL: String
  ) -> PrivateSessionSeed {
    var origins: [String: PrivateSessionOrigin] = [:]
    for origin in capture.sessionSeed.storageState.origins {
      origins[origin.origin] = PrivateSessionOrigin(
        origin: origin.origin,
        localStorage: Dictionary(
          uniqueKeysWithValues: origin.localStorage.map {
            ($0.name, $0.value)
          }
        ),
        sessionStorage: [:]
      )
    }
    for storage in capture.sessionSeed.webStorages.sorted(by: {
      $0.origin < $1.origin
    }) {
      let existing = origins[storage.origin]
      origins[storage.origin] = PrivateSessionOrigin(
        origin: storage.origin,
        localStorage: existing?.localStorage.merging(
          storage.localStorage,
          uniquingKeysWith: { _, current in current }
        ) ?? storage.localStorage,
        sessionStorage: existing?.sessionStorage.merging(
          storage.sessionStorage,
          uniquingKeysWith: { _, current in current }
        ) ?? storage.sessionStorage
      )
    }
    return PrivateSessionSeed(
      brand: brand,
      market: market,
      profile: profile,
      createdAt: capture.capturedAt,
      sourceURL: sourceURL,
      cookies: capture.sessionSeed.storageState.cookies.sorted {
        ($0.name, $0.domain, $0.path)
          < ($1.name, $1.domain, $1.path)
      },
      origins: origins.values.sorted { $0.origin < $1.origin }
    )
  }

  public static func extractScopedSessionSeed(
    capture: BrowserWorkerPrivateCapture,
    brand: String,
    market: String,
    profile: String,
    sourceURL: String,
    allowedDomains: [String]
  ) throws -> PrivateSessionSeed {
    let seed = extractSessionSeed(
      capture: capture,
      brand: brand,
      market: market,
      profile: profile,
      sourceURL: sourceURL
    )
    return try scopeSessionSeed(
      seed,
      allowedDomains: allowedDomains
    )
  }

  public static func scopeSessionSeed(
    _ seed: PrivateSessionSeed,
    allowedDomains: [String]
  ) throws -> PrivateSessionSeed {
    let domains = try normalizedDomains(allowedDomains)
    guard
      let sourceHost = URL(string: seed.sourceURL)?.host?.lowercased(),
      domains.contains(where: { contains(host: sourceHost, domain: $0) })
    else {
      throw BrowserSessionScopeError.sourceOutsideScope(seed.sourceURL)
    }
    let cookies = seed.cookies.filter { cookie in
      let host = cookie.domain
        .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        .lowercased()
      return domains.contains { contains(host: host, domain: $0) }
    }
    let origins = seed.origins.filter { origin in
      guard let host = URL(string: origin.origin)?.host?.lowercased() else {
        return false
      }
      return domains.contains { contains(host: host, domain: $0) }
    }
    guard !cookies.isEmpty || !origins.isEmpty else {
      throw BrowserSessionScopeError.noSessionState
    }
    return PrivateSessionSeed(
      brand: seed.brand,
      market: seed.market,
      profile: seed.profile,
      createdAt: seed.createdAt,
      sourceURL: seed.sourceURL,
      cookies: cookies,
      origins: origins
    )
  }

  private static func normalizedDomains(
    _ values: [String]
  ) throws -> [String] {
    guard !values.isEmpty else {
      throw BrowserSessionScopeError.invalidDomain("")
    }
    return try Set(
      values.map { value in
        let domain =
          value
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .trimmingCharacters(in: CharacterSet(charactersIn: "."))
          .lowercased()
        let allowed = CharacterSet(
          charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-"
        )
        guard
          !domain.isEmpty,
          !domain.hasPrefix("."),
          !domain.hasSuffix("."),
          !domain.contains(".."),
          domain.unicodeScalars.allSatisfy(allowed.contains)
        else {
          throw BrowserSessionScopeError.invalidDomain(value)
        }
        return domain
      }
    ).sorted()
  }

  private static func contains(host: String, domain: String) -> Bool {
    host == domain || host.hasSuffix(".\(domain)")
  }
}

public struct BrowserWorkerPrivateCapture:
  Codable,
  Equatable,
  Sendable
{
  public let capturedAt: String
  public let sessionSeed: BrowserWorkerSessionSnapshot
}

public struct BrowserWorkerSessionSnapshot:
  Codable,
  Equatable,
  Sendable
{
  public let storageState: PrivateBrowserStorageState
  public let webStorages: [PrivateBrowserWebStorage]

  private enum CodingKeys: String, CodingKey {
    case storageState
    case webStorage
    case webStorages
  }

  public init(
    storageState: PrivateBrowserStorageState,
    webStorages: [PrivateBrowserWebStorage]
  ) {
    self.storageState = storageState
    self.webStorages = webStorages
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    storageState = try container.decode(
      PrivateBrowserStorageState.self,
      forKey: .storageState
    )
    if let values = try container.decodeIfPresent(
      [PrivateBrowserWebStorage].self,
      forKey: .webStorages
    ) {
      webStorages = values
    } else if let value = try container.decodeIfPresent(
      PrivateBrowserWebStorage.self,
      forKey: .webStorage
    ) {
      webStorages = [value]
    } else {
      webStorages = []
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(storageState, forKey: .storageState)
    try container.encode(webStorages, forKey: .webStorages)
  }
}
