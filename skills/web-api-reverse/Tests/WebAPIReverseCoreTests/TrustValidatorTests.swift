import Testing

@testable import WebAPIReverseCore

@Suite("Trust validator")
struct TrustValidatorTests {
  @Test("A verified safe read produces deterministic operation policy data")
  func safeReadProducesPolicy() throws {
    let fixture = Fixture()

    let policies = try TrustValidator().validate(fixture.input())

    #expect(policies.kind == "web-api-reverse.operation-policies")
    #expect(policies.brand == "fixture")
    #expect(policies.market == "cn")
    #expect(policies.operations.count == 1)
    let policy = try #require(policies.operations.first)
    #expect(policy.operationId == "get.products")
    #expect(policy.clientOperationId == "getProducts")
    #expect(policy.path == "/products")
    #expect(policy.wirePath == "/products")
    #expect(policy.classification == .publicCurrentFact)
    #expect(policy.serviceFamily == "catalog")
    #expect(policy.evidenceIds == ["cap_products", "ver_products"])
    #expect(policy.sourceRevisions == ["desktop-shell@v1"])
    #expect(policy.fixturePaths == ["fixtures/get.products/ver_products.json"])
  }

  @Test("Reviewed named-component policy is preserved")
  func namedComponentPolicyIsPreserved() throws {
    let fixture = Fixture()
    let policies = try TrustValidator().validate(
      fixture.input(
        manifest: fixture.manifest(
          decision: fixture.decision(useNamedComponents: true)
        )
      )
    )

    #expect(try #require(policies.operations.first).useNamedComponents == true)
  }

