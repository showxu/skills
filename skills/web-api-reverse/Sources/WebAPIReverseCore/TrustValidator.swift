import Foundation

public enum TrustValidationError: Error, Equatable, LocalizedError {
  case unsupportedSchema(Int)
  case invalidKind(String)
  case scopeMismatch(String)
  case duplicateIdentifier(String)
  case missingOperation(String)
  case rejected(operationId: String, reason: String)

  public var errorDescription: String? {
    switch self {
    case .unsupportedSchema(let version):
      "Unsupported trust evidence schema version: \(version)"
    case .invalidKind(let kind):
      "Invalid trust evidence artifact kind: \(kind)"
    case .scopeMismatch(let message):
      "Trust evidence scope mismatch: \(message)"
    case .duplicateIdentifier(let identifier):
      "Duplicate trust evidence identifier: \(identifier)"
    case .missingOperation(let operationId):
      "Trusted operation is absent from Observed catalog: \(operationId)"
    case .rejected(let operationId, let reason):
      "Trust rejected for \(operationId): \(reason)"
    }
  }
}

public struct TrustValidator: Sendable {
  public init() {}

  public func validate(_ input: TrustValidationInput) throws -> ValidatedOperationPolicies {
    try validateArtifacts(input)

    let operationById = try uniqueDictionary(
      input.catalog.operations,
      id: \.operationId
    )
    let verificationById = try uniqueDictionary(
      input.verifications,
      id: \.verificationId
    )
    _ = try uniqueDictionary(input.manifest.operations, id: \.operationId)

    var policies: [ValidatedOperationPolicy] = []
    for decision in input.manifest.operations {
      guard let operation = operationById[decision.operationId] else {
        throw TrustValidationError.missingOperation(decision.operationId)
      }
      let receipts = try validate(
        operation: operation,
        decision: decision,
        sourceLock: input.sourceLock,
        verificationById: verificationById
      )
      policies.append(
        makePolicy(
          operation: operation,
          decision: decision,
          receipts: receipts
        )
      )
    }

    return ValidatedOperationPolicies(
      brand: input.catalog.brand,
      market: input.catalog.market,
      operations: policies.sorted { $0.operationId < $1.operationId }
    )
  }

  private func validateArtifacts(_ input: TrustValidationInput) throws {
    let schemaVersions =
      [
        input.catalog.schemaVersion,
        input.sourceLock.schemaVersion,
        input.manifest.schemaVersion,
      ] + input.verifications.map(\.schemaVersion)
    if let unsupported = schemaVersions.first(where: { $0 != 1 }) {
      throw TrustValidationError.unsupportedSchema(unsupported)
    }

    try validate(
      kind: input.catalog.kind,
      allowed: [
        "lifewear.observed-catalog",
        "web-api-reverse.observed-catalog",
      ]
    )
    try validate(
      kind: input.sourceLock.kind,
      allowed: [
        "lifewear.source-lock",
        "web-api-reverse.source-lock",
      ]
    )
    try validate(
      kind: input.manifest.kind,
      allowed: [
        "lifewear.trust-manifest",
        "web-api-reverse.trust-manifest",
      ]
    )
    for receipt in input.verifications {
      try validate(
        kind: receipt.kind,
        allowed: [
          "lifewear.verification-receipt",
          "marketplace.verification-receipt",
          "web-api-reverse.verification-receipt",
        ]
      )
    }

    let scope = "\(input.catalog.brand)/\(input.catalog.market)"
    guard input.sourceLock.brand == input.catalog.brand,
      input.sourceLock.market == input.catalog.market
    else {
      throw TrustValidationError.scopeMismatch(
        "source lock \(input.sourceLock.brand)/\(input.sourceLock.market) != \(scope)"
      )
    }
    guard input.manifest.brand == input.catalog.brand,
      input.manifest.market == input.catalog.market
    else {
      throw TrustValidationError.scopeMismatch(
        "trust manifest \(input.manifest.brand)/\(input.manifest.market) != \(scope)"
      )
    }
    for receipt in input.verifications {
      guard receipt.brand == input.catalog.brand,
        receipt.market == input.catalog.market
      else {
        throw TrustValidationError.scopeMismatch(
          "verification \(receipt.verificationId) "
            + "\(receipt.brand)/\(receipt.market) != \(scope)"
        )
      }
    }
  }

