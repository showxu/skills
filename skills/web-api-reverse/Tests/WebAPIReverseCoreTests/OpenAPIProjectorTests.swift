import Testing

@testable import WebAPIReverseCore

@Suite("OpenAPI projector")
struct OpenAPIProjectorTests {
  @Test("Projects route, request shapes, responses, fixtures, and evidence metadata")
  func projectsCompleteOperation() throws {
    let fixture = ProjectionFixture()

    let document = try OpenAPIProjector().project(fixture.input())

    #expect(document["openapi"] == .string("3.1.0"))
    #expect(
      document["servers"]
        == .array([
          .object(["url": .string("https://api.example.com")])
        ])
    )
    let operation = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    #expect(operation["operationId"] == .string("fetchProduct"))
    #expect(
      operation["x-web-api-reverse-operation-id"]
        == .string("post.products.product")
    )
    #expect(
      operation["x-web-api-reverse-evidence-ids"]
        == .array([.string("cap_product"), .string("ver_product")])
    )

    let parameters = try #require(operation["parameters"]?.arrayValue)
    #expect(hasParameter(parameters, name: "productId", location: "path"))
    #expect(hasParameter(parameters, name: "locale", location: "query"))
    #expect(!hasParameter(parameters, name: "X-Client", location: "header"))
    #expect(!hasParameter(parameters, name: "session", location: "cookie"))
    #expect(
      operation["requestBody"]?["content"]?["application/json"]?["schema"]
        == fixture.requestSchema
    )
    #expect(
      operation["responses"]?["200"]?["content"]?["application/json"]?[
        "examples"
      ]?["ver_product"]?["value"] == fixture.responseFixture
    )
    #expect(
      operation["responses"]?["400"]?["content"]?["application/json"]?[
        "schema"
      ]?["required"] == nil
    )
  }

  @Test("Encoded wire query becomes logical body and runtime facts stay out of inputs")
  func projectsLogicalBodyWithoutWireInputs() throws {
    let fixture = ProjectionFixture()
    let encodedSchema: JSONValue = .object([
      "additionalProperties": .bool(false),
      "properties": .object([
        "wareId": .object(["type": .string("string")])
      ]),
      "required": .array([.string("wareId")]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(
      request: RequestShape(
        contentType: nil,
        queryNames: ["appid", "body", "index"],
        headers: [
          HeaderPresence(name: "cookie", present: true, sensitive: true),
          HeaderPresence(name: "referer", present: true, sensitive: false),
        ],
        cookieNames: ["session"],
        bodySchema: nil,
        encodedQuerySchemas: ["body": encodedSchema]
      )
    )
    let policy = fixture.policy(
      runtimeManagedQueryNames: ["appid"],
      runtimeManagedHeaderNames: ["referer"]
    )
    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation, policy: policy)
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    let parameters = try #require(projected["parameters"]?.arrayValue)

    #expect(hasParameter(parameters, name: "productId", location: "path"))
    #expect(hasParameter(parameters, name: "index", location: "query"))
    #expect(!hasParameter(parameters, name: "appid", location: "query"))
    #expect(!hasParameter(parameters, name: "body", location: "query"))
    #expect(
      !parameters.contains { $0["in"] == JSONValue.string("header") }
    )
    #expect(
      !parameters.contains { $0["in"] == JSONValue.string("cookie") }
    )
    #expect(
      projected["requestBody"]?["content"]?["application/json"]?["schema"]
        == encodedSchema
    )
    #expect(
      projected["x-web-api-reverse-encoded-query-body-name"]
        == JSONValue.string("body")
    )
  }

  @Test("Empty form evidence projects as a bodyless request")
  func omitsZeroByteFormBody() throws {
    let fixture = ProjectionFixture()
    let emptyFormSchema: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([:]),
      "required": .array([]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(
      request: RequestShape(
        contentType: "application/x-www-form-urlencoded",
        queryNames: [],
        headers: [
          HeaderPresence(
            name: "content-type",
            present: true,
            sensitive: false
          )
        ],
        cookieNames: [],
        bodySchema: emptyFormSchema
      )
    )
    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )

    #expect(projected["requestBody"] == nil)
  }

  @Test("Nonstandard JSON media types project as generated JSON contracts")
  func canonicalizesJSONResponseMediaTypes() throws {
    let fixture = ProjectionFixture()
    let receipt = fixture.receipt(
      responseSchema: fixture.responseSchema,
      contentType: "text/plain; charset=utf-8"
    )
    let policy = fixture.policy(
      responseContentTypeAliases: ["text/plain": "application/json"]
    )
    let document = try OpenAPIProjector().project(
      fixture.input(policy: policy, receipt: receipt)
    )
    let operation = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )

    #expect(
      operation["responses"]?["200"]?["content"]?["application/json"]?[
        "schema"
      ] != nil
    )
    #expect(operation["responses"]?["200"]?["content"]?["text/plain"] == nil)
    #expect(
      operation["x-web-api-reverse-response-content-type-aliases"]
        == .object(["text/plain": .string("application/json")])
    )
  }

  @Test("Reviewed response fields may be widened to opaque stable types")
  func appliesOpaqueResponsePointers() throws {
    let fixture = ProjectionFixture()
    let schema: JSONValue = .object([
      "properties": .object([
        "data": .object([
          "properties": .object([
            "distinctId": .object(["type": .string("string")])
          ]),
          "required": .array([.string("distinctId")]),
          "type": .string("object"),
        ]),
        "ret": .object([
          "items": .object(["type": .string("string")]),
          "type": .string("array"),
        ]),
      ]),
      "required": .array([.string("data"), .string("ret")]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(responseSchema: schema)
    let policy = fixture.policy(opaqueResponsePointers: ["/data"])
    let receipt = fixture.receipt(
      responseSchema: schema,
      responseFixture: .object([
        "data": .object(["distinctId": .string("historical")]),
        "ret": .array([.string("SUCCESS")]),
      ])
    )

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation, policy: policy, receipt: receipt)
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    let response = try #require(
      projected["responses"]?["200"]?["content"]?["application/json"]?[
        "schema"
      ]
    )

    #expect(
      response["properties"]?["data"]
        == .object([
          "additionalProperties": .bool(true),
          "type": .string("object"),
        ])
    )
    #expect(
      response["properties"]?["ret"]?["items"]?["type"]
        == .string("string")
    )
    #expect(
      projected["x-web-api-reverse-opaque-response-pointers"]
        == .array([.string("/data")])
    )
  }

  @Test("Reviewed textual fixture omission preserves the wire response contract")
  func projectsOmittedReviewedTextFixture() throws {
    let fixture = ProjectionFixture()
    let textSchema: JSONValue = .object(["type": .string("string")])
    let extraction: JSONValue = .object([
      "kind": .string("javascriptAssignmentJSON"),
      "variable": .string("window.__PRODUCT_CONTEXT__"),
    ])
    let operation = fixture.operation(
      responseSchema: textSchema,
      responseContentType: "text/html; charset=utf-8"
    )
    let policy = fixture.policy(
      responseExtraction: extraction,
      fixturePaths: []
    )
    let receipt = fixture.receipt(
      responseSchema: textSchema,
      contentType: "text/html; charset=utf-8",
      fixtureOmissionReason: "Authenticated HTML remains private."
    )

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation, policy: policy, receipt: receipt)
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )

    #expect(
      projected["responses"]?["200"]?["content"]?[
        "text/html"
      ]?["schema"]?["type"] == .string("string")
    )
    #expect(
      projected["x-web-api-reverse-response-extraction"] == extraction
    )
  }

  @Test("Projected private extraction schema needs no durable fixture")
  func projectsOmittedAuthenticatedExtractionFixture() throws {
    let fixture = ProjectionFixture()
    let projectedSchema: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([
        "data": .object(["type": .string("object")])
      ]),
      "required": .array([.string("data")]),
      "type": .string("object"),
    ])
    let extraction: JSONValue = .object([
      "callbackQueryName": .string("callback"),
      "kind": .string("jsonP"),
    ])
    let operation = fixture.operation(
      responseSchema: projectedSchema,
      authPolicy: .sessionHeadersAndCookies
    )
    let policy = fixture.policy(
      authPolicy: .sessionHeadersAndCookies,
      responseExtraction: extraction,
      fixturePaths: []
    )
    let receipt = fixture.receipt(
      responseSchema: projectedSchema,
      fixtureOmissionReason: "Authenticated JSONP values remain private."
    )

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation, policy: policy, receipt: receipt)
    )
    let schema = try #require(
      document["paths"]?["/products/{productId}"]?["post"]?["responses"]?["200"]?[
        "content"
      ]?["application/json"]?["schema"]
    )

    #expect(schema["properties"]?["data"]?["type"] == .string("object"))
  }

  @Test("Approved response wins over observed business failure and stays evolvable")
  func approvedResponseWinsAndStaysEvolvable() throws {
    let fixture = ProjectionFixture()
    let failureSchema: JSONValue = .object([
      "additionalProperties": .bool(false),
      "properties": .object([
        "redirect": .object(["type": .string("string")])
      ]),
      "required": .array([.string("redirect")]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(
      additionalResponses: [
        ResponseShape(
          status: 200,
          contentType: "application/json",
          bodySchema: failureSchema,
          outcome: .businessError,
          businessErrorSignals: ["login-required"]
        ),
        ResponseShape(
          status: -1,
          contentType: "x-unknown",
          bodySchema: nil,
          outcome: .httpError,
          businessErrorSignals: ["transport"]
        ),
      ]
    )

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )
    let projectedOperation = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    let schema = try #require(
      projectedOperation["responses"]?["200"]?["content"]?[
        "application/json"
      ]?["schema"]
    )

    #expect(schema["oneOf"] == nil)
    #expect(schema["properties"]?["id"] != nil)
    #expect(schema["properties"]?["redirect"] == nil)
    #expect(schema["required"] == nil)
    #expect(schema["additionalProperties"] == .bool(true))
    #expect(projectedOperation["responses"]?["-1"] == nil)
    #expect(
      projectedOperation["x-web-api-reverse-observed-non-http-statuses"]
        == .array([.number(-1)])
    )
  }

  @Test("Invalid observed response media types do not enter OpenAPI content")
  func omitsInvalidObservedResponseMediaType() throws {
    let fixture = ProjectionFixture()
    let operation = fixture.operation(
      additionalResponses: [
        ResponseShape(
          status: 401,
          contentType: "x-unknown",
          bodySchema: .object(["type": .string("string")]),
          outcome: .httpError,
          businessErrorSignals: []
        )
      ]
    )

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )
    let projectedOperation = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    let response = try #require(
      projectedOperation["responses"]?["401"]
    )

    #expect(response["content"] == nil)
  }

  @Test("Dynamic response identifiers project as additional properties")
  func generalizesDynamicResponseIdentifiers() throws {
    let fixture = ProjectionFixture()
    let dynamicSchema: JSONValue = .object([
      "additionalProperties": .bool(false),
      "properties": .object([
        "728349185026": .object(["type": .string("string")])
      ]),
      "required": .array([.string("728349185026")]),
      "type": .string("object"),
    ])
    let projected = try responseSchema(
      from: OpenAPIProjector().project(
        fixture.input(
          operation: fixture.operation(responseSchema: dynamicSchema)
        )
      )
    )

    #expect(projected["properties"] == nil)
    #expect(
      projected["additionalProperties"]?["type"] == .string("string")
    )
  }

  @Test("Projection is deterministic across input order")
  func projectionIsDeterministic() throws {
    let fixture = ProjectionFixture()
    let second = fixture.secondaryOperation()
    let secondPolicy = fixture.secondaryPolicy()
    let forward = OpenAPIProjectionInput(
      catalog: fixture.catalog(
        operations: [fixture.operation(), second]
      ),
      policies: fixture.policies(
        operations: [fixture.policy(), secondPolicy]
      ),
      acceptedVerifications: [
        fixture.receipt(),
        fixture.secondaryReceipt(),
      ]
    )
    let reversed = OpenAPIProjectionInput(
      catalog: fixture.catalog(
        operations: [second, fixture.operation()]
      ),
      policies: fixture.policies(
        operations: [secondPolicy, fixture.policy()]
      ),
      acceptedVerifications: [
        fixture.secondaryReceipt(),
        fixture.receipt(),
      ]
    )

    let firstData = try DeterministicJSON.encode(
      OpenAPIProjector().project(forward)
    )
    let secondData = try DeterministicJSON.encode(
      OpenAPIProjector().project(reversed)
    )

    #expect(firstData == secondData)
  }

  @Test("Provider-owned gateway policy contributes its reviewed server")
  func projectsProviderOwnedRoutePolicy() throws {
    let fixture = ProjectionFixture()
    let route = RoutePolicy.provider(
      kind: "jdGateway",
      fields: [
        "appID": .string("item-v3"),
        "baseURL": .string("https://api.m.jd.com"),
        "functionID": .string("relsearch"),
      ]
    )
    let input = OpenAPIProjectionInput(
      catalog: fixture.catalog(
        operations: [
          fixture.operation(
            urlTemplate: "https://api.m.jd.com/api",
            routePolicy: route
          )
        ]
      ),
      policies: fixture.policies(
        operations: [
          fixture.policy(
            path: "/__jd_gateway/fetchProduct",
            wirePath: "/api",
            routePolicy: route
          )
        ]
      ),
      acceptedVerifications: [fixture.receipt()]
    )

    let document = try OpenAPIProjector().project(input)

    #expect(
      document["servers"]
        == .array([
          .object(["url": .string("https://api.m.jd.com")])
        ])
    )
    #expect(
      document["paths"]?["/__jd_gateway/fetchProduct"]?["post"]?[
        "x-web-api-reverse-wire-path"
      ] == .string("/api")
    )
  }

  @Test("Null-only evidence becomes optional and never emits type null")
  func nullOnlyEvidenceIsOptional() throws {
    let fixture = ProjectionFixture()
    let nullableSchema: JSONValue = .object([
      "properties": .object([
        "message": .object(["type": .string("null")]),
        "value": .object([
          "oneOf": .array([
            .object(["type": .string("string")]),
            .object(["type": .string("null")]),
          ])
        ]),
      ]),
      "required": .array([
        .string("message"),
        .string("value"),
      ]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(responseSchema: nullableSchema)
    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]?[
        "responses"
      ]?["200"]?["content"]?["application/json"]?["schema"]
    )

    #expect(projected["required"] == nil)
    #expect(
      projected["properties"]?["message"] == nil
    )
    #expect(
      projected["properties"]?["value"]?[
        "x-web-api-reverse-observed-nullable"
      ] == .bool(true)
    )
    #expect(!containsTypeNull(projected))
    #expect(
      document["paths"]?["/products/{productId}"]?["post"]?[
        "x-web-api-reverse-observed-null-paths"
      ] != nil
    )
  }

  @Test("Whole null response retains evidence without inventing a schema")
  func wholeNullResponseOmitsSchema() throws {
    let fixture = ProjectionFixture()
    let operation = fixture.operation(responseSchema: .null)
    let input = OpenAPIProjectionInput(
      catalog: fixture.catalog(operations: [operation]),
      policies: fixture.policies(),
      acceptedVerifications: [
        fixture.receipt(
          responseSchema: .null,
          responseFixture: .null
        )
      ]
    )

    let document = try OpenAPIProjector().project(input)
    let projectedOperation = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    let mediaType = try #require(
      projectedOperation["responses"]?["200"]?["content"]?[
        "application/json"
      ]
    )

    #expect(mediaType["schema"] == nil)
    #expect(
      mediaType["examples"]?["ver_product"]?["value"] == .null
    )
    #expect(
      projectedOperation["x-web-api-reverse-observed-null-paths"]?
        .arrayValue?.contains(.string("response.200")) == true
    )
  }

  @Test("Array properties with only null elements are omitted from responses")
  func nullOnlyArrayItemsAreOmitted() throws {
    let fixture = ProjectionFixture()
    let schema: JSONValue = .object([
      "properties": .object([
        "values": .object([
          "items": .object(["type": .string("null")]),
          "type": .string("array"),
        ])
      ]),
      "required": .array([.string("values")]),
      "type": .string("object"),
    ])
    let document = try OpenAPIProjector().project(
      fixture.input(operation: fixture.operation(responseSchema: schema))
    )
    let projected = try #require(
      document["paths"]?["/products/{productId}"]?["post"]?[
        "responses"
      ]?["200"]?["content"]?["application/json"]?["schema"]
    )

    #expect(projected["required"] == nil)
    #expect(projected["properties"]?["values"] == nil)
    #expect(!containsTypeNull(projected))
    #expect(
      document["paths"]?["/products/{productId}"]?["post"]?[
        "x-web-api-reverse-observed-null-paths"
      ]?.arrayValue?.contains(.string("response.200.values[]")) == true
    )
  }

  @Test("Nested nullable unions collapse into one optional scalar")
  func nestedNullableUnionCollapses() throws {
    let fixture = ProjectionFixture()
    let schema: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([
        "planOnDate": .object([
          "oneOf": .array([
            .object(["type": .string("integer")]),
            .object([
              "oneOf": .array([
                .object(["type": .string("integer")]),
                .object(["type": .string("null")]),
              ])
            ]),
          ])
        ])
      ]),
      "required": .array([.string("planOnDate")]),
      "type": .string("object"),
    ])

    let projected = try responseSchema(
      from: OpenAPIProjector().project(
        fixture.input(operation: fixture.operation(responseSchema: schema))
      )
    )
    let property = try #require(
      projected["properties"]?["planOnDate"]
    )

    #expect(property["type"] == .string("integer"))
    #expect(property["oneOf"] == nil)
    #expect(
      property["x-web-api-reverse-observed-nullable"] == .bool(true)
    )
    #expect(projected["required"] == nil)
  }

  @Test("Policy path aliases must cover every Observed path parameter")
  func appliesAndValidatesPathParameterAliases() throws {
    let fixture = ProjectionFixture()
    let observed = fixture.operation(
      urlTemplate:
        "https://api.example.com/p/products/{segment1}/colors/{segment2}"
    )
    let policy = fixture.policy(
      path: "/products/{productId}/colors/{colorCode}"
    )
    let aliased = OpenAPIProjectionInput(
      catalog: fixture.catalog(operations: [observed]),
      policies: fixture.policies(operations: [policy]),
      acceptedVerifications: [fixture.receipt()]
    )

    let document = try OpenAPIProjector().project(aliased)
    let operation = try #require(
      document["paths"]?[
        "/products/{productId}/colors/{colorCode}"
      ]?["post"]
    )
    let parameters = try #require(operation["parameters"]?.arrayValue)
    #expect(hasParameter(parameters, name: "productId", location: "path"))
    #expect(hasParameter(parameters, name: "colorCode", location: "path"))

    let mismatched = OpenAPIProjectionInput(
      catalog: fixture.catalog(operations: [observed]),
      policies: fixture.policies(
        operations: [fixture.policy(path: "/products/{productId}/colors")]
      ),
      acceptedVerifications: [fixture.receipt()]
    )
    #expect(
      throws: OpenAPIProjectionError.policyMismatch(
        operationId: "post.products.product",
        reason:
          "path parameter alias count differs: 1 reviewed for 2 observed"
      )
    ) {
      try OpenAPIProjector().project(mismatched)
    }

    let changedStaticRoute = OpenAPIProjectionInput(
      catalog: fixture.catalog(operations: [observed]),
      policies: fixture.policies(
        operations: [
          fixture.policy(
            path: "/catalog/{productId}/swatches/{colorCode}"
          )
        ]
      ),
      acceptedVerifications: [fixture.receipt()]
    )
    #expect(
      throws: OpenAPIProjectionError.policyMismatch(
        operationId: "post.products.product",
        reason: "reviewed path changes observed static route segments"
      )
    ) {
      try OpenAPIProjector().project(changedStaticRoute)
    }
  }

  @Test("Dynamic maps and high-cardinality records remain schema-owned")
  func preservesMapAndRecordShapes() throws {
    let fixture = ProjectionFixture()
    let mapSchema: JSONValue = .object([
      "additionalProperties": .object([
        "type": .string("string")
      ]),
      "type": .string("object"),
    ])
    let projectedMap = try responseSchema(
      from: OpenAPIProjector().project(
        fixture.input(
          operation: fixture.operation(responseSchema: mapSchema)
        )
      )
    )
    #expect(projectedMap["properties"] == nil)
    #expect(
      projectedMap["additionalProperties"]?["type"]
        == .string("string")
    )

    let mapWithAggregateKey: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([
        "0": .object([
          "properties": .object([
            "quantity": .object(["type": .string("string")])
          ]),
          "type": .string("object"),
        ]),
        "5925674118345": .object([
          "properties": .object([
            "quantity": .object(["type": .string("string")])
          ]),
          "type": .string("object"),
        ]),
      ]),
      "required": .array([.string("0"), .string("5925674118345")]),
      "type": .string("object"),
    ])
    let projectedAggregateMap = try responseSchema(
      from: OpenAPIProjector().project(
        fixture.input(
          operation: fixture.operation(responseSchema: mapWithAggregateKey)
        )
      )
    )
    #expect(projectedAggregateMap["properties"] == nil)
    #expect(
      projectedAggregateMap["additionalProperties"]?["type"]
        == .string("object")
    )

    let properties = Dictionary(
      uniqueKeysWithValues: (0..<30).map { index in
        (
          "field_\(index)",
          JSONValue.object([
            "type": .string(index.isMultiple(of: 2) ? "integer" : "string")
          ])
        )
      }
    )
    let recordSchema: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object(properties),
      "required": .array(properties.keys.sorted().map(JSONValue.string)),
      "type": .string("object"),
    ])
    let projectedRecord = try responseSchema(
      from: OpenAPIProjector().project(
        fixture.input(
          operation: fixture.operation(responseSchema: recordSchema)
        )
      )
    )
    #expect(projectedRecord["properties"]?.objectValue.count == 30)
    #expect(projectedRecord["additionalProperties"] == .bool(true))
  }

  @Test("Deep schemas use deterministic named components")
  func deepSchemasUseComponents() throws {
    let fixture = ProjectionFixture()
    let operation = fixture.operation(responseSchema: nestedSchema(depth: 18))

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )

    let operationDocument = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    #expect(
      operationDocument["x-web-api-reverse-named-components"]
        == .bool(true)
    )
    #expect(
      operationDocument["responses"]?["200"]?["content"]?[
        "application/json"
      ]?["schema"]?["$ref"] != nil
    )
    #expect(
      document["components"]?["schemas"]?.objectValue.isEmpty == false
    )
  }

  @Test("Reviewed policy can force named components for a small schema")
  func policyCanForceNamedComponents() throws {
    let fixture = ProjectionFixture()
    let document = try OpenAPIProjector().project(
      fixture.input(
        policy: fixture.policy(useNamedComponents: true)
      )
    )

    let operationDocument = try #require(
      document["paths"]?["/products/{productId}"]?["post"]
    )
    #expect(
      operationDocument["x-web-api-reverse-named-components"]
        == .bool(true)
    )
    #expect(
      operationDocument["responses"]?["200"]?["content"]?[
        "application/json"
      ]?["schema"]?["$ref"] != nil
    )
  }

  @Test("Nested component names are parent-scoped and singularized")
  func nestedComponentNamesAreDeterministic() throws {
    let fixture = ProjectionFixture()
    let nestedObject: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([
        "text": .object(["type": .string("string")])
      ]),
      "required": .array([.string("text")]),
      "type": .string("object"),
    ])
    let schema: JSONValue = .object([
      "additionalProperties": .bool(true),
      "properties": .object([
        "addresses": .object([
          "items": nestedObject,
          "type": .string("array"),
        ]),
        "deep": nestedSchema(depth: 18),
        "left": .object([
          "additionalProperties": .bool(true),
          "properties": .object(["value": nestedObject]),
          "required": .array([.string("value")]),
          "type": .string("object"),
        ]),
        "right": .object([
          "additionalProperties": .bool(true),
          "properties": .object([
            "value": .object([
              "additionalProperties": .bool(true),
              "properties": .object([
                "count": .object(["type": .string("integer")])
              ]),
              "required": .array([.string("count")]),
              "type": .string("object"),
            ])
          ]),
          "required": .array([.string("value")]),
          "type": .string("object"),
        ]),
      ]),
      "required": .array([
        .string("addresses"),
        .string("deep"),
        .string("left"),
        .string("right"),
      ]),
      "type": .string("object"),
    ])

    let first = try OpenAPIProjector().project(
      fixture.input(operation: fixture.operation(responseSchema: schema))
    )
    let second = try OpenAPIProjector().project(
      fixture.input(operation: fixture.operation(responseSchema: schema))
    )
    let names = Set(
      first["components"]?["schemas"]?.objectValue.keys.map { $0 } ?? []
    )

    #expect(
      try DeterministicJSON.encode(first)
        == DeterministicJSON.encode(second)
    )
    #expect(names.contains("ProductResponseAddressItem"))
    #expect(names.contains("ProductResponseLeftValue"))
    #expect(names.contains("ProductResponseRightValue"))
    #expect(!names.contains("ProductResponseAddresseItem"))
    #expect(!names.contains { $0.hasPrefix("Value_") })
  }

  @Test("Schemas over 512 KB use named components")
  func largeSchemasUseComponents() throws {
    let fixture = ProjectionFixture()
    let largeSchema: JSONValue = .object([
      "description": .string(
        String(
          repeating: "x",
          count: OpenAPIProjector.namedComponentByteThreshold
        )
      ),
      "properties": .object([
        "value": .object(["type": .string("string")])
      ]),
      "type": .string("object"),
    ])
    let operation = fixture.operation(responseSchema: largeSchema)

    let document = try OpenAPIProjector().project(
      fixture.input(operation: operation)
    )

    #expect(
      document["paths"]?["/products/{productId}"]?["post"]?[
        "x-web-api-reverse-named-components"
      ] == .bool(true)
    )
    #expect(
      document["components"]?["schemas"]?.objectValue.isEmpty == false
    )
  }

  @Test("Fixture set must match the validated policy exactly")
  func rejectsMissingAcceptedFixture() {
    let fixture = ProjectionFixture()
    let input = OpenAPIProjectionInput(
      catalog: fixture.catalog(),
      policies: fixture.policies(),
      acceptedVerifications: []
    )

    #expect(throws: OpenAPIProjectionError.missingVerification("ver_product")) {
      try OpenAPIProjector().project(input)
    }
  }

  @Test("Empty and populated array evidence share one item schema")
  func mergesEmptyAndPopulatedArrayEvidence() throws {
    let fixture = ProjectionFixture()
    let emptySchema = JSONSchemaInference.infer(.array([]))
    let populatedFixture: JSONValue = .array([
      .object([
        "id": .string("item-1"),
        "name": .string("Item"),
      ])
    ])
    let populatedSchema = JSONSchemaInference.infer(populatedFixture)
    let operation = fixture.operation(
      responseSchema: emptySchema,
      verificationIDs: ["ver_empty", "ver_populated"]
    )
    let policy = fixture.policy(
      evidenceIds: ["cap_product", "ver_empty", "ver_populated"],
      fixturePaths: [
        "fixtures/post.products.product/ver_empty.json",
        "fixtures/post.products.product/ver_populated.json",
      ]
    )
    let document = try OpenAPIProjector().project(
      OpenAPIProjectionInput(
        catalog: fixture.catalog(operations: [operation]),
        policies: fixture.policies(operations: [policy]),
        acceptedVerifications: [
          fixture.receipt(
            verificationId: "ver_empty",
            responseSchema: emptySchema,
            responseFixture: .array([])
          ),
          fixture.receipt(
            verificationId: "ver_populated",
            responseSchema: populatedSchema,
            responseFixture: populatedFixture
          ),
        ]
      )
    )
    let schema = try responseSchema(from: document)

    #expect(schema["type"] == .string("array"))
    #expect(schema["oneOf"] == nil)
    #expect(
      schema["items"]?["properties"]?["id"]?["type"]
        == .string("string")
    )
    #expect(
      schema["items"]?["properties"]?["name"]?["type"]
        == .string("string")
    )
  }
}