  @Test("Reviewed opaque response pointers are preserved")
  func opaqueResponsePointersArePreserved() throws {
    let fixture = Fixture()
    let policies = try TrustValidator().validate(
      fixture.input(
        manifest: fixture.manifest(
          decision: fixture.decision(
            opaqueResponsePointers: ["/data", "/metadata/volatile"]
          )
        )
      )
    )

    #expect(
      try #require(policies.operations.first).opaqueResponsePointers
        == ["/data", "/metadata/volatile"]
    )
  }

  @Test("Opaque response pointers must be absolute and unique")
  func opaqueResponsePointersFailClosed() {
    let fixture = Fixture()
    for pointers in [["data"], ["/data", "/data"], ["/data/~2invalid"]] {
      #expect(
        throws: trustRejection(
          "opaque response pointers must be unique absolute JSON Pointers"
        )
      ) {
        try TrustValidator().validate(
          fixture.input(
            manifest: fixture.manifest(
              decision: fixture.decision(
                opaqueResponsePointers: pointers
              )
            )
          )
        )
      }
    }
  }

  @Test("Encoded wire payload names become runtime policy facts")
  func encodedPayloadNamesBecomePolicyFacts() throws {
    let fixture = Fixture()
    let operation = fixture.operation(
      request: RequestShape(
        contentType: "application/x-www-form-urlencoded",
        queryNames: ["body"],
        headers: [],
        cookieNames: [],
        bodySchema: nil,
        encodedQuerySchemas: [
          "body": .object(["type": .string("object")])
        ],
        encodedBodySchemas: [
          "data": .object(["type": .string("object")])
        ]
      )
    )

    let policies = try TrustValidator().validate(
      fixture.input(catalog: fixture.catalog(operation: operation))
    )
    let policy = try #require(policies.operations.first)

    #expect(policy.encodedQueryBodyNames == ["body"])
    #expect(policy.encodedBodyFieldNames == ["data"])
  }

  @Test("Nonstandard JSON response media types become runtime aliases")
  func jsonResponseMediaTypesBecomePolicyAliases() throws {
    let fixture = Fixture()
    let policies = try TrustValidator().validate(
      fixture.input(
        receipts: [
          fixture.receipt(
            response: fixture.response(contentType: "text/json; charset=utf-8")
          )
        ]
      )
    )
    let policy = try #require(policies.operations.first)

    #expect(
      policy.responseContentTypeAliases
        == ["text/json": "application/json"]
    )
  }

  @Test("Reviewed wire media-type aliases survive trust validation")
  func reviewedResponseMediaTypeAliasesArePreserved() throws {
    let fixture = Fixture()
    let decision = fixture.decision(
      responseContentTypeAliases: ["text/plain": "application/json"]
    )
    let policies = try TrustValidator().validate(
      fixture.input(
        manifest: fixture.manifest(decision: decision),
        receipts: [
          fixture.receipt(
            response: fixture.response(contentType: "text/plain")
          )
        ]
      )
    )
    let policy = try #require(policies.operations.first)

    #expect(
      policy.responseContentTypeAliases
        == ["text/plain": "application/json"]
    )
  }

  @Test("Artifact and receipt scope must match exactly")
  func rejectsScopeMismatch() {
    let fixture = Fixture()
    let input = fixture.input(
      receipts: [
        fixture.receipt(market: "hk")
      ]
    )

    #expect(
      throws: TrustValidationError.scopeMismatch(
        "verification ver_products fixture/hk != fixture/cn"
      )
    ) {
      try TrustValidator().validate(input)
    }
  }

  @Test("Verification source references must equal the Observed source set")
  func rejectsDifferentSourceReferences() {
    let fixture = Fixture()
    let input = fixture.input(
      receipts: [
        fixture.receipt(
          sourceRefs: [
            SourceReference(
              captureId: "cap_other",
              sourceId: "desktop-shell",
              sourceVersion: "v1"
            )
          ]
        )
      ]
    )

    #expect(
      throws: trustRejection(
        "verification ver_products does not cover the exact Observed source set"
      )
    ) {
      try TrustValidator().validate(input)
    }
  }

  @Test("Every source reference must resolve to its captured lock revision")
  func rejectsIncompleteOrUnlinkedSource() {
    let fixture = Fixture()
    let partial = fixture.input(
      sourceLock: fixture.sourceLock(status: .partial)
    )
    #expect(
      throws: trustRejection(
        "source desktop-shell@v1 is not fully captured"
      )
    ) {
      try TrustValidator().validate(partial)
    }

    let unlinked = fixture.input(
      sourceLock: fixture.sourceLock(captureIds: ["cap_stale"])
    )
    #expect(
      throws: trustRejection(
        "source desktop-shell@v1 does not lock the referenced capture and fingerprint"
      )
    ) {
      try TrustValidator().validate(unlinked)
    }
  }

  @Test("Verification must prove success with a shaped fixture")
  func rejectsFailedOrFixturelessVerification() {
    let fixture = Fixture()
    let failed = fixture.input(
      receipts: [
        fixture.receipt(
          response: fixture.response(status: 401, outcome: .httpError)
        )
      ]
    )
    #expect(
      throws: trustRejection(
        "verification ver_products is not an HTTP success"
      )
    ) {
      try TrustValidator().validate(failed)
    }

    let fixtureless = fixture.input(
      receipts: [
        fixture.receipt(responseFixture: nil)
      ]
    )
    #expect(
      throws: trustRejection(
        "verification ver_products has no response fixture"
      )
    ) {
      try TrustValidator().validate(fixtureless)
    }
  }

  @Test("Cookie-bearing observation cannot be published as anonymous without anonymous replay")
  func cookieBearingObservationRequiresAnonymousReplay() throws {
    let fixture = Fixture()
    let operation = fixture.operation(
      request: RequestShape(
        contentType: nil,
        queryNames: [],
        headers: [
          HeaderPresence(name: "cookie", present: true, sensitive: true)
        ],
        cookieNames: ["account_session"],
        bodySchema: nil
      )
    )
    let catalog = fixture.catalog(operation: operation)

    #expect(
      throws: trustRejection(
        "verification ver_products does not prove an unauthenticated request shape"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(catalog: catalog)
      )
    }

    let cookieReplay = fixture.receipt(
      requestEvidence: VerificationRequestEvidence(
        finalURLTemplate: operation.urlTemplate,
        headerNames: ["cookie"],
        cookieNames: ["account_session"]
      )
    )
    #expect(
      throws: trustRejection(
        "verification ver_products used cookies but auth policy is none"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(catalog: catalog, receipts: [cookieReplay])
      )
    }

    let anonymousReplay = fixture.receipt(
      requestEvidence: VerificationRequestEvidence(
        finalURLTemplate: operation.urlTemplate,
        headerNames: ["accept"],
        cookieNames: []
      )
    )
    let accepted = try TrustValidator().validate(
      fixture.input(catalog: catalog, receipts: [anonymousReplay])
    )
    #expect(accepted.operations.count == 1)
  }

  @Test("Anonymous request proof may complement a separate reviewed response fixture")
  func acceptsSplitAnonymousRequestAndResponseEvidence() throws {
    let fixture = Fixture()
    let operation = fixture.operation(
      request: RequestShape(
        contentType: nil,
        queryNames: [],
        headers: [
          HeaderPresence(name: "cookie", present: true, sensitive: true)
        ],
        cookieNames: ["account_session"],
        bodySchema: nil
      ),
      verificationIds: ["ver_fixture", "ver_anonymous"]
    )
    let decision = fixture.decision(
      evidenceIds: ["cap_products", "ver_fixture", "ver_anonymous"]
    )
    let reviewedFixture = fixture.receipt(
      verificationId: "ver_fixture",
      responseFixture: .object(["items": .array([])])
    )
    let anonymousRequestProof = fixture.receipt(
      verificationId: "ver_anonymous",
      requestEvidence: VerificationRequestEvidence(
        finalURLTemplate: operation.urlTemplate,
        headerNames: ["accept"],
        cookieNames: []
      ),
      responseFixture: nil,
      fixtureOmissionReason:
        "The companion receipt retains the reviewed response fixture."
    )

    let policies = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(operation: operation),
        manifest: fixture.manifest(decision: decision),
        receipts: [reviewedFixture, anonymousRequestProof]
      )
    )

    #expect(
      policies.operations.first?.evidenceIds
        == ["cap_products", "ver_anonymous", "ver_fixture"]
    )
    #expect(policies.operations.first?.fixturePaths.count == 1)
  }

  @Test("A JSON null body is a retained fixture, not a missing fixture")
  func acceptsJSONNullFixture() throws {
    let fixture = Fixture()
    let nullResponse = fixture.response(
      bodySchema: .object(["type": .string("null")])
    )
    let receipt = fixture.receipt(
      response: nullResponse,
      responseFixture: nil
    )

    #expect(receipt.effectiveResponseFixture == .null)
    let policies = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(
          operation: fixture.operation(response: nullResponse)
        ),
        receipts: [receipt]
      )
    )
    #expect(
      policies.operations.first?.fixturePaths
        == ["fixtures/get.products/ver_products.json"]
    )
  }

  @Test("Explicit fixture omission is not converted into a JSON null fixture")
  func preservesExplicitFixtureOmission() {
    let fixture = Fixture()
    let nullResponse = fixture.response(
      bodySchema: .object(["type": .string("null")])
    )
    let receipt = fixture.receipt(
      response: nullResponse,
      responseFixture: nil,
      fixtureOmissionReason: "The response body was intentionally omitted."
    )

    #expect(receipt.effectiveResponseFixture == nil)
    #expect(
      throws: trustRejection(
        "verification ver_products has no response fixture"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(
            operation: fixture.operation(response: nullResponse)
          ),
          receipts: [receipt]
        )
      )
    }
  }

  @Test("Authenticated and lifecycle evidence may omit private JSON fixtures")
  func acceptsSensitiveAuthenticatedFixtureOmission() throws {
    let fixture = Fixture()
    let cases:
      [(
        OperationClassification,
        AuthPolicy,
        TrustSessionAction?,
        EvidenceClass
      )] = [
        (
          .authenticatedBusiness,
          .bearerAccessToken,
          .validate,
          .directReplay
        ),
        (
          .sessionLifecycle,
          .refreshTokenOnly,
          .refresh,
          .lifecycleReplay
        ),
      ]

    for (classification, authPolicy, sessionAction, evidenceClass) in cases {
      let operation = fixture.operation(
        classification: classification,
        authPolicy: authPolicy
      )
      let decision = fixture.decision(
        authPolicy: authPolicy,
        sessionAction: sessionAction
      )
      let receipt = fixture.receipt(
        verificationKind: evidenceClass,
        requestEvidence: fixture.nativeRequestEvidence(),
        responseFixture: nil,
        fixtureOmissionReason:
          "The authenticated response contains private account or session values."
      )

      let policies = try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: decision),
          receipts: [receipt]
        )
      )
      #expect(policies.operations.count == 1)
      #expect(policies.operations.first?.fixturePaths == [])
    }
  }

  @Test("Reviewed textual extraction may omit a retained response fixture")
  func acceptsReviewedTextualFixtureOmission() throws {
    let fixture = Fixture()
    let textResponse = fixture.response(
      contentType: "text/html; charset=utf-8",
      bodySchema: .object(["type": .string("string")])
    )
    let extraction: JSONValue = .object([
      "kind": .string("javascriptAssignmentJSON"),
      "variable": .string("window.__PRODUCT_CONTEXT__"),
    ])
    let accepted = try TrustValidator().validate(
      fixture.input(
        manifest: fixture.manifest(
          decision: fixture.decision(responseExtraction: extraction)
        ),
        receipts: [
          fixture.receipt(
            response: textResponse,
            responseFixture: nil,
            fixtureOmissionReason: "The sanitized HTML body was not retained."
          )
        ]
      )
    )

    #expect(accepted.operations.first?.responseExtraction == extraction)
    #expect(accepted.operations.first?.fixturePaths == [])
  }

  @Test("Textual fixture omission requires reviewed extraction and a reason")
  func rejectsUnreviewedTextualFixtureOmission() {
    let fixture = Fixture()
    let textResponse = fixture.response(
      contentType: "text/html",
      bodySchema: .object(["type": .string("string")])
    )
    let extraction: JSONValue = .object(["kind": .string("htmlAttribute")])

    let missingExtraction = fixture.input(
      receipts: [
        fixture.receipt(
          response: textResponse,
          responseFixture: nil,
          fixtureOmissionReason: "The sanitized HTML body was not retained."
        )
      ]
    )
    #expect(
      throws: trustRejection(
        "verification ver_products has no response fixture"
      )
    ) {
      try TrustValidator().validate(missingExtraction)
    }

    let missingReason = fixture.input(
      manifest: fixture.manifest(
        decision: fixture.decision(responseExtraction: extraction)
      ),
      receipts: [
        fixture.receipt(
          response: textResponse,
          responseFixture: nil
        )
      ]
    )
    #expect(
      throws: trustRejection(
        "verification ver_products has no response fixture"
      )
    ) {
      try TrustValidator().validate(missingReason)
    }
  }

  @Test("Reviewed auth, route, safety, and family must equal Observed facts")
  func rejectsReviewedFactDrift() {
    let fixture = Fixture()
    let mismatches: [(TrustManifestOperation, String)] = [
      (
        fixture.decision(authPolicy: .bearerAccessToken),
        "reviewed auth policy does not match Observed annotation"
      ),
      (
        fixture.decision(routePolicy: .fixed(baseURL: "https://other.example")),
        "reviewed route policy does not match Observed annotation"
      ),
      (
        fixture.decision(safety: .reversibleWrite),
        "reviewed safety does not match Observed annotation"
      ),
      (
        fixture.decision(family: "wishlist"),
        "reviewed family does not match Observed annotation"
      ),
    ]

    for (decision, reason) in mismatches {
      #expect(throws: trustRejection(reason)) {
        try TrustValidator().validate(
          fixture.input(manifest: fixture.manifest(decision: decision))
        )
      }
    }
  }

  @Test("Session lifecycle requires dedicated lifecycle evidence")
  func sessionLifecycleDoesNotInheritBusinessEvidence() throws {
    let fixture = Fixture()
    let operation = fixture.operation(
      classification: .sessionLifecycle,
      authPolicy: .refreshTokenOnly
    )
    let decision = fixture.decision(
      authPolicy: .refreshTokenOnly,
      sessionAction: .refresh
    )
    let direct = fixture.input(
      catalog: fixture.catalog(operation: operation),
      manifest: fixture.manifest(decision: decision)
    )

    #expect(
      throws: trustRejection(
        "verification ver_products has directReplay evidence; lifecycleReplay is required"
      )
    ) {
      try TrustValidator().validate(direct)
    }

    let lifecycleReceipt = fixture.receipt(
      verificationKind: .lifecycleReplay,
      requestEvidence: fixture.nativeRequestEvidence()
    )
    let accepted = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(operation: operation),
        manifest: fixture.manifest(decision: decision),
        receipts: [lifecycleReceipt]
      )
    )
    #expect(accepted.operations.first?.sessionAction == .refresh)
    #expect(accepted.operations.first?.authPolicy == .refreshTokenOnly)
  }

  @Test("Authenticated and lifecycle operations reject browser-only evidence")
  func authenticatedOperationsRequireNativeRequestEvidence() {
    let fixture = Fixture()
    let operation = fixture.operation(
      classification: .authenticatedBusiness,
      authPolicy: .sessionHeadersAndCookies
    )
    let decision = fixture.decision(
      authPolicy: .sessionHeadersAndCookies
    )

    #expect(
      throws: trustRejection(
        "verification ver_products has no native request evidence"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: decision)
        )
      )
    }
  }

  @Test("Authenticated evidence binds the reviewed static request variant")
  func authenticatedEvidenceBindsReviewedVariant() throws {
    let fixture = Fixture()
    let routePolicy = RoutePolicy.provider(
      kind: "fixtureGateway",
      fields: [
        "baseURL": .string("https://example.com"),
        "staticHeaders": .object(["Origin": .string("https://example.com")]),
        "staticQuery": .object(["appKey": .string("reviewed")]),
      ]
    )
    let operation = fixture.operation(
      classification: .authenticatedBusiness,
      authPolicy: .sessionHeadersAndCookies,
      routePolicy: routePolicy
    )
    let decision = fixture.decision(
      authPolicy: .sessionHeadersAndCookies,
      routePolicy: routePolicy
    )
    let missingVariant = fixture.receipt(
      requestEvidence: fixture.nativeRequestEvidence()
    )
    let digest = try ReviewedRequestVariant.digest(routePolicy: routePolicy)
    let reviewedVariant = try #require(digest)

    #expect(
      throws: trustRejection(
        "verification ver_products does not prove the reviewed request variant "
          + "(expected \(reviewedVariant), received missing)"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: decision),
          receipts: [missingVariant]
        )
      )
    }

    let exact = fixture.receipt(
      requestEvidence: fixture.nativeRequestEvidence(
        headerNames: ["accept", "origin"],
        requestVariantSHA256: reviewedVariant
      )
    )
    let policies = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(operation: operation),
        manifest: fixture.manifest(decision: decision),
        receipts: [exact]
      )
    )
    #expect(policies.operations.count == 1)
  }

  @Test("Authenticated replay headers must be owned by the reviewed policy")
  func authenticatedReplayHeadersRequireReviewedOwnership() throws {
    let fixture = Fixture()
    let routePolicy = RoutePolicy.provider(
      kind: "fixtureGateway",
      fields: [
        "baseURL": .string("https://example.com"),
        "staticHeaders": .object([
          "Origin": .string("https://example.com")
        ]),
      ]
    )
    let operation = fixture.operation(
      classification: .authenticatedBusiness,
      authPolicy: .sessionHeadersAndCookies,
      routePolicy: routePolicy
    )
    let digest = try #require(
      try ReviewedRequestVariant.digest(routePolicy: routePolicy)
    )
    let receipt = fixture.receipt(
      requestEvidence: fixture.nativeRequestEvidence(
        headerNames: ["accept", "cookie", "origin", "user-agent"],
        requestVariantSHA256: digest
      )
    )
    let unowned = fixture.decision(
      authPolicy: .sessionHeadersAndCookies,
      routePolicy: routePolicy
    )

    #expect(
      throws: trustRejection(
        "verification ver_products uses request headers not owned by the reviewed policy: user-agent"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: unowned),
          receipts: [receipt]
        )
      )
    }

    let owned = fixture.decision(
      authPolicy: .sessionHeadersAndCookies,
      routePolicy: routePolicy,
      runtimeManagedHeaderNames: ["user-agent"]
    )
    let policies = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(operation: operation),
        manifest: fixture.manifest(decision: owned),
        receipts: [receipt]
      )
    )
    #expect(policies.operations.count == 1)
  }

  @Test("Declared runtime headers must appear in native replay")
  func declaredRuntimeHeadersRequireReplayEvidence() throws {
    let fixture = Fixture()
    let operation = fixture.operation(
      classification: .sessionLifecycle,
      authPolicy: .refreshTokenOnly
    )
    let decision = fixture.decision(
      authPolicy: .refreshTokenOnly,
      sessionAction: .refresh,
      runtimeManagedHeaderNames: ["x-session-environment"]
    )
    let receipt = fixture.receipt(
      verificationKind: .lifecycleReplay,
      requestEvidence: fixture.nativeRequestEvidence()
    )

    #expect(
      throws: trustRejection(
        "verification ver_products does not prove declared request headers: x-session-environment"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: decision),
          receipts: [receipt]
        )
      )
    }
  }

  @Test("Classified-only and high-risk operations remain Observed-only")
  func rejectsClassifiedOnlyAndHighRisk() {
    let fixture = Fixture()
    let classified = fixture.input(
      catalog: fixture.catalog(
        operation: fixture.operation(classification: .storefrontClassifiedOnly)
      )
    )
    #expect(
      throws: trustRejection(
        "classification storefront-classified-only is Observed-only"
      )
    ) {
      try TrustValidator().validate(classified)
    }

    let highRisk = fixture.input(
      catalog: fixture.catalog(
        operation: fixture.operation(safety: .highRiskWrite)
      ),
      manifest: fixture.manifest(
        decision: fixture.decision(safety: .highRiskWrite)
      )
    )
    #expect(
      throws: trustRejection(
        "high-risk writes remain Observed-only"
      )
    ) {
      try TrustValidator().validate(highRisk)
    }
  }

  @Test("Reversible writes require reciprocal exact restoration proof")
  func reversibleWritesRequireStrictRestoration() throws {
    let fixture = Fixture()
    let operation = fixture.operation(safety: .reversibleWrite)
    let decision = fixture.decision(
      safety: .reversibleWrite,
      reversibleMutation: true
    )
    let proof = fixture.restorationProof(receiptId: "ver_restore")
    let mutation = fixture.receipt(
      verificationKind: .reversibleWriteReplay,
      restoration: proof
    )
    let incomplete = fixture.input(
      catalog: fixture.catalog(operation: operation),
      manifest: fixture.manifest(decision: decision),
      receipts: [mutation]
    )
    #expect(
      throws: trustRejection(
        "reversible write lacks paired exact restoration evidence"
      )
    ) {
      try TrustValidator().validate(incomplete)
    }

    let restoration = fixture.receipt(
      verificationId: "ver_restore",
      verificationKind: .reversibleWriteReplay,
      restoration: fixture.restorationProof(receiptId: "ver_products")
    )
    let accepted = try TrustValidator().validate(
      fixture.input(
        catalog: fixture.catalog(operation: operation),
        manifest: fixture.manifest(decision: decision),
        receipts: [mutation, restoration]
      )
    )
    #expect(accepted.operations.first?.reversibleMutation == true)
  }

  @Test("Restoration proof permits one identity and rejects hash drift")
  func restorationProofRejectsHashDrift() {
    let fixture = Fixture()
    let operation = fixture.operation(safety: .reversibleWrite)
    let decision = fixture.decision(
      safety: .reversibleWrite,
      reversibleMutation: true
    )
    let mutation = fixture.receipt(
      verificationKind: .reversibleWriteReplay,
      restoration: fixture.restorationProof(receiptId: "ver_restore")
    )
    let restoration = fixture.receipt(
      verificationId: "ver_restore",
      verificationKind: .reversibleWriteReplay,
      restoration: fixture.restorationProof(
        receiptId: "ver_products",
        changedIdentitySHA256: String(repeating: "4", count: 64)
      )
    )

    #expect(
      throws: trustRejection(
        "reversible write lacks paired exact restoration evidence"
      )
    ) {
      try TrustValidator().validate(
        fixture.input(
          catalog: fixture.catalog(operation: operation),
          manifest: fixture.manifest(decision: decision),
          receipts: [mutation, restoration]
        )
      )
    }
  }
}