  private func validate(
    operation: ObservedOperation,
    decision: TrustManifestOperation,
    sourceLock: SourceLock,
    verificationById: [String: TrustVerificationReceipt]
  ) throws -> [TrustVerificationReceipt] {
    guard operation.classification.isTrustEligible else {
      throw rejected(
        operation,
        "classification \(operation.classification.rawValue) is Observed-only"
      )
    }
    guard operation.safety != .highRiskWrite,
      decision.safety != .highRiskWrite
    else {
      throw rejected(operation, "high-risk writes remain Observed-only")
    }
    guard operation.safety != .unknown,
      decision.safety != .unknown
    else {
      throw rejected(operation, "unknown safety is not trustable")
    }
    guard operation.authPolicy != .unknown,
      decision.authPolicy != .unknown
    else {
      throw rejected(operation, "unknown authentication policy is not trustable")
    }
    guard !operation.routePolicy.isUnknown,
      !decision.routePolicy.isUnknown
    else {
      throw rejected(operation, "unknown route policy is not trustable")
    }
    guard operation.safety.rawValue == decision.safety.rawValue else {
      throw rejected(operation, "reviewed safety does not match Observed annotation")
    }
    guard operation.authPolicy.rawValue == decision.authPolicy.rawValue else {
      throw rejected(operation, "reviewed auth policy does not match Observed annotation")
    }
    guard operation.routePolicy == decision.routePolicy else {
      throw rejected(operation, "reviewed route policy does not match Observed annotation")
    }
    guard operation.serviceFamily == decision.family else {
      throw rejected(operation, "reviewed family does not match Observed annotation")
    }
    let opaqueResponsePointers = decision.opaqueResponsePointers ?? []
    guard Set(opaqueResponsePointers).count == opaqueResponsePointers.count,
      opaqueResponsePointers.allSatisfy(isValidResponsePointer)
    else {
      throw rejected(
        operation,
        "opaque response pointers must be unique absolute JSON Pointers"
      )
    }
    guard hasShapedSuccess(operation.responses) else {
      throw rejected(operation, "Observed evidence has no shaped success response")
    }

    let captureIds = Set(operation.sourceRefs.map(\.captureId))
    guard !captureIds.isDisjoint(with: decision.evidenceIds) else {
      throw rejected(operation, "trust decision does not reference its capture evidence")
    }
    try validateSources(
      operation: operation,
      sourceLock: sourceLock
    )

    let verificationIds = Set(
      decision.evidenceIds.filter { $0.hasPrefix("ver_") }
    )
    guard !verificationIds.isEmpty else {
      throw rejected(operation, "trust decision requires live verification evidence")
    }
    let expectedKind = expectedVerificationKind(for: operation)
    var selected: [TrustVerificationReceipt] = []
    for verificationId in verificationIds.sorted() {
      guard let receipt = verificationById[verificationId] else {
        throw rejected(operation, "verification evidence \(verificationId) was not provided")
      }
      guard receipt.operationId == operation.operationId,
        receipt.fingerprint == operation.fingerprint
      else {
        throw rejected(operation, "verification \(verificationId) belongs to another operation")
      }
      guard Set(receipt.sourceRefs) == Set(operation.sourceRefs) else {
        throw rejected(
          operation,
          "verification \(verificationId) does not cover the exact Observed source set"
        )
      }
      guard receipt.verificationKind == expectedKind else {
        throw rejected(
          operation,
          "verification \(verificationId) has \(receipt.verificationKind.rawValue) evidence; "
            + "\(expectedKind.rawValue) is required"
        )
      }
      selected.append(receipt)
    }

    for receipt in selected {
      try validateSuccess(
        receipt,
        operation: operation,
        decision: decision,
        selectedReceipts: selected
      )
      try validateNativeRequestEvidence(
        receipt,
        operation: operation,
        decision: decision
      )
    }

    try validateAuthenticationEvidence(
      selected,
      operation: operation
    )
    try validateResponseContentTypeAliases(
      decision.responseContentTypeAliases,
      operation: operation,
      receipts: selected
    )

    if decision.safety == .reversibleWrite {
      guard decision.reversibleMutation else {
        throw rejected(operation, "reversible write must be explicitly marked reversible")
      }
      for receipt in selected {
        guard
          hasStrictRestorationPair(
            receipt,
            verificationById: verificationById
          )
        else {
          throw rejected(operation, "reversible write lacks paired exact restoration evidence")
        }
      }
    } else if decision.reversibleMutation {
      throw rejected(operation, "safe read cannot be marked as a reversible mutation")
    }

    return selected
  }

