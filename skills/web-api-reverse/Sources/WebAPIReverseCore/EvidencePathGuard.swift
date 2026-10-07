import Darwin
import Foundation

public enum EvidencePathError: Error, Equatable, LocalizedError {
  case privateStateInsideAPI(String)
  case nonObservedWrite(String)
  case nonTrustedWrite(String)
  case unsafePath(String)

  public var errorDescription: String? {
    switch self {
    case .privateStateInsideAPI(let path):
      "Private browser/session state must be outside API/: \(path)"
    case .nonObservedWrite(let path):
      "Discovery output inside API/ must be written under API/Observed/: \(path)"
    case .nonTrustedWrite(let path):
      "Trust projection must target API/Trusted/: \(path)"
    case .unsafePath(let path):
      "Evidence path cannot be resolved without following an unsafe component: \(path)"
    }
  }
}

public enum EvidencePathGuard {
  public static func requirePrivateStateOutsideAPI(_ url: URL) throws {
    let components = try resolvedComponents(url)
    guard !containsAPIRoot(components) else {
      throw EvidencePathError.privateStateInsideAPI(url.path)
    }
  }

  public static func requireObservedWrite(_ url: URL) throws {
    let components = try resolvedComponents(url)
    guard let apiIndex = apiRootIndex(components) else {
      return
    }
    guard components.indices.contains(apiIndex + 1),
      components[apiIndex + 1] == "Observed"
    else {
      throw EvidencePathError.nonObservedWrite(url.path)
    }
  }

  public static func requireTrustedDirectory(_ url: URL) throws {
    let components = try resolvedComponents(url)
    guard let apiIndex = apiRootIndex(components),
      components.indices.contains(apiIndex + 1),
      components[apiIndex + 1] == "Trusted",
      components.count == apiIndex + 2
    else {
      throw EvidencePathError.nonTrustedWrite(url.path)
    }
  }

  private static func containsAPIRoot(_ components: [String]) -> Bool {
    apiRootIndex(components) != nil
  }

  private static func apiRootIndex(_ components: [String]) -> Int? {
    components.indices.last { components[$0] == "API" }
  }

  private static func resolvedComponents(_ url: URL) throws -> [String] {
    guard url.isFileURL, url.path.hasPrefix("/") else {
      throw EvidencePathError.unsafePath(url.path)
    }
    var candidate = url.standardizedFileURL
    var missing: [String] = []
    while true {
      let pointer = candidate.withUnsafeFileSystemRepresentation { path in
        guard let path else { return UnsafeMutablePointer<CChar>?.none }
        return Darwin.realpath(path, nil)
      }
      if let pointer {
        defer { Darwin.free(pointer) }
        var resolved = URL(
          fileURLWithPath: String(cString: pointer),
          isDirectory: true
        )
        for component in missing.reversed() {
          resolved.append(path: component)
        }
        return resolved.standardizedFileURL.pathComponents.filter {
          $0 != "/"
        }
      }
      guard errno == ENOENT else {
        throw EvidencePathError.unsafePath(url.path)
      }
      let parent = candidate.deletingLastPathComponent()
      guard parent.path != candidate.path else {
        throw EvidencePathError.unsafePath(url.path)
      }
      missing.append(candidate.lastPathComponent)
      candidate = parent
    }
  }
}
