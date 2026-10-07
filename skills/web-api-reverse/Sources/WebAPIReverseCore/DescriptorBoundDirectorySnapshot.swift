import Darwin
import Foundation

/// A bounded immutable view of one exact directory generation.
struct DescriptorBoundDirectorySnapshot: Sendable {
  let payloads: [String: Data]

  init(
    directory: URL,
    maximumFileBytes: Int,
    maximumTreeBytes: Int,
    maximumEntries: Int
  ) throws {
    let declared = directory.standardizedFileURL
    let parentURL = declared.deletingLastPathComponent()
    let name = declared.lastPathComponent
    guard Self.validName(name) else {
      throw ContractError.invalidDirectory(declared.path)
    }
    let parent = parentURL.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(
        path,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard parent >= 0 else {
      throw ContractError.invalidDirectory(parentURL.path)
    }
    defer { _ = Darwin.close(parent) }
    var parentIdentity = stat()
    var pathIdentity = stat()
    guard fstat(parent, &parentIdentity) == 0,
      Self.isOwnedDirectory(parentIdentity),
      Self.currentPath(parentURL, matches: parentIdentity),
      name.withCString({
        Darwin.fstatat(parent, $0, &pathIdentity, AT_SYMLINK_NOFOLLOW)
      }) == 0,
      Self.isOwnedDirectory(pathIdentity)
    else { throw ContractError.invalidDirectory(declared.path) }
    let descriptor = name.withCString {
      Darwin.openat(
        parent,
        $0,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard descriptor >= 0 else {
      throw ContractError.invalidDirectory(declared.path)
    }
    defer { _ = Darwin.close(descriptor) }
    var opened = stat()
    guard fstat(descriptor, &opened) == 0,
      Self.isOwnedDirectory(opened),
      Self.sameIdentity(opened, pathIdentity)
    else { throw ContractError.publicationIndeterminate(declared.path) }

    let names = try Self.entryNames(
      in: descriptor,
      maximumEntries: maximumEntries,
      evidencePath: declared.path
    )
    var result: [String: Data] = [:]
    var total = 0
    for childName in names {
      let evidencePath = declared.appending(path: childName).path
      let data = try Self.readFile(
        named: childName,
        under: descriptor,
        maximumBytes: maximumFileBytes,
        evidencePath: evidencePath
      )
      guard total <= maximumTreeBytes - data.count else {
        throw ContractError.publicationIndeterminate(declared.path)
      }
      total += data.count
      result[childName] = data
    }
    var final = stat()
    var finalPath = stat()
    guard fstat(descriptor, &final) == 0,
      Self.sameIdentity(opened, final),
      name.withCString({
        Darwin.fstatat(parent, $0, &finalPath, AT_SYMLINK_NOFOLLOW)
      }) == 0,
      Self.sameIdentity(opened, finalPath),
      Set(try Self.entryNames(
        in: descriptor,
        maximumEntries: maximumEntries,
        evidencePath: declared.path
      )) == Set(names),
      Self.currentPath(parentURL, matches: parentIdentity)
    else { throw ContractError.publicationIndeterminate(declared.path) }
    payloads = result
  }

  private static func readFile(
    named name: String,
    under descriptor: Int32,
    maximumBytes: Int,
    evidencePath: String
  ) throws -> Data {
    var pathMetadata = stat()
    guard name.withCString({
      Darwin.fstatat(descriptor, $0, &pathMetadata, AT_SYMLINK_NOFOLLOW)
    }) == 0,
      isOwnedRegularFile(pathMetadata),
      pathMetadata.st_size >= 0,
      pathMetadata.st_size <= maximumBytes
    else { throw ContractError.publicationIndeterminate(evidencePath) }
    let file = name.withCString {
      Darwin.openat(
        descriptor,
        $0,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
      )
    }
    guard file >= 0 else {
      throw ContractError.publicationIndeterminate(evidencePath)
    }
    defer { _ = Darwin.close(file) }
    var opened = stat()
    guard fstat(file, &opened) == 0,
      isOwnedRegularFile(opened),
      sameIdentity(opened, pathMetadata),
      opened.st_size == pathMetadata.st_size
    else { throw ContractError.publicationIndeterminate(evidencePath) }
    let data = try readAll(
      from: file,
      count: Int(opened.st_size),
      evidencePath: evidencePath
    )
    var final = stat()
    var finalPath = stat()
    guard fstat(file, &final) == 0,
      name.withCString({
        Darwin.fstatat(descriptor, $0, &finalPath, AT_SYMLINK_NOFOLLOW)
      }) == 0,
      stableFile(final, matches: opened),
      stableFile(finalPath, matches: opened)
    else { throw ContractError.publicationIndeterminate(evidencePath) }
    return data
  }

  private static func readAll(
    from descriptor: Int32,
    count: Int,
    evidencePath: String
  ) throws -> Data {
    var data = Data(count: count)
    try data.withUnsafeMutableBytes { bytes in
      if let base = bytes.baseAddress {
        var offset = 0
        while offset < bytes.count {
          let amount = Darwin.read(
            descriptor,
            base.advanced(by: offset),
            bytes.count - offset
          )
          if amount < 0, errno == EINTR { continue }
          guard amount > 0 else {
            throw ContractError.publicationIndeterminate(evidencePath)
          }
          offset += amount
        }
      }
      var extra: UInt8 = 0
      guard Darwin.read(descriptor, &extra, 1) == 0 else {
        throw ContractError.publicationIndeterminate(evidencePath)
      }
    }
    return data
  }

  private static func entryNames(
    in descriptor: Int32,
    maximumEntries: Int,
    evidencePath: String
  ) throws -> [String] {
    let duplicate = Darwin.dup(descriptor)
    guard duplicate >= 0, let stream = Darwin.fdopendir(duplicate) else {
      if duplicate >= 0 { _ = Darwin.close(duplicate) }
      throw ContractError.publicationIndeterminate(evidencePath)
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
        guard validName(name), names.count < maximumEntries else {
          throw ContractError.publicationIndeterminate(evidencePath)
        }
        names.append(name)
      }
    }
    return names.sorted()
  }

  private static func currentPath(_ url: URL, matches expected: stat) -> Bool {
    var current = stat()
    return url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return false }
      return Darwin.lstat(path, &current) == 0
        && isOwnedDirectory(current)
        && sameIdentity(current, expected)
    }
  }

  private static func stableFile(_ value: stat, matches expected: stat) -> Bool {
    isOwnedRegularFile(value)
      && sameIdentity(value, expected)
      && value.st_size == expected.st_size
      && value.st_mtimespec.tv_sec == expected.st_mtimespec.tv_sec
      && value.st_mtimespec.tv_nsec == expected.st_mtimespec.tv_nsec
      && value.st_ctimespec.tv_sec == expected.st_ctimespec.tv_sec
      && value.st_ctimespec.tv_nsec == expected.st_ctimespec.tv_nsec
  }

  private static func sameIdentity(_ lhs: stat, _ rhs: stat) -> Bool {
    lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
  }

  private static func isOwnedDirectory(_ metadata: stat) -> Bool {
    metadata.st_mode & S_IFMT == S_IFDIR && metadata.st_uid == geteuid()
  }

  private static func isOwnedRegularFile(_ metadata: stat) -> Bool {
    metadata.st_mode & S_IFMT == S_IFREG && metadata.st_uid == geteuid()
  }

  private static func validName(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && !value.contains("/") && !value.contains("\0")
  }
}
