import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Observed inventory builder")
struct InventoryBuilderTests {
  @Test("Groups fingerprints, applies annotations, and locks declared sources")
  func buildsAnnotatedInventory() throws {
    let desktop = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: ["quantity": 1],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )
    let h5 = try importReceipt(
      sourceId: "fixture-cn-h5",
      version: "h5-1",
      productCode: "484204",
      requestExtra: ["note": "sample"],
      capturedAt: "2026-07-29T10:00:00.000Z"
    )
    let fingerprint = try #require(desktop.exchanges.first?.fingerprint)
    let result = try InventoryBuilder.build(
      receipts: [h5, desktop],
      annotations: AnnotationFile(
        brand: "fixture",
        market: "cn",
        operations: [
          OperationAnnotation(
            fingerprint: fingerprint,
            operationId: "product.detail",
            serviceFamily: "product",
            productFamily: "current-facts",
            classification: .publicCurrentFact,
            safety: .safeRead,
            authPolicy: .none,
            routePolicy: .fixed(baseURL: "https://api.example.test")
          )
        ]
      ),
      sourceManifest: SourceManifest(
        brand: "fixture",
        market: "cn",
        requiredCoverageAreas: [
          "official-desktop",
          "official-h5",
        ],
        sources: [
          ExpectedSource(
            sourceId: "fixture-cn-web",
            surface: .web,
            version: "web-1",
            coverageAreas: ["official-desktop"]
          ),
          ExpectedSource(
            sourceId: "fixture-cn-h5",
            surface: .h5,
            version: "h5-1",
            coverageAreas: ["official-h5"]
          ),
          ExpectedSource(
            sourceId: "fixture-cn-ios",
            surface: .app,
            version: "ios-1",
            coverageAreas: ["native-ios"],
            coveragePolicy: .deferred,
            coverageRationale: "Reserved for the later app capture phase."
          ),
        ]
      )
    )

    #expect(result.catalog.updatedAt == "2026-07-29T10:00:00.000Z")
    #expect(result.catalog.operations.count == 1)
    let operation = try #require(result.catalog.operations.first)
    #expect(operation.operationId == "product.detail")
    #expect(operation.serviceFamily == "product")
    #expect(operation.classification == .publicCurrentFact)
    #expect(operation.sourceRefs.count == 2)
    #expect(operation.request.queryNames == ["color"])
    guard case .object(let bodySchema) = operation.request.bodySchema,
      case .object(let properties) = bodySchema["properties"],
      case .array(let required) = bodySchema["required"]
    else {
      Issue.record("Expected merged object request schema")
      return
    }
    #expect(Set(properties.keys) == ["note", "productCode", "quantity"])
    #expect(required == [.string("productCode")])

