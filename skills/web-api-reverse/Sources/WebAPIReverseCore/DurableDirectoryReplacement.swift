import Darwin
import Foundation

@_silgen_name("flock")
private func durableDirectoryFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

enum DurableDirectoryReplacementInterruptionPoint: Equatable, Sendable {
  case afterReadyJournal
  case afterDirectorySwap
  case afterCommittedJournal
}

enum DurableDirectoryReplacementTestPoint: Equatable, Sendable {
  case afterParentLock
  case beforeCommit
  case beforeSuccess
}

enum DurableDirectoryReplacementError: Error, Equatable, Sendable {
  case invalidParent(String)
  case invalidName(String)
  case transactionIndeterminate(String)
}

/// Descriptor-bound, journaled replacement for one generated directory.
struct DurableDirectoryReplacement: Sendable {
  private static let maximumJournalBytes = 64 * 1_024
  private static let maximumFileBytes = 64 * 1_024 * 1_024
  private static let maximumTreeBytes = 256 * 1_024 * 1_024
  private static let maximumEntries = 4_096
  private static let maximumDepth = 16

  private enum Phase: String, Codable, Sendable {
    case ready
    case committed
  }

  private struct DirectoryIdentity: Codable, Equatable, Sendable {
    let device: UInt64
    let inode: UInt64

    init(_ metadata: stat) {
      device = UInt64(metadata.st_dev)
      inode = UInt64(metadata.st_ino)
    }

    func matches(_ metadata: stat) -> Bool {
      device == UInt64(metadata.st_dev) && inode == UInt64(metadata.st_ino)
    }
  }

  private struct Journal: Codable, Sendable {
    let schemaVersion: Int
    let kind: String
    let destinationName: String
    let phase: Phase
    let originalIdentity: DirectoryIdentity?
    let stagedIdentity: DirectoryIdentity
    let files: [String: String]

    init(
      destinationName: String,
      phase: Phase,
      originalIdentity: DirectoryIdentity?,
      stagedIdentity: DirectoryIdentity,
      files: [String: String]
    ) {
      schemaVersion = 1
      kind = "web-api-reverse.directory-replacement"
      self.destinationName = destinationName
      self.phase = phase
      self.originalIdentity = originalIdentity
      self.stagedIdentity = stagedIdentity
      self.files = files
    }

    func updating(phase: Phase) -> Self {
      Self(
        destinationName: destinationName,
        phase: phase,
        originalIdentity: originalIdentity,
        stagedIdentity: stagedIdentity,
        files: files
      )
    }
  }

  let destinationURL: URL

  private let parentURL: URL
  private let destinationName: String
  private let stagingName: String
  private let journalName: String
  private let parentDevice: dev_t
  private let parentInode: ino_t
  private let interruptionPoint:
    DurableDirectoryReplacementInterruptionPoint?
  private let testHook:
    (@Sendable (DurableDirectoryReplacementTestPoint) throws -> Void)?

  init(
    destination: URL,
    interruptionPoint: DurableDirectoryReplacementInterruptionPoint? = nil,
    testHook: (
      @Sendable (DurableDirectoryReplacementTestPoint) throws -> Void
    )? = nil
  ) throws {
    let standardized = destination.standardizedFileURL
    let name = standardized.lastPathComponent
    guard Self.validName(name) else {
      throw DurableDirectoryReplacementError.invalidName(name)
    }
    let declaredParent = standardized.deletingLastPathComponent()
    let pointer = declaredParent.withUnsafeFileSystemRepresentation { path in
      guard let path else { return UnsafeMutablePointer<CChar>?.none }
      return Darwin.realpath(path, nil)
    }
    guard let pointer else {
      throw DurableDirectoryReplacementError.invalidParent(
        declaredParent.path
      )
    }
    defer { Darwin.free(pointer) }
    let canonicalParent = URL(
      fileURLWithPath: String(cString: pointer),
      isDirectory: true
    )
    let descriptor = Self.openDirectory(canonicalParent)
    var metadata = stat()
    guard
      descriptor >= 0,
      fstat(descriptor, &metadata) == 0,
      Self.isOwnedDirectory(metadata)
    else {
      if descriptor >= 0 { _ = Darwin.close(descriptor) }
      throw DurableDirectoryReplacementError.invalidParent(
        canonicalParent.path
      )
    }
    _ = Darwin.close(descriptor)

    parentURL = canonicalParent
    destinationName = name
    stagingName = ".\(name).next"
    journalName = ".\(name).transaction.json"
    destinationURL = canonicalParent.appending(
      path: name,
      directoryHint: .isDirectory
    )
    parentDevice = metadata.st_dev
    parentInode = metadata.st_ino
    self.interruptionPoint = interruptionPoint
    self.testHook = testHook
  }