private struct ProjectionFixture {
  let requestSchema: JSONValue = .object([
    "properties": .object([
      "includeStock": .object(["type": .string("boolean")])
    ]),
    "required": .array([.string("includeStock")]),
    "type": .string("object"),
  ])
  let responseSchema: JSONValue = .object([
    "properties": .object([
      "id": .object(["type": .string("string")])
    ]),
    "required": .array([.string("id")]),
    "type": .string("object"),
  ])
  let errorSchema: JSONValue = .object([
    "properties": .object([
      "message": .object(["type": .string("string")])
    ]),
    "required": .array([.string("message")]),
    "type": .string("object"),
  ])
  let responseFixture: JSONValue = .object([
    "id": .string("product-1")
  ])

  func input(
    operation: ObservedOperation? = nil,
    policy: ValidatedOperationPolicy? = nil,
    receipt: TrustVerificationReceipt? = nil
  ) -> OpenAPIProjectionInput {
    let selectedOperation = operation ?? self.operation()
    let acceptedResponseSchema = selectedOperation.responses.first {
      $0.status == 200 && $0.outcome == .success
    }?.bodySchema
    return OpenAPIProjectionInput(
      catalog: catalog(operations: [selectedOperation]),
      policies: policies(operations: [policy ?? self.policy()]),
      acceptedVerifications: [
        receipt ?? self.receipt(responseSchema: acceptedResponseSchema)
      ]
    )
  }

