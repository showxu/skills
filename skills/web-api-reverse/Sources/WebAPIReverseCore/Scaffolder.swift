import Foundation

public struct ScaffoldResult: Codable, Equatable, Sendable {
  public let providerRoot: String
  public let createdDirectories: [String]
  public let createdFiles: [String]
}

public struct ProviderScaffolder: Sendable {
  public init() {}

  public func scaffold(
    providerRoot: URL,
    provider: String? = nil,
    market: String = "cn",
    fileManager: FileManager = .default
  ) throws -> ScaffoldResult {
    let directories = [
      "API/Config",
      "API/Observed",
      "API/Trusted",
      "API/Published",
    ]
    for directory in directories {
      try fileManager.createDirectory(
        at: providerRoot.appending(path: directory, directoryHint: .isDirectory),
        withIntermediateDirectories: true
      )
    }
    var createdFiles: [String] = []
    if let provider {
      let files: [(String, Data)] = [
        (
          "API/Config/source-manifest.json",
          try DeterministicJSON.encode(
            SourceManifest(
              brand: provider,
              market: market,
              requiredCoverageAreas: [],
              sources: []
            )
          )
        ),
        (
          "API/Config/operation-annotations.json",
          try DeterministicJSON.encode(
            AnnotationFile(
              brand: provider,
              market: market,
              operations: []
            )
          )
        ),
        (
          "API/Config/trust-manifest.json",
          try DeterministicJSON.encode(
            TrustManifest(
              brand: provider,
              market: market,
              reviewedAt: "",
              operations: []
            )
          )
        ),
      ]
      for (path, data) in files {
        let destination = providerRoot.appending(path: path)
        guard !fileManager.fileExists(atPath: destination.path) else {
          continue
        }
        try data.write(to: destination, options: .atomic)
        createdFiles.append(path)
      }
    }
    return ScaffoldResult(
      providerRoot: providerRoot.path,
      createdDirectories: directories,
      createdFiles: createdFiles.sorted()
    )
  }
}