  func replace(
    payloads: [String: Data],
    validateFindings: ([ArtifactFinding]) throws -> Void
  ) throws {
    _ = try replace(
      preparing: { _ in (payloads, ()) },
      validateFindings: validateFindings
    )
  }

  func replace<Result>(
    preparing: (Int32) throws -> (payloads: [String: Data], result: Result),
    validateFindings: ([ArtifactFinding]) throws -> Void
  ) throws -> Result {
    try withLockedParent { parentDescriptor in
      try recoverIfNeeded(under: parentDescriptor)
      let prepared = try preparing(parentDescriptor)
      let manifest = try makeManifest(prepared.payloads)
      try replaceLocked(
        payloads: prepared.payloads,
        manifest: manifest,
        parentDescriptor: parentDescriptor,
        validateFindings: validateFindings
      )
      return prepared.result
    }
  }

  private func replaceLocked(
    payloads: [String: Data],
    manifest: [String: String],
    parentDescriptor: Int32,
    validateFindings: ([ArtifactFinding]) throws -> Void
  ) throws {
    guard try directoryIdentity(
        named: stagingName,
        under: parentDescriptor
      ) == nil,
      stagingName.withCString({
        Darwin.mkdirat(parentDescriptor, $0, mode_t(S_IRWXU))
      }) == 0,
      Darwin.fsync(parentDescriptor) == 0
    else { throw indeterminate() }

    do {
      let stagedIdentity = try require(
        try directoryIdentity(
          named: stagingName,
          under: parentDescriptor
        )
      )
      let stagingDescriptor = try openDirectory(
        named: stagingName,
        expected: stagedIdentity,
        under: parentDescriptor
      )
      defer { _ = Darwin.close(stagingDescriptor) }
      try writePayloads(payloads, to: stagingDescriptor)
      let findings = try validateDirectory(
        descriptor: stagingDescriptor,
        expected: stagedIdentity,
        pathName: stagingName,
        manifest: manifest,
        parentDescriptor: parentDescriptor
      )
      try validateFindings(findings)

      let journal = Journal(
        destinationName: destinationName,
        phase: .ready,
        originalIdentity: try directoryIdentity(
          named: destinationName,
          under: parentDescriptor
        ),
        stagedIdentity: stagedIdentity,
        files: manifest
      )
      try saveJournal(journal, under: parentDescriptor)
      if interruptionPoint == .afterReadyJournal { throw indeterminate() }
      try commitReadyJournal(journal, under: parentDescriptor)
      if interruptionPoint == .afterDirectorySwap { throw indeterminate() }
      try saveJournal(
        journal.updating(phase: .committed),
        under: parentDescriptor
      )
      if interruptionPoint == .afterCommittedJournal {
        throw indeterminate()
      }
      try? finalizeCommitted(journal, under: parentDescriptor)
    } catch {
      let replacementError = error
      do {
        if try loadJournal(from: parentDescriptor) == nil,
          let staged = try directoryIdentity(
            named: stagingName,
            under: parentDescriptor
          )
        {
          try? removeDirectory(
            named: stagingName,
            expected: staged,
            under: parentDescriptor
          )
        }
      } catch {
        // A durable journal is the authority for resolving an interrupted
        // commit. If it cannot be read, leave every generation in place.
        throw error
      }
      throw replacementError
    }
  }

  private func recoverIfNeeded(under descriptor: Int32) throws {
    guard let journal = try loadJournal(from: descriptor) else {
      if let staged = try directoryIdentity(
        named: stagingName,
        under: descriptor
      ) {
        try removeDirectory(
          named: stagingName,
          expected: staged,
          under: descriptor
        )
      }
      return
    }
    guard journal.destinationName == destinationName else {
      throw indeterminate()
    }
    if journal.phase == .ready {
      try commitReadyJournal(journal, under: descriptor)
      try saveJournal(journal.updating(phase: .committed), under: descriptor)
    }
    try finalizeCommitted(journal, under: descriptor)
  }

