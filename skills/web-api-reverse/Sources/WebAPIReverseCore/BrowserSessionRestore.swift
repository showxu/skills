import CryptoKit
import Darwin
import Foundation

@_silgen_name("flock")
private func browserRestoreFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

public enum BrowserSessionRestoreError: Error, Equatable, LocalizedError {
  case invalidSeed
  case stateOutsideScope
  case sessionCookieIsNotDurable(String)
  case sessionStorageIsNotDurable(String)
  case invalidCookie(String)
  case profileInUse(String)
  case profileNotDirectory(String)
  case profileChanged(String)
  case unsafeProfile(String)
  case commitFailed(String)
  case transactionIndeterminate(String)
  case transactionAlreadyFinished

  public var errorDescription: String? {
    switch self {
    case .invalidSeed:
      "The private session seed has an unsupported schema or kind."
    case .stateOutsideScope:
      "The private session seed contains state outside the requested domain scope."
    case .sessionCookieIsNotDurable(let name):
      "Session Cookie cannot be restored as durable profile state: \(name)"
    case .sessionStorageIsNotDurable(let origin):
      "Session storage cannot be restored as durable profile state: \(origin)"
    case .invalidCookie(let name):
      "The private session seed contains an invalid cookie: \(name)"
    case .profileInUse(let path):
      "The persistent browser profile is currently in use: \(path)"
    case .profileNotDirectory(let path):
      "The browser profile is not a directory: \(path)"
    case .profileChanged(let path):
      "The browser profile changed during restore and was left untouched: \(path)"
    case .unsafeProfile(let path):
      "The browser profile or its parent is not safe for an atomic restore: \(path)"
    case .commitFailed(let path):
      "The verified browser profile could not be committed atomically: \(path)"
    case .transactionIndeterminate(let path):
      "The browser profile restore entered an indeterminate state and requires recovery: \(path)"
    case .transactionAlreadyFinished:
      "The browser profile restore transaction has already finished."
    }
  }
}

public struct BrowserSessionRestoreValidation: Equatable, Sendable {
  public let seed: PrivateSessionSeed
  public let seedSHA256: String

  public init(seed: PrivateSessionSeed, seedSHA256: String) {
    self.seed = seed
    self.seedSHA256 = seedSHA256
  }
}

public enum BrowserSessionRestoreValidator {
  public static func validate(
    seed: PrivateSessionSeed,
    allowedDomains: [String]
  ) throws -> BrowserSessionRestoreValidation {
    try validateSessionSeed(
      seed,
      allowedDomains: allowedDomains,
      allowsSessionStorage: false
    )
  }
}

public enum BrowserSessionReplayValidator {
  public static func validate(
    seed: PrivateSessionSeed,
    allowedDomains: [String]
  ) throws -> BrowserSessionRestoreValidation {
    try validateSessionSeed(
      seed,
      allowedDomains: allowedDomains,
      allowsSessionStorage: true
    )
  }
}

private func validateSessionSeed(
  _ seed: PrivateSessionSeed,
  allowedDomains: [String],
  allowsSessionStorage: Bool
) throws -> BrowserSessionRestoreValidation {
  guard
    seed.schemaVersion == 1,
    seed.kind == "web-api-reverse.private-session-seed"
  else {
    throw BrowserSessionRestoreError.invalidSeed
  }
  let scoped = try BrowserWorker.scopeSessionSeed(
    seed,
    allowedDomains: allowedDomains
  )
  guard
    scoped.cookies.count == seed.cookies.count,
    scoped.origins.count == seed.origins.count
  else {
    throw BrowserSessionRestoreError.stateOutsideScope
  }
  for cookie in scoped.cookies {
    guard
      !cookie.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !cookie.domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      cookie.path.hasPrefix("/")
    else {
      throw BrowserSessionRestoreError.invalidCookie(
        cookie.name.isEmpty ? "<empty>" : cookie.name
      )
    }
    if !allowsSessionStorage, cookie.expires <= 0 {
      throw BrowserSessionRestoreError.sessionCookieIsNotDurable(
        cookie.name
      )
    }
  }
  for origin in scoped.origins
  where !allowsSessionStorage && !origin.sessionStorage.isEmpty {
    throw BrowserSessionRestoreError.sessionStorageIsNotDurable(
      origin.origin
    )
  }
  let encoded = try DeterministicJSON.encode(scoped)
  return BrowserSessionRestoreValidation(
    seed: scoped,
    seedSHA256: FileDigest.sha256(data: encoded)
  )
}

public final class BrowserProfileRestoreTransaction: @unchecked Sendable {
  private static let journalFileName = "restore-journal.json"
  private static let maximumJournalBytes = 64 * 1024

  public let profileDirectory: URL
  public let stagingDirectory: URL

  private let parentDirectory: URL
  private let profileName: String
  private let parentDescriptor: Int32
  private let transactionLockDescriptor: Int32
  private let workStore: PrivateArtifactStore
  private let snapshot: BrowserProfileSnapshot
  private let originalMetadata: stat?
  private let originalGeneration: String?
  private let claimedBrowserLock: BrowserLockClaim?
  private let lifecycleLock = NSLock()
  private var lifecycle: Lifecycle = .active
  private var descriptorsReleased = false

