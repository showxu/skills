import Darwin
import Foundation

@_silgen_name("flock")
private func webAPIReverseFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

public enum PrivateArtifactStoreError: Error, Equatable, LocalizedError,
  Sendable
{
  case invalidPrivateRoot(String)
  case unsafeDirectory(String)
  case invalidFileName(String)
  case missingFile(String)
  case fileTooLarge(String)
  case unsafeFile(String)
  case writeFailed(String)
  case transactionIndeterminate(String)
  case cleanupIncomplete(String)

  public var errorDescription: String? {
    switch self {
    case .invalidPrivateRoot(let path):
      "Private artifact root must be an absolute, non-symlinked directory outside source and API trees: \(path)"
    case .unsafeDirectory(let path):
      "Private artifact root changed identity or is not private: \(path)"
    case .invalidFileName(let name):
      "Private artifact file name must be one path component: \(name)"
    case .missingFile(let name):
      "Private artifact is missing: \(name)"
    case .fileTooLarge(let name):
      "Private artifact exceeds its byte limit: \(name)"
    case .unsafeFile(let name):
      "Private artifact is not a private regular file: \(name)"
    case .writeFailed(let name):
      "Private artifact could not be committed atomically: \(name)"
    case .transactionIndeterminate(let name):
      "Private artifact replacement is indeterminate; both generations were retained: \(name)"
    case .cleanupIncomplete(let name):
      "Private artifact committed, but the displaced generation requires cleanup: \(name)"
    }
  }
}

enum PrivateArtifactCommitStage: Sendable {
  case beforeAtomicReplacement
  case afterAtomicReplacement
  case afterDirectorySync
  case beforeRollbackSwap
  case beforeCommittedCleanup
  case afterOldGenerationUnlinked
}

enum PrivateArtifactReadStage: Sendable {
  case afterInitialStat
}

enum PrivateArtifactRemovalStage: Sendable {
  case beforeQuarantineRename
}

private struct PrivateArtifactReplacementJournal: Codable, Sendable {
  let schemaVersion: Int
  let kind: String
  let phase: String?
  let fileName: String
  let temporaryName: String
  let oldDevice: UInt64
  let oldInode: UInt64
  let newDevice: UInt64
  let newInode: UInt64

  init(fileName: String, temporaryName: String, old: stat, new: stat) {
    schemaVersion = 2
    kind = "web-api-reverse.private-artifact-replacement"
    phase = "staged"
    self.fileName = fileName
    self.temporaryName = temporaryName
    oldDevice = UInt64(old.st_dev)
    oldInode = UInt64(old.st_ino)
    newDevice = UInt64(new.st_dev)
    newInode = UInt64(new.st_ino)
  }

  private init(committed journal: Self) {
    schemaVersion = 2
    kind = journal.kind
    phase = "committed"
    fileName = journal.fileName
    temporaryName = journal.temporaryName
    oldDevice = journal.oldDevice
    oldInode = journal.oldInode
    newDevice = journal.newDevice
    newInode = journal.newInode
  }

  func committed() -> Self {
    Self(committed: self)
  }
}

/// Descriptor-anchored storage for raw browser and session artifacts.
///
/// The declared root is resolved once without accepting a symbolic-link
/// component, bound by device/inode, and reopened with `O_NOFOLLOW` before
/// every operation. Files are opened relative to that descriptor so replacing
/// the pathname cannot redirect a read or write into a source tree.
public struct PrivateArtifactStore: @unchecked Sendable {
  public let privateRoot: URL

  private let canonicalRootPath: String
  private let rootDevice: dev_t
  private let rootInode: ino_t
  private let parentDevice: dev_t
  private let parentInode: ino_t
  private let faultInjector:
    @Sendable (PrivateArtifactCommitStage) throws -> Void
  private let readFaultInjector:
    @Sendable (PrivateArtifactReadStage) throws -> Void
  private let removalFaultInjector:
    @Sendable (PrivateArtifactRemovalStage) throws -> Void

  public init(
    privateRoot: URL,
    createPrivateRoot: Bool = false
  ) throws {
    try self.init(
      privateRoot: privateRoot,
      createPrivateRoot: createPrivateRoot,
      faultInjector: { _ in },
      readFaultInjector: { _ in },
      removalFaultInjector: { _ in }
    )
  }