  private func commitReadyJournal(
    _ journal: Journal,
    under descriptor: Int32
  ) throws {
    try testHook?(.beforeCommit)
    guard currentParentIdentityMatches() else {
      try abortUncommitted(journal, under: descriptor)
      throw indeterminate()
    }
    let destinationIdentity = try directoryIdentity(
      named: destinationName,
      under: descriptor
    )
    let stagedIdentity = try directoryIdentity(
      named: stagingName,
      under: descriptor
    )
    if let original = journal.originalIdentity {
      if destinationIdentity == original,
        stagedIdentity == journal.stagedIdentity
      {
        _ = try validateDirectory(
          named: stagingName,
          expected: journal.stagedIdentity,
          manifest: journal.files,
          under: descriptor
        )
        try swapDirectories(under: descriptor)
      } else {
        guard
          destinationIdentity == journal.stagedIdentity,
          stagedIdentity == original || stagedIdentity == nil
        else { throw indeterminate() }
      }
    } else if destinationIdentity == nil,
      stagedIdentity == journal.stagedIdentity
    {
      _ = try validateDirectory(
        named: stagingName,
        expected: journal.stagedIdentity,
        manifest: journal.files,
        under: descriptor
      )
      try installNewDirectory(under: descriptor)
    } else {
      guard
        destinationIdentity == journal.stagedIdentity,
        stagedIdentity == nil
      else { throw indeterminate() }
    }

    do {
      _ = try validateDirectory(
        named: destinationName,
        expected: journal.stagedIdentity,
        manifest: journal.files,
        under: descriptor
      )
    } catch {
      try rollback(journal, under: descriptor)
      throw error
    }
  }

  private func abortUncommitted(
    _ journal: Journal,
    under descriptor: Int32
  ) throws {
    guard
      try directoryIdentity(named: destinationName, under: descriptor)
        == journal.originalIdentity,
      try directoryIdentity(named: stagingName, under: descriptor)
        == journal.stagedIdentity
    else { throw indeterminate() }
    try removeDirectory(
      named: stagingName,
      expected: journal.stagedIdentity,
      under: descriptor
    )
    try removeJournal(under: descriptor)
  }

  private func rollback(_ journal: Journal, under descriptor: Int32) throws {
    if let original = journal.originalIdentity {
      guard try directoryIdentity(
        named: destinationName,
        under: descriptor
      ) == journal.stagedIdentity,
        try directoryIdentity(named: stagingName, under: descriptor) == original
      else { throw indeterminate() }
      try swapDirectories(under: descriptor)
      try removeDirectory(
        named: stagingName,
        expected: journal.stagedIdentity,
        under: descriptor
      )
    } else {
      guard try directoryIdentity(
        named: destinationName,
        under: descriptor
      ) == journal.stagedIdentity,
        destinationName.withCString({ destinationPointer in
          stagingName.withCString { stagingPointer in
            Darwin.renameatx_np(
              descriptor,
              destinationPointer,
              descriptor,
              stagingPointer,
              UInt32(RENAME_EXCL)
            )
          }
        }) == 0,
        Darwin.fsync(descriptor) == 0
      else { throw indeterminate() }
      try removeDirectory(
        named: stagingName,
        expected: journal.stagedIdentity,
        under: descriptor
      )
    }
    try removeJournal(under: descriptor)
  }

  private func finalizeCommitted(
    _ journal: Journal,
    under descriptor: Int32
  ) throws {
    guard try directoryIdentity(
      named: destinationName,
      under: descriptor
    ) == journal.stagedIdentity else { throw indeterminate() }
    if let displaced = try directoryIdentity(
      named: stagingName,
      under: descriptor
    ) {
      guard displaced == journal.originalIdentity else {
        throw indeterminate()
      }
      try removeDirectory(
        named: stagingName,
        expected: displaced,
        under: descriptor
      )
    }
    try removeJournal(under: descriptor)
  }