    #expect(result.sourceLock.sources.count == 3)
    #expect(
      result.sourceLock.requiredCoverageAreas
        == ["official-desktop", "official-h5"]
    )
    let desktopLock = try #require(
      result.sourceLock.sources.first { $0.sourceId == "fixture-cn-web" }
    )
    #expect(desktopLock.coverageAreas == ["official-desktop"])
    let missing = try #require(
      result.sourceLock.sources.first { $0.sourceId == "fixture-cn-ios" }
    )
    #expect(missing.status == .missing)
    #expect(missing.sha256.isEmpty)
    #expect(missing.coveragePolicy == .deferred)
  }

  @Test("Conflicting SHA for one source revision is rejected")
  func sourceSHAConflictFails() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )
    let conflicting = CaptureReceipt(
      captureId: "cap_conflicting",
      capturedAt: "2026-07-29T10:00:00.000Z",
      brand: receipt.brand,
      market: receipt.market,
      source: CaptureSource(
        sourceId: receipt.source.sourceId,
        surface: receipt.source.surface,
        version: receipt.source.version,
        sha256: String(repeating: "f", count: 64),
        entryURL: receipt.source.entryURL
      ),
      flow: receipt.flow,
      exchanges: receipt.exchanges
    )

    #expect(
      throws: CapturePipelineError.conflictingSourceSHA(
        "fixture-cn-web@web-1"
      )
    ) {
      try InventoryBuilder.build(receipts: [receipt, conflicting])
    }
  }

  @Test("A manifest rejects an undeclared captured source revision")
  func undeclaredSourceFails() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-2",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )

    #expect(
      throws: CapturePipelineError.undeclaredSourceRevision(
        "fixture-cn-web@web-2"
      )
    ) {
      try InventoryBuilder.build(
        receipts: [receipt],
        sourceManifest: SourceManifest(
          brand: "fixture",
          market: "cn",
          requiredCoverageAreas: ["official-desktop"],
          sources: [
            ExpectedSource(
              sourceId: "fixture-cn-web",
              surface: .web,
              version: "web-1",
              coverageAreas: ["official-desktop"]
            )
          ]
        )
      )
    }
  }

  @Test("A manifest must explicitly assign every required coverage area")
  func missingCoverageAreaAssignmentFails() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )

    #expect(
      throws: CapturePipelineError.unassignedRequiredCoverageArea(
        "authenticated-account"
      )
    ) {
      try InventoryBuilder.build(
        receipts: [receipt],
        sourceManifest: SourceManifest(
          brand: "fixture",
          market: "cn",
          requiredCoverageAreas: [
            "authenticated-account",
            "official-desktop",
          ],
          sources: [
            ExpectedSource(
              sourceId: "fixture-cn-web",
              surface: .web,
              version: "web-1",
              coverageAreas: ["official-desktop"]
            )
          ]
        )
      )
    }
  }

  @Test("Coverage area identifiers and duplicates fail closed")
  func invalidCoverageAreaFails() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )

    #expect(
      throws: CapturePipelineError.invalidCoverageArea("Official Desktop")
    ) {
      try InventoryBuilder.build(
        receipts: [receipt],
        sourceManifest: SourceManifest(
          brand: "fixture",
          market: "cn",
          requiredCoverageAreas: ["Official Desktop"],
          sources: [
            ExpectedSource(
              sourceId: "fixture-cn-web",
              surface: .web,
              version: "web-1",
              coverageAreas: ["Official Desktop"]
            )
          ]
        )
      )
    }

    #expect(
      throws: CapturePipelineError.duplicateCoverageArea(
        scope: "requiredCoverageAreas",
        area: "official-desktop"
      )
    ) {
      try InventoryBuilder.build(
        receipts: [receipt],
        sourceManifest: SourceManifest(
          brand: "fixture",
          market: "cn",
          requiredCoverageAreas: [
            "official-desktop",
            "official-desktop",
          ],
          sources: [
            ExpectedSource(
              sourceId: "fixture-cn-web",
              surface: .web,
              version: "web-1",
              coverageAreas: ["official-desktop"]
            )
          ]
        )
      )
    }
  }

  @Test("A captured source cannot change the manifest surface")
  func sourceSurfaceMismatchFails() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )

    #expect(
      throws: CapturePipelineError.sourceSurfaceMismatch(
        source: "fixture-cn-web@web-1",
        expected: .h5,
        actual: .web
      )
    ) {
      try InventoryBuilder.build(
        receipts: [receipt],
        sourceManifest: SourceManifest(
          brand: "fixture",
          market: "cn",
          requiredCoverageAreas: ["official-h5"],
          sources: [
            ExpectedSource(
              sourceId: "fixture-cn-web",
              surface: .h5,
              version: "web-1",
              coverageAreas: ["official-h5"]
            )
          ]
        )
      )
    }
  }

  @Test("Reloads only successful exact-scope verification evidence")
  func reloadsProvenVerifications() throws {
    let receipt = try importReceipt(
      sourceId: "fixture-cn-web",
      version: "web-1",
      productCode: "484203",
      requestExtra: [:],
      capturedAt: "2026-07-29T09:00:00.000Z"
    )
    let fingerprint = try #require(receipt.exchanges.first?.fingerprint)
    let annotations = AnnotationFile(
      brand: "fixture",
      market: "cn",
      operations: [
        OperationAnnotation(
          fingerprint: fingerprint,
          operationId: "product.detail",
          serviceFamily: "product",
          productFamily: "current-facts",
          classification: .publicCurrentFact,
          safety: .safeRead,
          authPolicy: .none,
          routePolicy: .fixed(baseURL: "https://api.example.test")
        )
      ]
    )
    let initial = try InventoryBuilder.build(
      receipts: [receipt],
      annotations: annotations
    )
    let operation = try #require(initial.catalog.operations.first)
    let response = try #require(operation.responses.first)
    let successful = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_success",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T10:00:00.000Z",
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      sourceRefs: operation.sourceRefs,
      response: response,
      responseFixture: .object(["success": .bool(true)])
    )
    let stale = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_stale",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T11:00:00.000Z",
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      sourceRefs: [
        SourceReference(
          captureId: "cap_old",
          sourceId: "fixture-cn-web",
          sourceVersion: "web-0"
        )
      ],
      response: response,
      responseFixture: .object(["success": .bool(true)])
    )
    let failed = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_failed",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T12:00:00.000Z",
      operationId: operation.operationId,
      fingerprint: operation.fingerprint,
      sourceRefs: operation.sourceRefs,
      response: ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["type": .string("object")]),
        outcome: .businessError,
        businessErrorSignals: ["success=false"]
      ),
      responseFixture: .object(["success": .bool(false)])
    )

    let rebuilt = try InventoryBuilder.build(
      receipts: [receipt],
      annotations: annotations,
      verifications: [stale, successful, failed]
    )

    let rebuiltOperation = try #require(rebuilt.catalog.operations.first)
    #expect(rebuiltOperation.verificationIds == ["ver_success"])
    #expect(rebuilt.catalog.updatedAt == "2026-07-29T12:00:00.000Z")
  }

  @Test("Binds reciprocal reversible receipts across distinct operations")
  func bindsReciprocalReversibleReceipts() throws {
    let capturedAt = "2026-07-29T09:00:00.000Z"
    let receipt = try HARImporter.importHAR(
      data: makeHARData(entries: [
        harEntry(
          url: "https://api.example.test/p/favorites/add",
          startedAt: capturedAt,
          requestBody: ["productCode": "484203"],
          responseBody: ["success": true]
        ),
        harEntry(
          url: "https://api.example.test/p/favorites/remove",
          startedAt: capturedAt,
          requestBody: ["productCode": "484203"],
          responseBody: ["success": true]
        ),
      ]),
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-web",
        sourceVersion: "web-1",
        flow: "favorite-reversible",
        capturedAt: capturedAt
      )
    )
    let addFingerprint = try #require(
      receipt.exchanges.first {
        $0.sanitizedURL.contains("/favorites/add")
      }?.fingerprint
    )
    let removeFingerprint = try #require(
      receipt.exchanges.first {
        $0.sanitizedURL.contains("/favorites/remove")
      }?.fingerprint
    )
    let annotations = AnnotationFile(
      brand: "fixture",
      market: "cn",
      operations: [
        OperationAnnotation(
          fingerprint: addFingerprint,
          operationId: "favorite.add",
          serviceFamily: "favorite",
          productFamily: "remote-collection",
          classification: .authenticatedBusiness,
          safety: .reversibleWrite,
          authPolicy: .sessionHeadersAndCookies,
          routePolicy: .fixed(baseURL: "https://api.example.test")
        ),
        OperationAnnotation(
          fingerprint: removeFingerprint,
          operationId: "favorite.remove",
          serviceFamily: "favorite",
          productFamily: "remote-collection",
          classification: .authenticatedBusiness,
          safety: .reversibleWrite,
          authPolicy: .sessionHeadersAndCookies,
          routePolicy: .fixed(baseURL: "https://api.example.test")
        ),
      ]
    )
    let initial = try InventoryBuilder.build(
      receipts: [receipt],
      annotations: annotations
    )
    let add = try #require(
      initial.catalog.operations.first {
        $0.operationId == "favorite.add"
      }
    )
    let remove = try #require(
      initial.catalog.operations.first {
        $0.operationId == "favorite.remove"
      }
    )
    let proof = TrustRestorationProof(
      required: true,
      proven: true,
      beforeStateSHA256: String(repeating: "a", count: 64),
      mutatedStateSHA256: String(repeating: "b", count: 64),
      restoredStateSHA256: String(repeating: "a", count: 64),
      changedIdentitySHA256: String(repeating: "c", count: 64),
      changedIdentityCount: 1
    )
    let addReceipt = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_add",
      verificationKind: .reversibleWriteReplay,
      verifiedAt: "2026-07-29T10:00:00.000Z",
      operationId: add.operationId,
      fingerprint: add.fingerprint,
      sourceRefs: add.sourceRefs,
      response: try #require(add.responses.first),
      responseFixture: .object(["success": .bool(true)]),
      restoration: TrustRestorationProof(
        required: proof.required,
        proven: proof.proven,
        receiptId: "ver_remove",
        beforeStateSHA256: proof.beforeStateSHA256,
        mutatedStateSHA256: proof.mutatedStateSHA256,
        restoredStateSHA256: proof.restoredStateSHA256,
        changedIdentitySHA256: proof.changedIdentitySHA256,
        changedIdentityCount: proof.changedIdentityCount
      )
    )
    let removeReceipt = TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_remove",
      verificationKind: .reversibleWriteReplay,
      verifiedAt: "2026-07-29T10:00:00.000Z",
      operationId: remove.operationId,
      fingerprint: remove.fingerprint,
      sourceRefs: remove.sourceRefs,
      response: try #require(remove.responses.first),
      responseFixture: .object(["success": .bool(true)]),
      restoration: TrustRestorationProof(
        required: proof.required,
        proven: proof.proven,
        receiptId: "ver_add",
        beforeStateSHA256: proof.beforeStateSHA256,
        mutatedStateSHA256: proof.mutatedStateSHA256,
        restoredStateSHA256: proof.restoredStateSHA256,
        changedIdentitySHA256: proof.changedIdentitySHA256,
        changedIdentityCount: proof.changedIdentityCount
      )
    )

    let rebuilt = try InventoryBuilder.build(
      receipts: [receipt],
      annotations: annotations,
      verifications: [addReceipt, removeReceipt]
    )

    #expect(
      rebuilt.catalog.operations.first {
        $0.operationId == "favorite.add"
      }?.verificationIds == ["ver_add"]
    )
    #expect(
      rebuilt.catalog.operations.first {
        $0.operationId == "favorite.remove"
      }?.verificationIds == ["ver_remove"]
    )
  }

  @Test("Explicit annotation retains a redirected HTML document operation")
  func annotationRetainsRedirectedDocument() throws {
    let capturedAt = "2026-07-29T09:00:00.000Z"
    let imported = try HARImporter.importHAR(
      data: makeHARData(entries: [
        [
          "startedDateTime": capturedAt,
          "time": 12,
          "request": [
            "method": "GET",
            "url": "https://detail.example.test/item.htm?id=484203",
            "headers": [],
          ],
          "response": [
            "status": 200,
            "headers": [
              ["name": "Content-Type", "value": "text/html"]
            ],
            "content": [
              "mimeType": "text/html",
              "text": "<html><body>product</body></html>",
            ],
          ],
        ]
      ]),
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-web",
        sourceVersion: "web-1",
        flow: "product-document",
        capturedAt: capturedAt
      )
    )
    let exchange = try #require(imported.exchanges.first)
    let receipt = CaptureReceipt(
      captureId: imported.captureId,
      capturedAt: imported.capturedAt,
      brand: imported.brand,
      market: imported.market,
      source: CaptureSource(
        sourceId: imported.source.sourceId,
        surface: imported.source.surface,
        version: imported.source.version,
        sha256: imported.source.sha256,
        entryURL: "https://item.example.test/item.htm?id={value}"
      ),
      flow: imported.flow,
      exchanges: imported.exchanges
    )
    let annotations = AnnotationFile(
      brand: "fixture",
      market: "cn",
      operations: [
        OperationAnnotation(
          fingerprint: exchange.fingerprint,
          operationId: "product.document",
          serviceFamily: "product",
          productFamily: "current-facts",
          classification: .publicCurrentFact,
          safety: .safeRead,
          authPolicy: .none,
          routePolicy: .fixed(baseURL: "https://detail.example.test")
        )
      ]
    )

    let result = try InventoryBuilder.build(
      receipts: [receipt],
      annotations: annotations
    )

    let operation = try #require(result.catalog.operations.first)
    #expect(result.catalog.operations.count == 1)
    #expect(operation.operationId == "product.document")
    #expect(operation.fingerprint == exchange.fingerprint)
    #expect(operation.responses.first?.contentType == "text/html")
    #expect(
      result.sourceLock.sources.first?.operationFingerprints
        == [exchange.fingerprint]
    )
  }
}

private func importReceipt(
  sourceId: String,
  version: String,
  productCode: String,
  requestExtra: [String: Any],
  capturedAt: String
) throws -> CaptureReceipt {
  var request: [String: Any] = ["productCode": productCode]
  request.merge(requestExtra) { _, new in new }
  let data = try makeHARData(entries: [
    harEntry(
      url: "https://api.example.test/p/products/\(productCode)?color=09",
      startedAt: capturedAt,
      requestBody: request,
      responseBody: [
        "success": true,
        "data": ["productCode": productCode],
      ]
    )
  ])
  return try HARImporter.importHAR(
    data: data,
    options: HARImportOptions(
      brand: "fixture",
      market: "cn",
      surface: sourceId.hasSuffix("h5") ? .h5 : .web,
      sourceId: sourceId,
      sourceVersion: version,
      flow: "product-current-facts",
      capturedAt: capturedAt
    )
  )
}
