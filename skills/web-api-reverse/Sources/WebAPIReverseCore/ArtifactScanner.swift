import Foundation

public struct ArtifactFinding: Codable, Equatable, Sendable {
  public let path: String
  public let reason: String

  public init(path: String, reason: String) {
    self.path = path
    self.reason = reason
  }
}

public struct ArtifactScanner: Sendable {
  private static let generatedDirectoryNames: Set<String> = [
    ".build",
    ".git",
    ".hg",
    ".svn",
    ".swiftpm",
    "DerivedData",
    "node_modules",
  ]
  private static let rules: [(String, NSRegularExpression)] = [
    (
      "phone number",
      try! NSRegularExpression(
        pattern:
          #"(?<![A-Fa-f0-9])(?:\+?86[-\s]?)?1[3-9]\d{9}(?![A-Fa-f0-9])"#
      )
    ),
    (
      "email address",
      try! NSRegularExpression(
        pattern: #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#, options: .caseInsensitive)
    ),
    (
      "JWT",
      try! NSRegularExpression(
        pattern: #"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"#)
    ),
    (
      "bearer credential",
      try! NSRegularExpression(
        pattern: #"\bBearer\s+(?!\[REDACTED\])[A-Za-z0-9][A-Za-z0-9._~+/\-]{15,}=*"#,
        options: .caseInsensitive)
    ),
    (
      "API credential",
      try! NSRegularExpression(
        pattern:
          #"(?:^|[^A-Za-z0-9])(?:api[-_]?key|app[-_]?key|client[-_]?id)\b\\*[\"']?\s*[:=]\s*\\*[\"']?(?!\[REDACTED\])[A-Za-z0-9][A-Za-z0-9._~+/@\-]{7,}=*"#,
        options: .caseInsensitive
      )
    ),
    (
      "serialized credential",
      try! NSRegularExpression(
        pattern:
          #""(?:authorization|cookie|access[-_]?token|refresh[-_]?token|id[-_]?token|api[-_]?key|app[-_]?key|client[-_]?id|secret(?:[-_]?key)?|password|session)"\s*:\s*"(?!\[REDACTED\])[^"]+""#,
        options: .caseInsensitive
      )
    ),
  ]
  private static let chineseIdentityNumber = try! NSRegularExpression(
    pattern: #"\b\d{17}[\dXx]\b"#
  )
  private static let publicNumericAppIdentifier = try! NSRegularExpression(
    pattern:
      #"^(?:^|[^A-Za-z0-9])app[-_]?key\b\\*[\"']?\s*[:=]\s*\\*[\"']?\d{8}[\"']?$"#,
    options: .caseInsensitive
  )

  public init() {}

  public func scanFile(_ url: URL) throws -> [ArtifactFinding] {
    let data = try Data(contentsOf: url)
    return scan(data: data, path: url.path)
  }

  public func scan(
    data: Data,
    path: String
  ) -> [ArtifactFinding] {
    guard let text = String(data: data, encoding: .utf8) else {
      return [
        ArtifactFinding(
          path: path,
          reason: "non-UTF-8 artifact"
        )
      ]
    }
    var findings: [ArtifactFinding] = Self.rules.compactMap { reason, expression in
      let range = NSRange(text.startIndex..<text.endIndex, in: text)
      let matches = expression.matches(in: text, range: range)
      guard !matches.isEmpty else {
        return nil
      }
      if (reason == "API credential" || reason == "serialized credential"),
        matches.allSatisfy({ Self.isPublicNumericAppIdentifier($0, in: text) })
      {
        return nil
      }
      return ArtifactFinding(path: path, reason: reason)
    }
    if let value = try? DeterministicJSON.decode(JSONValue.self, from: data) {
      if EvidenceRedactor.containsStructuredChineseIdentityNumber(in: value) {
        findings.append(
          ArtifactFinding(
            path: path,
            reason: "Chinese identity number"
          )
        )
      }
      if EvidenceRedactor.containsStructuredPersonalMaterial(in: value) {
        findings.append(
          ArtifactFinding(
            path: path,
            reason: "structured personal identity"
          )
        )
      }
      if Self.containsEmbeddedPrivateResponseFixture(in: value) {
        findings.append(
          ArtifactFinding(
            path: path,
            reason: "embedded private response fixture"
          )
        )
      }
    } else {
      let range = NSRange(text.startIndex..<text.endIndex, in: text)
      if Self.chineseIdentityNumber.firstMatch(in: text, range: range) != nil {
        findings.append(
          ArtifactFinding(
            path: path,
            reason: "Chinese identity number"
          )
        )
      }
    }
    return findings.sorted { ($0.path, $0.reason) < ($1.path, $1.reason) }
  }

  private static func isPublicNumericAppIdentifier(
    _ match: NSTextCheckingResult,
    in text: String
  ) -> Bool {
    guard let range = Range(match.range, in: text) else { return false }
    let value = String(text[range])
    let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
    return publicNumericAppIdentifier.firstMatch(
      in: value,
      range: fullRange
    )?.range == fullRange
  }

  private static func containsEmbeddedPrivateResponseFixture(
    in value: JSONValue
  ) -> Bool {
    switch value {
    case .object(let object):
      for (key, child) in object {
        if key.filter({ $0.isLetter || $0.isNumber }).lowercased()
          == "responsefixture"
        {
          let payload: JSONValue?
          if case .string(let text) = child {
            payload = embeddedJSON(in: text)
          } else {
            payload = child
          }
          if let payload,
            containsPrivateCollection(in: payload)
              || EvidenceRedactor.containsStructuredPersonalMaterial(
                in: payload
              )
          {
            return true
          }
        }
        if containsEmbeddedPrivateResponseFixture(in: child) {
          return true
        }
      }
      return false
    case .array(let values):
      return values.contains(where: containsEmbeddedPrivateResponseFixture)
    case .string, .number, .bool, .null:
      return false
    }
  }

  private static func embeddedJSON(in text: String) -> JSONValue? {
    if let value = try? DeterministicJSON.decode(
      JSONValue.self,
      from: Data(text.utf8)
    ) {
      return value
    }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let open = trimmed.firstIndex(of: "("),
      let close = trimmed.lastIndex(of: ")"),
      open < close
    else {
      return nil
    }
    return try? DeterministicJSON.decode(
      JSONValue.self,
      from: Data(trimmed[trimmed.index(after: open)..<close].utf8)
    )
  }

  private static func containsPrivateCollection(in value: JSONValue) -> Bool {
    switch value {
    case .object(let object):
      if object.keys.contains(where: {
        $0.filter({ $0.isLetter || $0.isNumber }).lowercased()
          == "favlist"
      }) {
        return true
      }
      return object.values.contains(where: containsPrivateCollection)
    case .array(let values):
      return values.contains(where: containsPrivateCollection)
    case .string, .number, .bool, .null:
      return false
    }
  }

  public func scan(root: URL, fileManager: FileManager = .default) throws -> [ArtifactFinding] {
    var findings: [ArtifactFinding] = []
    guard
      let enumerator = fileManager.enumerator(
        at: root,
        includingPropertiesForKeys: [
          .isDirectoryKey,
          .isRegularFileKey,
          .isSymbolicLinkKey,
        ],
        options: []
      )
    else {
      throw ContractError.invalidDirectory(root.path)
    }

    for case let file as URL in enumerator {
      let values = try file.resourceValues(
        forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
      )
      if Self.generatedDirectoryNames.contains(file.lastPathComponent) {
        if values.isDirectory == true {
          enumerator.skipDescendants()
        }
        continue
      }
      if values.isSymbolicLink == true {
        if try Self.isCanonicalPublishedOpenAPIProjection(
          file,
          under: root,
          fileManager: fileManager
        ) {
          continue
        }
        throw ContractError.symbolicLink(file.path)
      }
      guard values.isRegularFile == true else {
        continue
      }
      findings.append(contentsOf: try scanFile(file))
    }
    return findings.sorted {
      ($0.path, $0.reason) < ($1.path, $1.reason)
    }
  }

  private static func isCanonicalPublishedOpenAPIProjection(
    _ link: URL,
    under root: URL,
    fileManager: FileManager
  ) throws -> Bool {
    let root = root.resolvingSymlinksInPath().standardizedFileURL
    let link = link.standardizedFileURL
    let rootComponents = root.pathComponents
    let linkComponents = link.pathComponents
    guard
      linkComponents.starts(with: rootComponents),
      linkComponents.count > rootComponents.count
    else {
      return false
    }
    let relative = Array(linkComponents.dropFirst(rootComponents.count))
    guard
      let sourcesIndex = relative.lastIndex(of: "Sources"),
      sourcesIndex + 2 == relative.count - 1,
      relative.last == "openapi.yaml"
    else {
      return false
    }
    let destination = try fileManager.destinationOfSymbolicLink(
      atPath: link.path
    )
    guard !destination.hasPrefix("/") else { return false }

    var expected = root
    for component in relative[..<sourcesIndex] {
      expected.append(path: component, directoryHint: .isDirectory)
    }
    expected.append(path: "API", directoryHint: .isDirectory)
    expected.append(path: "Published", directoryHint: .isDirectory)
    expected.append(path: "openapi.yaml")
    let resolvedDestination = URL(
      fileURLWithPath: destination,
      relativeTo: link.deletingLastPathComponent()
    ).standardizedFileURL
    guard resolvedDestination.path == expected.standardizedFileURL.path else {
      return false
    }
    let targetValues = try expected.resourceValues(
      forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
    return targetValues.isRegularFile == true
      && targetValues.isSymbolicLink != true
  }
}