  private func writePayloads(
    _ payloads: [String: Data],
    to rootDescriptor: Int32
  ) throws {
    for relativePath in payloads.keys.sorted() {
      guard let data = payloads[relativePath] else { throw indeterminate() }
      let components = try pathComponents(relativePath)
      let fileName = try require(components.last)
      try withDirectory(
        components: Array(components.dropLast()),
        from: rootDescriptor,
        create: true
      ) { directoryDescriptor in
        let file = fileName.withCString {
          Darwin.openat(
            directoryDescriptor,
            $0,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
            mode_t(S_IRUSR | S_IWUSR)
          )
        }
        guard file >= 0 else { throw indeterminate() }
        defer { _ = Darwin.close(file) }
        try writeAll(data, to: file)
        guard
          Darwin.fsync(file) == 0,
          Darwin.fsync(directoryDescriptor) == 0
        else { throw indeterminate() }
      }
    }
    guard Darwin.fsync(rootDescriptor) == 0 else { throw indeterminate() }
  }

  private func validateDirectory(
    named name: String,
    expected: DirectoryIdentity,
    manifest: [String: String],
    under parentDescriptor: Int32
  ) throws -> [ArtifactFinding] {
    let descriptor = try openDirectory(
      named: name,
      expected: expected,
      under: parentDescriptor
    )
    defer { _ = Darwin.close(descriptor) }
    return try validateDirectory(
      descriptor: descriptor,
      expected: expected,
      pathName: name,
      manifest: manifest,
      parentDescriptor: parentDescriptor
    )
  }

  private func validateDirectory(
    descriptor: Int32,
    expected: DirectoryIdentity,
    pathName: String,
    manifest: [String: String],
    parentDescriptor: Int32
  ) throws -> [ArtifactFinding] {
    var payloads: [String: Data] = [:]
    var byteCount = 0
    var remainingEntries = Self.maximumEntries
    try collectFiles(
      from: descriptor,
      prefix: "",
      depth: 0,
      byteCount: &byteCount,
      remainingEntries: &remainingEntries,
      payloads: &payloads
    )
    guard Set(payloads.keys) == Set(manifest.keys) else {
      throw indeterminate()
    }
    var findings: [ArtifactFinding] = []
    for relativePath in payloads.keys.sorted() {
      guard let data = payloads[relativePath],
        manifest[relativePath] == FileDigest.sha256(data: data)
      else { throw indeterminate() }
      findings.append(
        contentsOf: ArtifactScanner().scan(
          data: data,
          path: destinationURL.appending(path: relativePath).path
        )
      )
    }
    var metadata = stat()
    guard
      fstat(descriptor, &metadata) == 0,
      expected.matches(metadata),
      try directoryIdentity(
        named: pathName,
        under: parentDescriptor
      ) == expected
    else { throw indeterminate() }
    return findings.sorted { ($0.path, $0.reason) < ($1.path, $1.reason) }
  }

