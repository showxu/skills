import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Private source-product candidate inventory")
struct SourceCandidateInventoryTests {
  @Test("Inventories only reviewed structured fields on allowed hosts")
  func inventoriesStructuredCandidates() throws {
    let policy = SourceCandidateInventoryPolicy(
      provider: "gu",
      market: "cn",
      platformProvider: "taobao",
      allowedHosts: ["h5api.m.tmall.com"],
      productIdentifierKeys: ["itemId", "itemNumId", "auction_id"]
    )
    let inventory = try SourceCandidateInventoryBuilder().inventory(
      harData: Data(Self.har.utf8),
      policy: policy
    )

    #expect(inventory.provider == "gu")
    #expect(inventory.platformProvider == "taobao")
    #expect(inventory.scannedExchangeCount == 2)
    #expect(
      inventory.candidates.map(\.externalProductID)
        == ["1008781687549", "1022177040153", "1057646198562"]
    )
    #expect(inventory.candidates[0].occurrences.count == 2)
    #expect(
      Set(inventory.candidates.flatMap(\.occurrences).map(\.location))
        == ["request-query", "request-body", "response-body"]
    )
    #expect(
      inventory.candidates.allSatisfy { candidate in
        candidate.externalProductID.allSatisfy(\.isNumber)
      }
    )
  }

  @Test("Writes one owner-only private artifact outside API")
  func writesOwnerOnlyPrivateArtifact() throws {
    let root = URL(fileURLWithPath: "/tmp").appending(
      path: "source-candidate-inventory-\(UUID().uuidString)"
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "inventory.json")
    let inventory = SourceCandidateInventory(
      provider: "gu",
      market: "cn",
      platformProvider: "taobao",
      harSHA256: String(repeating: "a", count: 64),
      scannedExchangeCount: 1,
      candidates: []
    )
    let writer = PrivateSourceCandidateInventoryWriter()

    try writer.write(inventory, to: output)

    let attributes = try FileManager.default.attributesOfItem(
      atPath: output.path
    )
    #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    #expect(
      try DeterministicJSON.decode(
        SourceCandidateInventory.self,
        from: Data(contentsOf: output)
      ) == inventory
    )
    #expect(throws: SourceCandidateInventoryError.self) {
      try writer.write(inventory, to: output)
    }
    #expect(throws: EvidencePathError.self) {
      try writer.write(
        inventory,
        to: root.appending(path: "API/Observed/private.json")
      )
    }
  }

  @Test("Rejects unbounded or ambiguous policy")
  func rejectsInvalidPolicy() {
    let policy = SourceCandidateInventoryPolicy(
      provider: "gu",
      market: "cn",
      platformProvider: "taobao",
      allowedHosts: [],
      productIdentifierKeys: ["id"]
    )
    #expect(throws: SourceCandidateInventoryError.self) {
      try SourceCandidateInventoryBuilder().inventory(
        harData: Data(Self.har.utf8),
        policy: policy
      )
    }
  }

  private static let har = #"""
    {
      "log": {
        "entries": [
          {
            "request": {
              "method": "GET",
              "url": "https://h5api.m.tmall.com/h5/detail?itemId=1008781687549"
            },
            "response": {
              "status": 200,
              "content": {
                "mimeType": "application/javascript",
                "text": "mtopjsonp1({\"data\":{\"itemNumId\":\"1022177040153\",\"message\":\"itemId=9999999999999\"}})"
              }
            }
          },
          {
            "request": {
              "method": "POST",
              "url": "https://h5api.m.tmall.com/h5/detail",
              "postData": {
                "mimeType": "application/x-www-form-urlencoded",
                "text": "data=%7B%22auction_id%22%3A%221057646198562%22%2C%22itemId%22%3A%221008781687549%22%7D"
              }
            },
            "response": {"status": 200}
          },
          {
            "request": {
              "method": "GET",
              "url": "https://unreviewed.invalid/?itemId=1099999999999"
            },
            "response": {"status": 200}
          }
        ]
      }
    }
    """#
}