  func catalog(
    operations: [ObservedOperation]? = nil
  ) -> ObservedCatalog {
    ObservedCatalog(
      schemaVersion: 1,
      kind: "web-api-reverse.observed-catalog",
      brand: "fixture",
      market: "cn",
      updatedAt: "2026-07-29T00:00:00Z",
      operations: operations ?? [operation()]
    )
  }

  func operation(
    responseSchema: JSONValue? = nil,
    responseContentType: String = "application/json",
    urlTemplate: String =
      "https://api.example.com/p/products/{productId}",
    routePolicy: RoutePolicy =
      .fixed(baseURL: "https://api.example.com/p"),
    request: RequestShape? = nil,
    authPolicy: AuthPolicy = .none,
    additionalResponses: [ResponseShape] = [],
    verificationIDs: [String] = ["ver_product"]
  ) -> ObservedOperation {
    ObservedOperation(
      operationId: "post.products.product",
      fingerprint: String(repeating: "f", count: 64),
      method: "POST",
      urlTemplate: urlTemplate,
      protocol: .rest,
      serviceFamily: "catalog",
      productFamily: "products",
      classification: .publicCurrentFact,
      safety: .safeRead,
      authPolicy: authPolicy,
      routePolicy: routePolicy,
      request: request
        ?? RequestShape(
          contentType: "application/json",
          queryNames: ["locale"],
          headers: [
            HeaderPresence(
              name: "X-Client",
              present: true,
              sensitive: false
            )
          ],
          cookieNames: ["session"],
          bodySchema: requestSchema
        ),
      responses: [
        ResponseShape(
          status: 200,
          contentType: responseContentType,
          bodySchema: responseSchema ?? self.responseSchema,
          outcome: .success,
          businessErrorSignals: []
        ),
        ResponseShape(
          status: 400,
          contentType: "application/json",
          bodySchema: errorSchema,
          outcome: .httpError,
          businessErrorSignals: []
        ),
      ] + additionalResponses,
      sourceRefs: [
        SourceReference(
          captureId: "cap_product",
          sourceId: "desktop-product",
          sourceVersion: "v1"
        )
      ],
      verificationIds: verificationIDs
    )
  }

