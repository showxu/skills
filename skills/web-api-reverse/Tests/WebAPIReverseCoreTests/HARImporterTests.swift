import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Deterministic sanitized HAR import")
struct HARImporterTests {
  @Test("A bodyless successful transport does not prove business success")
  func treatsMissingResponseBodyAsUnknown() throws {
    let data = try makeHARData(entries: [
      [
        "startedDateTime": "2026-08-03T10:00:00Z",
        "time": 12,
        "request": [
          "method": "GET",
          "url": "https://api.example.test/product/current",
          "headers": [["name": "Accept", "value": "application/json"]],
        ],
        "response": [
          "status": 200,
          "headers": [
            [
              "name": "Content-Type", "value": "application/json",
            ]
          ],
          "content": ["mimeType": "application/json"],
        ],
      ]
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-current-product",
        sourceVersion: "2026-08-03",
        flow: "product-current-facts"
      )
    )

    #expect(receipt.exchanges.first?.response.outcome == .unknown)
    #expect(
      receipt.exchanges.first?.response.businessErrorSignals
        == ["response-body-unavailable"]
    )
  }

  @Test("All-zero provider codes remain successful at any length")
  func acceptsAllZeroSuccessCodes() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url: "https://api.example.test/session/refresh",
        startedAt: "2026-07-29T09:00:00.000Z",
        requestBody: ["refresh_token": "private-refresh-token"],
        responseBody: [
          "success": true,
          "code": "00000000",
          "message": "success",
          "data": ["accessToken": "private-access-token"],
        ]
      )
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-session",
        sourceVersion: "session-1",
        flow: "session-refresh"
      )
    )

    #expect(receipt.exchanges.first?.response.outcome == .success)
    #expect(
      receipt.exchanges.first?.response.businessErrorSignals.isEmpty == true
    )
  }

  @Test("Risk disposal envelopes require a successful business code")
  func rejectsRiskDisposalEnvelopeWithoutMessage() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url:
          "https://api.m.jd.com/?appid=pc-item-soa&functionId=pc_detailpage_wareBusiness",
        startedAt: "2026-08-01T09:00:00.000Z",
        requestBody: [:],
        responseBody: [
          "code": "605",
          "disposal": [
            "evContent": "private-risk-evidence",
            "rpId": "private-risk-id",
          ],
          "echo": "private-echo",
        ]
      )
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "jd",
        market: "cn",
        surface: .web,
        sourceId: "jd-cn-web-product",
        sourceVersion: "web-1",
        flow: "product-current-facts",
        routeDiscriminatorQueryNames: ["appid", "functionId"]
      )
    )

    #expect(receipt.exchanges.first?.response.outcome == .businessError)
    #expect(
      receipt.exchanges.first?.response.businessErrorSignals
        == ["code=non-success"]
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("private-risk-evidence"))
    #expect(!durable.contains("private-risk-id"))
    #expect(!durable.contains("private-echo"))
  }

  @Test("Response evidence preserves header and Set-Cookie names without values")
  func preservesSanitizedResponseLifecycleNames() throws {
    var entry = harEntry(
      url: "https://api.example.test/session/bootstrap",
      startedAt: "2026-08-02T09:00:00.000Z",
      requestBody: [:],
      responseBody: ["success": true]
    )
    entry["response"] = [
      "status": 200,
      "headers": [
        ["name": "Content-Type", "value": "application/json"],
        [
          "name": "Set-Cookie",
          "value": "session_token=private-value; Path=/; HttpOnly",
        ],
      ],
      "cookies": [
        ["name": "session_token", "value": "private-value"],
        ["name": "refresh_token", "value": "other-private-value"],
      ],
      "content": [
        "mimeType": "application/json",
        "text": jsonString(["success": true]),
      ],
    ]

    let receipt = try HARImporter.importHAR(
      data: try makeHARData(entries: [entry]),
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-session",
        sourceVersion: "session-1",
        flow: "session-bootstrap"
      )
    )

    #expect(
      receipt.exchanges.first?.response.responseHeaderNames
        == ["content-type", "set-cookie"]
    )
    #expect(
      receipt.exchanges.first?.response.setCookieNames
        == ["refresh_token", "session_token"]
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("private-value"))
    #expect(!durable.contains("other-private-value"))
  }

  @Test("Domain object codes are not generic business envelopes")
  func leavesOrdinaryDomainCodeSuccessful() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url: "https://api.example.test/products/style-code",
        startedAt: "2026-08-01T09:00:00.000Z",
        requestBody: [:],
        responseBody: [
          "code": "STYLE-484203",
          "name": "Product",
        ]
      )
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-product",
        sourceVersion: "web-1",
        flow: "product-current-facts"
      )
    )

    #expect(receipt.exchanges.first?.response.outcome == .success)
    #expect(
      receipt.exchanges.first?.response.businessErrorSignals.isEmpty == true
    )
  }

  @Test("JSONP risk challenges are not successful business evidence")
  func rejectsJSONPRiskChallenge() throws {
    let data = try makeHARData(entries: [
      harTextResponseEntry(
        url: "https://h5api.m.tmall.com/h5/mtop.example/1.0/",
        startedAt: "2026-08-02T09:00:00.000Z",
        responseHeaders: [
          ["name": "Content-Type", "value": "application/json;charset=UTF-8"],
          ["name": "bxpunish", "value": "1"],
        ],
        responseBody:
          #"mtopjsonp1({"ret":["RGV587_ERROR::SM::challenge"],"data":{"url":"https://example.test/_____tmd_____/login"}})"#
      )
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-product",
        sourceVersion: "web-1",
        flow: "product-current-facts"
      )
    )

    #expect(receipt.exchanges.first?.response.outcome == .businessError)
    #expect(
      receipt.exchanges.first?.response.businessErrorSignals == [
        "response-header.bxpunish=present",
        "ret=non-success",
      ]
    )
  }

  @Test("Import removes values and keeps REST operation identity stable")
  func importsSanitizedDeterministicReceipt() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url:
          "https://api.example.test/p/products/484203?color=09&access_token=top-secret-value",
        startedAt: "2026-07-29T09:00:00.000Z",
        requestBody: [
          "productCode": "484203",
          "quantity": 1,
        ],
        responseBody: [
          "success": true,
          "data": [
            "productCode": "484203",
            "phone": "13800138000",
          ],
        ]
      ),
      harEntry(
        url:
          "https://api.example.test/p/products/484204?access_token=another-secret&color=10",
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [
          "productCode": "484204",
          "note": "sample-only",
        ],
        responseBody: [
          "success": true,
          "data": [
            "productCode": "484204",
            "email": "person@example.com",
          ],
        ]
      ),
    ])
    let options = HARImportOptions(
      brand: "fixture",
      market: "cn",
      surface: .web,
      sourceId: "fixture-cn-web",
      sourceVersion: "web-1",
      flow: "product-current-facts",
      includeURLPatterns: ["api\\.example\\.test", "api\\.example\\.test"]
    )

    let first = try HARImporter.importHAR(data: data, options: options)
    let second = try HARImporter.importHAR(data: data, options: options)

    #expect(first == second)
    #expect(first.captureId == second.captureId)
    #expect(first.capturedAt == "2026-07-29T10:00:00.000Z")
    #expect(first.source.sha256 == FileDigest.sha256(data: data))
    #expect(
      first.source.entryURL
        == "https://api.example.test/p/products/{segment1}"
    )
    #expect(first.captureSelection?.patterns == ["api\\.example\\.test"])
    #expect(first.captureSelection?.selectedExchangeCount == 2)
    #expect(first.exchanges.count == 2)
    #expect(Set(first.exchanges.map(\.fingerprint)).count == 1)
    #expect(Set(first.exchanges.map(\.operationId)).count == 1)
    #expect(
      first.exchanges.allSatisfy {
        $0.urlTemplate
          == "https://api.example.test/p/products/{segment1}?access_token={access_token}&color={color}"
      })
    #expect(
      first.exchanges.allSatisfy {
        $0.request.headers.map(\.name)
          == ["authorization", "content-type", "cookie"]
      })
    #expect(
      first.exchanges.allSatisfy {
        $0.request.cookieNames == ["region", "session_id"]
      })

    let encoded = String(decoding: try DeterministicJSON.encode(first), as: UTF8.self)
    for secret in [
      "top-secret-value",
      "another-secret",
      "raw-bearer-token-that-must-not-survive",
      "private-cookie",
      "13800138000",
      "person@example.com",
      "sample-only",
    ] {
      #expect(!encoded.contains(secret))
    }
  }

  @Test("Product document slugs with trailing identifiers share one route")
  func normalizesDynamicProductDocumentSlugs() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url:
          "https://www.example.test/cn/zh/pretty-shirt-p01856281.html?v1=577411473",
        startedAt: "2026-08-02T09:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      ),
      harEntry(
        url:
          "https://www.example.test/cn/zh/other-skirt-p05344244.html?v1=545465463",
        startedAt: "2026-08-02T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      ),
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-product-document",
        sourceVersion: "web-1",
        flow: "product-current-facts"
      )
    )

    #expect(Set(receipt.exchanges.map(\.fingerprint)).count == 1)
    #expect(Set(receipt.exchanges.map(\.operationId)).count == 1)
    #expect(
      receipt.exchanges.allSatisfy {
        $0.urlTemplate
          == "https://www.example.test/cn/zh/{segment1}.html?v1={v1}"
      }
    )
  }

  @Test("Empty regex selection fails closed")
  func emptySelectionFails() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url: "https://example.test/api/product",
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      )
    ])

    #expect(throws: CapturePipelineError.emptySelection) {
      try HARImporter.importHAR(
        data: data,
        options: HARImportOptions(
          brand: "fixture",
          market: "cn",
          surface: .web,
          sourceId: "fixture-cn-web",
          sourceVersion: "web-1",
          flow: "selection",
          includeURLPatterns: ["does-not-match"]
        )
      )
    }
  }

  @Test("Browser-internal URL schemes are excluded before URL matching")
  func browserInternalSchemesAreExcluded() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url:
          "blob:https://api.example.test/2ff8b3cc-dd46-42e0-8463-e25c9cac5945",
        startedAt: "2026-07-29T09:59:00.000Z",
        requestBody: [:],
        responseBody: ["internal": true]
      ),
      harEntry(
        url: "https://api.example.test/products/484203",
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      ),
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-web",
        sourceVersion: "web-1",
        flow: "browser-internal-url",
        includeURLPatterns: ["https://api\\.example\\.test"]
      )
    )

    #expect(receipt.exchanges.count == 1)
    #expect(
      receipt.exchanges[0].sanitizedURL
        == "https://api.example.test/products/484203"
    )
    #expect(receipt.captureSelection?.totalExchangeCount == 2)
    #expect(receipt.captureSelection?.selectedExchangeCount == 1)
  }

  @Test("Dynamic personal path segment is sanitized in durable metadata")
  func dynamicPersonalPathIsSanitized() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url: "https://example.test/api/13800138000",
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      )
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-web",
        sourceVersion: "web-1",
        flow: "secret-guard"
      )
    )

    #expect(receipt.source.entryURL == "https://example.test/api/{segment1}")
    #expect(
      receipt.exchanges.first?.sanitizedURL
        == "https://example.test/api/%5BREDACTED%5D"
    )
    let encoded = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    #expect(!encoded.contains("13800138000"))
  }

  @Test("Explicit gateway discriminators keep same-path operations distinct")
  func gatewayDiscriminatorsArePartOfOperationIdentity() throws {
    let firstURL =
      "https://api.m.jd.com/api?appid=item-v3&functionId=relsearch"
      + "&body=%7B%22keyword%22%3A%22shirt%22%7D"
    let secondURL =
      "https://api.m.jd.com/api?appid=follow_for_concert"
      + "&functionId=batchIsFollow"
      + "&body=%7B%22wareIds%22%3A%5B%22484203%22%5D%7D"
    let data = try makeHARData(entries: [
      harEntry(
        url: firstURL,
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      ),
      harEntry(
        url: secondURL,
        startedAt: "2026-07-29T10:01:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      ),
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "jd",
        market: "cn",
        surface: .web,
        sourceId: "jd-cn-web",
        sourceVersion: "web-1",
        flow: "gateway",
        routeDiscriminatorQueryNames: ["functionId", "appid", "appid"]
      )
    )

    #expect(Set(receipt.exchanges.map(\.fingerprint)).count == 2)
    #expect(Set(receipt.exchanges.map(\.operationId)).count == 2)
    #expect(
      Set(receipt.exchanges.compactMap(\.routeDiscriminators))
        == Set([
          ["appid": "item-v3", "functionId": "relsearch"],
          [
            "appid": "follow_for_concert",
            "functionId": "batchIsFollow",
          ],
        ])
    )
    #expect(
      receipt.exchanges.allSatisfy {
        $0.request.encodedQuerySchemas?["body"] != nil
      }
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("484203"))
    #expect(!durable.contains("shirt"))
  }

  @Test("Explicit discriminator values fail closed when not public identifiers")
  func unsafeGatewayDiscriminatorFails() throws {
    let data = try makeHARData(entries: [
      harEntry(
        url:
          "https://api.example.test/api?functionId=user%40example.com",
        startedAt: "2026-07-29T10:00:00.000Z",
        requestBody: [:],
        responseBody: ["success": true]
      )
    ])

    #expect(
      throws: CapturePipelineError.unsafeRouteDiscriminator("functionId")
    ) {
      try HARImporter.importHAR(
        data: data,
        options: HARImportOptions(
          brand: "fixture",
          market: "cn",
          surface: .web,
          sourceId: "fixture-cn-web",
          sourceVersion: "web-1",
          flow: "unsafe-gateway",
          routeDiscriminatorQueryNames: ["functionId"]
        )
      )
    }
  }

  @Test("Malformed form percent escapes do not crash import")
  func malformedFormPercentEscapesAreBounded() throws {
    let data = try makeHARData(entries: [
      [
        "startedDateTime": "2026-07-29T10:00:00.000Z",
        "time": 12,
        "request": [
          "method": "POST",
          "url": "https://api.example.test/session/refresh",
          "headers": [
            [
              "name": "Content-Type",
              "value": "application/x-www-form-urlencoded",
            ]
          ],
          "postData": [
            "mimeType": "application/x-www-form-urlencoded",
            "text": "refreshToken=private%ZZvalue&label=hello+world",
          ],
        ],
        "response": [
          "status": 200,
          "headers": [
            ["name": "Content-Type", "value": "application/json"]
          ],
          "content": [
            "mimeType": "application/json",
            "text": jsonString(["success": true]),
          ],
        ],
      ]
    ])

    let receipt = try HARImporter.importHAR(
      data: data,
      options: HARImportOptions(
        brand: "fixture",
        market: "cn",
        surface: .web,
        sourceId: "fixture-cn-form",
        sourceVersion: "form-1",
        flow: "session-refresh"
      )
    )

    guard
      let schema = receipt.exchanges.first?.request.bodySchema,
      case .object(let schemaObject) = schema,
      case .object(let properties)? = schemaObject["properties"]
    else {
      Issue.record("Expected an object form-body schema")
      return
    }
    #expect(
      properties["refreshToken"]
        == .object(["type": .string("string")])
    )
    #expect(
      properties["label"]
        == .object(["type": .string("string")])
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    #expect(!durable.contains("private%ZZvalue"))
    #expect(!durable.contains("hello world"))
  }
}

