import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Provider evidence scaffolder")
struct ScaffolderTests {
  @Test("Creates scoped Config skeletons without overwriting review input")
  func createsScopedConfigWithoutOverwrite() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scaffold-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: root) }

    let first = try ProviderScaffolder().scaffold(
      providerRoot: root,
      provider: "fixture",
      market: "cn"
    )
    #expect(
      first.createdFiles == [
        "API/Config/operation-annotations.json",
        "API/Config/source-manifest.json",
        "API/Config/trust-manifest.json",
      ])
    let sourceManifestURL = root.appending(
      path: "API/Config/source-manifest.json"
    )
    let sourceManifest = try DeterministicJSON.decode(
      SourceManifest.self,
      from: Data(contentsOf: sourceManifestURL)
    )
    #expect(sourceManifest.brand == "fixture")
    #expect(sourceManifest.market == "cn")
    #expect(sourceManifest.sources.isEmpty)

    try Data("reviewed\n".utf8).write(
      to: sourceManifestURL,
      options: .atomic
    )
    let second = try ProviderScaffolder().scaffold(
      providerRoot: root,
      provider: "replacement",
      market: "other"
    )
    #expect(second.createdFiles.isEmpty)
    #expect(
      try String(contentsOf: sourceManifestURL, encoding: .utf8)
        == "reviewed\n"
    )
  }
}
