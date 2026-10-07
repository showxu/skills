import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Private artifact descriptor boundary")
struct PrivateArtifactStoreTests {
  @Test("Private output is bounded, private, and atomically replaceable")
  func writesAndReadsPrivateFiles() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let store = try PrivateArtifactStore(
      privateRoot: fixture.root.appending(path: "private"),
      createPrivateRoot: true
    )

    try store.write(
      Data("first".utf8),
      named: "capture.json",
      maximumBytes: 1024
    )
    try store.write(
      Data("second".utf8),
      named: "capture.json",
      maximumBytes: 1024
    )

    #expect(
      try store.read(named: "capture.json", maximumBytes: 6)
        == Data("second".utf8)
    )
    #expect(
      throws: PrivateArtifactStoreError.fileTooLarge("capture.json")
    ) {
      _ = try store.read(named: "capture.json", maximumBytes: 5)
    }
    #expect(try permissions(store.privateRoot) == 0o700)
    #expect(
      try permissions(store.privateRoot.appending(path: "capture.json"))
        == 0o600
    )
    #expect(
      throws: PrivateArtifactStoreError.fileTooLarge("capture.json")
    ) {
      try store.write(
        Data(repeating: 0x41, count: 7),
        named: "capture.json",
        maximumBytes: 6
      )
    }
    #expect(
      try store.read(named: "capture.json", maximumBytes: 6)
        == Data("second".utf8)
    )
  }

  @Test("A symlink parent cannot redirect private output into API")
  func rejectsSymlinkParentIntoAPI() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let api = fixture.root.appending(path: "provider/API")
    try FileManager.default.createDirectory(
      at: api,
      withIntermediateDirectories: true
    )
    let link = fixture.root.appending(path: "private-link")
    try FileManager.default.createSymbolicLink(
      at: link,
      withDestinationURL: api
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      _ = try PrivateArtifactStore(
        privateRoot: link.appending(path: "auth"),
        createPrivateRoot: true
      )
    }
    #expect(
      !FileManager.default.fileExists(
        atPath: api.appending(path: "auth").path
      )
    )
  }

  @Test("A symlink leaf cannot redirect private reads or replacement")
  func rejectsSymlinkLeaf() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let store = try PrivateArtifactStore(
      privateRoot: fixture.root.appending(path: "private"),
      createPrivateRoot: true
    )
    let outside = fixture.root.appending(path: "outside.json")
    try Data("outside".utf8).write(to: outside)
    try FileManager.default.createSymbolicLink(
      at: store.privateRoot.appending(path: "capture.json"),
      withDestinationURL: outside
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      _ = try store.read(named: "capture.json", maximumBytes: 1024)
    }
    #expect(throws: PrivateArtifactStoreError.self) {
      try store.write(
        Data("private".utf8),
        named: "capture.json",
        maximumBytes: 1024
      )
    }
    #expect(try String(contentsOf: outside, encoding: .utf8) == "outside")
  }

  @Test("Replacing the root pathname cannot redirect a later write")
  func rejectsReplacedRoot() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let displaced = fixture.root.appending(path: "displaced")
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    try FileManager.default.moveItem(at: root, to: displaced)
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: false
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      try store.write(
        Data("secret".utf8),
        named: "capture.json",
        maximumBytes: 1024
      )
    }
    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "capture.json").path
      )
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: displaced.appending(path: "capture.json").path
      )
    )
  }

  @Test("A replacement race rolls back the anchored atomic write")
  func rollsBackRootReplacementRace() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let displaced = fixture.root.appending(path: "displaced")
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true,
      faultInjector: { stage in
        guard stage == .beforeAtomicReplacement else { return }
        try FileManager.default.moveItem(at: root, to: displaced)
        try FileManager.default.createDirectory(
          at: root,
          withIntermediateDirectories: false
        )
      }
    )
    try Data("previous".utf8).write(
      to: root.appending(path: "capture.json"),
      options: .atomic
    )
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o600],
      ofItemAtPath: root.appending(path: "capture.json").path
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      try store.write(
        Data("candidate".utf8),
        named: "capture.json",
        maximumBytes: 1024
      )
    }
    #expect(
      try String(
        contentsOf: displaced.appending(path: "capture.json"),
        encoding: .utf8
      ) == "previous"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: root.appending(path: "capture.json").path
      )
    )
  }

  @Test("A reverse-swap failure retains both private generations")
  func reverseSwapFailureRetainsBothGenerations() throws {
    struct InjectedFailure: Error {}

    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let bootstrap = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    let previous = Data("previous-valid-session".utf8)
    let candidate = Data("candidate-session".utf8)
    try bootstrap.write(
      previous,
      named: "session.json",
      maximumBytes: 1_024
    )
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false,
      faultInjector: { stage in
        if stage == .afterAtomicReplacement || stage == .beforeRollbackSwap {
          throw InjectedFailure()
        }
      }
    )

    #expect(
      throws: PrivateArtifactStoreError.transactionIndeterminate(
        "session.json"
      )
    ) {
      try store.write(
        candidate,
        named: "session.json",
        maximumBytes: 1_024
      )
    }
    let generations = try FileManager.default.contentsOfDirectory(
      at: root,
      includingPropertiesForKeys: nil
    ).map { try Data(contentsOf: $0) }
    #expect(generations.contains(previous))
    #expect(generations.contains(candidate))
    let recovered = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false
    )
    #expect(
      try recovered.read(named: "session.json", maximumBytes: 1_024)
        == previous
    )

    #expect(
      throws: PrivateArtifactStoreError.transactionIndeterminate(
        "session.json"
      )
    ) {
      try store.write(
        candidate,
        named: "session.json",
        maximumBytes: 1_024
      )
    }
    try recovered.remove(named: "session.json")
    #expect(try !recovered.contains("session.json"))
  }

  @Test("A replaced canonical leaf cannot be reported as committed")
  func leafRacePreservesAllPrivateGenerations() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let bootstrap = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    let artifact = root.appending(path: "session.json")
    let stolenCandidate = root.appending(path: "candidate.stolen")
    let previous = Data("previous-session".utf8)
    let candidate = Data("candidate-session".utf8)
    let attacker = Data("third-generation".utf8)
    try bootstrap.write(
      previous,
      named: "session.json",
      maximumBytes: 1_024
    )
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false,
      faultInjector: { stage in
        guard stage == .afterAtomicReplacement else { return }
        try FileManager.default.moveItem(at: artifact, to: stolenCandidate)
        try attacker.write(to: artifact)
        try FileManager.default.setAttributes(
          [.posixPermissions: 0o600],
          ofItemAtPath: artifact.path
        )
      }
    )

    #expect(
      throws: PrivateArtifactStoreError.transactionIndeterminate(
        "session.json"
      )
    ) {
      try store.write(
        candidate,
        named: "session.json",
        maximumBytes: 1_024
      )
    }
    #expect(try Data(contentsOf: artifact) == attacker)
    #expect(try Data(contentsOf: stolenCandidate) == candidate)
    let generations = try FileManager.default.contentsOfDirectory(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey]
    ).compactMap { try? Data(contentsOf: $0) }
    #expect(generations.contains(previous))
  }

  @Test(
    "Committed private cleanup is deferred without reporting a failed write",
    arguments: [
      PrivateArtifactCommitStage.beforeCommittedCleanup,
      .afterOldGenerationUnlinked,
    ]
  )
  func committedCleanupIsRestartRecoverable(
    stage: PrivateArtifactCommitStage
  ) throws {
    struct InjectedFailure: Error {}

    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let bootstrap = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    try bootstrap.write(
      Data("previous-session".utf8),
      named: "session.json",
      maximumBytes: 1_024
    )
    let candidate = Data("committed-session".utf8)
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false,
      faultInjector: { currentStage in
        if currentStage == stage { throw InjectedFailure() }
      }
    )

    try store.write(
      candidate,
      named: "session.json",
      maximumBytes: 1_024
    )
    let recovered = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false
    )
    #expect(
      try recovered.read(named: "session.json", maximumBytes: 1_024)
        == candidate
    )
    #expect(
      try FileManager.default.contentsOfDirectory(atPath: root.path)
        == ["session.json"]
    )
  }

  @Test("A private file changed during read is rejected")
  func rejectsChangedDuringRead() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let bootstrap = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    try bootstrap.write(
      Data("before".utf8),
      named: "capture.json",
      maximumBytes: 1024
    )
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: false,
      faultInjector: { _ in },
      readFaultInjector: { stage in
        guard stage == .afterInitialStat else { return }
        let handle = try FileHandle(
          forWritingTo: root.appending(path: "capture.json")
        )
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: Data("after!".utf8))
        try handle.synchronize()
        try handle.close()
      }
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      _ = try store.read(named: "capture.json", maximumBytes: 1024)
    }
  }

  @Test("Temporary cleanup never follows a replaced root")
  func cleanupRejectsRootReplacementRace() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let root = fixture.root.appending(path: "private")
    let displaced = fixture.root.appending(path: "displaced")
    let store = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true,
      faultInjector: { _ in },
      removalFaultInjector: { stage in
        guard stage == .beforeQuarantineRename else { return }
        try FileManager.default.moveItem(at: root, to: displaced)
        try FileManager.default.createDirectory(
          at: root,
          withIntermediateDirectories: false
        )
        try Data("replacement".utf8).write(
          to: root.appending(path: "marker")
        )
      }
    )
    try Data("private".utf8).write(
      to: root.appending(path: "capture.json")
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      try store.removeRoot()
    }
    #expect(
      try String(
        contentsOf: root.appending(path: "marker"),
        encoding: .utf8
      ) == "replacement"
    )
    #expect(
      try String(
        contentsOf: displaced.appending(path: "capture.json"),
        encoding: .utf8
      ) == "private"
    )
  }

  @Test("A Git worktree control file marks reusable source")
  func rejectsGitWorktreeRoot() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let worktree = fixture.root.appending(path: "web-worktree")
    try FileManager.default.createDirectory(
      at: worktree,
      withIntermediateDirectories: false
    )
    try Data("gitdir: /private/repository/worktrees/web\n".utf8).write(
      to: worktree.appending(path: ".git")
    )

    #expect(throws: PrivateArtifactStoreError.self) {
      _ = try PrivateArtifactStore(
        privateRoot: worktree.appending(path: "captures"),
        createPrivateRoot: true
      )
    }
    #expect(
      !FileManager.default.fileExists(
        atPath: worktree.appending(path: "captures").path
      )
    )
  }

  private func permissions(_ url: URL) throws -> Int {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return (attributes[.posixPermissions] as? NSNumber)?.intValue ?? -1
  }
}

private struct Fixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-private-store-tests-\(UUID().uuidString.lowercased())"
    )
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: false
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
