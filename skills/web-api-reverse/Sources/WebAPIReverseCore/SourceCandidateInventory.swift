import Darwin
import Foundation

public struct SourceCandidateInventoryPolicy:
  Codable, Equatable, Sendable
{
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let platformProvider: String
  public let allowedHosts: [String]
  public let productIdentifierKeys: [String]
  public let minimumIdentifierLength: Int
  public let maximumIdentifierLength: Int
  public let maximumBodyBytes: Int

  public init(
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.source-candidate-inventory-policy",
    provider: String,
    market: String,
    platformProvider: String,
    allowedHosts: [String],
    productIdentifierKeys: [String],
    minimumIdentifierLength: Int = 8,
    maximumIdentifierLength: Int = 16,
    maximumBodyBytes: Int = 2_000_000
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.provider = provider
    self.market = market
    self.platformProvider = platformProvider
    self.allowedHosts = allowedHosts
    self.productIdentifierKeys = productIdentifierKeys
    self.minimumIdentifierLength = minimumIdentifierLength
    self.maximumIdentifierLength = maximumIdentifierLength
    self.maximumBodyBytes = maximumBodyBytes
  }
}

public struct SourceCandidateOccurrence: Codable, Equatable, Sendable {
  public let exchangeIndex: Int
  public let host: String
  public let location: String
  public let field: String
  public let jsonPath: String?

  public init(
    exchangeIndex: Int,
    host: String,
    location: String,
    field: String,
    jsonPath: String? = nil
  ) {
    self.exchangeIndex = exchangeIndex
    self.host = host
    self.location = location
    self.field = field
    self.jsonPath = jsonPath
  }
}

public struct SourceProductCandidate: Codable, Equatable, Sendable {
  public let externalProductID: String
  public let occurrences: [SourceCandidateOccurrence]

  public init(
    externalProductID: String,
    occurrences: [SourceCandidateOccurrence]
  ) {
    self.externalProductID = externalProductID
    self.occurrences = occurrences
  }
}

public struct SourceCandidateInventory: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let platformProvider: String
  public let harSHA256: String
  public let scannedExchangeCount: Int
  public let candidates: [SourceProductCandidate]

  public init(
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.private-source-candidate-inventory",
    provider: String,
    market: String,
    platformProvider: String,
    harSHA256: String,
    scannedExchangeCount: Int,
    candidates: [SourceProductCandidate]
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.provider = provider
    self.market = market
    self.platformProvider = platformProvider
    self.harSHA256 = harSHA256
    self.scannedExchangeCount = scannedExchangeCount
    self.candidates = candidates
  }
}

public enum SourceCandidateInventoryError:
  Error, Equatable, LocalizedError
{
  case invalidPolicy(String)
  case invalidHAR
  case outputAlreadyExists(String)
  case symbolicLink(String)

  public var errorDescription: String? {
    switch self {
    case .invalidPolicy(let reason):
      "Invalid source-candidate inventory policy: \(reason)"
    case .invalidHAR:
      "The source-candidate input is not a valid HAR document."
    case .outputAlreadyExists(let path):
      "Private source-candidate output already exists: \(path)"
    case .symbolicLink(let path):
      "Private source-candidate output cannot use a symbolic link: \(path)"
    }
  }
}

public struct SourceCandidateInventoryBuilder: Sendable {
  public init() {}

  public func inventory(
    harURL: URL,
    policy: SourceCandidateInventoryPolicy
  ) throws -> SourceCandidateInventory {
    try inventory(harData: Data(contentsOf: harURL), policy: policy)
  }

