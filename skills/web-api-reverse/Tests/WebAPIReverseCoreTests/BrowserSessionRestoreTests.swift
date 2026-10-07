import CryptoKit
import Darwin
import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Browser session restore")
struct BrowserSessionRestoreTests {
  @Test("Validates durable provider-scoped state")
  func validatesScopedState() throws {
    let seed = fixtureSeed()
    let validation = try BrowserSessionRestoreValidator.validate(
      seed: seed,
      allowedDomains: ["example.test"]
    )

    #expect(validation.seed == seed)
    #expect(
      validation.seedSHA256.range(
        of: #"^[a-f0-9]{64}$"#,
        options: .regularExpression
      ) != nil
    )
  }

  @Test("Rejects state outside the requested provider scope")
  func rejectsCrossProviderState() {
    let seed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: fixtureSeed().cookies + [
        PrivateSessionCookie(
          name: "other",
          value: "private-other",
          domain: ".other.test",
          path: "/",
          expires: -1,
          httpOnly: true,
          secure: true,
          sameSite: "Lax"
        )
      ],
      origins: fixtureSeed().origins
    )

    #expect(throws: BrowserSessionRestoreError.stateOutsideScope) {
      try BrowserSessionRestoreValidator.validate(
        seed: seed,
        allowedDomains: ["example.test"]
      )
    }
  }

  @Test("Rejects tab-scoped session storage")
  func rejectsSessionStorage() {
    let seed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: fixtureSeed().cookies,
      origins: [
        PrivateSessionOrigin(
          origin: "https://example.test",
          localStorage: [:],
          sessionStorage: ["transient": "private"]
        )
      ]
    )

    #expect(
      throws: BrowserSessionRestoreError.sessionStorageIsNotDurable(
        "https://example.test"
      )
    ) {
      try BrowserSessionRestoreValidator.validate(
        seed: seed,
        allowedDomains: ["example.test"]
      )
    }
  }

  @Test("Rejects session Cookies as durable browser profile state")
  func rejectsSessionCookiesForRestore() {
    let seed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: [
        PrivateSessionCookie(
          name: "session-only",
          value: "private-cookie",
          domain: ".example.test",
          path: "/",
          expires: -1,
          httpOnly: true,
          secure: true,
          sameSite: "Lax"
        )
      ],
      origins: fixtureSeed().origins
    )

    #expect(
      throws: BrowserSessionRestoreError.sessionCookieIsNotDurable(
        "session-only"
      )
    ) {
      try BrowserSessionRestoreValidator.validate(
        seed: seed,
        allowedDomains: ["example.test"]
      )
    }
  }

  @Test("Allows tab-scoped state for one browser replay lifecycle")
  func allowsSessionStorageForReplay() throws {
    let seed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: fixtureSeed().cookies,
      origins: [
        PrivateSessionOrigin(
          origin: "https://example.test",
          localStorage: [:],
          sessionStorage: ["transient": "private"]
        )
      ]
    )

    let validation = try BrowserSessionReplayValidator.validate(
      seed: seed,
      allowedDomains: ["example.test"]
    )

    #expect(validation.seed == seed)
  }

  @Test("Preserves valid empty-value browser cookies")
  func preservesEmptyValueCookies() throws {
    let seed = PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: fixtureSeed().cookies + [
        PrivateSessionCookie(
          name: "empty-preference",
          value: "",
          domain: ".example.test",
          path: "/",
          expires: 2_000_000_000,
          httpOnly: false,
          secure: true,
          sameSite: "Lax"
        )
      ],
      origins: fixtureSeed().origins
    )

    let validation = try BrowserSessionReplayValidator.validate(
      seed: seed,
      allowedDomains: ["example.test"]
    )

    #expect(validation.seed == seed)
  }

  @Test("Rollback leaves the original profile untouched")
  func rollbackPreservesOriginalProfile() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let transaction = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try Data("staged".utf8).write(
      to: transaction.stagingDirectory.appending(path: "added.txt")
    )

    try transaction.rollback()

    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "sentinel.txt"),
        encoding: .utf8
      ) == "original"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: fixture.profile.appending(path: "added.txt").path
      )
    )
  }

  @Test("Commit swaps the verified staging profile atomically")
  func commitPreservesUnrelatedState() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let transaction = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try Data("restored".utf8).write(
      to: transaction.stagingDirectory.appending(path: "restored.txt")
    )

    try transaction.commit()

    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "sentinel.txt"),
        encoding: .utf8
      ) == "original"
    )
    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "restored.txt"),
        encoding: .utf8
      ) == "restored"
    )
  }

  @Test("Refuses a profile with an active browser lock")
  func rejectsProfileInUse() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    try Data("locked".utf8).write(
      to: fixture.profile.appending(path: "SingletonLock")
    )

    #expect(throws: BrowserSessionRestoreError.self) {
      try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    }
  }

  @Test("A changed source profile cannot be overwritten at commit")
  func rejectsSourceChangeBeforeCommit() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let sentinel = fixture.profile.appending(path: "sentinel.txt")
    let transaction = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try Data("external-change".utf8).write(to: sentinel)

    #expect(
      throws: BrowserSessionRestoreError.profileChanged(
        transaction.profileDirectory.path
      )
    ) {
      try transaction.commit()
    }
    #expect(
      try String(contentsOf: sentinel, encoding: .utf8)
        == "external-change"
    )
    try transaction.rollback()
  }

  @Test("A second restore cannot race the active transaction")
  func serializesRestoreTransactions() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let first = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )

    #expect(throws: BrowserSessionRestoreError.self) {
      _ = try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    }
    try first.rollback()
  }

  @Test("Concurrent commit and rollback cannot corrupt the profile")
  func serializesConcurrentLifecycleCalls() async throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let transaction = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try Data("staged".utf8).write(
      to: transaction.stagingDirectory.appending(path: "staged.txt")
    )

    await withTaskGroup(of: Void.self) { group in
      group.addTask { try? transaction.commit() }
      group.addTask { try? transaction.rollback() }
    }

    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "sentinel.txt"),
        encoding: .utf8
      ) == "original"
    )
    let next = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try next.rollback()
  }

  @Test("Abandoning an active transaction releases its browser claim")
  func abandonedTransactionRollsBackOnDeinit() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    var transaction: BrowserProfileRestoreTransaction? =
      try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    try Data("staged".utf8).write(
      to: try #require(transaction).stagingDirectory
        .appending(path: "staged.txt")
    )
    transaction = nil

    #expect(
      !FileManager.default.fileExists(
        atPath: fixture.profile.appending(path: "SingletonLock").path
      )
    )
    let next = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    try next.rollback()
  }

  @Test("A restart rolls back an interrupted profile swap")
  func restartRecoversSwapBeforeCommitJournal() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    var transaction: BrowserProfileRestoreTransaction? =
      try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    try Data("uncommitted".utf8).write(
      to: try #require(transaction).stagingDirectory
        .appending(path: "interrupted.txt")
    )

    let canonicalProfilePath = try #require(transaction).profileDirectory.path
    #expect(
      throws: BrowserSessionRestoreError.transactionIndeterminate(
        canonicalProfilePath
      )
    ) {
      try transaction?.simulateAbruptInterruptionForTesting(
        after: .afterProfileSwap
      )
    }
    transaction = nil

    let recovered = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "sentinel.txt"),
        encoding: .utf8
      ) == "original"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: fixture.profile.appending(path: "interrupted.txt").path
      )
    )
    try recovered.rollback()
  }

  @Test("Recovery never removes a profile taken over after interruption")
  func restartFailsClosedAfterBrowserTakeover() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    var transaction: BrowserProfileRestoreTransaction? =
      try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    try Data("uncommitted".utf8).write(
      to: try #require(transaction).stagingDirectory
        .appending(path: "interrupted.txt")
    )
    #expect(throws: BrowserSessionRestoreError.self) {
      try transaction?.simulateAbruptInterruptionForTesting(
        after: .afterProfileSwap
      )
    }
    transaction = nil

    let singletonLock = fixture.profile.appending(path: "SingletonLock")
    try FileManager.default.removeItem(at: singletonLock)
    try FileManager.default.createSymbolicLink(
      at: singletonLock,
      withDestinationURL: URL(
        fileURLWithPath: "browser-\(getpid())",
        relativeTo: fixture.profile
      )
    )
    try Data("browser-change".utf8).write(
      to: fixture.profile.appending(path: "browser-change.txt")
    )

    #expect(throws: BrowserSessionRestoreError.self) {
      _ = try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    }
    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "browser-change.txt"),
        encoding: .utf8
      ) == "browser-change"
    )
    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "interrupted.txt"),
        encoding: .utf8
      ) == "uncommitted"
    )
  }

  @Test("A restart completes a durable committed profile swap")
  func restartFinishesCommittedSwap() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    var transaction: BrowserProfileRestoreTransaction? =
      try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    try Data("committed".utf8).write(
      to: try #require(transaction).stagingDirectory
        .appending(path: "committed.txt")
    )

    let canonicalProfilePath = try #require(transaction).profileDirectory.path
    #expect(
      throws: BrowserSessionRestoreError.transactionIndeterminate(
        canonicalProfilePath
      )
    ) {
      try transaction?.simulateAbruptInterruptionForTesting(
        after: .afterCommitJournal
      )
    }
    transaction = nil

    let recovered = try BrowserProfileRestoreTransaction(
      profileDirectory: fixture.profile
    )
    #expect(
      try String(
        contentsOf: fixture.profile.appending(path: "committed.txt"),
        encoding: .utf8
      ) == "committed"
    )
    try recovered.rollback()
  }

  @Test("An unjournaled restore directory fails closed")
  func refusesAmbiguousStaleWorkDirectory() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let digest = SHA256.hash(data: Data("profile".utf8)).prefix(12).map {
      String(format: "%02x", $0)
    }.joined()
    let work = fixture.root.appending(
      path: ".lifewear-restore-\(digest).work",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: work,
      withIntermediateDirectories: false,
      attributes: [.posixPermissions: 0o700]
    )

    #expect(throws: BrowserSessionRestoreError.self) {
      _ = try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    }
    #expect(FileManager.default.fileExists(atPath: work.path))
  }

  @Test("Nested profile symbolic links fail before staging")
  func rejectsNestedProfileSymbolicLink() throws {
    let fixture = try ProfileFixture()
    defer { fixture.remove() }
    let victim = fixture.root.appending(path: "victim")
    try Data("private".utf8).write(to: victim)
    try FileManager.default.createDirectory(
      at: fixture.profile.appending(path: "Default"),
      withIntermediateDirectories: true
    )
    try FileManager.default.createSymbolicLink(
      at: fixture.profile.appending(path: "Default/Cookies"),
      withDestinationURL: victim
    )

    #expect(throws: BrowserProfileSnapshotError.self) {
      _ = try BrowserProfileRestoreTransaction(
        profileDirectory: fixture.profile
      )
    }
    #expect(try String(contentsOf: victim, encoding: .utf8) == "private")
  }

  private func fixtureSeed() -> PrivateSessionSeed {
    PrivateSessionSeed(
      brand: "fixture",
      market: "cn",
      profile: "fixture-profile",
      createdAt: "2026-07-31T00:00:00Z",
      sourceURL: "https://example.test/account",
      cookies: [
        PrivateSessionCookie(
          name: "session",
          value: "private-cookie",
          domain: ".example.test",
          path: "/",
          expires: 2_000_000_000,
          httpOnly: true,
          secure: true,
          sameSite: "Lax"
        )
      ],
      origins: [
        PrivateSessionOrigin(
          origin: "https://example.test",
          localStorage: ["token": "private-token"],
          sessionStorage: [:]
        )
      ]
    )
  }
}

private struct ProfileFixture {
  let root: URL
  let profile: URL

  init() throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-session-restore-\(UUID().uuidString)"
    )
    profile = root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    try Data("original".utf8).write(
      to: profile.appending(path: "sentinel.txt")
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