  private func validateNativeRequestEvidence(
    _ receipt: TrustVerificationReceipt,
    operation: ObservedOperation,
    decision: TrustManifestOperation
  ) throws {
    guard
      operation.classification == .sessionLifecycle
        || operation.classification == .authenticatedBusiness
    else {
      return
    }
    guard let request = receipt.requestEvidence else {
      throw rejected(
        operation,
        "verification \(receipt.verificationId) has no native request evidence"
      )
    }
    guard request.finalURLTemplate == operation.urlTemplate else {
      throw rejected(
        operation,
        "verification \(receipt.verificationId) native request URL does not match Observed"
      )
    }
    if let expected = try ReviewedRequestVariant.digest(
      routePolicy: decision.routePolicy
    ) {
      guard request.requestVariantSHA256 == expected else {
        throw rejected(
          operation,
          "verification \(receipt.verificationId) does not prove the reviewed request variant "
            + "(expected \(expected), received \(request.requestVariantSHA256 ?? "missing"))"
        )
      }
    }
    try validateNativeRequestHeaderOwnership(
      request,
      verificationId: receipt.verificationId,
      operation: operation,
      decision: decision
    )
  }

  private func validateNativeRequestHeaderOwnership(
    _ request: VerificationRequestEvidence,
    verificationId: String,
    operation: ObservedOperation,
    decision: TrustManifestOperation
  ) throws {
    let replayHeaders = Set(request.headerNames.map { $0.lowercased() })
    let staticHeaders = reviewedStaticHeaderNames(decision.routePolicy)
    let managedHeaders = Set(
      (decision.runtimeManagedHeaderNames ?? []).map { $0.lowercased() }
    )
    let declaredHeaders = staticHeaders.union(managedHeaders)
    let missing = declaredHeaders.subtracting(replayHeaders).sorted()
    guard missing.isEmpty else {
      throw rejected(
        operation,
        "verification \(verificationId) does not prove declared request headers: "
          + missing.joined(separator: ", ")
      )
    }

    var implicitlyOwned: Set<String> = [
      "accept",
      "content-length",
      "content-type",
      "host",
    ]
    switch decision.authPolicy {
    case .sessionHeadersAndCookies:
      implicitlyOwned.insert("cookie")
    case .bearerAccessToken, .accessAndRefreshToken:
      implicitlyOwned.insert("authorization")
    case .none, .refreshTokenOnly, .unknown:
      break
    }
    let unowned =
      replayHeaders
      .subtracting(declaredHeaders)
      .subtracting(implicitlyOwned)
      .sorted()
    guard unowned.isEmpty else {
      throw rejected(
        operation,
        "verification \(verificationId) uses request headers not owned by the reviewed policy: "
          + unowned.joined(separator: ", ")
      )
    }
  }

  private func reviewedStaticHeaderNames(
    _ routePolicy: RoutePolicy
  ) -> Set<String> {
    guard case .provider(_, let fields) = routePolicy,
      case .object(let headers) = fields["staticHeaders"]
    else {
      return []
    }
    return Set(headers.keys.map { $0.lowercased() })
  }

  private func validateSources(
    operation: ObservedOperation,
    sourceLock: SourceLock
  ) throws {
    for reference in operation.sourceRefs {
      let matching = sourceLock.sources.filter {
        $0.sourceId == reference.sourceId
          && $0.version == reference.sourceVersion
      }
      guard matching.count == 1, let source = matching.first else {
        throw rejected(
          operation,
          "source \(reference.sourceId)@\(reference.sourceVersion) is not uniquely locked"
        )
      }
      guard source.status == .captured else {
        throw rejected(
          operation,
          "source \(reference.sourceId)@\(reference.sourceVersion) is not fully captured"
        )
      }
      guard source.captureIds.contains(reference.captureId),
        source.operationFingerprints.contains(operation.fingerprint)
      else {
        throw rejected(
          operation,
          "source \(reference.sourceId)@\(reference.sourceVersion) "
            + "does not lock the referenced capture and fingerprint"
        )
      }
    }
  }