  public func inventory(
    harData: Data,
    policy: SourceCandidateInventoryPolicy
  ) throws -> SourceCandidateInventory {
    let normalizedPolicy = try validate(policy)
    let document: HARDocument
    do {
      document = try JSONDecoder().decode(HARDocument.self, from: harData)
    } catch {
      throw SourceCandidateInventoryError.invalidHAR
    }

    var occurrences: [String: Set<SourceCandidateOccurrence>] = [:]
    var scannedExchangeCount = 0
    for (index, entry) in document.log.entries.enumerated() {
      guard let components = URLComponents(string: entry.request.url),
        let rawHost = components.host
      else {
        continue
      }
      let host = rawHost.lowercased()
      guard normalizedPolicy.allowedHosts.contains(host) else {
        continue
      }
      scannedExchangeCount += 1

      for item in components.queryItems ?? [] {
        collectIdentifier(
          item.value,
          field: item.name,
          path: nil,
          exchangeIndex: index,
          host: host,
          location: "request-query",
          policy: normalizedPolicy,
          occurrences: &occurrences
        )
        parseNestedText(
          item.value,
          path: "$query.\(item.name)",
          exchangeIndex: index,
          host: host,
          location: "request-query",
          policy: normalizedPolicy,
          occurrences: &occurrences
        )
      }

      for parameter in entry.request.postData?.params ?? [] {
        collectIdentifier(
          parameter.value,
          field: parameter.name,
          path: nil,
          exchangeIndex: index,
          host: host,
          location: "request-body",
          policy: normalizedPolicy,
          occurrences: &occurrences
        )
        parseNestedText(
          parameter.value,
          path: "$body.\(parameter.name)",
          exchangeIndex: index,
          host: host,
          location: "request-body",
          policy: normalizedPolicy,
          occurrences: &occurrences
        )
      }
      parseBody(
        entry.request.postData?.text,
        exchangeIndex: index,
        host: host,
        location: "request-body",
        policy: normalizedPolicy,
        occurrences: &occurrences
      )
      if entry.response.content?.encoding?.lowercased() != "base64" {
        parseBody(
          entry.response.content?.text,
          exchangeIndex: index,
          host: host,
          location: "response-body",
          policy: normalizedPolicy,
          occurrences: &occurrences
        )
      }
    }

    let candidates = occurrences.keys.sorted().map { identifier in
      SourceProductCandidate(
        externalProductID: identifier,
        occurrences: (occurrences[identifier] ?? []).sorted(by: occurrenceOrder)
      )
    }
    return SourceCandidateInventory(
      provider: normalizedPolicy.provider,
      market: normalizedPolicy.market,
      platformProvider: normalizedPolicy.platformProvider,
      harSHA256: FileDigest.sha256(data: harData),
      scannedExchangeCount: scannedExchangeCount,
      candidates: candidates
    )
  }

  private func validate(
    _ policy: SourceCandidateInventoryPolicy
  ) throws -> NormalizedPolicy {
    guard policy.schemaVersion == 1 else {
      throw SourceCandidateInventoryError.invalidPolicy(
        "schemaVersion must be 1"
      )
    }
    guard policy.kind == "web-api-reverse.source-candidate-inventory-policy" else {
      throw SourceCandidateInventoryError.invalidPolicy("kind is unsupported")
    }
    guard !policy.provider.isEmpty, !policy.market.isEmpty,
      !policy.platformProvider.isEmpty
    else {
      throw SourceCandidateInventoryError.invalidPolicy(
        "provider, market, and platformProvider are required"
      )
    }
    let hosts = Set(
      policy.allowedHosts.map { $0.lowercased() }.filter { !$0.isEmpty }
    )
    let keys = Set(
      policy.productIdentifierKeys.map(normalizedKey).filter { !$0.isEmpty }
    )
    guard !hosts.isEmpty, !keys.isEmpty else {
      throw SourceCandidateInventoryError.invalidPolicy(
        "allowedHosts and productIdentifierKeys cannot be empty"
      )
    }
    guard policy.minimumIdentifierLength > 0,
      policy.maximumIdentifierLength >= policy.minimumIdentifierLength,
      policy.maximumIdentifierLength <= 64
    else {
      throw SourceCandidateInventoryError.invalidPolicy(
        "identifier length bounds are invalid"
      )
    }
    guard (1...10_000_000).contains(policy.maximumBodyBytes) else {
      throw SourceCandidateInventoryError.invalidPolicy(
        "maximumBodyBytes must be between 1 and 10000000"
      )
    }
    return NormalizedPolicy(
      provider: policy.provider,
      market: policy.market,
      platformProvider: policy.platformProvider,
      allowedHosts: hosts,
      productIdentifierKeys: keys,
      minimumIdentifierLength: policy.minimumIdentifierLength,
      maximumIdentifierLength: policy.maximumIdentifierLength,
      maximumBodyBytes: policy.maximumBodyBytes
    )
  }

