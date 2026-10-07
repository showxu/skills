import Darwin
import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Browser profile snapshot")
struct BrowserProfileSnapshotTests {
  @Test
  func exposesStableDiagnosticCodes() {
    #expect(
      BrowserProfileSnapshotError.sourceMissing("missing").diagnosticCode
        == "browser.profile.missing"
    )
    #expect(
      BrowserProfileSnapshotError.sourceNotDirectory("file").diagnosticCode
        == "browser.profile.not_directory"
    )
    #expect(
      BrowserProfileSnapshotError.sourceInUse("profile").diagnosticCode
        == "browser.profile.in_use"
    )
  }

  @Test("Inspection writes stay isolated from the persistent profile")
  func isolatesInspectionWrites() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "persistent")
    let privateOutput = root.appending(path: "private-output")
    let sourceCookie = source.appending(path: "Default/Cookies")
    try FileManager.default.createDirectory(
      at: sourceCookie.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try Data("valid-session".utf8).write(to: sourceCookie)
    try Data("version".utf8).write(
      to: source.appending(path: "RunningChromeVersion")
    )

    let snapshot = try BrowserProfileSnapshot.create(
      from: source,
      under: privateOutput
    )
    let snapshotCookie = snapshot.directory.appending(
      path: "Default/Cookies"
    )
    try Data("server-deleted-session".utf8).write(to: snapshotCookie)

    #expect(try String(contentsOf: sourceCookie) == "valid-session")
    #expect(
      !FileManager.default.fileExists(
        atPath: snapshot.directory.appending(path: "RunningChromeVersion").path
      )
    )

    try snapshot.remove()
    #expect(
      !FileManager.default.fileExists(atPath: snapshot.directory.path)
    )
    #expect(try String(contentsOf: sourceCookie) == "valid-session")
  }

  @Test("Active source profiles fail instead of producing stale auth state")
  func rejectsSourceInUse() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "persistent")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try Data("locked".utf8).write(
      to: source.appending(path: "SingletonLock")
    )

    #expect(
      throws: BrowserProfileSnapshotError.sourceInUse(source.path)
    ) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private")
      )
    }
    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "private").path
      )
    )
  }

  @Test("A live Chromium singleton process keeps the profile locked")
  func rejectsLiveSingletonProcess() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "persistent")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try FileManager.default.createSymbolicLink(
      atPath: source.appending(path: "SingletonLock").path,
      withDestinationPath: "test-host-\(getpid())"
    )

    #expect(
      throws: BrowserProfileSnapshotError.sourceInUse(source.path)
    ) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private")
      )
    }
  }

  @Test("A stale Chromium singleton lock does not force another login")
  func ignoresStaleSingletonProcess() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "persistent")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try Data("retained".utf8).write(
      to: source.appending(path: "Cookies")
    )
    try FileManager.default.createSymbolicLink(
      atPath: source.appending(path: "SingletonLock").path,
      withDestinationPath: "test-host-2147000000"
    )
    try FileManager.default.createSymbolicLink(
      atPath: source.appending(path: "SingletonCookie").path,
      withDestinationPath: "stale-cookie"
    )

    let snapshot = try BrowserProfileSnapshot.create(
      from: source,
      under: root.appending(path: "private")
    )

    #expect(
      FileManager.default.fileExists(
        atPath: snapshot.directory.appending(path: "Cookies").path
      )
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: snapshot.directory.appending(path: "SingletonLock").path
      )
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: snapshot.directory.appending(path: "SingletonCookie").path
      )
    )
  }

  @Test("Failed source validation does not create a snapshot")
  func rejectsMissingSource() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }

    #expect(throws: BrowserProfileSnapshotError.self) {
      _ = try BrowserProfileSnapshot.create(
        from: root.appending(path: "missing"),
        under: root.appending(path: "private")
      )
    }
    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "private").path
      )
    )
  }

  @Test("Rejects a browser profile root symbolic link")
  func rejectsRootSymbolicLink() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let actual = root.appending(path: "actual")
    let source = root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: actual,
      withIntermediateDirectories: true
    )
    try FileManager.default.createSymbolicLink(
      at: source,
      withDestinationURL: actual
    )

    #expect(throws: BrowserProfileSnapshotError.unsafeSource(source.path)) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private")
      )
    }
  }

  @Test("Rejects nested browser profile symbolic links")
  func rejectsNestedSymbolicLink() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "profile")
    let victim = root.appending(path: "real-cookies")
    try FileManager.default.createDirectory(
      at: source.appending(path: "Default"),
      withIntermediateDirectories: true
    )
    try Data("private".utf8).write(to: victim)
    try FileManager.default.createSymbolicLink(
      at: source.appending(path: "Default/Cookies"),
      withDestinationURL: victim
    )

    #expect(throws: BrowserProfileSnapshotError.self) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private")
      )
    }
    #expect(try String(contentsOf: victim, encoding: .utf8) == "private")
  }

  @Test("A source change during copy fails closed")
  func rejectsSourceChangeDuringCopy() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "profile")
    let sourceFile = source.appending(path: "Cookies")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try Data("before".utf8).write(to: sourceFile)

    #expect(throws: BrowserProfileSnapshotError.self) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private"),
        copyFaultInjector: { stage in
          guard stage == .afterEntryCopied("Cookies") else { return }
          try Data("changed".utf8).write(to: sourceFile)
        }
      )
    }
  }

  @Test("A browser lock appearing during copy fails closed")
  func rejectsLockAppearingDuringCopy() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try Data("cookies".utf8).write(to: source.appending(path: "Cookies"))

    #expect(throws: BrowserProfileSnapshotError.sourceInUse(source.path)) {
      _ = try BrowserProfileSnapshot.create(
        from: source,
        under: root.appending(path: "private"),
        copyFaultInjector: { stage in
          guard stage == .afterEntryCopied("Cookies") else { return }
          try Data("locked".utf8).write(
            to: source.appending(path: "SingletonLock")
          )
        }
      )
    }
  }

  @Test("Cleanup cannot follow a replaced snapshot root")
  func cleanupRejectsReplacedRoot() throws {
    let root = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString.lowercased()
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appending(path: "profile")
    let privateRoot = root.appending(path: "private")
    let displaced = root.appending(path: "displaced")
    let victim = root.appending(path: "victim")
    try FileManager.default.createDirectory(
      at: source,
      withIntermediateDirectories: true
    )
    try Data("cookies".utf8).write(to: source.appending(path: "Cookies"))
    try FileManager.default.createDirectory(
      at: victim,
      withIntermediateDirectories: true
    )
    try Data("keep".utf8).write(to: victim.appending(path: "keep.txt"))
    let snapshot = try BrowserProfileSnapshot.create(
      from: source,
      under: privateRoot
    )
    try FileManager.default.moveItem(at: privateRoot, to: displaced)
    try FileManager.default.createSymbolicLink(
      at: privateRoot,
      withDestinationURL: victim
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      try snapshot.remove()
    }
    #expect(
      try String(
        contentsOf: victim.appending(path: "keep.txt"),
        encoding: .utf8
      ) == "keep"
    )
  }
}