  private func validateSuccess(
    _ receipt: TrustVerificationReceipt,
    operation: ObservedOperation,
    decision: TrustManifestOperation,
    selectedReceipts: [TrustVerificationReceipt]
  ) throws {
    let status = receipt.response.status
    guard (200..<300).contains(status),
      status != 401,
      status != 403
    else {
      throw rejected(operation, "verification \(receipt.verificationId) is not an HTTP success")
    }
    guard receipt.response.outcome == .success else {
      throw rejected(
        operation,
        "verification \(receipt.verificationId) does not prove business success"
      )
    }
    guard status == 204 || receipt.response.bodySchema != nil else {
      throw rejected(operation, "verification \(receipt.verificationId) has no response shape")
    }
    let reviewedFixtureOmission =
      decision.responseExtraction != nil
      && receipt.response.contentType?.lowercased()
        .hasPrefix("text/") == true
      && isStringSchema(receipt.response.bodySchema)
      && receipt.fixtureOmissionReason?
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let sensitiveAuthenticatedFixtureOmission =
      [
        OperationClassification.authenticatedBusiness,
        .sessionLifecycle,
      ].contains(operation.classification)
      && receipt.requestEvidence != nil
      && receipt.fixtureOmissionReason?
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let splitAnonymousFixtureOmission =
      operation.authPolicy == .none
      && receipt.requestEvidence != nil
      && receipt.fixtureOmissionReason?
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
      && selectedReceipts.contains {
        $0.verificationId != receipt.verificationId
          && $0.effectiveResponseFixture != nil
      }
    guard
      status == 204 || receipt.effectiveResponseFixture != nil
        || reviewedFixtureOmission
        || sensitiveAuthenticatedFixtureOmission
        || splitAnonymousFixtureOmission
    else {
      throw rejected(operation, "verification \(receipt.verificationId) has no response fixture")
    }
    do {
      if reviewedFixtureOmission {
        try ReviewedResponseExtractor.validatePolicy(
          decision.responseExtraction
        )
      } else if sensitiveAuthenticatedFixtureOmission
        || splitAnonymousFixtureOmission
      {
        // Authenticated response values stay private. Their reviewed schema
        // and native request proof are sufficient for contract projection.
      } else {
        _ = try ReviewedResponseExtractor.project(
          response: receipt.response,
          fixture: receipt.effectiveResponseFixture,
          policy: decision.responseExtraction
        )
      }
    } catch {
      throw rejected(
        operation,
        "verification \(receipt.verificationId) response extraction failed: \(error.localizedDescription)"
      )
    }
  }

  private func isStringSchema(_ value: JSONValue?) -> Bool {
    guard case .object(let schema) = value else {
      return false
    }
    return schema["type"] == .string("string")
  }

  private func validateAuthenticationEvidence(
    _ receipts: [TrustVerificationReceipt],
    operation: ObservedOperation
  ) throws {
    if let reason = AuthenticationEvidenceContract.rejectionReason(
      operation: operation,
      receipts: receipts
    ) {
      throw rejected(operation, reason)
    }
  }

  private func hasStrictRestorationPair(
    _ receipt: TrustVerificationReceipt,
    verificationById: [String: TrustVerificationReceipt]
  ) -> Bool {
    guard hasStrictRestoration(receipt),
      let proof = receipt.restoration,
      let pairId = proof.receiptId,
      pairId != receipt.verificationId,
      let paired = verificationById[pairId],
      paired.brand == receipt.brand,
      paired.market == receipt.market,
      paired.verificationKind == .reversibleWriteReplay,
      paired.restoration?.receiptId == receipt.verificationId,
      hasStrictRestoration(paired),
      isSuccessful(paired.response),
      paired.response.status == 204
        || paired.effectiveResponseFixture != nil,
      let pairedProof = paired.restoration
    else {
      return false
    }
    return proof.beforeStateSHA256 == pairedProof.beforeStateSHA256
      && proof.mutatedStateSHA256 == pairedProof.mutatedStateSHA256
      && proof.restoredStateSHA256 == pairedProof.restoredStateSHA256
      && proof.changedIdentitySHA256 == pairedProof.changedIdentitySHA256
      && proof.changedIdentityCount == pairedProof.changedIdentityCount
  }