  init(
    privateRoot: URL,
    createPrivateRoot: Bool,
    faultInjector:
      @escaping @Sendable (PrivateArtifactCommitStage) throws -> Void,
    readFaultInjector:
      @escaping @Sendable (PrivateArtifactReadStage) throws -> Void = { _ in },
    removalFaultInjector:
      @escaping @Sendable (PrivateArtifactRemovalStage) throws -> Void = { _ in }
  ) throws {
    guard privateRoot.isFileURL, privateRoot.path.hasPrefix("/") else {
      throw PrivateArtifactStoreError.invalidPrivateRoot(privateRoot.path)
    }
    let declaredRoot = privateRoot.standardizedFileURL
    let resolvedPath = try Self.resolvedDirectoryPath(for: declaredRoot)
    guard !Self.isInsideReusableSource(resolvedPath) else {
      throw PrivateArtifactStoreError.invalidPrivateRoot(resolvedPath)
    }
    let canonicalRoot = URL(
      fileURLWithPath: resolvedPath,
      isDirectory: true
    )
    if createPrivateRoot {
      try Self.createDirectoryTree(at: canonicalRoot)
    }
    let descriptor = Self.openDirectory(canonicalRoot)
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory(resolvedPath)
    }
    defer { _ = Darwin.close(descriptor) }
    var metadata = stat()
    guard
      fstat(descriptor, &metadata) == 0,
      Self.securePrivateDirectory(descriptor, metadata: &metadata)
    else {
      throw PrivateArtifactStoreError.unsafeDirectory(resolvedPath)
    }
    self.privateRoot = canonicalRoot
    canonicalRootPath = resolvedPath
    rootDevice = metadata.st_dev
    rootInode = metadata.st_ino
    let parent = canonicalRoot.deletingLastPathComponent()
    let parentDescriptor = Self.openDirectory(parent)
    var parentMetadata = stat()
    guard
      parentDescriptor >= 0,
      fstat(parentDescriptor, &parentMetadata) == 0,
      parentMetadata.st_mode & S_IFMT == S_IFDIR
    else {
      if parentDescriptor >= 0 { _ = Darwin.close(parentDescriptor) }
      throw PrivateArtifactStoreError.unsafeDirectory(parent.path)
    }
    _ = Darwin.close(parentDescriptor)
    parentDevice = parentMetadata.st_dev
    parentInode = parentMetadata.st_ino
    self.faultInjector = faultInjector
    self.readFaultInjector = readFaultInjector
    self.removalFaultInjector = removalFaultInjector
  }

  public static func makeTemporaryRoot(prefix: String) throws -> URL {
    let safePrefix = prefix.filter { $0.isLetter || $0.isNumber || $0 == "-" }
    guard !safePrefix.isEmpty else {
      throw PrivateArtifactStoreError.invalidFileName(prefix)
    }
    let root = FileManager.default.temporaryDirectory.appending(
      path: "\(safePrefix)-\(UUID().uuidString.lowercased())",
      directoryHint: .isDirectory
    )
    _ = try PrivateArtifactStore(
      privateRoot: root,
      createPrivateRoot: true
    )
    return root
  }

  public func read(
    named fileName: String,
    maximumBytes: Int
  ) throws -> Data {
    guard maximumBytes >= 0 else {
      throw PrivateArtifactStoreError.fileTooLarge(fileName)
    }
    return try withRootDescriptor { directoryDescriptor in
      guard webAPIReverseFlock(directoryDescriptor, LOCK_EX) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      defer { _ = webAPIReverseFlock(directoryDescriptor, LOCK_UN) }
      try recoverReplacementIfNeeded(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      let descriptor = try Self.openPrivateFile(
        named: fileName,
        under: directoryDescriptor
      )
      defer { _ = Darwin.close(descriptor) }
      var metadata = stat()
      guard
        fstat(descriptor, &metadata) == 0,
        Self.isPrivateRegularFile(metadata)
      else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      guard metadata.st_size >= 0, metadata.st_size <= maximumBytes else {
        throw PrivateArtifactStoreError.fileTooLarge(fileName)
      }
      try readFaultInjector(.afterInitialStat)
      let data = try Self.readAll(
        from: descriptor,
        byteCount: Int(metadata.st_size),
        fileName: fileName
      )
      try Self.requireUnchangedFile(
        named: fileName,
        initial: metadata,
        descriptor: descriptor,
        directoryDescriptor: directoryDescriptor
      )
      return data
    }
  }

  public func write(
    _ data: Data,
    named fileName: String,
    maximumBytes: Int
  ) throws {
    guard data.count <= maximumBytes else {
      throw PrivateArtifactStoreError.fileTooLarge(fileName)
    }
    try withRootDescriptor { directoryDescriptor in
      guard webAPIReverseFlock(directoryDescriptor, LOCK_EX) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      defer { _ = webAPIReverseFlock(directoryDescriptor, LOCK_UN) }
      try recoverReplacementIfNeeded(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      try installPrivateFile(
        named: fileName,
        directoryDescriptor: directoryDescriptor
      ) { descriptor in
        try Self.writeAll(data, to: descriptor, fileName: fileName)
      }
    }
  }

  public func copyFile(
    named fileName: String,
    from source: PrivateArtifactStore,
    maximumBytes: Int
  ) throws {
    guard maximumBytes >= 0 else {
      throw PrivateArtifactStoreError.fileTooLarge(fileName)
    }
    try withLockedCopyDirectories(
      source: source,
      fileName: fileName
    ) { sourceDirectory, destinationDirectory, sameRoot in
      let sourceDescriptor = try Self.openPrivateFile(
        named: fileName,
        under: sourceDirectory
      )
      defer { _ = Darwin.close(sourceDescriptor) }
      var metadata = stat()
      guard
        fstat(sourceDescriptor, &metadata) == 0,
        Self.isPrivateRegularFile(metadata)
      else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      guard metadata.st_size >= 0, metadata.st_size <= maximumBytes else {
        throw PrivateArtifactStoreError.fileTooLarge(fileName)
      }
      try source.readFaultInjector(.afterInitialStat)
      if sameRoot {
        try Self.requireUnchangedFile(
          named: fileName,
          initial: metadata,
          descriptor: sourceDescriptor,
          directoryDescriptor: sourceDirectory
        )
        return
      }
      try installPrivateFile(
        named: fileName,
        directoryDescriptor: destinationDirectory
      ) { destinationDescriptor in
        try Self.copyAll(
          from: sourceDescriptor,
          to: destinationDescriptor,
          expectedBytes: Int(metadata.st_size),
          fileName: fileName
        )
        try Self.requireUnchangedFile(
          named: fileName,
          initial: metadata,
          descriptor: sourceDescriptor,
          directoryDescriptor: sourceDirectory
        )
      }
    }
  }

  public func contains(_ fileName: String) throws -> Bool {
    try Self.requireFileName(fileName)
    return try withRootDescriptor { directoryDescriptor in
      guard webAPIReverseFlock(directoryDescriptor, LOCK_EX) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      defer { _ = webAPIReverseFlock(directoryDescriptor, LOCK_UN) }
      try recoverReplacementIfNeeded(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      var metadata = stat()
      let status = fileName.withCString {
        Darwin.fstatat(
          directoryDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }
      if status != 0, errno == ENOENT { return false }
      guard status == 0, Self.isPrivateRegularFile(metadata) else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      return true
    }
  }

  public func remove(named fileName: String) throws {
    try Self.requireFileName(fileName)
    try withRootDescriptor { directoryDescriptor in
      guard webAPIReverseFlock(directoryDescriptor, LOCK_EX) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      defer { _ = webAPIReverseFlock(directoryDescriptor, LOCK_UN) }
      try recoverReplacementIfNeeded(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      let descriptor = try Self.openPrivateFile(
        named: fileName,
        under: directoryDescriptor
      )
      defer { _ = Darwin.close(descriptor) }
      var metadata = stat()
      guard
        fstat(descriptor, &metadata) == 0,
        Self.isPrivateRegularFile(metadata)
      else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      try removalFaultInjector(.beforeQuarantineRename)
      let quarantine =
        ".web-api-reverse-remove-"
        + UUID().uuidString.lowercased()
      let renameStatus = fileName.withCString { filePointer in
        quarantine.withCString { quarantinePointer in
          Darwin.renameatx_np(
            directoryDescriptor,
            filePointer,
            directoryDescriptor,
            quarantinePointer,
            UInt32(RENAME_EXCL)
          )
        }
      }
      guard renameStatus == 0 else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      var quarantined = stat()
      guard
        quarantine.withCString({
          Darwin.fstatat(
            directoryDescriptor,
            $0,
            &quarantined,
            AT_SYMLINK_NOFOLLOW
          )
        }) == 0,
        quarantined.st_dev == metadata.st_dev,
        quarantined.st_ino == metadata.st_ino,
        quarantine.withCString({
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }) == 0,
        Darwin.fsync(directoryDescriptor) == 0
      else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
    }
  }

  func withExclusiveLock<Result: Sendable>(
    named lockName: String,
    _ operation: @Sendable () async throws -> Result
  ) async throws -> Result {
    try Self.requireFileName(lockName)
    let descriptor = try withRootDescriptor { rootDescriptor in
      let descriptor = lockName.withCString {
        Darwin.openat(
          rootDescriptor,
          $0,
          O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC,
          mode_t(S_IRUSR | S_IWUSR)
        )
      }
      var metadata = stat()
      guard
        descriptor >= 0,
        fstat(descriptor, &metadata) == 0,
        Self.isPrivateRegularFile(metadata),
        webAPIReverseFlock(descriptor, LOCK_EX) == 0
      else {
        if descriptor >= 0 { _ = Darwin.close(descriptor) }
        throw PrivateArtifactStoreError.writeFailed(lockName)
      }
      return descriptor
    }
    defer {
      _ = webAPIReverseFlock(descriptor, LOCK_UN)
      _ = Darwin.close(descriptor)
    }
    return try await operation()
  }

  func removeDirectory(named directoryName: String) throws {
    try Self.requireFileName(directoryName)
    try withRootDescriptor { rootDescriptor in
      var metadata = stat()
      let status = directoryName.withCString {
        Darwin.fstatat(
          rootDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }
      if status != 0, errno == ENOENT { return }
      guard status == 0, metadata.st_mode & S_IFMT == S_IFDIR else {
        throw PrivateArtifactStoreError.unsafeDirectory(directoryName)
      }
      let descriptor = directoryName.withCString {
        Darwin.openat(
          rootDescriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      guard descriptor >= 0 else {
        throw PrivateArtifactStoreError.unsafeDirectory(directoryName)
      }
      do {
        try Self.removeContents(of: descriptor)
        _ = Darwin.close(descriptor)
      } catch {
        _ = Darwin.close(descriptor)
        throw error
      }
      var finalMetadata = stat()
      guard
        directoryName.withCString({
          Darwin.fstatat(
            rootDescriptor,
            $0,
            &finalMetadata,
            AT_SYMLINK_NOFOLLOW
          )
        }) == 0,
        finalMetadata.st_dev == metadata.st_dev,
        finalMetadata.st_ino == metadata.st_ino,
        directoryName.withCString({
          Darwin.unlinkat(rootDescriptor, $0, AT_REMOVEDIR)
        }) == 0,
        Darwin.fsync(rootDescriptor) == 0
      else {
        throw PrivateArtifactStoreError.unsafeDirectory(directoryName)
      }
    }
  }

  public func removeRoot() throws {
    let parent = privateRoot.deletingLastPathComponent()
    let leaf = privateRoot.lastPathComponent
    try Self.requireFileName(leaf)
    let parentDescriptor = Self.openDirectory(parent)
    var parentMetadata = stat()
    guard
      parentDescriptor >= 0,
      fstat(parentDescriptor, &parentMetadata) == 0,
      parentMetadata.st_dev == parentDevice,
      parentMetadata.st_ino == parentInode
    else {
      if parentDescriptor >= 0 { _ = Darwin.close(parentDescriptor) }
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    defer { _ = Darwin.close(parentDescriptor) }
    var rootMetadata = stat()
    guard
      leaf.withCString({
        Darwin.fstatat(
          parentDescriptor,
          $0,
          &rootMetadata,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0,
      rootMetadata.st_mode & S_IFMT == S_IFDIR,
      rootMetadata.st_dev == rootDevice,
      rootMetadata.st_ino == rootInode
    else {
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    try removalFaultInjector(.beforeQuarantineRename)
    let quarantine = ".web-api-reverse-remove-\(UUID().uuidString.lowercased())"
    let renameStatus = leaf.withCString { leafPointer in
      quarantine.withCString { quarantinePointer in
        Darwin.renameatx_np(
          parentDescriptor,
          leafPointer,
          parentDescriptor,
          quarantinePointer,
          UInt32(RENAME_EXCL)
        )
      }
    }
    guard renameStatus == 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    var quarantinedMetadata = stat()
    let quarantinedIsBoundRoot = quarantine.withCString {
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &quarantinedMetadata,
        AT_SYMLINK_NOFOLLOW
      )
    } == 0
      && quarantinedMetadata.st_mode & S_IFMT == S_IFDIR
      && quarantinedMetadata.st_dev == rootDevice
      && quarantinedMetadata.st_ino == rootInode
    guard quarantinedIsBoundRoot else {
      _ = quarantine.withCString { quarantinePointer in
        leaf.withCString { leafPointer in
          Darwin.renameatx_np(
            parentDescriptor,
            quarantinePointer,
            parentDescriptor,
            leafPointer,
            UInt32(RENAME_EXCL)
          )
        }
      }
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    let rootDescriptor = quarantine.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard rootDescriptor >= 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    defer { _ = Darwin.close(rootDescriptor) }
    try Self.removeContents(of: rootDescriptor)
    guard quarantine.withCString({
      Darwin.unlinkat(parentDescriptor, $0, AT_REMOVEDIR)
    }) == 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    _ = Darwin.fsync(parentDescriptor)
  }

  private func withLockedCopyDirectories<Result>(
    source: PrivateArtifactStore,
    fileName: String,
    operation: (Int32, Int32, Bool) throws -> Result
  ) throws -> Result {
    let sameRoot =
      source.rootDevice == rootDevice && source.rootInode == rootInode
    if sameRoot {
      return try withRootDescriptor { directoryDescriptor in
        guard webAPIReverseFlock(directoryDescriptor, LOCK_EX) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        defer { _ = webAPIReverseFlock(directoryDescriptor, LOCK_UN) }
        try recoverReplacementIfNeeded(
          fileName: fileName,
          directoryDescriptor: directoryDescriptor
        )
        return try operation(
          directoryDescriptor,
          directoryDescriptor,
          true
        )
      }
    }

    if source.canonicalRootPath < canonicalRootPath {
      return try source.withRootDescriptor { sourceDirectory in
        guard webAPIReverseFlock(sourceDirectory, LOCK_EX) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        defer { _ = webAPIReverseFlock(sourceDirectory, LOCK_UN) }
        try source.recoverReplacementIfNeeded(
          fileName: fileName,
          directoryDescriptor: sourceDirectory
        )
        return try withRootDescriptor { destinationDirectory in
          guard webAPIReverseFlock(destinationDirectory, LOCK_EX) == 0 else {
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          defer { _ = webAPIReverseFlock(destinationDirectory, LOCK_UN) }
          try recoverReplacementIfNeeded(
            fileName: fileName,
            directoryDescriptor: destinationDirectory
          )
          return try operation(sourceDirectory, destinationDirectory, false)
        }
      }
    }

    return try withRootDescriptor { destinationDirectory in
      guard webAPIReverseFlock(destinationDirectory, LOCK_EX) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      defer { _ = webAPIReverseFlock(destinationDirectory, LOCK_UN) }
      try recoverReplacementIfNeeded(
        fileName: fileName,
        directoryDescriptor: destinationDirectory
      )
      return try source.withRootDescriptor { sourceDirectory in
        guard webAPIReverseFlock(sourceDirectory, LOCK_EX) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        defer { _ = webAPIReverseFlock(sourceDirectory, LOCK_UN) }
        try source.recoverReplacementIfNeeded(
          fileName: fileName,
          directoryDescriptor: sourceDirectory
        )
        return try operation(sourceDirectory, destinationDirectory, false)
      }
    }
  }

  private func recoverReplacementIfNeeded(
    fileName: String,
    directoryDescriptor: Int32
  ) throws {
    let journalName = Self.replacementJournalName(for: fileName)
    var journalMetadata = stat()
    let status = journalName.withCString {
      Darwin.fstatat(
        directoryDescriptor,
        $0,
        &journalMetadata,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if status != 0, errno == ENOENT { return }
    guard
      status == 0,
      Self.isPrivateRegularFile(journalMetadata),
      journalMetadata.st_size >= 0,
      journalMetadata.st_size <= 16 * 1_024
    else {
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    let journalDescriptor = journalName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard journalDescriptor >= 0 else {
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    defer { _ = Darwin.close(journalDescriptor) }
    let journal: PrivateArtifactReplacementJournal
    do {
      journal = try DeterministicJSON.decode(
        PrivateArtifactReplacementJournal.self,
        from: Self.readAll(
          from: journalDescriptor,
          byteCount: Int(journalMetadata.st_size),
          fileName: journalName
        )
      )
    } catch {
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    let phase =
      journal.schemaVersion == 1 && journal.phase == nil
      ? "staged" : journal.phase
    guard
      ((journal.schemaVersion == 1 && journal.phase == nil)
        || (journal.schemaVersion == 2
          && (phase == "staged" || phase == "committed"))),
      journal.kind == "web-api-reverse.private-artifact-replacement",
      journal.fileName == fileName,
      !journal.temporaryName.isEmpty,
      !journal.temporaryName.contains("/")
    else {
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    let current = try Self.regularFileIdentity(
      named: fileName,
      under: directoryDescriptor,
      errorName: fileName
    )
    let temporary = try Self.regularFileIdentity(
      named: journal.temporaryName,
      under: directoryDescriptor,
      errorName: fileName
    )
    let currentIsOld = Self.identity(
      current,
      matchesDevice: journal.oldDevice,
      inode: journal.oldInode
    )
    let currentIsNew = Self.identity(
      current,
      matchesDevice: journal.newDevice,
      inode: journal.newInode
    )
    let temporaryIsOld = Self.identity(
      temporary,
      matchesDevice: journal.oldDevice,
      inode: journal.oldInode
    )
    let temporaryIsNew = Self.identity(
      temporary,
      matchesDevice: journal.newDevice,
      inode: journal.newInode
    )
    if phase == "committed" {
      if currentIsNew, temporaryIsOld {
        guard journal.temporaryName.withCString({
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }) == 0, Darwin.fsync(directoryDescriptor) == 0 else {
          throw PrivateArtifactStoreError.cleanupIncomplete(fileName)
        }
        try removeReplacementJournal(
          fileName: fileName,
          directoryDescriptor: directoryDescriptor
        )
        return
      }
      if currentIsNew, temporary == nil {
        try removeReplacementJournal(
          fileName: fileName,
          directoryDescriptor: directoryDescriptor
        )
        return
      }
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    if currentIsOld, temporaryIsNew {
      guard journal.temporaryName.withCString({
        Darwin.unlinkat(directoryDescriptor, $0, 0)
      }) == 0, Darwin.fsync(directoryDescriptor) == 0 else {
        throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
      }
      try removeReplacementJournal(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      return
    }
    if currentIsOld, temporary == nil {
      try removeReplacementJournal(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      return
    }
    if currentIsNew, temporaryIsOld {
      let rollbackStatus = journal.temporaryName.withCString {
        temporaryPointer in
        fileName.withCString { filePointer in
          Darwin.renameatx_np(
            directoryDescriptor,
            temporaryPointer,
            directoryDescriptor,
            filePointer,
            UInt32(RENAME_SWAP)
          )
        }
      }
      guard
        rollbackStatus == 0,
        Darwin.fsync(directoryDescriptor) == 0,
        journal.temporaryName.withCString({
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }) == 0,
        Darwin.fsync(directoryDescriptor) == 0
      else {
        throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
      }
      try removeReplacementJournal(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      return
    }
    if currentIsNew, temporary == nil {
      try removeReplacementJournal(
        fileName: fileName,
        directoryDescriptor: directoryDescriptor
      )
      return
    }
    throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
  }

  private func writeReplacementJournal(
    _ journal: PrivateArtifactReplacementJournal,
    fileName: String,
    directoryDescriptor: Int32
  ) throws {
    let journalName = Self.replacementJournalName(for: fileName)
    let data = try DeterministicJSON.encode(journal)
    guard data.count <= 16 * 1_024 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    let descriptor = journalName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
    }
    defer { _ = Darwin.close(descriptor) }
    do {
      try Self.writeAll(data, to: descriptor, fileName: journalName)
      guard
        Darwin.fsync(descriptor) == 0,
        Darwin.fsync(directoryDescriptor) == 0
      else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
    } catch {
      _ = journalName.withCString {
        Darwin.unlinkat(directoryDescriptor, $0, 0)
      }
      _ = Darwin.fsync(directoryDescriptor)
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
  }

  private func markReplacementCommitted(
    _ journal: PrivateArtifactReplacementJournal,
    fileName: String,
    directoryDescriptor: Int32
  ) throws {
    let journalName = Self.replacementJournalName(for: fileName)
    let temporaryName =
      journalName + ".committed-" + UUID().uuidString.lowercased()
    let data = try DeterministicJSON.encode(journal.committed())
    guard data.count <= 16 * 1_024 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    let descriptor = temporaryName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    var removeTemporary = true
    defer {
      _ = Darwin.close(descriptor)
      if removeTemporary {
        _ = temporaryName.withCString {
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }
      }
    }
    try Self.writeAll(data, to: descriptor, fileName: temporaryName)
    guard Darwin.fsync(descriptor) == 0 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    let swapStatus = temporaryName.withCString { temporaryPointer in
      journalName.withCString { journalPointer in
        Darwin.renameatx_np(
          directoryDescriptor,
          temporaryPointer,
          directoryDescriptor,
          journalPointer,
          UInt32(RENAME_SWAP)
        )
      }
    }
    guard swapStatus == 0 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    removeTemporary = false
    guard Darwin.fsync(directoryDescriptor) == 0 else {
      let rollbackStatus = temporaryName.withCString { temporaryPointer in
        journalName.withCString { journalPointer in
          Darwin.renameatx_np(
            directoryDescriptor,
            temporaryPointer,
            directoryDescriptor,
            journalPointer,
            UInt32(RENAME_SWAP)
          )
        }
      }
      guard rollbackStatus == 0, Darwin.fsync(directoryDescriptor) == 0 else {
        throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
      }
      removeTemporary = true
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    _ = temporaryName.withCString {
      Darwin.unlinkat(directoryDescriptor, $0, 0)
    }
    _ = Darwin.fsync(directoryDescriptor)
  }

  private func removeReplacementJournal(
    fileName: String,
    directoryDescriptor: Int32
  ) throws {
    let journalName = Self.replacementJournalName(for: fileName)
    let status = journalName.withCString {
      Darwin.unlinkat(directoryDescriptor, $0, 0)
    }
    guard
      status == 0 || errno == ENOENT,
      Darwin.fsync(directoryDescriptor) == 0
    else {
      throw PrivateArtifactStoreError.cleanupIncomplete(fileName)
    }
  }

  private static func replacementJournalName(for fileName: String) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in fileName.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return ".web-api-reverse-transaction-"
      + String(hash, radix: 16)
      + ".json"
  }

  private static func regularFileIdentity(
    named name: String,
    under directoryDescriptor: Int32,
    errorName: String
  ) throws -> (device: UInt64, inode: UInt64)? {
    var metadata = stat()
    let status = name.withCString {
      Darwin.fstatat(
        directoryDescriptor,
        $0,
        &metadata,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if status != 0, errno == ENOENT { return nil }
    guard status == 0, Self.isPrivateRegularFile(metadata) else {
      throw PrivateArtifactStoreError.transactionIndeterminate(errorName)
    }
    return (UInt64(metadata.st_dev), UInt64(metadata.st_ino))
  }

  private static func identity(
    _ identity: (device: UInt64, inode: UInt64)?,
    matchesDevice device: UInt64,
    inode: UInt64
  ) -> Bool {
    identity?.device == device && identity?.inode == inode
  }

  private func installPrivateFile(
    named fileName: String,
    directoryDescriptor: Int32,
    populate: (Int32) throws -> Void
  ) throws {
    try Self.requireFileName(fileName)
    var existing = stat()
    let existingStatus = fileName.withCString {
      Darwin.fstatat(
        directoryDescriptor,
        $0,
        &existing,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if existingStatus == 0 {
      guard Self.isPrivateRegularFile(existing) else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
    } else if errno != ENOENT {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }

    let temporaryName =
      ".web-api-reverse-\(ProcessInfo.processInfo.processIdentifier)-"
      + UUID().uuidString.lowercased()
    let descriptor = temporaryName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
    var removeTemporary = true
    defer {
      _ = Darwin.close(descriptor)
      if removeTemporary {
        _ = temporaryName.withCString {
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }
      }
    }
    do {
      try populate(descriptor)
      guard Darwin.fsync(descriptor) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      try faultInjector(.beforeAtomicReplacement)
      var candidate = stat()
      guard fstat(descriptor, &candidate) == 0 else {
        throw PrivateArtifactStoreError.writeFailed(fileName)
      }
      if existingStatus == 0 {
        let journal = PrivateArtifactReplacementJournal(
          fileName: fileName,
          temporaryName: temporaryName,
          old: existing,
          new: candidate
        )
        try writeReplacementJournal(
          journal,
          fileName: fileName,
          directoryDescriptor: directoryDescriptor
        )
        let status = temporaryName.withCString { temporaryPointer in
          fileName.withCString { filePointer in
            Darwin.renameatx_np(
              directoryDescriptor,
              temporaryPointer,
              directoryDescriptor,
              filePointer,
              UInt32(RENAME_SWAP)
            )
          }
        }
        guard status == 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        removeTemporary = false
        do {
          var replaced = stat()
          let replacedStatus = temporaryName.withCString {
            Darwin.fstatat(
              directoryDescriptor,
              $0,
              &replaced,
              AT_SYMLINK_NOFOLLOW
            )
          }
          guard
            replacedStatus == 0,
            replaced.st_dev == existing.st_dev,
            replaced.st_ino == existing.st_ino
          else {
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          try faultInjector(.afterAtomicReplacement)
          guard Self.identity(
            try Self.regularFileIdentity(
              named: fileName,
              under: directoryDescriptor,
              errorName: fileName
            ),
            matchesDevice: journal.newDevice,
            inode: journal.newInode
          ) else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
          guard Darwin.fsync(directoryDescriptor) == 0 else {
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          try faultInjector(.afterDirectorySync)
          try verifyRootIdentity()
          guard Self.identity(
            try Self.regularFileIdentity(
              named: fileName,
              under: directoryDescriptor,
              errorName: fileName
            ),
            matchesDevice: journal.newDevice,
            inode: journal.newInode
          ) else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
          try markReplacementCommitted(
            journal,
            fileName: fileName,
            directoryDescriptor: directoryDescriptor
          )
        } catch PrivateArtifactStoreError.transactionIndeterminate {
          throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
        } catch {
          guard
            Self.identity(
              try Self.regularFileIdentity(
                named: fileName,
                under: directoryDescriptor,
                errorName: fileName
              ),
              matchesDevice: journal.newDevice,
              inode: journal.newInode
            ),
            Self.identity(
              try Self.regularFileIdentity(
                named: temporaryName,
                under: directoryDescriptor,
                errorName: fileName
              ),
              matchesDevice: journal.oldDevice,
              inode: journal.oldInode
            )
          else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
          do {
            try faultInjector(.beforeRollbackSwap)
          } catch {
            throw PrivateArtifactStoreError.transactionIndeterminate(
              fileName
            )
          }
          let rollbackStatus = temporaryName.withCString { temporaryPointer in
            fileName.withCString { filePointer in
              Darwin.renameatx_np(
                directoryDescriptor,
                temporaryPointer,
                directoryDescriptor,
                filePointer,
                UInt32(RENAME_SWAP)
              )
            }
          }
          guard
            rollbackStatus == 0,
            Darwin.fsync(directoryDescriptor) == 0
          else {
            throw PrivateArtifactStoreError.transactionIndeterminate(
              fileName
            )
          }
          guard
            Self.identity(
              try Self.regularFileIdentity(
                named: fileName,
                under: directoryDescriptor,
                errorName: fileName
              ),
              matchesDevice: journal.oldDevice,
              inode: journal.oldInode
            ),
            Self.identity(
              try Self.regularFileIdentity(
                named: temporaryName,
                under: directoryDescriptor,
                errorName: fileName
              ),
              matchesDevice: journal.newDevice,
              inode: journal.newInode
            )
          else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
          guard temporaryName.withCString({
            Darwin.unlinkat(directoryDescriptor, $0, 0)
          }) == 0, Darwin.fsync(directoryDescriptor) == 0 else {
            throw PrivateArtifactStoreError.cleanupIncomplete(fileName)
          }
          try? removeReplacementJournal(
            fileName: fileName,
            directoryDescriptor: directoryDescriptor
          )
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        var oldGenerationWasSynced = false
        do {
          try faultInjector(.beforeCommittedCleanup)
          if temporaryName.withCString({
            Darwin.unlinkat(directoryDescriptor, $0, 0)
          }) == 0 {
            try faultInjector(.afterOldGenerationUnlinked)
            oldGenerationWasSynced = Darwin.fsync(directoryDescriptor) == 0
          }
        } catch {}
        guard Self.identity(
          try Self.regularFileIdentity(
            named: fileName,
            under: directoryDescriptor,
            errorName: fileName
          ),
          matchesDevice: journal.newDevice,
          inode: journal.newInode
        ) else {
          throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
        }
        if oldGenerationWasSynced {
          try? removeReplacementJournal(
            fileName: fileName,
            directoryDescriptor: directoryDescriptor
          )
        }
        try verifyRootIdentity()
        guard Self.identity(
          try Self.regularFileIdentity(
            named: fileName,
            under: directoryDescriptor,
            errorName: fileName
          ),
          matchesDevice: journal.newDevice,
          inode: journal.newInode
        ) else {
          throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
        }
      } else {
        let status = temporaryName.withCString { temporaryPointer in
          fileName.withCString { filePointer in
            Darwin.renameatx_np(
              directoryDescriptor,
              temporaryPointer,
              directoryDescriptor,
              filePointer,
              UInt32(RENAME_EXCL)
            )
          }
        }
        guard status == 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        removeTemporary = false
        do {
          try faultInjector(.afterAtomicReplacement)
          guard Self.identity(
            try Self.regularFileIdentity(
              named: fileName,
              under: directoryDescriptor,
              errorName: fileName
            ),
            matchesDevice: UInt64(candidate.st_dev),
            inode: UInt64(candidate.st_ino)
          ) else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
          guard Darwin.fsync(directoryDescriptor) == 0 else {
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          try faultInjector(.afterDirectorySync)
          try verifyRootIdentity()
          guard Self.identity(
            try Self.regularFileIdentity(
              named: fileName,
              under: directoryDescriptor,
              errorName: fileName
            ),
            matchesDevice: UInt64(candidate.st_dev),
            inode: UInt64(candidate.st_ino)
          ) else {
            throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
          }
        } catch PrivateArtifactStoreError.transactionIndeterminate {
          throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
        } catch {
          if Self.identity(
            try? Self.regularFileIdentity(
              named: fileName,
              under: directoryDescriptor,
              errorName: fileName
            ),
            matchesDevice: UInt64(candidate.st_dev),
            inode: UInt64(candidate.st_ino)
          ) {
            _ = fileName.withCString {
              Darwin.unlinkat(directoryDescriptor, $0, 0)
            }
            _ = Darwin.fsync(directoryDescriptor)
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          throw PrivateArtifactStoreError.transactionIndeterminate(fileName)
        }
      }
    } catch let error as PrivateArtifactStoreError {
      throw error
    } catch {
      throw PrivateArtifactStoreError.writeFailed(fileName)
    }
  }

  func withRootDescriptor<Result>(
    _ operation: (Int32) throws -> Result
  ) throws -> Result {
    let descriptor = Self.openDirectory(privateRoot)
    var metadata = stat()
    guard
      descriptor >= 0,
      fstat(descriptor, &metadata) == 0,
      Self.securePrivateDirectory(descriptor, metadata: &metadata),
      metadata.st_dev == rootDevice,
      metadata.st_ino == rootInode,
      (try? Self.canonicalPath(privateRoot)) == canonicalRootPath
    else {
      if descriptor >= 0 { _ = Darwin.close(descriptor) }
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    defer { _ = Darwin.close(descriptor) }
    let result = try operation(descriptor)
    try verifyRootIdentity()
    return result
  }

  private func verifyRootIdentity() throws {
    let descriptor = Self.openDirectory(privateRoot)
    var metadata = stat()
    guard
      descriptor >= 0,
      fstat(descriptor, &metadata) == 0,
      metadata.st_dev == rootDevice,
      metadata.st_ino == rootInode,
      (try? Self.canonicalPath(privateRoot)) == canonicalRootPath
    else {
      if descriptor >= 0 { _ = Darwin.close(descriptor) }
      throw PrivateArtifactStoreError.unsafeDirectory(canonicalRootPath)
    }
    _ = Darwin.close(descriptor)
  }

  private static func requireFileName(_ fileName: String) throws {
    guard
      !fileName.isEmpty,
      fileName != ".",
      fileName != "..",
      !fileName.contains("/"),
      !fileName.contains("\0")
    else {
      throw PrivateArtifactStoreError.invalidFileName(fileName)
    }
  }

  private static func resolvedDirectoryPath(for url: URL) throws -> String {
    var candidate = url
    var missing: [String] = []
    while true {
      let descriptor = openDirectory(candidate)
      if descriptor >= 0 {
        _ = Darwin.close(descriptor)
        var resolved = URL(
          fileURLWithPath: try canonicalPath(candidate),
          isDirectory: true
        )
        for component in missing.reversed() {
          resolved.append(path: component, directoryHint: .isDirectory)
        }
        return resolved.path
      }
      guard errno == ENOENT else {
        throw PrivateArtifactStoreError.invalidPrivateRoot(url.path)
      }
      let parent = candidate.deletingLastPathComponent()
      guard parent.path != candidate.path else {
        throw PrivateArtifactStoreError.invalidPrivateRoot(url.path)
      }
      missing.append(candidate.lastPathComponent)
      candidate = parent
    }
  }

  private static func createDirectoryTree(at url: URL) throws {
    let components = NSString(string: url.path).pathComponents
      .filter { $0 != "/" }
    var descriptor = Darwin.open(
      "/",
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory(url.path)
    }
    defer { _ = Darwin.close(descriptor) }
    for component in components {
      var next = component.withCString {
        Darwin.openat(
          descriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      if next < 0, errno == ENOENT {
        let status = component.withCString {
          Darwin.mkdirat(descriptor, $0, mode_t(S_IRWXU))
        }
        guard status == 0 || errno == EEXIST else {
          throw PrivateArtifactStoreError.unsafeDirectory(url.path)
        }
        next = component.withCString {
          Darwin.openat(
            descriptor,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
      }
      guard next >= 0 else {
        throw PrivateArtifactStoreError.unsafeDirectory(url.path)
      }
      _ = Darwin.close(descriptor)
      descriptor = next
    }
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

  private static func openPrivateFile(
    named fileName: String,
    under directoryDescriptor: Int32
  ) throws -> Int32 {
    try requireFileName(fileName)
    let descriptor = fileName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
      )
    }
    if descriptor < 0, errno == ENOENT {
      throw PrivateArtifactStoreError.missingFile(fileName)
    }
    guard descriptor >= 0 else {
      throw PrivateArtifactStoreError.unsafeFile(fileName)
    }
    return descriptor
  }

  private static func canonicalPath(_ url: URL) throws -> String {
    let pointer = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return UnsafeMutablePointer<CChar>?.none }
      return Darwin.realpath(path, nil)
    }
    guard let pointer else {
      throw PrivateArtifactStoreError.invalidPrivateRoot(url.path)
    }
    defer { Darwin.free(pointer) }
    return String(cString: pointer)
  }

  private static func isInsideReusableSource(_ path: String) -> Bool {
    let components = URL(fileURLWithPath: path).pathComponents
    if components.contains("API") { return true }
    var candidate = URL(fileURLWithPath: path, isDirectory: true)
    while true {
      let descriptor = openDirectory(candidate)
      if descriptor >= 0 {
        var metadata = stat()
        let hasPackageManifest =
          "Package.swift".withCString {
            Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
          } == 0 && metadata.st_mode & S_IFMT == S_IFREG
        let hasGitControlEntry =
          ".git".withCString {
            Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
          } == 0
        _ = Darwin.close(descriptor)
        if hasPackageManifest || hasGitControlEntry { return true }
      }
      let parent = candidate.deletingLastPathComponent()
      if parent.path == candidate.path { return false }
      candidate = parent
    }
  }

  private static func securePrivateDirectory(
    _ descriptor: Int32,
    metadata: inout stat
  ) -> Bool {
    guard
      metadata.st_mode & S_IFMT == S_IFDIR,
      metadata.st_uid == geteuid()
    else {
      return false
    }
    if metadata.st_mode & 0o077 != 0 {
      guard
        Darwin.fchmod(descriptor, mode_t(S_IRWXU)) == 0,
        fstat(descriptor, &metadata) == 0
      else {
        return false
      }
    }
    return metadata.st_mode & 0o077 == 0
  }

  private static func isPrivateRegularFile(_ metadata: stat) -> Bool {
    metadata.st_mode & S_IFMT == S_IFREG
      && metadata.st_uid == geteuid()
      && metadata.st_mode & 0o077 == 0
  }

  private static func readAll(
    from descriptor: Int32,
    byteCount: Int,
    fileName: String
  ) throws -> Data {
    var data = Data(count: byteCount)
    let bytesRead = try data.withUnsafeMutableBytes { bytes -> Int in
      guard let base = bytes.baseAddress else { return 0 }
      var offset = 0
      while offset < bytes.count {
        let count = Darwin.read(
          descriptor,
          base.advanced(by: offset),
          bytes.count - offset
        )
        if count < 0, errno == EINTR { continue }
        guard count > 0 else {
          throw PrivateArtifactStoreError.unsafeFile(fileName)
        }
        offset += count
      }
      return offset
    }
    guard bytesRead == byteCount else {
      throw PrivateArtifactStoreError.unsafeFile(fileName)
    }
    var sentinel: UInt8 = 0
    var sentinelCount: Int
    repeat {
      sentinelCount = Darwin.read(descriptor, &sentinel, 1)
    } while sentinelCount < 0 && errno == EINTR
    guard sentinelCount == 0 else {
      throw PrivateArtifactStoreError.unsafeFile(fileName)
    }
    return data
  }

  private static func writeAll(
    _ data: Data,
    to descriptor: Int32,
    fileName: String
  ) throws {
    try data.withUnsafeBytes { bytes in
      guard let base = bytes.baseAddress else { return }
      var offset = 0
      while offset < bytes.count {
        let count = Darwin.write(
          descriptor,
          base.advanced(by: offset),
          bytes.count - offset
        )
        if count < 0, errno == EINTR { continue }
        guard count > 0 else {
          throw PrivateArtifactStoreError.writeFailed(fileName)
        }
        offset += count
      }
    }
  }

  private static func copyAll(
    from source: Int32,
    to destination: Int32,
    expectedBytes: Int,
    fileName: String
  ) throws {
    var copied = 0
    var buffer = [UInt8](repeating: 0, count: 64 * 1024)
    while copied < expectedBytes {
      let count = Darwin.read(
        source,
        &buffer,
        min(buffer.count, expectedBytes - copied)
      )
      if count < 0, errno == EINTR { continue }
      guard count > 0 else {
        throw PrivateArtifactStoreError.unsafeFile(fileName)
      }
      try buffer.withUnsafeBytes { bytes in
        guard let base = bytes.baseAddress else { return }
        var offset = 0
        while offset < count {
          let written = Darwin.write(
            destination,
            base.advanced(by: offset),
            count - offset
          )
          if written < 0, errno == EINTR { continue }
          guard written > 0 else {
            throw PrivateArtifactStoreError.writeFailed(fileName)
          }
          offset += written
        }
      }
      copied += count
    }
    var sentinel: UInt8 = 0
    var sentinelCount: Int
    repeat {
      sentinelCount = Darwin.read(source, &sentinel, 1)
    } while sentinelCount < 0 && errno == EINTR
    guard sentinelCount == 0 else {
      throw PrivateArtifactStoreError.unsafeFile(fileName)
    }
  }

  private static func requireUnchangedFile(
    named fileName: String,
    initial: stat,
    descriptor: Int32,
    directoryDescriptor: Int32
  ) throws {
    var finalDescriptorMetadata = stat()
    var finalPathMetadata = stat()
    guard
      fstat(descriptor, &finalDescriptorMetadata) == 0,
      fileName.withCString({
        Darwin.fstatat(
          directoryDescriptor,
          $0,
          &finalPathMetadata,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0,
      sameFileVersion(initial, finalDescriptorMetadata),
      sameFileVersion(initial, finalPathMetadata)
    else {
      throw PrivateArtifactStoreError.unsafeFile(fileName)
    }
  }

  private static func sameFileVersion(_ lhs: stat, _ rhs: stat) -> Bool {
    lhs.st_dev == rhs.st_dev
      && lhs.st_ino == rhs.st_ino
      && lhs.st_size == rhs.st_size
      && lhs.st_mtimespec.tv_sec == rhs.st_mtimespec.tv_sec
      && lhs.st_mtimespec.tv_nsec == rhs.st_mtimespec.tv_nsec
      && lhs.st_ctimespec.tv_sec == rhs.st_ctimespec.tv_sec
      && lhs.st_ctimespec.tv_nsec == rhs.st_ctimespec.tv_nsec
  }

  private static func removeContents(of directoryDescriptor: Int32) throws {
    let duplicate = Darwin.dup(directoryDescriptor)
    guard duplicate >= 0, let stream = Darwin.fdopendir(duplicate) else {
      if duplicate >= 0 { _ = Darwin.close(duplicate) }
      throw PrivateArtifactStoreError.unsafeDirectory("temporary-root")
    }
    defer { _ = Darwin.closedir(stream) }
    while let entry = Darwin.readdir(stream) {
      let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
        pointer.withMemoryRebound(
          to: CChar.self,
          capacity: Int(MAXNAMLEN) + 1
        ) {
          String(cString: $0)
        }
      }
      if name == "." || name == ".." { continue }
      var metadata = stat()
      guard name.withCString({
        Darwin.fstatat(
          directoryDescriptor,
          $0,
          &metadata,
          AT_SYMLINK_NOFOLLOW
        )
      }) == 0 else {
        throw PrivateArtifactStoreError.unsafeFile(name)
      }
      if metadata.st_mode & S_IFMT == S_IFDIR {
        let child = name.withCString {
          Darwin.openat(
            directoryDescriptor,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard child >= 0 else {
          throw PrivateArtifactStoreError.unsafeDirectory(name)
        }
        do {
          try removeContents(of: child)
          _ = Darwin.close(child)
        } catch {
          _ = Darwin.close(child)
          throw error
        }
        guard name.withCString({
          Darwin.unlinkat(directoryDescriptor, $0, AT_REMOVEDIR)
        }) == 0 else {
          throw PrivateArtifactStoreError.unsafeDirectory(name)
        }
      } else {
        guard name.withCString({
          Darwin.unlinkat(directoryDescriptor, $0, 0)
        }) == 0 else {
          throw PrivateArtifactStoreError.unsafeFile(name)
        }
      }
    }
    guard Darwin.fsync(directoryDescriptor) == 0 else {
      throw PrivateArtifactStoreError.unsafeDirectory("temporary-root")
    }
  }
}