  private func parseBody(
    _ text: String?,
    exchangeIndex: Int,
    host: String,
    location: String,
    policy: NormalizedPolicy,
    occurrences: inout [String: Set<SourceCandidateOccurrence>]
  ) {
    guard let text,
      text.utf8.count <= policy.maximumBodyBytes
    else {
      return
    }
    parseForm(
      text,
      exchangeIndex: exchangeIndex,
      host: host,
      location: location,
      policy: policy,
      occurrences: &occurrences
    )
    parseNestedText(
      text,
      path: "$",
      exchangeIndex: exchangeIndex,
      host: host,
      location: location,
      policy: policy,
      occurrences: &occurrences
    )
  }

  private func parseForm(
    _ text: String,
    exchangeIndex: Int,
    host: String,
    location: String,
    policy: NormalizedPolicy,
    occurrences: inout [String: Set<SourceCandidateOccurrence>]
  ) {
    guard text.contains("="),
      let components = URLComponents(string: "https://private.invalid/?\(text)")
    else {
      return
    }
    for item in components.queryItems ?? [] {
      collectIdentifier(
        item.value,
        field: item.name,
        path: nil,
        exchangeIndex: exchangeIndex,
        host: host,
        location: location,
        policy: policy,
        occurrences: &occurrences
      )
      parseNestedText(
        item.value,
        path: "$form.\(item.name)",
        exchangeIndex: exchangeIndex,
        host: host,
        location: location,
        policy: policy,
        occurrences: &occurrences
      )
    }
  }

  private func parseNestedText(
    _ text: String?,
    path: String,
    exchangeIndex: Int,
    host: String,
    location: String,
    policy: NormalizedPolicy,
    occurrences: inout [String: Set<SourceCandidateOccurrence>],
    depth: Int = 0
  ) {
    guard depth <= 3, let text else { return }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty,
      trimmed.utf8.count <= policy.maximumBodyBytes,
      let data = structuredJSONData(trimmed),
      let object = try? JSONSerialization.jsonObject(with: data)
    else {
      return
    }
    walk(
      object,
      path: path,
      exchangeIndex: exchangeIndex,
      host: host,
      location: location,
      policy: policy,
      occurrences: &occurrences,
      depth: depth
    )
  }

  private func walk(
    _ value: Any,
    path: String,
    exchangeIndex: Int,
    host: String,
    location: String,
    policy: NormalizedPolicy,
    occurrences: inout [String: Set<SourceCandidateOccurrence>],
    depth: Int
  ) {
    if let object = value as? [String: Any] {
      for key in object.keys.sorted() {
        guard let child = object[key] else { continue }
        let childPath = "\(path).\(key)"
        collectIdentifier(
          child,
          field: key,
          path: childPath,
          exchangeIndex: exchangeIndex,
          host: host,
          location: location,
          policy: policy,
          occurrences: &occurrences
        )
        if let nested = child as? String {
          parseNestedText(
            nested,
            path: childPath,
            exchangeIndex: exchangeIndex,
            host: host,
            location: location,
            policy: policy,
            occurrences: &occurrences,
            depth: depth + 1
          )
        } else {
          walk(
            child,
            path: childPath,
            exchangeIndex: exchangeIndex,
            host: host,
            location: location,
            policy: policy,
            occurrences: &occurrences,
            depth: depth
          )
        }
      }
    } else if let array = value as? [Any] {
      for (index, child) in array.enumerated() {
        walk(
          child,
          path: "\(path)[\(index)]",
          exchangeIndex: exchangeIndex,
          host: host,
          location: location,
          policy: policy,
          occurrences: &occurrences,
          depth: depth
        )
      }
    }
  }

  private func collectIdentifier(
    _ rawValue: Any?,
    field: String,
    path: String?,
    exchangeIndex: Int,
    host: String,
    location: String,
    policy: NormalizedPolicy,
    occurrences: inout [String: Set<SourceCandidateOccurrence>]
  ) {
    guard policy.productIdentifierKeys.contains(normalizedKey(field)),
      let identifier = identifier(rawValue, policy: policy)
    else {
      return
    }
    occurrences[identifier, default: []].insert(
      SourceCandidateOccurrence(
        exchangeIndex: exchangeIndex,
        host: host,
        location: location,
        field: field,
        jsonPath: path
      )
    )
  }