  private func collectFiles(
    from descriptor: Int32,
    prefix: String,
    depth: Int,
    byteCount: inout Int,
    remainingEntries: inout Int,
    payloads: inout [String: Data]
  ) throws {
    guard depth <= Self.maximumDepth else { throw indeterminate() }
    for name in try entryNames(in: descriptor) {
      guard remainingEntries > 0 else { throw indeterminate() }
      remainingEntries -= 1
      let relativePath = prefix.isEmpty ? name : "\(prefix)/\(name)"
      var pathMetadata = stat()
      guard name.withCString({
        Darwin.fstatat(descriptor, $0, &pathMetadata, AT_SYMLINK_NOFOLLOW)
      }) == 0 else { throw indeterminate() }
      if Self.isOwnedDirectory(pathMetadata) {
        let child = try openDirectory(
          named: name,
          expected: DirectoryIdentity(pathMetadata),
          under: descriptor
        )
        defer { _ = Darwin.close(child) }
        try collectFiles(
          from: child,
          prefix: relativePath,
          depth: depth + 1,
          byteCount: &byteCount,
          remainingEntries: &remainingEntries,
          payloads: &payloads
        )
      } else if Self.isOwnedRegularFile(pathMetadata) {
        guard
          pathMetadata.st_size >= 0,
          pathMetadata.st_size <= Self.maximumFileBytes,
          byteCount <= Self.maximumTreeBytes - Int(pathMetadata.st_size)
        else { throw indeterminate() }
        let file = name.withCString {
          Darwin.openat(
            descriptor,
            $0,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard file >= 0 else { throw indeterminate() }
        defer { _ = Darwin.close(file) }
        var opened = stat()
        guard
          fstat(file, &opened) == 0,
          Self.isOwnedRegularFile(opened),
          opened.st_dev == pathMetadata.st_dev,
          opened.st_ino == pathMetadata.st_ino,
          opened.st_size == pathMetadata.st_size
        else { throw indeterminate() }
        let data = try readAll(from: file, count: Int(opened.st_size))
        var final = stat()
        var finalPath = stat()
        guard
          fstat(file, &final) == 0,
          name.withCString({
            Darwin.fstatat(descriptor, $0, &finalPath, AT_SYMLINK_NOFOLLOW)
          }) == 0,
          final.st_dev == opened.st_dev,
          final.st_ino == opened.st_ino,
          final.st_size == opened.st_size,
          final.st_mtimespec.tv_sec == opened.st_mtimespec.tv_sec,
          final.st_mtimespec.tv_nsec == opened.st_mtimespec.tv_nsec,
          finalPath.st_dev == opened.st_dev,
          finalPath.st_ino == opened.st_ino
        else { throw indeterminate() }
        byteCount += data.count
        guard payloads.updateValue(data, forKey: relativePath) == nil else {
          throw indeterminate()
        }
      } else {
        throw indeterminate()
      }
    }
  }

  private func makeManifest(_ payloads: [String: Data]) throws
    -> [String: String]
  {
    var total = 0
    var result: [String: String] = [:]
    for path in payloads.keys.sorted() {
      _ = try pathComponents(path)
      guard let data = payloads[path],
        data.count <= Self.maximumFileBytes,
        total <= Self.maximumTreeBytes - data.count
      else { throw indeterminate() }
      total += data.count
      result[path] = FileDigest.sha256(data: data)
    }
    guard result.count <= Self.maximumEntries else { throw indeterminate() }
    return result
  }

  private func swapDirectories(under descriptor: Int32) throws {
    guard destinationName.withCString({ destinationPointer in
      stagingName.withCString { stagingPointer in
        Darwin.renameatx_np(
          descriptor,
          destinationPointer,
          descriptor,
          stagingPointer,
          UInt32(RENAME_SWAP)
        )
      }
    }) == 0, Darwin.fsync(descriptor) == 0 else { throw indeterminate() }
  }

  private func installNewDirectory(under descriptor: Int32) throws {
    guard stagingName.withCString({ stagingPointer in
      destinationName.withCString { destinationPointer in
        Darwin.renameatx_np(
          descriptor,
          stagingPointer,
          descriptor,
          destinationPointer,
          UInt32(RENAME_EXCL)
        )
      }
    }) == 0, Darwin.fsync(descriptor) == 0 else { throw indeterminate() }
  }

  private func loadJournal(from descriptor: Int32) throws -> Journal? {
    var metadata = stat()
    let status = journalName.withCString {
      Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
    }
    if status != 0, errno == ENOENT { return nil }
    guard
      status == 0,
      Self.isOwnedRegularFile(metadata),
      metadata.st_size >= 0,
      metadata.st_size <= Self.maximumJournalBytes
    else { throw indeterminate() }
    let file = journalName.withCString {
      Darwin.openat(
        descriptor,
        $0,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard file >= 0 else { throw indeterminate() }
    defer { _ = Darwin.close(file) }
    let journal = try DeterministicJSON.decode(
      Journal.self,
      from: readAll(from: file, count: Int(metadata.st_size))
    )
    guard
      journal.schemaVersion == 1,
      journal.kind == "web-api-reverse.directory-replacement",
      journal.destinationName == destinationName,
      journal.files.count <= Self.maximumEntries,
      try journal.files.keys.allSatisfy({
        try pathComponents($0).count > 0
      }),
      journal.files.values.allSatisfy({
        $0.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil
      })
    else { throw indeterminate() }
    return journal
  }

  private func saveJournal(_ journal: Journal, under descriptor: Int32) throws {
    let data = try DeterministicJSON.encode(journal)
    guard data.count <= Self.maximumJournalBytes else { throw indeterminate() }
    let temporary = journalName + ".next-" + UUID().uuidString.lowercased()
    let file = temporary.withCString {
      Darwin.openat(
        descriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard file >= 0 else { throw indeterminate() }
    var removeTemporary = true
    defer {
      _ = Darwin.close(file)
      if removeTemporary {
        _ = temporary.withCString { Darwin.unlinkat(descriptor, $0, 0) }
      }
    }
    try writeAll(data, to: file)
    guard Darwin.fsync(file) == 0 else { throw indeterminate() }
    var existing = stat()
    let status = journalName.withCString {
      Darwin.fstatat(descriptor, $0, &existing, AT_SYMLINK_NOFOLLOW)
    }
    if status == 0 {
      guard
        Self.isOwnedRegularFile(existing),
        temporary.withCString({ temporaryPointer in
          journalName.withCString { journalPointer in
            Darwin.renameatx_np(
              descriptor,
              temporaryPointer,
              descriptor,
              journalPointer,
              UInt32(RENAME_SWAP)
            )
          }
        }) == 0,
        Darwin.fsync(descriptor) == 0
      else { throw indeterminate() }
      removeTemporary = false
      _ = temporary.withCString { Darwin.unlinkat(descriptor, $0, 0) }
      _ = Darwin.fsync(descriptor)
    } else if errno == ENOENT {
      guard temporary.withCString({ temporaryPointer in
        journalName.withCString { journalPointer in
          Darwin.renameatx_np(
            descriptor,
            temporaryPointer,
            descriptor,
            journalPointer,
            UInt32(RENAME_EXCL)
          )
        }
      }) == 0, Darwin.fsync(descriptor) == 0 else { throw indeterminate() }
      removeTemporary = false
    } else {
      throw indeterminate()
    }
  }

  private func removeJournal(under descriptor: Int32) throws {
    let status = journalName.withCString {
      Darwin.unlinkat(descriptor, $0, 0)
    }
    guard status == 0 || errno == ENOENT,
      Darwin.fsync(descriptor) == 0
    else { throw indeterminate() }
  }

  private func removeDirectory(
    named name: String,
    expected: DirectoryIdentity,
    under descriptor: Int32
  ) throws {
    let directory = try openDirectory(
      named: name,
      expected: expected,
      under: descriptor
    )
    defer { _ = Darwin.close(directory) }
    var remainingEntries = Self.maximumEntries
    try removeContents(
      of: directory,
      depth: 0,
      remainingEntries: &remainingEntries
    )
    var final = stat()
    guard
      fstat(directory, &final) == 0,
      expected.matches(final)
    else { throw indeterminate() }
    let quarantine = ".directory-delete-" + UUID().uuidString.lowercased()
    guard name.withCString({ namePointer in
      quarantine.withCString { quarantinePointer in
        Darwin.renameatx_np(
          descriptor,
          namePointer,
          descriptor,
          quarantinePointer,
          UInt32(RENAME_EXCL)
        )
      }
    }) == 0,
      try directoryIdentity(named: quarantine, under: descriptor) == expected,
      quarantine.withCString({
        Darwin.unlinkat(descriptor, $0, AT_REMOVEDIR)
      }) == 0,
      Darwin.fsync(descriptor) == 0
    else { throw indeterminate() }
  }

  private func removeContents(
    of descriptor: Int32,
    depth: Int,
    remainingEntries: inout Int
  ) throws {
    guard depth <= Self.maximumDepth else { throw indeterminate() }
    for name in try entryNames(in: descriptor) {
      guard remainingEntries > 0 else { throw indeterminate() }
      remainingEntries -= 1
      var metadata = stat()
      guard name.withCString({
        Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
      }) == 0 else { throw indeterminate() }
      if Self.isOwnedDirectory(metadata) {
        let identity = DirectoryIdentity(metadata)
        let child = try openDirectory(
          named: name,
          expected: identity,
          under: descriptor
        )
        defer { _ = Darwin.close(child) }
        try removeContents(
          of: child,
          depth: depth + 1,
          remainingEntries: &remainingEntries
        )
        let quarantine = ".entry-delete-" + UUID().uuidString.lowercased()
        guard name.withCString({ namePointer in
          quarantine.withCString { quarantinePointer in
            Darwin.renameatx_np(
              descriptor,
              namePointer,
              descriptor,
              quarantinePointer,
              UInt32(RENAME_EXCL)
            )
          }
        }) == 0,
          try directoryIdentity(named: quarantine, under: descriptor)
            == identity,
          quarantine.withCString({
            Darwin.unlinkat(descriptor, $0, AT_REMOVEDIR)
          }) == 0
        else { throw indeterminate() }
      } else if Self.isOwnedRegularFile(metadata) {
        let file = name.withCString {
          Darwin.openat(
            descriptor,
            $0,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard file >= 0 else { throw indeterminate() }
        defer { _ = Darwin.close(file) }
        var opened = stat()
        let quarantine = ".entry-delete-" + UUID().uuidString.lowercased()
        guard
          fstat(file, &opened) == 0,
          opened.st_dev == metadata.st_dev,
          opened.st_ino == metadata.st_ino,
          name.withCString({ namePointer in
            quarantine.withCString { quarantinePointer in
              Darwin.renameatx_np(
                descriptor,
                namePointer,
                descriptor,
                quarantinePointer,
                UInt32(RENAME_EXCL)
              )
            }
          }) == 0
        else { throw indeterminate() }
        var quarantined = stat()
        guard quarantine.withCString({
          Darwin.fstatat(
            descriptor,
            $0,
            &quarantined,
            AT_SYMLINK_NOFOLLOW
          )
        }) == 0,
          quarantined.st_dev == opened.st_dev,
          quarantined.st_ino == opened.st_ino,
          quarantine.withCString({
            Darwin.unlinkat(descriptor, $0, 0)
          }) == 0
        else { throw indeterminate() }
      } else {
        throw indeterminate()
      }
    }
    guard Darwin.fsync(descriptor) == 0 else { throw indeterminate() }
  }

  private func withDirectory<Result>(
    components: [String],
    from rootDescriptor: Int32,
    create: Bool,
    operation: (Int32) throws -> Result
  ) throws -> Result {
    var descriptor = Darwin.dup(rootDescriptor)
    guard descriptor >= 0 else { throw indeterminate() }
    defer { _ = Darwin.close(descriptor) }
    for component in components {
      var child = component.withCString {
        Darwin.openat(
          descriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      if child < 0, create, errno == ENOENT {
        guard component.withCString({
          Darwin.mkdirat(descriptor, $0, mode_t(S_IRWXU))
        }) == 0, Darwin.fsync(descriptor) == 0 else { throw indeterminate() }
        child = component.withCString {
          Darwin.openat(
            descriptor,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
      }
      var metadata = stat()
      guard
        child >= 0,
        fstat(child, &metadata) == 0,
        Self.isOwnedDirectory(metadata)
      else {
        if child >= 0 { _ = Darwin.close(child) }
        throw indeterminate()
      }
      _ = Darwin.close(descriptor)
      descriptor = child
    }
    return try operation(descriptor)
  }

  private func openDirectory(
    named name: String,
    expected: DirectoryIdentity,
    under descriptor: Int32
  ) throws -> Int32 {
    let child = name.withCString {
      Darwin.openat(
        descriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    var metadata = stat()
    guard
      child >= 0,
      fstat(child, &metadata) == 0,
      Self.isOwnedDirectory(metadata),
      expected.matches(metadata),
      try directoryIdentity(named: name, under: descriptor) == expected
    else {
      if child >= 0 { _ = Darwin.close(child) }
      throw indeterminate()
    }
    return child
  }

  private func directoryIdentity(
    named name: String,
    under descriptor: Int32
  ) throws -> DirectoryIdentity? {
    var metadata = stat()
    let status = name.withCString {
      Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
    }
    if status != 0, errno == ENOENT { return nil }
    guard status == 0, Self.isOwnedDirectory(metadata) else {
      throw indeterminate()
    }
    return DirectoryIdentity(metadata)
  }

  private func entryNames(in descriptor: Int32) throws -> [String] {
    let duplicate = Darwin.dup(descriptor)
    guard duplicate >= 0, let stream = Darwin.fdopendir(duplicate) else {
      if duplicate >= 0 { _ = Darwin.close(duplicate) }
      throw indeterminate()
    }
    defer { _ = Darwin.closedir(stream) }
    var names: [String] = []
    while let entry = Darwin.readdir(stream) {
      let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
        pointer.withMemoryRebound(
          to: CChar.self,
          capacity: Int(MAXNAMLEN) + 1
        ) { String(cString: $0) }
      }
      if name != ".", name != ".." {
        names.append(name)
        guard names.count <= Self.maximumEntries else {
          throw indeterminate()
        }
      }
    }
    return names.sorted()
  }

  private func withLockedParent<Result>(
    _ operation: (Int32) throws -> Result
  ) throws -> Result {
    let descriptor = Self.openDirectory(parentURL)
    guard
      descriptor >= 0,
      matchesParentIdentity(descriptor),
      durableDirectoryFlock(descriptor, LOCK_EX) == 0,
      currentParentIdentityMatches()
    else {
      if descriptor >= 0 { _ = Darwin.close(descriptor) }
      throw indeterminate()
    }
    defer {
      _ = durableDirectoryFlock(descriptor, LOCK_UN)
      _ = Darwin.close(descriptor)
    }
    try testHook?(.afterParentLock)
    guard currentParentIdentityMatches() else { throw indeterminate() }
    let result = try operation(descriptor)
    try testHook?(.beforeSuccess)
    guard currentParentIdentityMatches() else { throw indeterminate() }
    return result
  }

  private func currentParentIdentityMatches() -> Bool {
    let descriptor = Self.openDirectory(parentURL)
    guard descriptor >= 0 else { return false }
    defer { _ = Darwin.close(descriptor) }
    return matchesParentIdentity(descriptor)
  }

  private func matchesParentIdentity(_ descriptor: Int32) -> Bool {
    var metadata = stat()
    return fstat(descriptor, &metadata) == 0
      && Self.isOwnedDirectory(metadata)
      && metadata.st_dev == parentDevice
      && metadata.st_ino == parentInode
  }

  private func pathComponents(_ relativePath: String) throws -> [String] {
    let components = relativePath.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map(String.init)
    guard
      !relativePath.hasPrefix("/"),
      !components.isEmpty,
      components.count <= Self.maximumDepth,
      components.allSatisfy(Self.validName)
    else { throw indeterminate() }
    return components
  }

  private func readAll(from descriptor: Int32, count: Int) throws -> Data {
    var data = Data(count: count)
    try data.withUnsafeMutableBytes { bytes in
      guard let base = bytes.baseAddress else { return }
      var offset = 0
      while offset < bytes.count {
        let amount = Darwin.read(
          descriptor,
          base.advanced(by: offset),
          bytes.count - offset
        )
        if amount < 0, errno == EINTR { continue }
        guard amount > 0 else { throw indeterminate() }
        offset += amount
      }
      var extra: UInt8 = 0
      guard Darwin.read(descriptor, &extra, 1) == 0 else {
        throw indeterminate()
      }
    }
    return data
  }

  private func writeAll(_ data: Data, to descriptor: Int32) throws {
    try data.withUnsafeBytes { bytes in
      guard let base = bytes.baseAddress else { return }
      var offset = 0
      while offset < bytes.count {
        let amount = Darwin.write(
          descriptor,
          base.advanced(by: offset),
          bytes.count - offset
        )
        if amount < 0, errno == EINTR { continue }
        guard amount > 0 else { throw indeterminate() }
        offset += amount
      }
    }
  }

  private func require<T>(_ value: T?) throws -> T {
    guard let value else { throw indeterminate() }
    return value
  }

  private func indeterminate() -> DurableDirectoryReplacementError {
    .transactionIndeterminate(destinationURL.path)
  }

  private static func validName(_ name: String) -> Bool {
    !name.isEmpty && name != "." && name != ".."
      && !name.contains("/") && !name.contains("\0")
  }

  private static func isOwnedDirectory(_ metadata: stat) -> Bool {
    metadata.st_mode & S_IFMT == S_IFDIR && metadata.st_uid == geteuid()
  }

  private static func isOwnedRegularFile(_ metadata: stat) -> Bool {
    metadata.st_mode & S_IFMT == S_IFREG && metadata.st_uid == geteuid()
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
}
