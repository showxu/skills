import Foundation

public struct ArtifactSanitizationResult: Codable, Equatable, Sendable {
  public let root: String
  public let sanitizedPaths: [String]

  public init(root: String, sanitizedPaths: [String]) {
    self.root = root
    self.sanitizedPaths = sanitizedPaths
  }
}

public struct ArtifactSanitizer: Sendable {
  public init() {}

  public func sanitize(
    root: URL,
    fileManager: FileManager = .default
  ) throws -> ArtifactSanitizationResult {
    let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
    guard
      let enumerator = fileManager.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: [.skipsHiddenFiles]
      )
    else {
      throw ContractError.invalidDirectory(root.path)
    }

    var sanitizedPaths: [String] = []
    for case let file as URL in enumerator {
      let values = try file.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      guard values.isSymbolicLink != true else {
        let resolved = file.resolvingSymlinksInPath().standardizedFileURL
        guard resolved.pathComponents.starts(with: resolvedRoot.pathComponents) else {
          throw ContractError.symbolicLink(file.path)
        }
        continue
      }
      guard values.isRegularFile == true else {
        continue
      }
      let data = try Data(contentsOf: file)
      guard let value = try? DeterministicJSON.decode(JSONValue.self, from: data) else {
        continue
      }
      let sanitized = EvidenceRedactor.redactReusableArtifactMaterial(value)
      guard sanitized != value else {
        continue
      }
      try DeterministicJSON.write(sanitized, to: file, fileManager: fileManager)
      sanitizedPaths.append(file.path)
    }

    return ArtifactSanitizationResult(
      root: root.path,
      sanitizedPaths: sanitizedPaths.sorted()
    )
  }
}
