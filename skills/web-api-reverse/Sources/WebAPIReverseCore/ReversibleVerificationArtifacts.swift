import Foundation

public struct ReversibleVerificationArtifactPaths:
  Codable,
  Equatable,
  Sendable
{
  public let directory: String
  public let sequence: String
  public let readBefore: String
  public let add: String
  public let readMutated: String
  public let remove: String
  public let readRestored: String

  public init(
    directory: String,
    sequence: String,
    readBefore: String,
    add: String,
    readMutated: String,
    remove: String,
    readRestored: String
  ) {
    self.directory = directory
    self.sequence = sequence
    self.readBefore = readBefore
    self.add = add
    self.readMutated = readMutated
    self.remove = remove
    self.readRestored = readRestored
  }
}

public enum ReversibleVerificationArtifactError:
  Error,
  Equatable,
  LocalizedError
{
  case invalidSequenceId(String)
  case invalidOutputDirectory(String)
  case symbolicLink(String)
  case unexpectedFiles([String])
  case sensitiveArtifacts(Int)
  case rollbackFailed(original: String, rollback: String)
  case transactionIndeterminate(String)

  public var errorDescription: String? {
    switch self {
    case .invalidSequenceId(let value):
      "Invalid reversible verification sequence ID: \(value)"
    case .invalidOutputDirectory(let path):
      "Invalid reversible verification output directory: \(path)"
    case .symbolicLink(let path):
      "Reversible verification output cannot use a symbolic link: \(path)"
    case .unexpectedFiles(let files):
      "Reversible verification artifact set is not exact: \(files.joined(separator: ", "))"
    case .sensitiveArtifacts(let count):
      "Reversible verification artifacts contain \(count) sensitive finding(s)."
    case .rollbackFailed(let original, let rollback):
      "Artifact write failed (\(original)); rollback also failed: \(rollback)"
    case .transactionIndeterminate(let path):
      "Reversible verification artifact transaction is indeterminate: \(path)"
    }
  }
}

public struct ReversibleVerificationArtifactWriter {
  private static let fileNames = [
    "add.json",
    "read-before.json",
    "read-mutated.json",
    "read-restored.json",
    "remove.json",
    "sequence.json",
  ]

  private let fileManager: FileManager
  private let interruptionPoint:
    DurableDirectoryReplacementInterruptionPoint?

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    interruptionPoint = nil
  }

  init(
    fileManager: FileManager = .default,
    interruptionPoint: DurableDirectoryReplacementInterruptionPoint
  ) {
    self.fileManager = fileManager
    self.interruptionPoint = interruptionPoint
  }

  public func write(
    _ result: ReversibleVerificationResult,
    under outputRoot: URL
  ) throws -> ReversibleVerificationArtifactPaths {
    try EvidencePathGuard.requireObservedWrite(outputRoot)
    try validateSequenceId(result.sequence.sequenceId)
    try validateOutputRoot(outputRoot)
    try fileManager.createDirectory(
      at: outputRoot,
      withIntermediateDirectories: true
    )

    let destination = outputRoot.appending(
      path: result.sequence.sequenceId,
      directoryHint: .isDirectory
    )
    do {
      let transaction = try DurableDirectoryReplacement(
        destination: destination,
        interruptionPoint: interruptionPoint
      )
      try transaction.replace(
        payloads: try payloads(result)
      ) { findings in
        guard findings.isEmpty else {
          throw ReversibleVerificationArtifactError.sensitiveArtifacts(
            findings.count
          )
        }
      }
    } catch let error as DurableDirectoryReplacementError {
      throw ReversibleVerificationArtifactError.transactionIndeterminate(
        String(describing: error)
      )
    } catch {
      throw error
    }

    return paths(for: destination)
  }

  private func payloads(
    _ result: ReversibleVerificationResult
  ) throws -> [String: Data] {
    [
      "sequence.json": try DeterministicJSON.encode(result.sequence),
      "read-before.json": try DeterministicJSON.encode(
        result.receipts.readBefore
      ),
      "add.json": try DeterministicJSON.encode(result.receipts.add),
      "read-mutated.json": try DeterministicJSON.encode(
        result.receipts.readMutated
      ),
      "remove.json": try DeterministicJSON.encode(result.receipts.remove),
      "read-restored.json": try DeterministicJSON.encode(
        result.receipts.readRestored
      ),
    ]
  }

  private func validateOutputRoot(_ outputRoot: URL) throws {
    guard fileManager.fileExists(atPath: outputRoot.path) else {
      return
    }
    let values = try outputRoot.resourceValues(
      forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
    )
    if values.isSymbolicLink == true {
      throw ReversibleVerificationArtifactError.symbolicLink(
        outputRoot.path
      )
    }
    guard values.isDirectory == true else {
      throw ReversibleVerificationArtifactError.invalidOutputDirectory(
        outputRoot.path
      )
    }
  }

  private func validateExactTree(_ directory: URL) throws {
    let names = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [
        .isRegularFileKey,
        .isSymbolicLinkKey,
      ],
      options: [.skipsHiddenFiles]
    ).map { url -> String in
      let values = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      if values.isSymbolicLink == true {
        throw ReversibleVerificationArtifactError.symbolicLink(url.path)
      }
      guard values.isRegularFile == true else {
        throw ReversibleVerificationArtifactError.unexpectedFiles([
          url.lastPathComponent
        ])
      }
      return url.lastPathComponent
    }.sorted()
    guard names == Self.fileNames else {
      throw ReversibleVerificationArtifactError.unexpectedFiles(names)
    }
  }

  private func validateSequenceId(_ value: String) throws {
    guard value.count == 20,
      value.hasPrefix("rev_"),
      value.dropFirst(4).allSatisfy(\.isHexDigit)
    else {
      throw ReversibleVerificationArtifactError.invalidSequenceId(value)
    }
  }

  private func paths(
    for directory: URL
  ) -> ReversibleVerificationArtifactPaths {
    ReversibleVerificationArtifactPaths(
      directory: directory.path,
      sequence: directory.appending(path: "sequence.json").path,
      readBefore: directory.appending(path: "read-before.json").path,
      add: directory.appending(path: "add.json").path,
      readMutated: directory.appending(path: "read-mutated.json").path,
      remove: directory.appending(path: "remove.json").path,
      readRestored: directory.appending(path: "read-restored.json").path
    )
  }
}
