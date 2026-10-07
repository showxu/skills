import Foundation

public struct PrivateBrowserCapture: Codable, Equatable, Sendable {
  public let capturedAt: String
  public let sessionSeed: PrivateBrowserSessionSnapshot
}

public struct PrivateBrowserSessionSnapshot: Codable, Equatable, Sendable {
  public let storageState: PrivateBrowserStorageState
  public let webStorage: PrivateBrowserWebStorage
}

public struct PrivateBrowserStorageState: Codable, Equatable, Sendable {
  public let cookies: [PrivateSessionCookie]
  public let origins: [PrivateBrowserStorageOrigin]
}

public struct PrivateBrowserStorageOrigin: Codable, Equatable, Sendable {
  public let origin: String
  public let localStorage: [PrivateBrowserStorageEntry]
}

public struct PrivateBrowserStorageEntry: Codable, Equatable, Sendable {
  public let name: String
  public let value: String
}

public struct PrivateBrowserWebStorage: Codable, Equatable, Sendable {
  public let origin: String
  public let localStorage: [String: String]
  public let sessionStorage: [String: String]
}

public enum BrowserSessionSeedExtractor {
  public static func extract(
    capture: PrivateBrowserCapture,
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

    let current = capture.sessionSeed.webStorage
    let existing = origins[current.origin]
    origins[current.origin] = PrivateSessionOrigin(
      origin: current.origin,
      localStorage: existing?.localStorage.merging(
        current.localStorage,
        uniquingKeysWith: { _, current in current }
      ) ?? current.localStorage,
      sessionStorage: current.sessionStorage
    )

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
}