  func policies(
    operations: [ValidatedOperationPolicy]? = nil
  ) -> ValidatedOperationPolicies {
    ValidatedOperationPolicies(
      brand: "fixture",
      market: "cn",
      operations: operations ?? [policy()]
    )
  }

  func policy(
    path: String = "/products/{productId}",
    wirePath: String? = nil,
    routePolicy: RoutePolicy =
      .fixed(baseURL: "https://api.example.com/p"),
    authPolicy: AuthPolicy = .none,
    runtimeManagedQueryNames: [String] = [],
    runtimeManagedHeaderNames: [String] = [],
    responseContentTypeAliases: [String: String] = [:],
    useNamedComponents: Bool = false,
    opaqueResponsePointers: [String] = [],
    responseExtraction: JSONValue? = nil,
    evidenceIds: [String] = ["ver_product", "cap_product"],
    fixturePaths: [String] = [
      "fixtures/post.products.product/ver_product.json"
    ]
  ) -> ValidatedOperationPolicy {
    ValidatedOperationPolicy(
      operationId: "post.products.product",
      clientOperationId: "fetchProduct",
      method: "POST",
      path: path,
      wirePath: wirePath,
      classification: .publicCurrentFact,
      serviceFamily: "catalog",
      authPolicy: authPolicy,
      routePolicy: routePolicy,
      safety: .safeRead,
      sessionAction: nil,
      evidenceIds: evidenceIds,
      sourceRevisions: ["desktop-product@v1"],
      reversibleMutation: false,
      fixturePaths: fixturePaths,
      runtimeManagedQueryNames: runtimeManagedQueryNames,
      runtimeManagedHeaderNames: runtimeManagedHeaderNames,
      responseContentTypeAliases: responseContentTypeAliases,
      useNamedComponents: useNamedComponents,
      responseExtraction: responseExtraction,
      opaqueResponsePointers: opaqueResponsePointers
    )
  }

