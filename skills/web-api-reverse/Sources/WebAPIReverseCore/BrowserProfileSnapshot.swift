import Darwin
import CryptoKit
import Foundation

public enum BrowserProfileSnapshotError: Error, Equatable, LocalizedError {
  case sourceMissing(String)
  case sourceNotDirectory(String)
  case sourceInUse(String)
  case unsafeSource(String)
  case sourceChanged(String)
  case snapshotTooLarge(String)

  public var errorDescription: String? {
    switch self {
    case .sourceMissing(let path):
      "The browser profile does not exist: \(path)"
    case .sourceNotDirectory(let path):
      "The browser profile is not a directory: \(path)"
    case .sourceInUse(let path):
      "The browser profile is currently in use and cannot be audited from a stable snapshot: \(path)"
    case .unsafeSource(let path):
      "The browser profile contains a symbolic link or unsupported file: \(path)"
    case .sourceChanged(let path):
      "The browser profile changed while its disposable snapshot was being created: \(path)"
    case .snapshotTooLarge(let path):
      "The browser profile exceeds the bounded snapshot limits: \(path)"
    }
  }

  public var diagnosticCode: String {
    switch self {
    case .sourceMissing:
      "browser.profile.missing"
    case .sourceNotDirectory:
      "browser.profile.not_directory"
    case .sourceInUse:
      "browser.profile.in_use"
    case .unsafeSource:
      "browser.profile.unsafe_source"
    case .sourceChanged:
      "browser.profile.changed"
    case .snapshotTooLarge:
      "browser.profile.too_large"
    }
  }
}

enum BrowserProfileSnapshotCopyStage: Equatable, Sendable {
  case afterEntryCopied(String)
}

public struct BrowserProfileSnapshot: @unchecked Sendable {
  public let directory: URL

  let owner: PrivateArtifactStore
  let directoryName: String

  public static func create(
    from source: URL,
    under privateDirectory: URL
  ) throws -> BrowserProfileSnapshot {
    try create(
      from: source,
      under: privateDirectory,
      copyFaultInjector: { _ in }
    )
  }

  static func create(
    from source: URL,
    under privateDirectory: URL,
    copyFaultInjector:
      @escaping @Sendable (BrowserProfileSnapshotCopyStage) throws -> Void
  ) throws -> BrowserProfileSnapshot {
    let sourceDescriptor = try openDirectoryWithoutSymbolicLinks(source)
    defer { _ = Darwin.close(sourceDescriptor) }

    var sourceMetadata = stat()
    guard
      fstat(sourceDescriptor, &sourceMetadata) == 0,
      sourceMetadata.st_mode & S_IFMT == S_IFDIR,
      sourceMetadata.st_uid == geteuid()
    else {
      throw BrowserProfileSnapshotError.sourceNotDirectory(source.path)
    }
    guard !hasBrowserLock(sourceDescriptor) else {
      throw BrowserProfileSnapshotError.sourceInUse(source.path)
    }

    let owner = try PrivateArtifactStore(
      privateRoot: privateDirectory,
      createPrivateRoot: true
    )

    let directoryName =
      ".browser-profile-snapshot-\(UUID().uuidString.lowercased())"
    do {
      try owner.withRootDescriptor { rootDescriptor in
        guard directoryName.withCString({
          Darwin.mkdirat(rootDescriptor, $0, mode_t(S_IRWXU))
        }) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(directoryName)
        }
        let destinationDescriptor = directoryName.withCString {
          Darwin.openat(
            rootDescriptor,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard destinationDescriptor >= 0 else {
          throw PrivateArtifactStoreError.unsafeDirectory(directoryName)
        }
        defer { _ = Darwin.close(destinationDescriptor) }
        var budget = CopyBudget()
        try copyDirectory(
          sourceDescriptor,
          to: destinationDescriptor,
          relativePath: "",
          profilePath: source.path,
          isProfileRoot: true,
          budget: &budget,
          copyFaultInjector: copyFaultInjector
        )
        guard Darwin.fsync(destinationDescriptor) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(directoryName)
        }
      }
      guard !hasBrowserLock(sourceDescriptor) else {
        throw BrowserProfileSnapshotError.sourceInUse(source.path)
      }
      try requireSameSource(
        source,
        descriptor: sourceDescriptor,
        initial: sourceMetadata
      )
      return BrowserProfileSnapshot(
        directory: owner.privateRoot.appending(
          path: directoryName,
          directoryHint: .isDirectory
        ),
        owner: owner,
        directoryName: directoryName
      )
    } catch {
      try? owner.removeDirectory(named: directoryName)
      throw error
    }
  }