  private func identifier(
    _ value: Any?,
    policy: NormalizedPolicy
  ) -> String? {
    let candidate: String
    if let value = value as? String {
      candidate = value
    } else if let value = value as? NSNumber {
      candidate = value.stringValue
    } else {
      return nil
    }
    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      (policy.minimumIdentifierLength...policy.maximumIdentifierLength)
        .contains(trimmed.count),
      trimmed.unicodeScalars.allSatisfy({ (48...57).contains($0.value) })
    else {
      return nil
    }
    return trimmed
  }

  private func structuredJSONData(_ value: String) -> Data? {
    if value.hasPrefix("{") || value.hasPrefix("[") {
      return Data(value.utf8)
    }
    guard let open = value.firstIndex(of: "("),
      let close = value.lastIndex(of: ")"),
      open < close
    else {
      return nil
    }
    let payload = value[value.index(after: open)..<close]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard payload.hasPrefix("{") || payload.hasPrefix("[") else {
      return nil
    }
    return Data(payload.utf8)
  }

  private func normalizedKey(_ value: String) -> String {
    value.unicodeScalars.filter(CharacterSet.alphanumerics.contains)
      .map(String.init).joined().lowercased()
  }

  private func occurrenceOrder(
    _ lhs: SourceCandidateOccurrence,
    _ rhs: SourceCandidateOccurrence
  ) -> Bool {
    (
      lhs.exchangeIndex,
      lhs.host,
      lhs.location,
      lhs.field,
      lhs.jsonPath ?? ""
    ) < (
      rhs.exchangeIndex,
      rhs.host,
      rhs.location,
      rhs.field,
      rhs.jsonPath ?? ""
    )
  }
}

public struct PrivateSourceCandidateInventoryWriter {
  private let fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func write(
    _ inventory: SourceCandidateInventory,
    to output: URL
  ) throws {
    try EvidencePathGuard.requirePrivateStateOutsideAPI(output)
    guard !fileManager.fileExists(atPath: output.path) else {
      throw SourceCandidateInventoryError.outputAlreadyExists(output.path)
    }
    let directory = output.deletingLastPathComponent()
    let resolvedDirectory = try resolvedDirectoryPath(directory)
    try EvidencePathGuard.requirePrivateStateOutsideAPI(
      resolvedDirectory.appending(path: output.lastPathComponent)
    )
    var isDirectory: ObjCBool = false
    if !fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
      try fileManager.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: [.posixPermissions: 0o700]
      )
    } else if !isDirectory.boolValue {
      throw SourceCandidateInventoryError.symbolicLink(directory.path)
    }
    try DeterministicJSON.write(inventory, to: output, fileManager: fileManager)
    try fileManager.setAttributes(
      [.posixPermissions: 0o600],
      ofItemAtPath: output.path
    )
  }

  private func resolvedDirectoryPath(_ directory: URL) throws -> URL {
    var existing = directory.standardizedFileURL
    var missingComponents: [String] = []
    while !fileManager.fileExists(atPath: existing.path) {
      let parent = existing.deletingLastPathComponent()
      guard parent.path != existing.path else {
        throw SourceCandidateInventoryError.symbolicLink(directory.path)
      }
      missingComponents.insert(existing.lastPathComponent, at: 0)
      existing = parent
    }

    var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
    let resolved = existing.path.withCString { path in
      realpath(path, &buffer)
    }
    guard resolved != nil else {
      throw SourceCandidateInventoryError.symbolicLink(existing.path)
    }
    let terminator = buffer.firstIndex(of: 0) ?? buffer.endIndex
    let resolvedPath = String(
      decoding: buffer[..<terminator].map(UInt8.init(bitPattern:)),
      as: UTF8.self
    )
    return missingComponents.reduce(
      URL(fileURLWithPath: resolvedPath, isDirectory: true)
    ) { partial, component in
      partial.appending(path: component, directoryHint: .isDirectory)
    }
  }
}

private struct NormalizedPolicy: Sendable {
  let provider: String
  let market: String
  let platformProvider: String
  let allowedHosts: Set<String>
  let productIdentifierKeys: Set<String>
  let minimumIdentifierLength: Int
  let maximumIdentifierLength: Int
  let maximumBodyBytes: Int
}

extension SourceCandidateOccurrence: Hashable {}
