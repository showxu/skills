import Darwin
import Foundation

@_silgen_name("flock")
private func providerAPIAuthorityFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

/// One bounded, descriptor-bound view of every API artifact that may affect
/// publication. Paths are retained only as deterministic evidence labels;
/// all authority reads are completed through the already locked API fd.
struct ProviderAPIAuthoritySnapshot: Sendable {
  static let maximumPublishedFileBytes = 16 * 1_024 * 1_024
  private static let maximumAuthorityFileBytes = 64 * 1_024 * 1_024
  private static let maximumTreeBytes = 256 * 1_024 * 1_024
  private static let maximumEntries = 4_096
  private static let maximumDepth = 16

  let files: [String: Data]
  let directories: Set<String>

  init(apiDescriptor: Int32, includePublished: Bool = false) throws {
    var builder = try Builder(apiDescriptor: apiDescriptor)
    for path in [
      "Trusted/openapi.yaml",
      "Trusted/operation-policies.json",
      "Trusted/approval-receipt.json",
      "Config/capability-claim.json",
    ] {
      try builder.captureFile(path, required: true)
    }
    let approvalData = try builder.requireData(
      "API/Trusted/approval-receipt.json"
    )
    let approval = try DeterministicJSON.decode(
      ApprovalReceipt.self,
      from: approvalData
    )
    for path in approval.inputHashes.keys.sorted()
    where !ApprovalInputPathPolicy.isAllowed(path) {
      throw ContractError.invalidApproval(
        "input hash path is not canonical provider authority: \(path)"
      )
    }

    try builder.captureDirectory("Config", required: true)
    for path in [
      "Observed/catalog.json",
      "Observed/source-lock.json",
    ] {
      try builder.captureFile(path, required: false)
    }
    for path in [
      "Observed/verifications",
      "Observed/verification",
      "Observed/source-verifications",
      "Observed/collection-verifications",
    ] {
      try builder.captureDirectory(path, required: false)
    }
    for approvedPath in approval.inputHashes.keys.sorted() {
      let relative = try Self.apiRelativePath(approvedPath)
      try builder.captureFile(relative, required: false, refresh: true)
    }
    if includePublished {
      try builder.captureDirectory("Published", required: true)
    }

    // Every captured authority byte and directory membership must still be
    // the same generation when the snapshot completes.
    for path in builder.files.keys.sorted()
    where !path.hasPrefix("API/Published/") {
      try builder.captureFile(
        String(path.dropFirst("API/".count)),
        required: true,
        refresh: true
      )
    }
    try builder.verifyCapturedDirectories()
    files = builder.files
    directories = builder.directories
  }

  func requiredData(_ path: String) throws -> Data {
    guard let data = files[path] else { throw ContractError.missingFile(path) }
    return data
  }

  func optionalData(_ path: String) -> Data? {
    files[path]
  }

  func containsDirectory(_ path: String) -> Bool {
    directories.contains(path)
  }

  func directFiles(in directory: String) -> [(path: String, data: Data)] {
    let prefix = directory.hasSuffix("/") ? directory : directory + "/"
    return files.keys.sorted().compactMap { path in
      guard path.hasPrefix(prefix) else { return nil }
      let remainder = path.dropFirst(prefix.count)
      guard !remainder.isEmpty, !remainder.contains("/"),
        let data = files[path]
      else { return nil }
      return (path, data)
    }
  }

  func recursiveFiles(in directory: String) -> [(path: String, data: Data)] {
    let prefix = directory.hasSuffix("/") ? directory : directory + "/"
    return files.keys.sorted().compactMap { path in
      guard path.hasPrefix(prefix), let data = files[path] else { return nil }
      return (path, data)
    }
  }

  private static func apiRelativePath(_ path: String) throws -> String {
    let components = path.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map(String.init)
    guard ApprovalInputPathPolicy.isAllowed(path),
      components.count >= 3,
      components.first == "API",
      components.dropFirst().allSatisfy(validName)
    else {
      throw ContractError.invalidApproval(
        "input hash path is not a provider-owned API artifact: \(path)"
      )
    }
    return components.dropFirst().joined(separator: "/")
  }

  private struct DirectoryIdentity: Equatable {
    let device: dev_t
    let inode: ino_t

    init(_ metadata: stat) {
      device = metadata.st_dev
      inode = metadata.st_ino
    }

    func matches(_ metadata: stat) -> Bool {
      device == metadata.st_dev && inode == metadata.st_ino
    }
  }

  private struct Builder {
    let apiDescriptor: Int32
    var files: [String: Data] = [:]
    var directories: Set<String> = ["API"]
    var rootIdentities: [String: DirectoryIdentity] = [:]
    var directoryIdentities: [String: DirectoryIdentity] = [:]
    var directoryEntries: [String: Set<String>] = [:]
    var remainingEntries = ProviderAPIAuthoritySnapshot.maximumEntries
    var remainingBytes = ProviderAPIAuthoritySnapshot.maximumTreeBytes

