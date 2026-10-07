import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Artifact scanner")
struct ArtifactScannerTests {
  @Test("Finds tokens and personal identifiers")
  func findsSensitiveMaterial() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: "artifact.json")
    try Data(#"{"authorization":"Bearer abcdefghijklmnopqrstuvwxyz","phone":"13800138000"}"#.utf8)
      .write(to: file)

    let findings = try ArtifactScanner().scan(root: root)
    #expect(findings.map(\.reason).contains("phone number"))
    #expect(findings.map(\.reason).contains("bearer credential"))
  }

  @Test(
    "Finds reusable API credential fields",
    arguments: ["api-key", "app_key", "clientId"]
  )
  func findsReusableAPICredentialFields(name: String) {
    let data = Data("{\"\(name)\":\"credential-value\"}".utf8)

    #expect(
      ArtifactScanner().scan(data: data, path: "artifact.json")
        .map(\.reason) == ["API credential", "serialized credential"]
    )
  }

  @Test("Allows a public numeric MTop application identifier")
  func allowsPublicNumericMTopApplicationIdentifier() {
    let data = Data(
      #"{"x-web-api-reverse-route-policy":{"kind":"taobaoMTop","staticQuery":{"appKey":"12574478"}}}"#.utf8
    )

    #expect(ArtifactScanner().scan(data: data, path: "openapi.yaml").isEmpty)
  }

  @Test(
    "Still rejects credential-shaped application keys",
    arguments: [
      #"{"appKey":"credential-value"}"#,
      #"{"appKey":"123456789"}"#,
      #"{"apiKey":"12345678"}"#,
    ]
  )
  func rejectsCredentialShapedApplicationKeys(_ text: String) {
    #expect(
      ArtifactScanner().scan(data: Data(text.utf8), path: "artifact.json")
        .map(\.reason) == ["API credential", "serialized credential"]
    )
  }

  @Test("Finds API credentials embedded in reusable text captures")
  func findsEmbeddedAPICredential() {
    for text in [
      #"<script>window.config={apiKey:'credential-value'}</script>"#,
      #"{\"responseFixture\":\"{\\\"apiKey\\\":\\\"credential-value\\\"}\"}"#,
      #"{\"responseFixture\":\"{\\\"storefront_API_KEY\\\":\\\"credential-value\\\"}\"}"#,
    ] {
      #expect(
        ArtifactScanner().scan(
          data: Data(text.utf8),
          path: "capture.html"
        ).map(\.reason) == ["API credential"]
      )
    }
  }

  @Test("Allows redacted placeholders and public OpenAPI text")
  func allowsSanitizedMaterial() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: "artifact.json")
    try Data(#"{"authorization":"[REDACTED]","productCode":"484203"}"#.utf8)
      .write(to: file)

    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test("Distinguishes public Product IDs from personal identity numbers")
  func distinguishesPublicProductIdentifiers() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let product = root.appending(path: "product.json")
    try Data(#"{"productId":"110105194912310021"}"#.utf8)
      .write(to: product)
    #expect(try ArtifactScanner().scan(root: root).isEmpty)

    let unsafe = root.appending(path: "unsafe.json")
    try Data(#"{"description":"110105194912310021"}"#.utf8)
      .write(to: unsafe)
    #expect(
      try ArtifactScanner().scan(root: root).map(\.reason)
        == ["Chinese identity number"]
    )
  }

  @Test("Finds structured account identity without flagging product identifiers")
  func findsStructuredAccountIdentity() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let unsafe = root.appending(path: "account.json")
    try Data(
      #"{"responseFixture":{"data":{"displayNick":"private","nick":"private","userNumId":"123456"}}}"#
        .utf8
    ).write(to: unsafe)
    let product = root.appending(path: "product.json")
    try Data(
      #"{"name":"SUPIMA COTTON T","productCode":"484203","skuId":"sku-1"}"#.utf8
    ).write(to: product)

    let findings = try ArtifactScanner().scan(root: root)
    #expect(
      findings.map(\.reason) == [
        "embedded private response fixture",
        "structured personal identity",
      ]
    )
  }

  @Test("Rejects private collections nested in JSONP response fixtures")
  func rejectsEmbeddedPrivateCollectionFixture() {
    let privateFixture = Data(
      #"{"responseFixture":"callback({\"data\":{\"favList\":[{\"itemId\":\"1\"}]}})"}"#
        .utf8
    )
    let publicFixture = Data(
      #"{"responseFixture":"callback({\"data\":{\"productId\":\"1\"}})"}"#
        .utf8
    )

    #expect(
      ArtifactScanner().scan(data: privateFixture, path: "private.json")
        .map(\.reason) == ["embedded private response fixture"]
    )
    #expect(
      ArtifactScanner().scan(data: publicFixture, path: "public.json")
        .isEmpty
    )
  }

  @Test("Allows structurally redacted account identity")
  func allowsRedactedAccountIdentity() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: "account.json")
    try Data(
      #"{"data":{"displayNick":"[REDACTED]","nick":"[REDACTED]","userNumId":"[REDACTED]"}}"#.utf8
    ).write(to: file)

    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test("Sanitizer removes account identity and preserves schemas and products")
  func sanitizerIsStructural() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "sanitize-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: "openapi.yaml")
    let input: JSONValue = .object([
      "example": .object([
        "displayNick": .string("private"),
        "nick": .string("private"),
        "userNumId": .string("123456"),
      ]),
      "product": .object([
        "name": .string("SUPIMA COTTON T"),
        "productCode": .string("484203"),
      ]),
      "publicAppKey": .object([
        "appKey": .string("12574478")
      ]),
      "requestEvidence": .object([
        "finalURLTemplate": .string(
          "https://www.zara.cn/sizing-info?clientId=14&locale=zh_CN"
        )
      ]),
      "schema": .object([
        "properties": .object([
          "apiKey": .object(["type": .string("string")]),
          "userNumId": .object(["type": .string("string")]),
        ])
      ]),
      "responseFixture": .string(
        #"<script>window.config={apiKey:'credential-value'}</script><script type="application/ld+json">{"@type":"Product","productId":"547296718"}</script>"#
      ),
    ])
    try DeterministicJSON.write(input, to: file)

    let result = try ArtifactSanitizer().sanitize(root: root)
    let sanitized = try DeterministicJSON.decode(
      JSONValue.self,
      from: Data(contentsOf: file)
    )

    #expect(result.sanitizedPaths.count == 1)
    #expect(result.sanitizedPaths.first?.hasSuffix("/openapi.yaml") == true)
    #expect(!EvidenceRedactor.containsStructuredPersonalMaterial(in: sanitized))
    guard case .object(let object) = sanitized else {
      Issue.record("Expected sanitized document")
      return
    }
    #expect(
      object["product"]
        == .object([
          "name": .string("SUPIMA COTTON T"),
          "productCode": .string("484203"),
        ])
    )
    #expect(
      object["publicAppKey"]
        == .object(["appKey": .string("12574478")])
    )
    #expect(
      object["requestEvidence"]
        == .object([
          "finalURLTemplate": .string(
            "https://www.zara.cn/sizing-info?clientId=14&locale=zh_CN"
          )
        ])
    )
    #expect(
      object["schema"]
        == .object([
          "properties": .object([
            "apiKey": .object(["type": .string("string")]),
            "userNumId": .object(["type": .string("string")])
          ])
        ])
    )
    guard case .string(let responseFixture) = object["responseFixture"] else {
      Issue.record("Expected sanitized textual response fixture")
      return
    }
    #expect(responseFixture.contains("apiKey:'[REDACTED]'") == true)
    #expect(responseFixture.contains("\"productId\":\"547296718\"") == true)
    #expect(ArtifactScanner().scan(data: Data(responseFixture.utf8), path: "fixture.html").isEmpty)
  }

  @Test("Does not treat a phone-like SHA-256 substring as PII")
  func allowsCryptographicFingerprints() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: "artifact.json")
    try Data(
      #"""
      {"fingerprint":"a13800138000bcdef0123456789abcdef0123456789abcdef0123456789abc"}
      """#.utf8
    ).write(to: file)

    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test("Rejects symbolic links even when their target is inside the root")
  func rejectsSymbolicLinks() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let target = root.appending(path: "target.json")
    try Data(#"{"authorization":"Bearer abcdefghijklmnopqrstuvwxyz"}"#.utf8)
      .write(to: target)
    try FileManager.default.createSymbolicLink(
      at: root.appending(path: "linked.json"),
      withDestinationURL: target
    )

    #expect(throws: ContractError.self) {
      try ArtifactScanner().scan(root: root)
    }

    try FileManager.default.removeItem(at: root.appending(path: "linked.json"))

    let outside = FileManager.default.temporaryDirectory
      .appending(path: "outside-\(UUID().uuidString).json")
    try Data("{}".utf8).write(to: outside)
    defer { try? FileManager.default.removeItem(at: outside) }
    try FileManager.default.createSymbolicLink(
      at: root.appending(path: "outside.json"),
      withDestinationURL: outside
    )

    #expect(throws: ContractError.self) {
      try ArtifactScanner().scan(root: root)
    }
  }

  @Test("Allows only the canonical package-local Published OpenAPI projection")
  func allowsCanonicalPublishedOpenAPIProjection() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    let published = root.appending(
      path: "API/Published",
      directoryHint: .isDirectory
    )
    let apiTarget = root.appending(
      path: "Sources/ProviderAPI",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: published,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: apiTarget,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: root) }
    try Data("openapi: 3.1.0\n".utf8).write(
      to: published.appending(path: "openapi.yaml")
    )
    try FileManager.default.createSymbolicLink(
      atPath: apiTarget.appending(path: "openapi.yaml").path,
      withDestinationPath: "../../API/Published/openapi.yaml"
    )

    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test(
    "Skips generated dependency and build directories",
    arguments: [
      ".build",
      ".git",
      ".hg",
      ".svn",
      ".swiftpm",
      "DerivedData",
      "node_modules",
    ]
  )
  func skipsGeneratedDirectories(_ directoryName: String) throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    let generated = root.appending(
      path: directoryName,
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: generated,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let target = generated.appending(path: "target.json")
    try Data(
      #"{"authorization":"Bearer generated-private-credential"}"#.utf8
    ).write(to: target)
    try FileManager.default.createSymbolicLink(
      at: generated.appending(path: "linked.json"),
      withDestinationURL: target
    )

    #expect(try ArtifactScanner().scan(root: root).isEmpty)
  }

  @Test("Scans hidden files")
  func scansHiddenFiles() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = root.appending(path: ".credentials.json")
    try Data(#"{"refresh_token":"private-refresh-token-value"}"#.utf8).write(to: file)

    #expect(try ArtifactScanner().scan(root: root).map(\.reason) == ["serialized credential"])
  }

  @Test("Rejects binary artifacts")
  func rejectsBinaryArtifacts() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "scan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    try Data([0xFF, 0xFE, 0x00]).write(to: root.appending(path: "capture.bin"))

    #expect(try ArtifactScanner().scan(root: root).map(\.reason) == ["non-UTF-8 artifact"])
  }
}