  private func hasStrictRestoration(_ receipt: TrustVerificationReceipt) -> Bool {
    guard let proof = receipt.restoration,
      proof.required,
      proof.proven,
      let receiptId = proof.receiptId,
      !receiptId.isEmpty,
      isSHA256(proof.beforeStateSHA256),
      isSHA256(proof.mutatedStateSHA256),
      isSHA256(proof.restoredStateSHA256),
      isSHA256(proof.changedIdentitySHA256),
      proof.beforeStateSHA256 == proof.restoredStateSHA256,
      proof.beforeStateSHA256 != proof.mutatedStateSHA256,
      proof.changedIdentityCount == 1
    else {
      return false
    }
    return true
  }

  private func makePolicy(
    operation: ObservedOperation,
    decision: TrustManifestOperation,
    receipts: [TrustVerificationReceipt]
  ) -> ValidatedOperationPolicy {
    let fixturePaths =
      receipts
      .filter {
        decision.authPolicy == .none && $0.effectiveResponseFixture != nil
      }
      .map {
        "fixtures/\(safePathComponent(operation.operationId))/\($0.verificationId).json"
      }
      .sorted()
    let revisions = Set(
      operation.sourceRefs.map { "\($0.sourceId)@\($0.sourceVersion)" }
    ).sorted()
    return ValidatedOperationPolicy(
      operationId: operation.operationId,
      clientOperationId: decision.clientOperationId,
      method: operation.method,
      path: decision.publishedPath ?? operationPath(operation),
      wirePath: operationPath(operation),
      classification: operation.classification,
      serviceFamily: decision.family,
      authPolicy: decision.authPolicy,
      routePolicy: decision.routePolicy,
      safety: decision.safety,
      sessionAction: decision.sessionAction,
      evidenceIds: Array(Set(decision.evidenceIds)).sorted(),
      sourceRevisions: revisions,
      reversibleMutation: decision.reversibleMutation,
      fixturePaths: fixturePaths,
      runtimeManagedQueryNames: decision.runtimeManagedQueryNames ?? [],
      runtimeManagedHeaderNames: decision.runtimeManagedHeaderNames ?? [],
      runtimeManagedCookieNames: decision.runtimeManagedCookieNames ?? [],
      encodedQueryBodyNames:
        operation.request.encodedQuerySchemas?.keys.sorted() ?? [],
      encodedBodyFieldNames:
        operation.request.encodedBodySchemas?.keys.sorted() ?? [],
      responseContentTypeAliases: MediaTypeFacts.responseAliases(
        observed: operation.responses,
        verified: receipts
      ).merging(decision.responseContentTypeAliases ?? [:]) {
        _, reviewed in reviewed
      },
      pathParameterNames: decision.pathParameterNames,
      useNamedComponents: decision.useNamedComponents == true,
      responseExtraction: decision.responseExtraction,
      opaqueResponsePointers: decision.opaqueResponsePointers ?? []
    )
  }

  private func validateResponseContentTypeAliases(
    _ aliases: [String: String]?,
    operation: ObservedOperation,
    receipts: [TrustVerificationReceipt]
  ) throws {
    guard let aliases else { return }
    let observed = Set(
      (operation.responses.compactMap(\.contentType)
        + receipts.compactMap(\.response.contentType))
        .map(MediaTypeFacts.normalized)
    )
    let mediaTypePattern =
      #"^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$"#
    for (source, destination) in aliases {
      let normalizedSource = MediaTypeFacts.normalized(source)
      let normalizedDestination = MediaTypeFacts.normalized(destination)
      guard observed.contains(normalizedSource) else {
        throw rejected(
          operation,
          "reviewed response content-type alias source was not observed"
        )
      }
      guard
        normalizedSource != normalizedDestination,
        normalizedSource.range(
          of: mediaTypePattern,
          options: .regularExpression
        ) != nil,
        normalizedDestination.range(
          of: mediaTypePattern,
          options: .regularExpression
        ) != nil
      else {
        throw rejected(
          operation,
          "reviewed response content-type alias is invalid"
        )
      }
    }
  }