    init(apiDescriptor: Int32) throws {
      self.apiDescriptor = apiDescriptor
      try bindRoot("Trusted", required: true)
      try bindRoot("Config", required: true)
      try bindRoot("Observed", required: false)
    }

    func verifyCapturedDirectories() throws {
      for path in directoryEntries.keys.sorted() {
        let relative = String(path.dropFirst("API/".count))
        let components = try pathComponents(relative)
        guard let descriptor = try openDirectoryPath(components),
          let identity = directoryIdentities[path],
          let expectedEntries = directoryEntries[path]
        else { throw ContractError.publicationIndeterminate(path) }
        var current = stat()
        let actualEntries: Set<String>
        do {
          guard fstat(descriptor, &current) == 0,
            identity.matches(current)
          else { throw ContractError.publicationIndeterminate(path) }
          actualEntries = Set(try entryNames(in: descriptor))
        } catch {
          _ = Darwin.close(descriptor)
          throw error
        }
        guard Darwin.close(descriptor) == 0,
          actualEntries == expectedEntries
        else { throw ContractError.publicationIndeterminate(path) }
      }
    }

    private mutating func bindRoot(
      _ name: String,
      required: Bool
    ) throws {
      if rootIdentities[name] != nil { return }
      var metadata = stat()
      let status = name.withCString {
        Darwin.fstatat(apiDescriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
      }
      if status != 0, errno == ENOENT, !required { return }
      guard status == 0, Self.isOwnedDirectory(metadata) else {
        throw required
          ? ContractError.invalidDirectory("API/\(name)")
          : ContractError.publicationIndeterminate("API/\(name)")
      }
      let identity = DirectoryIdentity(metadata)
      let descriptor = try openDirectory(
        named: name,
        expected: identity,
        under: apiDescriptor,
        evidencePath: "API/\(name)"
      )
      _ = Darwin.close(descriptor)
      rootIdentities[name] = identity
      directoryIdentities["API/\(name)"] = identity
    }

    mutating func captureFile(
      _ relativePath: String,
      required: Bool,
      refresh: Bool = false
    ) throws {
      let components = try pathComponents(relativePath)
      if let root = components.first {
        try bindRoot(root, required: required)
      }
      let fileName = try requireValue(components.last)
      guard let parent = try openDirectoryPath(Array(components.dropLast()))
      else {
        if required { throw ContractError.missingFile("API/\(relativePath)") }
        return
      }
      defer { _ = Darwin.close(parent) }
      guard
        let data = try readFile(
          named: fileName,
          under: parent,
          required: required,
          evidencePath: "API/\(relativePath)"
        )
      else { return }
      let path = "API/\(relativePath)"
      if let existing = files[path] {
        guard !refresh || existing == data else {
          throw ContractError.publicationIndeterminate(path)
        }
      } else {
        guard remainingEntries > 0,
          remainingBytes >= data.count
        else { throw ContractError.publicationIndeterminate(path) }
        remainingEntries -= 1
        remainingBytes -= data.count
        files[path] = data
      }
    }

    mutating func captureDirectory(
      _ relativePath: String,
      required: Bool
    ) throws {
      let components = try pathComponents(relativePath)
      if let root = components.first {
        try bindRoot(root, required: required)
      }
      guard let descriptor = try openDirectoryPath(components) else {
        if required {
          throw ContractError.invalidDirectory("API/\(relativePath)")
        }
        return
      }
      defer { _ = Darwin.close(descriptor) }
      let path = "API/\(relativePath)"
      var metadata = stat()
      guard fstat(descriptor, &metadata) == 0 else {
        throw ContractError.publicationIndeterminate(path)
      }
      let identity = DirectoryIdentity(metadata)
      if let existing = directoryIdentities[path] {
        guard existing == identity else {
          throw ContractError.publicationIndeterminate(path)
        }
      } else {
        directoryIdentities[path] = identity
      }
      directories.insert(path)
      try captureContents(
        of: descriptor,
        prefix: path,
        depth: components.count
      )
    }

    func requireData(_ path: String) throws -> Data {
      guard let data = files[path] else { throw ContractError.missingFile(path) }
      return data
    }

    private mutating func captureContents(
      of descriptor: Int32,
      prefix: String,
      depth: Int
    ) throws {
      guard depth <= ProviderAPIAuthoritySnapshot.maximumDepth else {
        throw ContractError.publicationIndeterminate(prefix)
      }
      let names = try entryNames(in: descriptor)
      let entries = Set(names)
      if let existing = directoryEntries[prefix] {
        guard existing == entries else {
          throw ContractError.publicationIndeterminate(prefix)
        }
      } else {
        directoryEntries[prefix] = entries
      }
      for name in names {
        guard remainingEntries > 0 else {
          throw ContractError.publicationIndeterminate(prefix)
        }
        let path = "\(prefix)/\(name)"
        var metadata = stat()
        guard
          name.withCString({
            Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
          }) == 0
        else { throw ContractError.publicationIndeterminate(path) }
        if Self.isOwnedDirectory(metadata) {
          remainingEntries -= 1
          let identity = DirectoryIdentity(metadata)
          if let existing = directoryIdentities[path] {
            guard existing == identity else {
              throw ContractError.publicationIndeterminate(path)
            }
          } else {
            directoryIdentities[path] = identity
          }
          let child = try openDirectory(
            named: name,
            expected: identity,
            under: descriptor,
            evidencePath: path
          )
          do {
            directories.insert(path)
            try captureContents(
              of: child,
              prefix: path,
              depth: depth + 1
            )
            var final = stat()
            var finalPath = stat()
            guard fstat(child, &final) == 0,
              identity.matches(final),
              name.withCString({
                Darwin.fstatat(
                  descriptor,
                  $0,
                  &finalPath,
                  AT_SYMLINK_NOFOLLOW
                )
              }) == 0,
              identity.matches(finalPath)
            else { throw ContractError.publicationIndeterminate(path) }
          } catch {
            _ = Darwin.close(child)
            throw error
          }
          guard Darwin.close(child) == 0 else {
            throw ContractError.publicationIndeterminate(path)
          }
        } else if Self.isOwnedRegularFile(metadata) {
          guard
            let data = try readFile(
              named: name,
              under: descriptor,
              required: true,
              evidencePath: path
            ), remainingBytes >= data.count
          else { throw ContractError.publicationIndeterminate(path) }
          remainingEntries -= 1
          remainingBytes -= data.count
          if let existing = files[path] {
            guard existing == data else {
              throw ContractError.publicationIndeterminate(path)
            }
          } else {
            files[path] = data
          }
        } else {
          throw ContractError.symbolicLink(path)
        }
      }
    }

    private func openDirectoryPath(_ components: [String]) throws -> Int32? {
      var descriptor = Darwin.dup(apiDescriptor)
      guard descriptor >= 0 else {
        throw ContractError.publicationIndeterminate("API")
      }
      for (index, component) in components.enumerated() {
        var metadata = stat()
        let status = component.withCString {
          Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
        }
        if status != 0, errno == ENOENT {
          _ = Darwin.close(descriptor)
          return nil
        }
        guard status == 0, Self.isOwnedDirectory(metadata) else {
          _ = Darwin.close(descriptor)
          throw ContractError.invalidDirectory(component)
        }
        let expected =
          index == 0
          ? rootIdentities[component] ?? DirectoryIdentity(metadata)
          : DirectoryIdentity(metadata)
        guard expected.matches(metadata) else {
          _ = Darwin.close(descriptor)
          throw ContractError.publicationIndeterminate("API/\(component)")
        }
        let next = try openDirectory(
          named: component,
          expected: expected,
          under: descriptor,
          evidencePath: component
        )
        _ = Darwin.close(descriptor)
        descriptor = next
      }
      return descriptor
    }

    private func openDirectory(
      named name: String,
      expected: DirectoryIdentity,
      under descriptor: Int32,
      evidencePath: String
    ) throws -> Int32 {
      let child = name.withCString {
        Darwin.openat(
          descriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      var opened = stat()
      var current = stat()
      guard child >= 0,
        fstat(child, &opened) == 0,
        Self.isOwnedDirectory(opened),
        expected.matches(opened),
        name.withCString({
          Darwin.fstatat(descriptor, $0, &current, AT_SYMLINK_NOFOLLOW)
        }) == 0,
        expected.matches(current)
      else {
        if child >= 0 { _ = Darwin.close(child) }
        throw ContractError.publicationIndeterminate(evidencePath)
      }
      return child
    }

    private func readFile(
      named name: String,
      under descriptor: Int32,
      required: Bool,
      evidencePath: String
    ) throws -> Data? {
      var pathMetadata = stat()
      let status = name.withCString {
        Darwin.fstatat(descriptor, $0, &pathMetadata, AT_SYMLINK_NOFOLLOW)
      }
      if status != 0, errno == ENOENT {
        if required { throw ContractError.missingFile(evidencePath) }
        return nil
      }
      guard status == 0,
        Self.isOwnedRegularFile(pathMetadata),
        pathMetadata.st_size >= 0,
        pathMetadata.st_size
          <= ProviderAPIAuthoritySnapshot.maximumAuthorityFileBytes
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
        Self.isOwnedRegularFile(opened),
        opened.st_dev == pathMetadata.st_dev,
        opened.st_ino == pathMetadata.st_ino,
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
        final.st_dev == opened.st_dev,
        final.st_ino == opened.st_ino,
        final.st_size == opened.st_size,
        final.st_mtimespec.tv_sec == opened.st_mtimespec.tv_sec,
        final.st_mtimespec.tv_nsec == opened.st_mtimespec.tv_nsec,
        final.st_ctimespec.tv_sec == opened.st_ctimespec.tv_sec,
        final.st_ctimespec.tv_nsec == opened.st_ctimespec.tv_nsec,
        finalPath.st_dev == opened.st_dev,
        finalPath.st_ino == opened.st_ino,
        finalPath.st_size == opened.st_size,
        finalPath.st_mtimespec.tv_sec == opened.st_mtimespec.tv_sec,
        finalPath.st_mtimespec.tv_nsec == opened.st_mtimespec.tv_nsec,
        finalPath.st_ctimespec.tv_sec == opened.st_ctimespec.tv_sec,
        finalPath.st_ctimespec.tv_nsec == opened.st_ctimespec.tv_nsec
      else { throw ContractError.publicationIndeterminate(evidencePath) }
      return data
    }

    private func entryNames(in descriptor: Int32) throws -> [String] {
      let duplicate = Darwin.dup(descriptor)
      guard duplicate >= 0, let stream = Darwin.fdopendir(duplicate) else {
        if duplicate >= 0 { _ = Darwin.close(duplicate) }
        throw ContractError.publicationIndeterminate("API")
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
          guard Self.validName(name) else {
            throw ContractError.publicationIndeterminate(name)
          }
          names.append(name)
          guard names.count <= ProviderAPIAuthoritySnapshot.maximumEntries
          else { throw ContractError.publicationIndeterminate("API") }
        }
      }
      return names.sorted()
    }

    private func pathComponents(_ path: String) throws -> [String] {
      let components = path.split(
        separator: "/",
        omittingEmptySubsequences: false
      ).map(String.init)
      guard !path.hasPrefix("/"),
        !components.isEmpty,
        components.count <= ProviderAPIAuthoritySnapshot.maximumDepth,
        components.allSatisfy(Self.validName)
      else { throw ContractError.publicationIndeterminate(path) }
      return components
    }

    private func readAll(
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

    private func requireValue<Value>(_ value: Value?) throws -> Value {
      guard let value else {
        throw ContractError.publicationIndeterminate("API")
      }
      return value
    }

    private static func validName(_ value: String) -> Bool {
      ProviderAPIAuthoritySnapshot.validName(value)
    }

    private static func isOwnedDirectory(_ metadata: stat) -> Bool {
      metadata.st_mode & S_IFMT == S_IFDIR && metadata.st_uid == geteuid()
    }

    private static func isOwnedRegularFile(_ metadata: stat) -> Bool {
      metadata.st_mode & S_IFMT == S_IFREG && metadata.st_uid == geteuid()
    }
  }

  private static func validName(_ value: String) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && !value.contains("/") && !value.contains("\0")
  }
}

enum ProviderAPIAuthorityReader {
  static func withSharedSnapshot<Result>(
    providerRoot: URL,
    includePublished: Bool = false,
    _ operation: (ProviderAPIAuthoritySnapshot) throws -> Result
  ) throws -> Result {
    let api = providerRoot.standardizedFileURL.appending(
      path: "API",
      directoryHint: .isDirectory
    )
    let descriptor = api.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(
        path,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
      )
    }
    var identity = stat()
    guard descriptor >= 0,
      fstat(descriptor, &identity) == 0,
      identity.st_mode & S_IFMT == S_IFDIR,
      identity.st_uid == geteuid(),
      providerAPIAuthorityFlock(descriptor, LOCK_SH) == 0,
      currentPath(api, matches: identity)
    else {
      if descriptor >= 0 { _ = Darwin.close(descriptor) }
      throw ContractError.publicationIndeterminate(api.path)
    }
    defer {
      _ = providerAPIAuthorityFlock(descriptor, LOCK_UN)
      _ = Darwin.close(descriptor)
    }
    let snapshot = try ProviderAPIAuthoritySnapshot(
      apiDescriptor: descriptor,
      includePublished: includePublished
    )
    let result = try operation(snapshot)
    guard currentPath(api, matches: identity) else {
      throw ContractError.publicationIndeterminate(api.path)
    }
    return result
  }

  private static func currentPath(_ api: URL, matches expected: stat) -> Bool {
    var current = stat()
    return api.withUnsafeFileSystemRepresentation { path in
      guard let path else { return false }
      return Darwin.lstat(path, &current) == 0
        && current.st_mode & S_IFMT == S_IFDIR
        && current.st_uid == geteuid()
        && current.st_dev == expected.st_dev
        && current.st_ino == expected.st_ino
    }
  }
}