  private enum Lifecycle {
    case active
    case finished
    case indeterminate
  }

  private enum SimulatedAbruptInterruption: Error {
    case stop
  }

  enum InterruptionPoint: Sendable {
    case afterProfileSwap
    case afterCommitJournal
  }

  private enum JournalPhase: String, Codable, Sendable {
    case staged
    case committed
  }

  private struct DirectoryIdentity: Codable, Equatable, Sendable {
    let device: UInt64
    let inode: UInt64

    init(_ metadata: stat) {
      device = UInt64(metadata.st_dev)
      inode = UInt64(metadata.st_ino)
    }
  }

  private struct RestoreJournal: Codable, Sendable {
    let schemaVersion: Int
    let kind: String
    let phase: JournalPhase
    let profileName: String
    let snapshotDirectoryName: String
    let originalIdentity: DirectoryIdentity?
    let stagedIdentity: DirectoryIdentity
    let claimedBrowserLock: BrowserLockClaim?
    let stagedBrowserLock: BrowserLockClaim?
    let stagedGeneration: String?

    init(
      phase: JournalPhase,
      profileName: String,
      snapshotDirectoryName: String,
      originalIdentity: DirectoryIdentity?,
      stagedIdentity: DirectoryIdentity,
      claimedBrowserLock: BrowserLockClaim?,
      stagedBrowserLock: BrowserLockClaim? = nil,
      stagedGeneration: String? = nil
    ) {
      schemaVersion = 1
      kind = "web-api-reverse.browser-profile-restore"
      self.phase = phase
      self.profileName = profileName
      self.snapshotDirectoryName = snapshotDirectoryName
      self.originalIdentity = originalIdentity
      self.stagedIdentity = stagedIdentity
      self.claimedBrowserLock = claimedBrowserLock
      self.stagedBrowserLock = stagedBrowserLock
      self.stagedGeneration = stagedGeneration
    }

    func updating(
      phase: JournalPhase,
      claimedBrowserLock: BrowserLockClaim?,
      stagedBrowserLock: BrowserLockClaim? = nil,
      stagedGeneration: String? = nil
    ) -> Self {
      Self(
        phase: phase,
        profileName: profileName,
        snapshotDirectoryName: snapshotDirectoryName,
        originalIdentity: originalIdentity,
        stagedIdentity: stagedIdentity,
        claimedBrowserLock: claimedBrowserLock,
        stagedBrowserLock: stagedBrowserLock,
        stagedGeneration: stagedGeneration
      )
    }
  }