  func receipt(
    verificationId: String = "ver_product",
    responseSchema: JSONValue? = nil,
    responseFixture: JSONValue? = nil,
    contentType: String = "application/json",
    fixtureOmissionReason: String? = nil
  ) -> TrustVerificationReceipt {
    TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: verificationId,
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "post.products.product",
      fingerprint: String(repeating: "f", count: 64),
      sourceRefs: [
        SourceReference(
          captureId: "cap_product",
          sourceId: "desktop-product",
          sourceVersion: "v1"
        )
      ],
      response: ResponseShape(
        status: 200,
        contentType: contentType,
        bodySchema: responseSchema ?? self.responseSchema,
        outcome: .success,
        businessErrorSignals: []
      ),
      responseFixture:
        fixtureOmissionReason == nil
        ? (responseFixture ?? self.responseFixture) : nil,
      fixtureOmissionReason: fixtureOmissionReason
    )
  }

  func secondaryOperation() -> ObservedOperation {
    ObservedOperation(
      operationId: "get.categories",
      fingerprint: String(repeating: "e", count: 64),
      method: "GET",
      urlTemplate: "https://config.example.com/categories",
      protocol: .rest,
      serviceFamily: "config",
      productFamily: "categories",
      classification: .remoteConfig,
      safety: .safeRead,
      authPolicy: .none,
      routePolicy: .fixed(baseURL: "https://config.example.com"),
      request: RequestShape(
        contentType: nil,
        queryNames: [],
        headers: [],
        cookieNames: [],
        bodySchema: nil
      ),
      responses: [
        ResponseShape(
          status: 200,
          contentType: "application/json",
          bodySchema: .object(["type": .string("array")]),
          outcome: .success,
          businessErrorSignals: []
        )
      ],
      sourceRefs: [
        SourceReference(
          captureId: "cap_categories",
          sourceId: "config",
          sourceVersion: "v1"
        )
      ],
      verificationIds: ["ver_categories"]
    )
  }

  func secondaryPolicy() -> ValidatedOperationPolicy {
    ValidatedOperationPolicy(
      operationId: "get.categories",
      clientOperationId: "getCategories",
      method: "GET",
      path: "/categories",
      classification: .remoteConfig,
      serviceFamily: "config",
      authPolicy: .none,
      routePolicy: .fixed(baseURL: "https://config.example.com"),
      safety: .safeRead,
      sessionAction: nil,
      evidenceIds: ["cap_categories", "ver_categories"],
      sourceRevisions: ["config@v1"],
      reversibleMutation: false,
      fixturePaths: ["fixtures/get.categories/ver_categories.json"]
    )
  }

  func secondaryReceipt() -> TrustVerificationReceipt {
    TrustVerificationReceipt(
      brand: "fixture",
      market: "cn",
      verificationId: "ver_categories",
      verificationKind: .directReplay,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "get.categories",
      fingerprint: String(repeating: "e", count: 64),
      sourceRefs: [
        SourceReference(
          captureId: "cap_categories",
          sourceId: "config",
          sourceVersion: "v1"
        )
      ],
      response: ResponseShape(
        status: 200,
        contentType: "application/json",
        bodySchema: .object(["type": .string("array")]),
        outcome: .success,
        businessErrorSignals: []
      ),
      responseFixture: .array([])
    )
  }
}