  /// Removes only the descriptor-bound snapshot created by this value.
  public func remove() throws {
    try owner.removeDirectory(named: directoryName)
  }

  static func sourceGeneration(for source: URL) throws -> String {
    let descriptor = try openDirectoryWithoutSymbolicLinks(source)
    defer { _ = Darwin.close(descriptor) }
    var budget = FingerprintBudget()
    try fingerprintDirectory(
      descriptor,
      relativePath: "",
      isProfileRoot: true,
      budget: &budget
    )
    return budget.hasher.finalize().map {
      String(format: "%02x", $0)
    }.joined()
  }

  private struct CopyBudget {
    var entries = 0
    var bytes: Int64 = 0
  }

  private struct FingerprintBudget {
    var entries = 0
    var bytes: Int64 = 0
    var hasher = SHA256()
  }

  private static func fingerprintDirectory(
    _ source: Int32,
    relativePath: String,
    isProfileRoot: Bool,
    budget: inout FingerprintBudget
  ) throws {
    for name in try entryNames(in: source) {
      if isProfileRoot, transientProfileEntries.contains(name) { continue }
      budget.entries += 1
      guard budget.entries <= maximumEntryCount else {
        throw BrowserProfileSnapshotError.snapshotTooLarge(relativePath)
      }
      let childPath = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
      var metadata = stat()
      guard name.withCString({
        Darwin.fstatat(source, $0, &metadata, AT_SYMLINK_NOFOLLOW)
      }) == 0 else {
        throw BrowserProfileSnapshotError.sourceChanged(childPath)
      }
      switch metadata.st_mode & S_IFMT {
      case S_IFDIR:
        updateFingerprint(
          &budget.hasher,
          kind: "directory",
          path: childPath,
          metadata: metadata
        )
        let child = name.withCString {
          Darwin.openat(
            source,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard child >= 0 else {
          throw BrowserProfileSnapshotError.unsafeSource(childPath)
        }
        do {
          try fingerprintDirectory(
            child,
            relativePath: childPath,
            isProfileRoot: false,
            budget: &budget
          )
          try requireSameEntry(
            name,
            under: source,
            descriptor: child,
            initial: metadata,
            path: childPath
          )
          _ = Darwin.close(child)
        } catch {
          _ = Darwin.close(child)
          throw error
        }
      case S_IFREG:
        guard
          metadata.st_size >= 0,
          metadata.st_size <= maximumFileBytes
        else {
          throw BrowserProfileSnapshotError.snapshotTooLarge(childPath)
        }
        budget.bytes += Int64(metadata.st_size)
        guard budget.bytes <= maximumTotalBytes else {
          throw BrowserProfileSnapshotError.snapshotTooLarge(relativePath)
        }
        updateFingerprint(
          &budget.hasher,
          kind: "file",
          path: childPath,
          metadata: metadata
        )
        let file = name.withCString {
          Darwin.openat(
            source,
            $0,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard file >= 0 else {
          throw BrowserProfileSnapshotError.unsafeSource(childPath)
        }
        do {
          var remaining = Int(metadata.st_size)
          var buffer = [UInt8](repeating: 0, count: 64 * 1024)
          while remaining > 0 {
            let count = Darwin.read(file, &buffer, min(buffer.count, remaining))
            if count < 0, errno == EINTR { continue }
            guard count > 0 else {
              throw BrowserProfileSnapshotError.sourceChanged(childPath)
            }
            budget.hasher.update(data: Data(buffer.prefix(count)))
            remaining -= count
          }
          var sentinel: UInt8 = 0
          var sentinelCount: Int
          repeat {
            sentinelCount = Darwin.read(file, &sentinel, 1)
          } while sentinelCount < 0 && errno == EINTR
          guard sentinelCount == 0 else {
            throw BrowserProfileSnapshotError.sourceChanged(childPath)
          }
          try requireSameEntry(
            name,
            under: source,
            descriptor: file,
            initial: metadata,
            path: childPath
          )
          _ = Darwin.close(file)
        } catch {
          _ = Darwin.close(file)
          throw error
        }
      default:
        throw BrowserProfileSnapshotError.unsafeSource(childPath)
      }
    }
  }

  private static func updateFingerprint(
    _ hasher: inout SHA256,
    kind: String,
    path: String,
    metadata: stat
  ) {
    hasher.update(
      data: Data(
        "\(kind.utf8.count):\(kind)\(path.utf8.count):\(path):"
          .utf8
      )
    )
    let values: [Int64] = [
      Int64(metadata.st_dev),
      Int64(metadata.st_ino),
      Int64(metadata.st_size),
      Int64(metadata.st_mtimespec.tv_sec),
      Int64(metadata.st_mtimespec.tv_nsec),
      Int64(metadata.st_ctimespec.tv_sec),
      Int64(metadata.st_ctimespec.tv_nsec),
    ]
    values.withUnsafeBytes { hasher.update(bufferPointer: $0) }
  }

  private static func copyDirectory(
    _ source: Int32,
    to destination: Int32,
    relativePath: String,
    profilePath: String,
    isProfileRoot: Bool,
    budget: inout CopyBudget,
    copyFaultInjector:
      @escaping @Sendable (BrowserProfileSnapshotCopyStage) throws -> Void
  ) throws {
    var initialDirectory = stat()
    guard fstat(source, &initialDirectory) == 0 else {
      throw BrowserProfileSnapshotError.sourceChanged(relativePath)
    }
    for name in try entryNames(in: source) {
      if isProfileRoot, transientProfileEntries.contains(name) { continue }
      budget.entries += 1
      guard budget.entries <= maximumEntryCount else {
        throw BrowserProfileSnapshotError.snapshotTooLarge(relativePath)
      }
      let childPath = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
      var metadata = stat()
      guard name.withCString({
        Darwin.fstatat(source, $0, &metadata, AT_SYMLINK_NOFOLLOW)
      }) == 0 else {
        throw BrowserProfileSnapshotError.sourceChanged(childPath)
      }
      switch metadata.st_mode & S_IFMT {
      case S_IFDIR:
        let sourceChild = name.withCString {
          Darwin.openat(
            source,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard sourceChild >= 0 else {
          throw BrowserProfileSnapshotError.unsafeSource(childPath)
        }
        defer { _ = Darwin.close(sourceChild) }
        guard name.withCString({
          Darwin.mkdirat(destination, $0, mode_t(S_IRWXU))
        }) == 0 else {
          throw PrivateArtifactStoreError.writeFailed(childPath)
        }
        let destinationChild = name.withCString {
          Darwin.openat(
            destination,
            $0,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard destinationChild >= 0 else {
          throw PrivateArtifactStoreError.unsafeDirectory(childPath)
        }
        do {
          try copyDirectory(
            sourceChild,
            to: destinationChild,
            relativePath: childPath,
            profilePath: profilePath,
            isProfileRoot: false,
            budget: &budget,
            copyFaultInjector: copyFaultInjector
          )
          guard Darwin.fsync(destinationChild) == 0 else {
            throw PrivateArtifactStoreError.writeFailed(childPath)
          }
          _ = Darwin.close(destinationChild)
        } catch {
          _ = Darwin.close(destinationChild)
          throw error
        }
        try copyFaultInjector(.afterEntryCopied(childPath))
        try requireSameEntry(
          name,
          under: source,
          descriptor: sourceChild,
          initial: metadata,
          path: childPath
        )
      case S_IFREG:
        guard
          metadata.st_size >= 0,
          metadata.st_size <= maximumFileBytes
        else {
          throw BrowserProfileSnapshotError.snapshotTooLarge(childPath)
        }
        budget.bytes += Int64(metadata.st_size)
        guard budget.bytes <= maximumTotalBytes else {
          throw BrowserProfileSnapshotError.snapshotTooLarge(relativePath)
        }
        let sourceFile = name.withCString {
          Darwin.openat(
            source,
            $0,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
          )
        }
        guard sourceFile >= 0 else {
          throw BrowserProfileSnapshotError.unsafeSource(childPath)
        }
        defer { _ = Darwin.close(sourceFile) }
        var openedMetadata = stat()
        guard
          fstat(sourceFile, &openedMetadata) == 0,
          sameVersion(metadata, openedMetadata)
        else {
          throw BrowserProfileSnapshotError.sourceChanged(childPath)
        }
        let destinationFile = name.withCString {
          Darwin.openat(
            destination,
            $0,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
            mode_t(S_IRUSR | S_IWUSR)
          )
        }
        guard destinationFile >= 0 else {
          throw PrivateArtifactStoreError.writeFailed(childPath)
        }
        do {
          try copyFile(
            sourceFile,
            to: destinationFile,
            expectedBytes: Int(metadata.st_size),
            path: childPath
          )
          guard Darwin.fsync(destinationFile) == 0 else {
            throw PrivateArtifactStoreError.writeFailed(childPath)
          }
          _ = Darwin.close(destinationFile)
        } catch {
          _ = Darwin.close(destinationFile)
          throw error
        }
        try copyFaultInjector(.afterEntryCopied(childPath))
        try requireSameEntry(
          name,
          under: source,
          descriptor: sourceFile,
          initial: metadata,
          path: childPath
        )
      default:
        throw BrowserProfileSnapshotError.unsafeSource(childPath)
      }
    }
    if isProfileRoot, hasBrowserLock(source) {
      throw BrowserProfileSnapshotError.sourceInUse(profilePath)
    }
    var finalDirectory = stat()
    guard
      fstat(source, &finalDirectory) == 0,
      sameVersion(initialDirectory, finalDirectory)
    else {
      throw BrowserProfileSnapshotError.sourceChanged(relativePath)
    }
  }

  private static func copyFile(
    _ source: Int32,
    to destination: Int32,
    expectedBytes: Int,
    path: String
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
        throw BrowserProfileSnapshotError.sourceChanged(path)
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
            throw PrivateArtifactStoreError.writeFailed(path)
          }
          offset += written
        }
      }
      copied += count
    }
    var sentinel: UInt8 = 0
    var count: Int
    repeat {
      count = Darwin.read(source, &sentinel, 1)
    } while count < 0 && errno == EINTR
    guard count == 0 else {
      throw BrowserProfileSnapshotError.sourceChanged(path)
    }
  }

  private static func entryNames(in descriptor: Int32) throws -> [String] {
    let duplicate = Darwin.dup(descriptor)
    guard duplicate >= 0, let stream = Darwin.fdopendir(duplicate) else {
      if duplicate >= 0 { _ = Darwin.close(duplicate) }
      throw BrowserProfileSnapshotError.unsafeSource("<directory>")
    }
    defer { _ = Darwin.closedir(stream) }
    var result: [String] = []
    while let entry = Darwin.readdir(stream) {
      let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
        pointer.withMemoryRebound(
          to: CChar.self,
          capacity: Int(MAXNAMLEN) + 1
        ) { String(cString: $0) }
      }
      if name != ".", name != ".." { result.append(name) }
    }
    return result.sorted()
  }

  private static func requireSameEntry(
    _ name: String,
    under parent: Int32,
    descriptor: Int32,
    initial: stat,
    path: String
  ) throws {
    var descriptorMetadata = stat()
    var pathMetadata = stat()
    guard
      fstat(descriptor, &descriptorMetadata) == 0,
      name.withCString({
        Darwin.fstatat(parent, $0, &pathMetadata, AT_SYMLINK_NOFOLLOW)
      }) == 0,
      sameVersion(initial, descriptorMetadata),
      sameVersion(initial, pathMetadata)
    else {
      throw BrowserProfileSnapshotError.sourceChanged(path)
    }
  }

  private static func requireSameSource(
    _ source: URL,
    descriptor: Int32,
    initial: stat
  ) throws {
    let reopened = try openDirectoryWithoutSymbolicLinks(source)
    defer { _ = Darwin.close(reopened) }
    var descriptorMetadata = stat()
    var reopenedMetadata = stat()
    guard
      fstat(descriptor, &descriptorMetadata) == 0,
      fstat(reopened, &reopenedMetadata) == 0,
      sameVersion(initial, descriptorMetadata),
      sameVersion(initial, reopenedMetadata)
    else {
      throw BrowserProfileSnapshotError.sourceChanged(source.path)
    }
  }

  private static func openDirectoryWithoutSymbolicLinks(
    _ url: URL
  ) throws -> Int32 {
    guard url.isFileURL, url.path.hasPrefix("/") else {
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    let standardized = url.standardizedFileURL
    let parent = standardized.deletingLastPathComponent()
    guard let resolvedParent = parent.withUnsafeFileSystemRepresentation({ path in
      guard let path else { return UnsafeMutablePointer<CChar>?.none }
      return Darwin.realpath(path, nil)
    }) else {
      if errno == ENOENT {
        throw BrowserProfileSnapshotError.sourceMissing(url.path)
      }
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    defer { Darwin.free(resolvedParent) }
    let parentDescriptor = Darwin.open(
      resolvedParent,
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard parentDescriptor >= 0 else {
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    defer { _ = Darwin.close(parentDescriptor) }
    let leaf = standardized.lastPathComponent
    var leafMetadata = stat()
    if leaf.withCString({
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &leafMetadata,
        AT_SYMLINK_NOFOLLOW
      )
    }) != 0 {
      if errno == ENOENT {
        throw BrowserProfileSnapshotError.sourceMissing(url.path)
      }
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    guard leafMetadata.st_mode & S_IFMT == S_IFDIR else {
      if leafMetadata.st_mode & S_IFMT == S_IFLNK {
        throw BrowserProfileSnapshotError.unsafeSource(url.path)
      }
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    let descriptor = leaf.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard descriptor >= 0 else {
      throw BrowserProfileSnapshotError.sourceNotDirectory(url.path)
    }
    return descriptor
  }

  private static func hasBrowserLock(_ profile: Int32) -> Bool {
    var lockMetadata = stat()
    let lockStatus = "SingletonLock".withCString {
      Darwin.fstatat(profile, $0, &lockMetadata, AT_SYMLINK_NOFOLLOW)
    }
    if lockStatus == 0 {
      guard lockMetadata.st_mode & S_IFMT == S_IFLNK else { return true }
      var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
      let count = "SingletonLock".withCString {
        Darwin.readlinkat(profile, $0, &buffer, buffer.count - 1)
      }
      guard count > 0 else { return true }
      buffer[Int(count)] = 0
      let target = String(decoding: buffer.prefix(Int(count)).map(UInt8.init), as: UTF8.self)
      guard let pid = browserPID(fromSingletonLockTarget: target) else {
        return true
      }
      return processExists(pid)
    }
    return browserLockEntries
      .filter { $0 != "SingletonLock" }
      .contains { name in
        name.withCString {
          Darwin.fstatat(profile, $0, &lockMetadata, AT_SYMLINK_NOFOLLOW)
        } == 0
      }
  }

  private static func browserPID(
    fromSingletonLockTarget target: String
  ) -> pid_t? {
    guard
      let component = target.split(separator: "-").last,
      let value = Int32(component),
      value > 0
    else { return nil }
    return value
  }

  private static func processExists(_ pid: pid_t) -> Bool {
    if kill(pid, 0) == 0 { return true }
    return errno == EPERM
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

  private static let maximumFileBytes: off_t = 512 * 1024 * 1024
  private static let maximumTotalBytes: Int64 = 4 * 1024 * 1024 * 1024
  private static let maximumEntryCount = 200_000

  private static let browserLockEntries = [
    "SingletonCookie", "SingletonLock", "SingletonSocket",
  ]

  private static let transientProfileEntries = [
    "DevToolsActivePort", "RunningChromeVersion", "SingletonCookie",
    "SingletonLock", "SingletonSocket",
  ]
}