  public init(
    profileDirectory: URL,
    fileManager: FileManager = .default
  ) throws {
    _ = fileManager
    let standardized = profileDirectory.standardizedFileURL
    guard
      standardized.isFileURL,
      standardized.path.hasPrefix("/"),
      !standardized.lastPathComponent.isEmpty,
      standardized.lastPathComponent != ".",
      standardized.lastPathComponent != ".."
    else {
      throw BrowserSessionRestoreError.unsafeProfile(profileDirectory.path)
    }
    let canonicalParent = try Self.canonicalDirectory(
      standardized.deletingLastPathComponent()
    )
    let parentDescriptor = Self.openDirectory(canonicalParent)
    guard parentDescriptor >= 0 else {
      throw BrowserSessionRestoreError.unsafeProfile(profileDirectory.path)
    }
    var keepParentDescriptor = false
    defer {
      if !keepParentDescriptor { _ = Darwin.close(parentDescriptor) }
    }
    let profileName = standardized.lastPathComponent
    let transactionLockDescriptor = try Self.acquireTransactionLock(
      profileName: profileName,
      parentDescriptor: parentDescriptor,
      profilePath: standardized.path
    )
    var keepTransactionLock = false
    defer {
      if !keepTransactionLock {
        _ = browserRestoreFlock(transactionLockDescriptor, LOCK_UN)
        _ = Darwin.close(transactionLockDescriptor)
      }
    }

    let canonicalProfile = canonicalParent.appending(
      path: profileName,
      directoryHint: .isDirectory
    )
    let workName = Self.workDirectoryName(profileName: profileName)
    let workURL = canonicalParent.appending(
      path: workName,
      directoryHint: .isDirectory
    )
    if workName.withCString({
      var metadata = stat()
      return Darwin.fstatat(
        parentDescriptor,
        $0,
        &metadata,
        AT_SYMLINK_NOFOLLOW
      )
    }) == 0 {
      let staleStore = try PrivateArtifactStore(privateRoot: workURL)
      try Self.recoverInterruptedRestore(
        workStore: staleStore,
        profileName: profileName,
        parentDescriptor: parentDescriptor,
        profilePath: canonicalProfile.path
      )
    } else if errno != ENOENT {
      throw BrowserSessionRestoreError.unsafeProfile(workURL.path)
    }
    var original = stat()
    let profileStatus = profileName.withCString {
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &original,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if profileStatus == 0 {
      guard original.st_mode & S_IFMT == S_IFDIR else {
        throw BrowserSessionRestoreError.profileNotDirectory(
          canonicalProfile.path
        )
      }
    } else if errno != ENOENT {
      throw BrowserSessionRestoreError.unsafeProfile(canonicalProfile.path)
    }
    let workStore = try PrivateArtifactStore(
      privateRoot: workURL,
      createPrivateRoot: true
    )
    var snapshot: BrowserProfileSnapshot?
    var claim: BrowserLockClaim?
    var generation: String?
    do {
      if profileStatus == 0 {
        snapshot = try BrowserProfileSnapshot.create(
          from: canonicalProfile,
          under: workStore.privateRoot
        )
        try Self.saveJournal(
          Self.makeJournal(
            phase: .staged,
            profileName: profileName,
            snapshot: try snapshot.unwrap(
              or: BrowserSessionRestoreError.commitFailed(
                canonicalProfile.path
              )
            ),
            originalMetadata: original,
            claimedBrowserLock: nil
          ),
          to: workStore
        )
        claim = try Self.claimBrowserLock(
          profileName: profileName,
          parentDescriptor: parentDescriptor,
          profilePath: canonicalProfile.path
        )
        guard
          profileName.withCString({
            Darwin.fstatat(
              parentDescriptor,
              $0,
              &original,
              AT_SYMLINK_NOFOLLOW
            )
          }) == 0
        else {
          throw BrowserSessionRestoreError.profileChanged(
            canonicalProfile.path
          )
        }
        generation = try BrowserProfileSnapshot.sourceGeneration(
          for: canonicalProfile
        )
        let stagedJournal = try Self.loadJournal(from: workStore)
        try Self.saveJournal(
          stagedJournal.updating(
            phase: .staged,
            claimedBrowserLock: claim
          ),
          to: workStore
        )
      } else {
        let emptyRoot = try PrivateArtifactStore.makeTemporaryRoot(
          prefix: "web-api-reverse-empty-profile"
        )
        let emptyStore = try PrivateArtifactStore(privateRoot: emptyRoot)
        defer { try? emptyStore.removeRoot() }
        snapshot = try BrowserProfileSnapshot.create(
          from: emptyRoot,
          under: workStore.privateRoot
        )
        try Self.saveJournal(
          Self.makeJournal(
            phase: .staged,
            profileName: profileName,
            snapshot: try snapshot.unwrap(
              or: BrowserSessionRestoreError.commitFailed(
                canonicalProfile.path
              )
            ),
            originalMetadata: nil,
            claimedBrowserLock: nil
          ),
          to: workStore
        )
      }
    } catch {
      if let claim {
        try? Self.releaseBrowserLock(
          claim,
          profileName: profileName,
          parentDescriptor: parentDescriptor
        )
      }
      try? snapshot?.remove()
      try? workStore.removeRoot()
      if case BrowserProfileSnapshotError.sourceInUse = error {
        throw BrowserSessionRestoreError.profileInUse(canonicalProfile.path)
      }
      throw error
    }
    let committedSnapshot = try snapshot.unwrap(
      or: BrowserSessionRestoreError.commitFailed(canonicalProfile.path)
    )

    self.profileDirectory = canonicalProfile
    parentDirectory = canonicalParent
    self.profileName = profileName
    self.parentDescriptor = parentDescriptor
    self.transactionLockDescriptor = transactionLockDescriptor
    self.workStore = workStore
    self.snapshot = committedSnapshot
    stagingDirectory = committedSnapshot.directory
    originalMetadata = profileStatus == 0 ? original : nil
    originalGeneration = generation
    claimedBrowserLock = claim
    keepParentDescriptor = true
    keepTransactionLock = true
  }

  deinit {
    lifecycleLock.lock()
    if lifecycle == .active {
      try? rollbackLocked()
    }
    releaseDescriptorsLocked()
    lifecycleLock.unlock()
  }

  public func commit() throws {
    try commit(interruptAfter: nil)
  }

  func simulateAbruptInterruptionForTesting(
    after point: InterruptionPoint
  ) throws {
    try commit(interruptAfter: point)
  }

  private func commit(
    interruptAfter interruptionPoint: InterruptionPoint?
  ) throws {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    guard lifecycle == .active else {
      throw BrowserSessionRestoreError.transactionAlreadyFinished
    }
    try requireOriginalProfileUnchanged()
    let journal = try Self.loadJournal(from: workStore)
    guard
      journal.phase == .staged,
      journal.profileName == profileName,
      journal.snapshotDirectoryName == snapshot.directoryName,
      journal.claimedBrowserLock?.target == claimedBrowserLock?.target
    else {
      throw BrowserSessionRestoreError.transactionIndeterminate(
        profileDirectory.path
      )
    }
    var stagedBrowserLock: BrowserLockClaim?
    var stagedGeneration: String?
    var preparedJournal: RestoreJournal?
    do {
      let claim = try Self.claimBrowserLock(
        profileDirectory: snapshot.directory
      )
      stagedBrowserLock = claim
      let generation = try BrowserProfileSnapshot.sourceGeneration(
        for: snapshot.directory
      )
      stagedGeneration = generation
      let updatedJournal = journal.updating(
        phase: .staged,
        claimedBrowserLock: claimedBrowserLock,
        stagedBrowserLock: claim,
        stagedGeneration: generation
      )
      preparedJournal = updatedJournal
      try Self.saveJournal(updatedJournal, to: workStore)
    } catch {
      if let stagedBrowserLock {
        try? Self.releaseBrowserLock(
          stagedBrowserLock,
          at: snapshot.directory
        )
      }
      throw error
    }
    guard
      let stagedBrowserLock,
      let stagedGeneration,
      let preparedJournal
    else {
      throw BrowserSessionRestoreError.transactionIndeterminate(
        profileDirectory.path
      )
    }
    var exchanged = false
    var installedNewProfile = false
    var interrupted = false
    do {
      try snapshot.owner.withRootDescriptor { workDescriptor in
        if originalMetadata != nil {
          guard profileName.withCString({ profilePointer in
            snapshot.directoryName.withCString { snapshotPointer in
              Darwin.renameatx_np(
                parentDescriptor,
                profilePointer,
                workDescriptor,
                snapshotPointer,
                UInt32(RENAME_SWAP)
              )
            }
          }) == 0 else {
            throw BrowserSessionRestoreError.commitFailed(
              profileDirectory.path
            )
          }
          exchanged = true
        } else {
          guard snapshot.directoryName.withCString({ snapshotPointer in
            profileName.withCString { profilePointer in
              Darwin.renameatx_np(
                workDescriptor,
                snapshotPointer,
                parentDescriptor,
                profilePointer,
                UInt32(RENAME_EXCL)
              )
            }
          }) == 0 else {
            throw BrowserSessionRestoreError.commitFailed(
              profileDirectory.path
            )
          }
          installedNewProfile = true
        }
        guard
          Darwin.fsync(parentDescriptor) == 0,
          Darwin.fsync(workDescriptor) == 0
        else {
          throw BrowserSessionRestoreError.commitFailed(
            profileDirectory.path
          )
        }
      }
      if interruptionPoint == .afterProfileSwap {
        interrupted = true
        throw SimulatedAbruptInterruption.stop
      }
      try Self.saveJournal(
        preparedJournal.updating(
          phase: .committed,
          claimedBrowserLock: claimedBrowserLock,
          stagedBrowserLock: stagedBrowserLock,
          stagedGeneration: stagedGeneration
        ),
        to: workStore
      )
      if interruptionPoint == .afterCommitJournal {
        interrupted = true
        throw SimulatedAbruptInterruption.stop
      }
    } catch {
      if interrupted {
        lifecycle = .indeterminate
        releaseDescriptorsLocked()
        throw BrowserSessionRestoreError.transactionIndeterminate(
          profileDirectory.path
        )
      }
      if exchanged {
        let restored: Bool
        do {
          try snapshot.owner.withRootDescriptor { workDescriptor in
            let status = profileName.withCString { profilePointer in
              snapshot.directoryName.withCString { snapshotPointer in
                Darwin.renameatx_np(
                  parentDescriptor,
                  profilePointer,
                  workDescriptor,
                  snapshotPointer,
                  UInt32(RENAME_SWAP)
                )
              }
            }
            guard
              status == 0,
              Darwin.fsync(parentDescriptor) == 0,
              Darwin.fsync(workDescriptor) == 0
            else {
              throw BrowserSessionRestoreError.transactionIndeterminate(
                profileDirectory.path
              )
            }
          }
          restored = true
        } catch {
          restored = false
        }
        guard restored else {
          lifecycle = .indeterminate
          releaseDescriptorsLocked()
          throw BrowserSessionRestoreError.transactionIndeterminate(
            profileDirectory.path
          )
        }
      } else if installedNewProfile {
        let restored: Bool
        do {
          try snapshot.owner.withRootDescriptor { workDescriptor in
            let status = profileName.withCString { profilePointer in
              snapshot.directoryName.withCString { snapshotPointer in
                Darwin.renameatx_np(
                  parentDescriptor,
                  profilePointer,
                  workDescriptor,
                  snapshotPointer,
                  UInt32(RENAME_EXCL)
                )
              }
            }
            guard
              status == 0,
              Darwin.fsync(parentDescriptor) == 0,
              Darwin.fsync(workDescriptor) == 0
            else {
              throw BrowserSessionRestoreError.transactionIndeterminate(
                profileDirectory.path
              )
            }
          }
          restored = true
        } catch {
          restored = false
        }
        guard restored else {
          lifecycle = .indeterminate
          releaseDescriptorsLocked()
          throw BrowserSessionRestoreError.transactionIndeterminate(
            profileDirectory.path
          )
        }
      }
      do {
        try Self.releaseBrowserLock(
          stagedBrowserLock,
          at: snapshot.directory
        )
      } catch {
        lifecycle = .indeterminate
        releaseDescriptorsLocked()
        throw BrowserSessionRestoreError.transactionIndeterminate(
          profileDirectory.path
        )
      }
      throw error
    }
    do {
      try Self.releaseBrowserLock(
        stagedBrowserLock,
        profileName: profileName,
        parentDescriptor: parentDescriptor
      )
    } catch {
      lifecycle = .indeterminate
      releaseDescriptorsLocked()
      throw BrowserSessionRestoreError.transactionIndeterminate(
        profileDirectory.path
      )
    }
    lifecycle = .finished
    try? snapshot.remove()
    try? workStore.removeRoot()
    releaseDescriptorsLocked()
  }

  public func rollback() throws {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    guard lifecycle == .active else { return }
    try rollbackLocked()
  }

  private func rollbackLocked() throws {
    if let claimedBrowserLock {
      try Self.releaseBrowserLock(
        claimedBrowserLock,
        profileName: profileName,
        parentDescriptor: parentDescriptor
      )
    }
    try snapshot.remove()
    try workStore.removeRoot()
    lifecycle = .finished
    releaseDescriptorsLocked()
  }

  private func releaseDescriptorsLocked() {
    guard !descriptorsReleased else { return }
    _ = browserRestoreFlock(transactionLockDescriptor, LOCK_UN)
    _ = Darwin.close(transactionLockDescriptor)
    _ = Darwin.close(parentDescriptor)
    descriptorsReleased = true
  }

  private func requireOriginalProfileUnchanged() throws {
    var metadata = stat()
    let status = profileName.withCString {
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &metadata,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if let originalMetadata {
      guard
        status == 0,
        Self.sameVersion(originalMetadata, metadata),
        claimedBrowserLock.map({
          Self.browserLockMatches(
            $0,
            profileName: profileName,
            parentDescriptor: parentDescriptor
          )
        }) == true
      else {
        throw BrowserSessionRestoreError.profileChanged(
          profileDirectory.path
        )
      }
      guard
        let originalGeneration,
        try BrowserProfileSnapshot.sourceGeneration(for: profileDirectory)
          == originalGeneration
      else {
        throw BrowserSessionRestoreError.profileChanged(
          profileDirectory.path
        )
      }
    } else if status == 0 || errno != ENOENT {
      throw BrowserSessionRestoreError.profileChanged(profileDirectory.path)
    }
  }

  private struct BrowserLockClaim: Codable, Sendable {
    let target: String
    let device: UInt64
    let inode: UInt64
  }

  private static func claimBrowserLock(
    profileName: String,
    parentDescriptor: Int32,
    profilePath: String
  ) throws -> BrowserLockClaim {
    let profileDescriptor = profileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard profileDescriptor >= 0 else {
      throw BrowserSessionRestoreError.profileChanged(profilePath)
    }
    defer { _ = Darwin.close(profileDescriptor) }
    return try claimBrowserLock(
      profileDescriptor: profileDescriptor,
      profilePath: profilePath
    )
  }

  private static func claimBrowserLock(
    profileDirectory: URL
  ) throws -> BrowserLockClaim {
    let descriptor = openDirectory(profileDirectory)
    guard descriptor >= 0 else {
      throw BrowserSessionRestoreError.profileChanged(
        profileDirectory.path
      )
    }
    defer { _ = Darwin.close(descriptor) }
    return try claimBrowserLock(
      profileDescriptor: descriptor,
      profilePath: profileDirectory.path
    )
  }

  private static func claimBrowserLock(
    profileDescriptor: Int32,
    profilePath: String
  ) throws -> BrowserLockClaim {
    try removeStaleSingletonLock(
      profileDescriptor: profileDescriptor,
      profilePath: profilePath
    )
    let target = "lifewear-restore-\(getpid())"
    let status = target.withCString { targetPointer in
      "SingletonLock".withCString { namePointer in
        Darwin.symlinkat(targetPointer, profileDescriptor, namePointer)
      }
    }
    guard status == 0 else {
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    var metadata = stat()
    guard
      "SingletonLock".withCString({
        Darwin.fstatat(
          profileDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0,
      metadata.st_mode & S_IFMT == S_IFLNK,
      Darwin.fsync(profileDescriptor) == 0
    else {
      _ = "SingletonLock".withCString {
        Darwin.unlinkat(profileDescriptor, $0, 0)
      }
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    return BrowserLockClaim(
      target: target,
      device: UInt64(metadata.st_dev),
      inode: UInt64(metadata.st_ino)
    )
  }

  private static func removeStaleSingletonLock(
    profileDescriptor: Int32,
    profilePath: String
  ) throws {
    var metadata = stat()
    let status = "SingletonLock".withCString {
      Darwin.fstatat(
        profileDescriptor,
        $0,
        &metadata,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if status != 0, errno == ENOENT { return }
    guard status == 0, metadata.st_mode & S_IFMT == S_IFLNK else {
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
    let count = "SingletonLock".withCString {
      Darwin.readlinkat(
        profileDescriptor,
        $0,
        &buffer,
        buffer.count - 1
      )
    }
    guard count > 0 else {
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    let target = String(
      decoding: buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) },
      as: UTF8.self
    )
    if
      let component = target.split(separator: "-").last,
      let pid = Int32(component),
      pid > 0,
      Darwin.kill(pid, 0) == 0 || errno == EPERM
    {
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    let quarantine = ".lifewear-stale-lock-\(UUID().uuidString.lowercased())"
    guard "SingletonLock".withCString({ sourcePointer in
      quarantine.withCString { quarantinePointer in
        Darwin.renameatx_np(
          profileDescriptor,
          sourcePointer,
          profileDescriptor,
          quarantinePointer,
          UInt32(RENAME_EXCL)
        )
      }
    }) == 0 else {
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    var quarantined = stat()
    guard
      quarantine.withCString({
        Darwin.fstatat(
          profileDescriptor,
          $0,
          &quarantined,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0,
      quarantined.st_dev == metadata.st_dev,
      quarantined.st_ino == metadata.st_ino,
      quarantine.withCString({
        Darwin.unlinkat(profileDescriptor, $0, 0)
      }) == 0,
      Darwin.fsync(profileDescriptor) == 0
    else {
      _ = quarantine.withCString { quarantinePointer in
        "SingletonLock".withCString { sourcePointer in
          Darwin.renameatx_np(
            profileDescriptor,
            quarantinePointer,
            profileDescriptor,
            sourcePointer,
            UInt32(RENAME_EXCL)
          )
        }
      }
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
  }

  private static func releaseBrowserLock(
    _ claim: BrowserLockClaim,
    profileName: String,
    parentDescriptor: Int32
  ) throws {
    let profileDescriptor = profileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard profileDescriptor >= 0 else {
      throw BrowserSessionRestoreError.profileChanged(profileName)
    }
    defer { _ = Darwin.close(profileDescriptor) }
    try releaseBrowserLock(
      claim,
      profileDescriptor: profileDescriptor,
      profilePath: profileName,
      missingIsSuccess: false
    )
  }

  private static func releaseBrowserLock(
    _ claim: BrowserLockClaim,
    at profileDirectory: URL,
    missingIsSuccess: Bool = false
  ) throws {
    let profileDescriptor = openDirectory(profileDirectory)
    guard profileDescriptor >= 0 else {
      throw BrowserSessionRestoreError.profileChanged(
        profileDirectory.path
      )
    }
    defer { _ = Darwin.close(profileDescriptor) }
    try releaseBrowserLock(
      claim,
      profileDescriptor: profileDescriptor,
      profilePath: profileDirectory.path,
      missingIsSuccess: missingIsSuccess
    )
  }

  private static func releaseBrowserLock(
    _ claim: BrowserLockClaim,
    profileDescriptor: Int32,
    profilePath: String,
    missingIsSuccess: Bool
  ) throws {
    if missingIsSuccess {
      var metadata = stat()
      let status = "SingletonLock".withCString {
        Darwin.fstatat(
          profileDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }
      if status != 0, errno == ENOENT { return }
    }
    guard browserLockMatches(
      claim,
      profileDescriptor: profileDescriptor
    ) else {
      throw BrowserSessionRestoreError.profileChanged(profilePath)
    }
    guard
      "SingletonLock".withCString({
        Darwin.unlinkat(profileDescriptor, $0, 0)
      }) == 0,
      Darwin.fsync(profileDescriptor) == 0
    else {
      throw BrowserSessionRestoreError.commitFailed(profilePath)
    }
  }

  private static func browserLockMatches(
    _ claim: BrowserLockClaim,
    profileName: String,
    parentDescriptor: Int32
  ) -> Bool {
    let profileDescriptor = profileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard profileDescriptor >= 0 else { return false }
    defer { _ = Darwin.close(profileDescriptor) }
    return browserLockMatches(claim, profileDescriptor: profileDescriptor)
  }

  private static func browserLockMatches(
    _ claim: BrowserLockClaim,
    profileDescriptor: Int32
  ) -> Bool {
    var metadata = stat()
    guard
      "SingletonLock".withCString({
        Darwin.fstatat(
          profileDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0,
      metadata.st_mode & S_IFMT == S_IFLNK,
      UInt64(metadata.st_dev) == claim.device,
      UInt64(metadata.st_ino) == claim.inode
    else { return false }
    var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
    let count = "SingletonLock".withCString {
      Darwin.readlinkat(
        profileDescriptor,
        $0,
        &buffer,
        buffer.count - 1
      )
    }
    guard count > 0 else { return false }
    let target = String(
      decoding: buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) },
      as: UTF8.self
    )
    return target == claim.target
  }

  private static func makeJournal(
    phase: JournalPhase,
    profileName: String,
    snapshot: BrowserProfileSnapshot,
    originalMetadata: stat?,
    claimedBrowserLock: BrowserLockClaim?
  ) throws -> RestoreJournal {
    let stagedIdentity = try snapshot.owner.withRootDescriptor {
      workDescriptor in
      guard
        let identity = try directoryIdentity(
          named: snapshot.directoryName,
          under: workDescriptor
        )
      else {
        throw BrowserSessionRestoreError.transactionIndeterminate(
          snapshot.directory.path
        )
      }
      return identity
    }
    return RestoreJournal(
      phase: phase,
      profileName: profileName,
      snapshotDirectoryName: snapshot.directoryName,
      originalIdentity: originalMetadata.map(DirectoryIdentity.init),
      stagedIdentity: stagedIdentity,
      claimedBrowserLock: claimedBrowserLock,
      stagedBrowserLock: nil,
      stagedGeneration: nil
    )
  }

  private static func saveJournal(
    _ journal: RestoreJournal,
    to workStore: PrivateArtifactStore
  ) throws {
    try workStore.write(
      DeterministicJSON.encode(journal),
      named: journalFileName,
      maximumBytes: maximumJournalBytes
    )
  }

  private static func loadJournal(
    from workStore: PrivateArtifactStore
  ) throws -> RestoreJournal {
    let journal: RestoreJournal
    do {
      journal = try DeterministicJSON.decode(
        RestoreJournal.self,
        from: workStore.read(
          named: journalFileName,
          maximumBytes: maximumJournalBytes
        )
      )
    } catch {
      throw BrowserSessionRestoreError.transactionIndeterminate(
        workStore.privateRoot.path
      )
    }
    guard
      journal.schemaVersion == 1,
      journal.kind == "web-api-reverse.browser-profile-restore",
      !journal.snapshotDirectoryName.isEmpty,
      !journal.snapshotDirectoryName.contains("/"),
      journal.snapshotDirectoryName.hasPrefix(
        ".browser-profile-snapshot-"
      )
    else {
      throw BrowserSessionRestoreError.transactionIndeterminate(
        workStore.privateRoot.path
      )
    }
    return journal
  }

  private static func recoverInterruptedRestore(
    workStore: PrivateArtifactStore,
    profileName: String,
    parentDescriptor: Int32,
    profilePath: String
  ) throws {
    guard try workStore.contains(journalFileName) else {
      throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
    }
    let journal = try loadJournal(from: workStore)
    guard journal.profileName == profileName else {
      throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
    }
    let profileIdentity = try directoryIdentity(
      named: profileName,
      under: parentDescriptor
    )
    let snapshotIdentity = try workStore.withRootDescriptor {
      try directoryIdentity(
        named: journal.snapshotDirectoryName,
        under: $0
      )
    }

    switch (journal.phase, journal.originalIdentity) {
    case (.staged, .some(let originalIdentity)):
      if
        profileIdentity == originalIdentity,
        snapshotIdentity == journal.stagedIdentity
      {
        try releaseInterruptedBrowserLock(
          journal.claimedBrowserLock,
          profileName: profileName,
          parentDescriptor: parentDescriptor,
          profilePath: profilePath
        )
      } else if
        profileIdentity == journal.stagedIdentity,
        snapshotIdentity == originalIdentity
      {
        try requireStagedProfileUnchanged(
          journal,
          profileName: profileName,
          parentDescriptor: parentDescriptor,
          profilePath: profilePath
        )
        try swapProfileAndSnapshot(
          profileName: profileName,
          snapshotName: journal.snapshotDirectoryName,
          parentDescriptor: parentDescriptor,
          workStore: workStore,
          profilePath: profilePath
        )
        try releaseInterruptedBrowserLock(
          journal.claimedBrowserLock,
          profileName: profileName,
          parentDescriptor: parentDescriptor,
          profilePath: profilePath
        )
      } else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
    case (.staged, .none):
      if profileIdentity == nil, snapshotIdentity == journal.stagedIdentity {
        break
      }
      if profileIdentity == journal.stagedIdentity, snapshotIdentity == nil {
        try requireStagedProfileUnchanged(
          journal,
          profileName: profileName,
          parentDescriptor: parentDescriptor,
          profilePath: profilePath
        )
        try moveNewProfileBackToSnapshot(
          profileName: profileName,
          snapshotName: journal.snapshotDirectoryName,
          parentDescriptor: parentDescriptor,
          workStore: workStore,
          profilePath: profilePath
        )
      } else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
    case (.committed, .some(let originalIdentity)):
      guard
        profileIdentity == journal.stagedIdentity,
        snapshotIdentity == originalIdentity || snapshotIdentity == nil
      else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
      try releaseCommittedStagedBrowserLockIfPresent(
        journal,
        profileName: profileName,
        parentDescriptor: parentDescriptor
      )
    case (.committed, .none):
      guard
        profileIdentity == journal.stagedIdentity,
        snapshotIdentity == nil
      else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
      try releaseCommittedStagedBrowserLockIfPresent(
        journal,
        profileName: profileName,
        parentDescriptor: parentDescriptor
      )
    }
    try workStore.removeRoot()
  }

  private static func directoryIdentity(
    named name: String,
    under parentDescriptor: Int32
  ) throws -> DirectoryIdentity? {
    var metadata = stat()
    let status = name.withCString {
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &metadata,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if status != 0, errno == ENOENT { return nil }
    guard
      status == 0,
      metadata.st_mode & S_IFMT == S_IFDIR,
      metadata.st_uid == geteuid()
    else {
      throw BrowserSessionRestoreError.transactionIndeterminate(name)
    }
    return DirectoryIdentity(metadata)
  }

  private static func swapProfileAndSnapshot(
    profileName: String,
    snapshotName: String,
    parentDescriptor: Int32,
    workStore: PrivateArtifactStore,
    profilePath: String
  ) throws {
    try workStore.withRootDescriptor { workDescriptor in
      let status = profileName.withCString { profilePointer in
        snapshotName.withCString { snapshotPointer in
          Darwin.renameatx_np(
            parentDescriptor,
            profilePointer,
            workDescriptor,
            snapshotPointer,
            UInt32(RENAME_SWAP)
          )
        }
      }
      guard
        status == 0,
        Darwin.fsync(parentDescriptor) == 0,
        Darwin.fsync(workDescriptor) == 0
      else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
    }
  }

  private static func moveNewProfileBackToSnapshot(
    profileName: String,
    snapshotName: String,
    parentDescriptor: Int32,
    workStore: PrivateArtifactStore,
    profilePath: String
  ) throws {
    try workStore.withRootDescriptor { workDescriptor in
      let status = profileName.withCString { profilePointer in
        snapshotName.withCString { snapshotPointer in
          Darwin.renameatx_np(
            parentDescriptor,
            profilePointer,
            workDescriptor,
            snapshotPointer,
            UInt32(RENAME_EXCL)
          )
        }
      }
      guard
        status == 0,
        Darwin.fsync(parentDescriptor) == 0,
        Darwin.fsync(workDescriptor) == 0
      else {
        throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
      }
    }
  }

  private static func releaseInterruptedBrowserLock(
    _ claim: BrowserLockClaim?,
    profileName: String,
    parentDescriptor: Int32,
    profilePath: String
  ) throws {
    if let claim {
      let profileDescriptor = profileName.withCString {
        Darwin.openat(
          parentDescriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      guard profileDescriptor >= 0 else {
        throw BrowserSessionRestoreError.profileChanged(profilePath)
      }
      defer { _ = Darwin.close(profileDescriptor) }
      if browserLockMatches(claim, profileDescriptor: profileDescriptor) {
        try releaseBrowserLock(
          claim,
          profileDescriptor: profileDescriptor,
          profilePath: profilePath,
          missingIsSuccess: true
        )
      }
      return
    }
    let profileDescriptor = profileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard profileDescriptor >= 0 else {
      throw BrowserSessionRestoreError.profileChanged(profilePath)
    }
    defer { _ = Darwin.close(profileDescriptor) }
    try removeStaleSingletonLock(
      profileDescriptor: profileDescriptor,
      profilePath: profilePath
    )
  }

  private static func requireStagedProfileUnchanged(
    _ journal: RestoreJournal,
    profileName: String,
    parentDescriptor: Int32,
    profilePath: String
  ) throws {
    guard
      let stagedBrowserLock = journal.stagedBrowserLock,
      let stagedGeneration = journal.stagedGeneration,
      browserLockMatches(
        stagedBrowserLock,
        profileName: profileName,
        parentDescriptor: parentDescriptor
      ),
      try BrowserProfileSnapshot.sourceGeneration(
        for: URL(fileURLWithPath: profilePath, isDirectory: true)
      ) == stagedGeneration
    else {
      throw BrowserSessionRestoreError.transactionIndeterminate(profilePath)
    }
  }

  private static func releaseCommittedStagedBrowserLockIfPresent(
    _ journal: RestoreJournal,
    profileName: String,
    parentDescriptor: Int32
  ) throws {
    guard let claim = journal.stagedBrowserLock else { return }
    let profileDescriptor = profileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard profileDescriptor >= 0 else { return }
    defer { _ = Darwin.close(profileDescriptor) }
    guard browserLockMatches(claim, profileDescriptor: profileDescriptor)
    else {
      return
    }
    try releaseBrowserLock(
      claim,
      profileDescriptor: profileDescriptor,
      profilePath: profileName,
      missingIsSuccess: true
    )
  }

  private static func acquireTransactionLock(
    profileName: String,
    parentDescriptor: Int32,
    profilePath: String
  ) throws -> Int32 {
    let digest = SHA256.hash(data: Data(profileName.utf8)).prefix(12).map {
      String(format: "%02x", $0)
    }.joined()
    let lockName = ".lifewear-restore-\(digest).lock"
    let descriptor = lockName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard descriptor >= 0 else {
      throw BrowserSessionRestoreError.unsafeProfile(profilePath)
    }
    var metadata = stat()
    guard
      fstat(descriptor, &metadata) == 0,
      metadata.st_mode & S_IFMT == S_IFREG,
      metadata.st_uid == geteuid(),
      browserRestoreFlock(descriptor, LOCK_EX | LOCK_NB) == 0
    else {
      _ = Darwin.close(descriptor)
      throw BrowserSessionRestoreError.profileInUse(profilePath)
    }
    return descriptor
  }

  private static func canonicalDirectory(_ url: URL) throws -> URL {
    let pointer = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return UnsafeMutablePointer<CChar>?.none }
      return Darwin.realpath(path, nil)
    }
    guard let pointer else {
      throw BrowserSessionRestoreError.unsafeProfile(url.path)
    }
    defer { Darwin.free(pointer) }
    return URL(fileURLWithPath: String(cString: pointer), isDirectory: true)
  }

  private static func openDirectory(_ url: URL) -> Int32 {
    url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return -1 }
      return Darwin.open(
        path,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
  }

  private static func workDirectoryName(profileName: String) -> String {
    let digest = SHA256.hash(data: Data(profileName.utf8)).prefix(12).map {
      String(format: "%02x", $0)
    }.joined()
    return ".lifewear-restore-\(digest).work"
  }

  private static func sameVersion(_ lhs: stat, _ rhs: stat) -> Bool {
    lhs.st_dev == rhs.st_dev
      && lhs.st_ino == rhs.st_ino
      && lhs.st_size == rhs.st_size
      && lhs.st_mtimespec.tv_sec == rhs.st_mtimespec.tv_sec
      && lhs.st_mtimespec.tv_nsec == rhs.st_mtimespec.tv_nsec
      && lhs.st_ctimespec.tv_sec == rhs.st_ctimespec.tv_sec
      && lhs.st_ctimespec.tv_nsec == rhs.st_ctimespec.tv_nsec
  }
}

private extension Optional {
  func unwrap(or error: @autoclosure () -> any Error) throws -> Wrapped {
    guard let self else { throw error() }
    return self
  }
}