private struct Fixture {
  private let sourceReference = SourceReference(
    captureId: "cap_products",
    sourceId: "desktop-shell",
    sourceVersion: "v1"
  )

  func input(
    catalog: ObservedCatalog? = nil,
    sourceLock: SourceLock? = nil,
    manifest: TrustManifest? = nil,
    receipts: [TrustVerificationReceipt]? = nil
  ) -> TrustValidationInput {
    TrustValidationInput(
      catalog: catalog ?? self.catalog(),
      sourceLock: sourceLock ?? self.sourceLock(),
      manifest: manifest ?? self.manifest(),
      verifications: receipts ?? [receipt()]
    )
  }

  func catalog(operation: ObservedOperation? = nil) -> ObservedCatalog {
    ObservedCatalog(
      schemaVersion: 1,
      kind: "web-api-reverse.observed-catalog",
      brand: "fixture",
      market: "cn",
      updatedAt: "2026-07-29T00:00:00Z",
      operations: [operation ?? self.operation()]
    )
  }

  func operation(
    classification: OperationClassification = .publicCurrentFact,
    safety: OperationSafety = .safeRead,
    authPolicy: AuthPolicy = .none,
    routePolicy: RoutePolicy = .fixed(baseURL: "https://example.com"),
    request: RequestShape? = nil,
    response: ResponseShape? = nil,
    verificationIds: [String] = ["ver_products"]
  ) -> ObservedOperation {
    ObservedOperation(
      operationId: "get.products",
      fingerprint: String(repeating: "f", count: 64),
      method: "GET",
      urlTemplate: "https://example.com/products",
      protocol: .rest,
      serviceFamily: "catalog",
      productFamily: "products",
      classification: classification,
      safety: safety,
      authPolicy: authPolicy,
      routePolicy: routePolicy,
      request: request
        ?? RequestShape(
          contentType: nil,
          queryNames: [],
          headers: [],
          cookieNames: [],
          bodySchema: nil
        ),
      responses: [response ?? self.response()],
      sourceRefs: [sourceReference],
      verificationIds: verificationIds
    )
  }