  private func isValidResponsePointer(_ pointer: String) -> Bool {
    guard pointer.hasPrefix("/"), pointer.count > 1 else { return false }
    return pointer.dropFirst().split(separator: "/", omittingEmptySubsequences: false)
      .allSatisfy { component in
        !component.isEmpty
          && component.range(
            of: #"~(?![01])"#,
            options: .regularExpression
          ) == nil
      }
  }

  private func operationPath(_ operation: ObservedOperation) -> String {
    if case .sessionEnvironment(let path) = operation.routePolicy {
      return path
    }
    return URLComponents(string: operation.urlTemplate)?.percentEncodedPath
      ?? operation.urlTemplate
  }

  private func expectedVerificationKind(
    for operation: ObservedOperation
  ) -> EvidenceClass {
    if operation.safety == .reversibleWrite {
      return .reversibleWriteReplay
    }
    if operation.classification == .sessionLifecycle {
      return .lifecycleReplay
    }
    return .directReplay
  }

  private func hasShapedSuccess(_ responses: [ResponseShape]) -> Bool {
    responses.contains { response in
      isSuccessful(response)
        && (response.status == 204 || response.bodySchema != nil)
    }
  }

  private func isSuccessful(_ response: ResponseShape) -> Bool {
    (200..<300).contains(response.status)
      && response.status != 401
      && response.status != 403
      && response.outcome == .success
  }

  private func isSHA256(_ value: String?) -> Bool {
    guard let value, value.count == 64 else {
      return false
    }
    return value.allSatisfy {
      ("a"..."f").contains(String($0))
        || ("0"..."9").contains(String($0))
    }
  }

  private func safePathComponent(_ value: String) -> String {
    String(
      value.map {
        $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "_"
          ? $0
          : "_"
      }
    )
  }

  private func validate(kind: String, allowed: Set<String>) throws {
    guard allowed.contains(kind) else {
      throw TrustValidationError.invalidKind(kind)
    }
  }

  private func uniqueDictionary<Element>(
    _ values: [Element],
    id: KeyPath<Element, String>
  ) throws -> [String: Element] {
    var result: [String: Element] = [:]
    for value in values {
      let identifier = value[keyPath: id]
      guard result.updateValue(value, forKey: identifier) == nil else {
        throw TrustValidationError.duplicateIdentifier(identifier)
      }
    }
    return result
  }

  private func rejected(
    _ operation: ObservedOperation,
    _ reason: String
  ) -> TrustValidationError {
    .rejected(operationId: operation.operationId, reason: reason)
  }
}

enum AuthenticationEvidenceContract {
  static func rejectionReason(
    operation: ObservedOperation,
    receipts: [TrustVerificationReceipt]
  ) -> String? {
    guard operation.authPolicy == .none else { return nil }

    let observedCookieNames = Set(operation.request.cookieNames)
    let observedAuthorizationHeaders = Set(
      operation.request.headers
        .map { $0.name.lowercased() }
        .filter(isAuthenticationHeader)
    )
    guard
      !observedCookieNames.isEmpty || !observedAuthorizationHeaders.isEmpty
    else {
      return nil
    }

    var rejectionReasons: [String] = []
    for receipt in receipts {
      guard let request = receipt.requestEvidence else {
        rejectionReasons.append(
          "verification \(receipt.verificationId) does not prove an unauthenticated request shape"
        )
        continue
      }
      guard request.finalURLTemplate == operation.urlTemplate else {
        rejectionReasons.append(
          "verification \(receipt.verificationId) request URL does not match Observed"
        )
        continue
      }
      guard request.cookieNames.isEmpty else {
        rejectionReasons.append(
          "verification \(receipt.verificationId) used cookies but auth policy is none"
        )
        continue
      }
      let replayAuthorizationHeaders = request.headerNames
        .map { $0.lowercased() }
        .filter(isAuthenticationHeader)
      guard replayAuthorizationHeaders.isEmpty else {
        rejectionReasons.append(
          "verification \(receipt.verificationId) used authentication headers but auth policy is none"
        )
        continue
      }
      return nil
    }

    if rejectionReasons.count == 1 {
      return rejectionReasons[0]
    }
    return
      "verification evidence does not include an exact unauthenticated request shape"
  }

  private static func isAuthenticationHeader(_ name: String) -> Bool {
    ["authorization", "cookie", "proxy-authorization"].contains(name)
  }
}