private func hasParameter(
  _ parameters: [JSONValue],
  name: String,
  location: String
) -> Bool {
  parameter(parameters, name: name, location: location) != nil
}

private func parameter(
  _ parameters: [JSONValue],
  name: String,
  location: String
) -> JSONValue? {
  parameters.first {
    $0["name"] == .string(name)
      && $0["in"] == .string(location)
  }
}

private func nestedSchema(depth: Int) -> JSONValue {
  var schema: JSONValue = .object(["type": .string("string")])
  for index in 0..<depth {
    schema = .object([
      "properties": .object(["level\(index)": schema]),
      "required": .array([.string("level\(index)")]),
      "type": .string("object"),
    ])
  }
  return schema
}

private func containsTypeNull(_ value: JSONValue) -> Bool {
  switch value {
  case .object(let object):
    if object["type"] == .string("null") {
      return true
    }
    return object.values.contains(where: containsTypeNull)
  case .array(let array):
    return array.contains(where: containsTypeNull)
  case .string, .number, .bool, .null:
    return false
  }
}

private func responseSchema(from document: JSONValue) throws -> JSONValue {
  try #require(
    document["paths"]?["/products/{productId}"]?["post"]?["responses"]?["200"]?[
      "content"
    ]?["application/json"]?["schema"]
  )
}

extension JSONValue {
  fileprivate subscript(key: String) -> JSONValue? {
    guard case .object(let object) = self else {
      return nil
    }
    return object[key]
  }

  fileprivate var arrayValue: [JSONValue]? {
    guard case .array(let array) = self else {
      return nil
    }
    return array
  }

  fileprivate var objectValue: [String: JSONValue] {
    guard case .object(let object) = self else {
      return [:]
    }
    return object
  }
}