  func sourceLock(
    status: SourceStatus = .captured,
    captureIds: [String] = ["cap_products"]
  ) -> SourceLock {
    SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: "fixture",
      market: "cn",
      sources: [
        SourceLockEntry(
          sourceId: "desktop-shell",
          surface: .web,
          version: "v1",
          coveragePolicy: .required,
          coverageRationale: nil,
          sha256: String(repeating: "a", count: 64),
          status: status,
          capturedAt: "2026-07-29T00:00:00Z",
          captureIds: captureIds,
          operationFingerprints: [String(repeating: "f", count: 64)]
        )
      ]
    )
  }

  func manifest(
    decision: TrustManifestOperation? = nil
  ) -> TrustManifest {
    TrustManifest(
      brand: "fixture",
      market: "cn",
      reviewedAt: "2026-07-29T00:00:00Z",
      operations: [decision ?? self.decision()]
    )
  }

  func decision(
    family: String = "catalog",
    authPolicy: AuthPolicy = .none,
    routePolicy: RoutePolicy = .fixed(baseURL: "https://example.com"),
    safety: OperationSafety = .safeRead,
    reversibleMutation: Bool = false,
    sessionAction: TrustSessionAction? = nil,
    runtimeManagedHeaderNames: [String] = [],
    useNamedComponents: Bool = false,
    responseContentTypeAliases: [String: String] = [:],
    responseExtraction: JSONValue? = nil,
    opaqueResponsePointers: [String] = [],
    evidenceIds: [String] = ["ver_products", "cap_products", "cap_products"]
  ) -> TrustManifestOperation {
    TrustManifestOperation(
      operationId: "get.products",
      clientOperationId: "getProducts",
      evidenceIds: evidenceIds,
      family: family,
      authPolicy: authPolicy,
      routePolicy: routePolicy,
      safety: safety,
      reversibleMutation: reversibleMutation,
      sessionAction: sessionAction,
      summary: "Get products",
      runtimeManagedHeaderNames: runtimeManagedHeaderNames,
      useNamedComponents: useNamedComponents,
      responseContentTypeAliases: responseContentTypeAliases,
      responseExtraction: responseExtraction,
      opaqueResponsePointers: opaqueResponsePointers
    )
  }

  func receipt(
    market: String = "cn",
    verificationId: String = "ver_products",
    verificationKind: EvidenceClass = .directReplay,
    sourceRefs: [SourceReference]? = nil,
    requestEvidence: VerificationRequestEvidence? = nil,
    response: ResponseShape? = nil,
    responseFixture: JSONValue? = .object(["items": .array([])]),
    fixtureOmissionReason: String? = nil,
    restoration: TrustRestorationProof? = nil
  ) -> TrustVerificationReceipt {
    TrustVerificationReceipt(
      brand: "fixture",
      market: market,
      verificationId: verificationId,
      verificationKind: verificationKind,
      verifiedAt: "2026-07-29T00:00:00Z",
      operationId: "get.products",
      fingerprint: String(repeating: "f", count: 64),
      sourceRefs: sourceRefs ?? [sourceReference],
      requestEvidence: requestEvidence,
      response: response ?? self.response(),
      responseFixture: responseFixture,
      fixtureOmissionReason: fixtureOmissionReason,
      restoration: restoration
    )
  }

  func response(
    status: Int = 200,
    outcome: ResponseOutcome = .success,
    contentType: String = "application/json",
    bodySchema: JSONValue = .object(["type": .string("object")])
  ) -> ResponseShape {
    ResponseShape(
      status: status,
      contentType: contentType,
      bodySchema: bodySchema,
      outcome: outcome,
      businessErrorSignals: []
    )
  }

  func nativeRequestEvidence(
    headerNames: [String] = ["accept"],
    requestVariantSHA256: String? = nil
  ) -> VerificationRequestEvidence {
    VerificationRequestEvidence(
      finalURLTemplate: "https://example.com/products",
      headerNames: headerNames,
      cookieNames: [],
      requestVariantSHA256: requestVariantSHA256
    )
  }

  func restorationProof(
    receiptId: String,
    changedIdentitySHA256: String = String(repeating: "3", count: 64)
  ) -> TrustRestorationProof {
    TrustRestorationProof(
      required: true,
      proven: true,
      receiptId: receiptId,
      beforeStateSHA256: String(repeating: "1", count: 64),
      mutatedStateSHA256: String(repeating: "2", count: 64),
      restoredStateSHA256: String(repeating: "1", count: 64),
      changedIdentitySHA256: changedIdentitySHA256,
      changedIdentityCount: 1
    )
  }
}

private func trustRejection(_ reason: String) -> TrustValidationError {
  .rejected(operationId: "get.products", reason: reason)
}