func makeHARData(entries: [[String: Any]]) throws -> Data {
  try JSONSerialization.data(
    withJSONObject: ["log": ["entries": entries]],
    options: [.sortedKeys]
  )
}

func harEntry(
  url: String,
  startedAt: String,
  requestBody: [String: Any],
  responseBody: [String: Any]
) -> [String: Any] {
  [
    "startedDateTime": startedAt,
    "time": 12,
    "request": [
      "method": "POST",
      "url": url,
      "headers": [
        ["name": "Authorization", "value": "Bearer raw-bearer-token-that-must-not-survive"],
        ["name": "Cookie", "value": "session_id=private-cookie; region=cn"],
        ["name": "Content-Type", "value": "application/json"],
      ],
      "postData": [
        "mimeType": "application/json",
        "text": jsonString(requestBody),
      ],
    ],
    "response": [
      "status": 200,
      "headers": [
        ["name": "Content-Type", "value": "application/json"]
      ],
      "content": [
        "mimeType": "application/json",
        "text": jsonString(responseBody),
      ],
    ],
  ]
}

private func harTextResponseEntry(
  url: String,
  startedAt: String,
  responseHeaders: [[String: String]],
  responseBody: String
) -> [String: Any] {
  [
    "startedDateTime": startedAt,
    "time": 12,
    "request": [
      "method": "GET",
      "url": url,
      "headers": [["name": "Accept", "value": "application/json"]],
    ],
    "response": [
      "status": 200,
      "headers": responseHeaders,
      "content": [
        "mimeType": "application/json;charset=UTF-8",
        "text": responseBody,
      ],
    ],
  ]
}

private func jsonString(_ value: Any) -> String {
  let data = try! JSONSerialization.data(
    withJSONObject: value,
    options: [.sortedKeys]
  )
  return String(decoding: data, as: UTF8.self)
}
