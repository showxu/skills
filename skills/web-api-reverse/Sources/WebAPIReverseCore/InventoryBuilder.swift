import Foundation

public enum InventoryBuilder {
  public static func build(
    receipts: [CaptureReceipt],
    annotations: AnnotationFile? = nil,
    sourceManifest: SourceManifest? = nil,
    verifications: [TrustVerificationReceipt] = [],
    sourceProductVerifications: [SourceProductVerificationReceipt] = []
  ) throws -> InventoryResult {
    guard let firstReceipt = receipts.first else {
      throw CapturePipelineError.emptyInventory
    }
    let brand = firstReceipt.brand
    let market = firstReceipt.market
    for receipt in receipts
    where receipt.brand != brand || receipt.market != market {
      throw CapturePipelineError.scopeMismatch(
        expectedBrand: brand,
        expectedMarket: market
      )
    }
    if let annotations {
      guard annotations.brand == brand, annotations.market == market else {
        throw CapturePipelineError.scopeMismatch(
          expectedBrand: brand,
          expectedMarket: market
        )
      }
      try validateAnnotations(annotations)
    }
    if let sourceManifest {
      guard sourceManifest.brand == brand, sourceManifest.market == market else {
        throw CapturePipelineError.scopeMismatch(
          expectedBrand: brand,
          expectedMarket: market
        )
      }
      try validateSourceManifest(sourceManifest)
    }
    try validateVerifications(
      verifications,
      brand: brand,
      market: market
    )
    try validateSourceProductVerifications(
      sourceProductVerifications,
      brand: brand,
      market: market
    )
    let uniqueVerifications = verifications.reduce(
      into: [String: TrustVerificationReceipt]()
    ) {
      $0[$1.verificationId] = $1
    }.values.sorted { $0.verificationId < $1.verificationId }

    let annotationsByFingerprint = Dictionary(
      uniqueKeysWithValues: (annotations?.operations ?? []).map {
        ($0.fingerprint, $0)
      }
    )
    var groups: [String: [(CaptureReceipt, SanitizedExchange)]] = [:]
    for receipt in receipts.sorted(by: { $0.captureId < $1.captureId }) {
      for exchange in receipt.exchanges
      where annotationsByFingerprint[exchange.fingerprint] != nil
        || isObservedCandidate(
          receipt: receipt,
          exchange: exchange
        )
      {
        groups[exchange.fingerprint, default: []].append((receipt, exchange))
      }
    }
    let operations = try groups.map { fingerprint, group in
      try makeOperation(
        fingerprint: fingerprint,
        group: group,
        annotation: annotationsByFingerprint[fingerprint],
        verifications: uniqueVerifications
      )
    }.sorted { $0.operationId < $1.operationId }
    let catalog = ObservedCatalog(
      schemaVersion: 1,
      kind: "web-api-reverse.observed-catalog",
      brand: brand,
      market: market,
      updatedAt: (receipts.map(\.capturedAt)
        + uniqueVerifications.map(\.verifiedAt)
        + sourceProductVerifications.map(\.verifiedAt)).sorted().last
        ?? "1970-01-01T00:00:00.000Z",
      operations: operations
    )
    return InventoryResult(
      catalog: catalog,
      sourceLock: try makeSourceLock(
        brand: brand,
        market: market,
        receipts: receipts,
        operations: operations,
        manifest: sourceManifest,
        sourceProductVerifications: sourceProductVerifications
      )
    )
  }

  public static func bindingCurrentVerifications(
    to catalog: ObservedCatalog,
    verifications: [TrustVerificationReceipt]
  ) throws -> ObservedCatalog {
    try validateVerifications(
      verifications,
      brand: catalog.brand,
      market: catalog.market
    )
    let operations = catalog.operations.map { operation in
      ObservedOperation(
        operationId: operation.operationId,
        fingerprint: operation.fingerprint,
        method: operation.method,
        urlTemplate: operation.urlTemplate,
        protocol: operation.protocol,
        serviceFamily: operation.serviceFamily,
        productFamily: operation.productFamily,
        classification: operation.classification,
        safety: operation.safety,
        authPolicy: operation.authPolicy,
        routePolicy: operation.routePolicy,
        routeDiscriminators: operation.routeDiscriminators ?? [:],
        request: operation.request,
        responses: operation.responses,
        sourceRefs: operation.sourceRefs,
        verificationIds: provenVerificationIDs(
          verifications.filter {
            $0.operationId == operation.operationId
              && $0.fingerprint == operation.fingerprint
          },
          allReceipts: verifications,
          operationID: operation.operationId,
          classification: operation.classification,
          safety: operation.safety,
          sourceRefs: Set(operation.sourceRefs)
        )
      )
    }
    return ObservedCatalog(
      schemaVersion: catalog.schemaVersion,
      kind: catalog.kind,
      brand: catalog.brand,
      market: catalog.market,
      updatedAt: catalog.updatedAt,
      operations: operations
    )
  }

  public static func isObservedCandidate(
    receipt: CaptureReceipt,
    exchange: SanitizedExchange
  ) -> Bool {
    if let entryURL = receipt.source.entryURL,
      sameNavigationResource(entryURL, exchange.sanitizedURL)
    {
      return true
    }
    if exchange.protocol == .graphql || exchange.protocol == .persistedQuery {
      return true
    }
    if [exchange.request.contentType, exchange.response.contentType]
      .compactMap({ $0 })
      .contains(where: {
        $0.range(
          of: #"\b(?:json|graphql)\b"#,
          options: [.regularExpression, .caseInsensitive]
        ) != nil
      })
    {
      return true
    }
    guard
      let path = URLComponents(string: exchange.sanitizedURL)?
        .path.lowercased()
    else {
      return false
    }
    return path.range(
      of: #"(?:^|/)(?:api|graphql|gql|p|h)(?:/|$)"#,
      options: .regularExpression
    ) != nil || path.hasSuffix(".json")
  }

  private static func validateAnnotations(_ file: AnnotationFile) throws {
    var fingerprints: Set<String> = []
    var operationIds: Set<String> = []
    for annotation in file.operations {
      guard fingerprints.insert(annotation.fingerprint).inserted else {
        throw CapturePipelineError.duplicateAnnotation(annotation.fingerprint)
      }
      if let operationId = annotation.operationId,
        !operationIds.insert(operationId).inserted
      {
        throw CapturePipelineError.duplicateAnnotation(operationId)
      }
    }
  }

  private static func validateSourceManifest(_ manifest: SourceManifest) throws {
    var keys: Set<String> = []
    var coverageSources: [SourceCoverageContract.Source] = []
    for source in manifest.sources {
      let key = sourceKey(source.sourceId, source.version)
      guard keys.insert(key).inserted else {
        throw CapturePipelineError.duplicateSourceRevision(key)
      }
      let policy = source.coveragePolicy ?? .required
      if policy != .required,
        source.coverageRationale?
          .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
      {
        throw CapturePipelineError.missingCoverageRationale(key)
      }
      coverageSources.append(
        SourceCoverageContract.Source(
          key: key,
          policy: policy,
          areas: source.coverageAreas
        )
      )
    }
    _ = try SourceCoverageContract.validate(
      requiredAreas: manifest.requiredCoverageAreas,
      sources: coverageSources
    )
  }

  private static func validateVerifications(
    _ receipts: [TrustVerificationReceipt],
    brand: String,
    market: String
  ) throws {
    var byID: [String: TrustVerificationReceipt] = [:]
    for receipt in receipts {
      guard receipt.schemaVersion == 1 else {
        throw EvidenceScopeError.unsupportedSchema(receipt.schemaVersion)
      }
      guard
        [
          "lifewear.verification-receipt",
          "marketplace.verification-receipt",
          "web-api-reverse.verification-receipt",
        ].contains(receipt.kind)
      else {
        throw EvidenceScopeError.invalidKind(receipt.kind)
      }
      guard receipt.brand == brand, receipt.market == market else {
        throw EvidenceScopeError.mismatch(
          "\(receipt.verificationId) \(receipt.brand)/\(receipt.market) "
            + "vs \(brand)/\(market)"
        )
      }
      if let existing = byID[receipt.verificationId],
        existing != receipt
      {
        throw EvidenceScopeError.mismatch(
          "conflicting verification \(receipt.verificationId)"
        )
      }
      byID[receipt.verificationId] = receipt
    }
  }

  private static func validateSourceProductVerifications(
    _ receipts: [SourceProductVerificationReceipt],
    brand: String,
    market: String
  ) throws {
    var byID: [String: SourceProductVerificationReceipt] = [:]
    for receipt in receipts {
      try SourceProductVerifier.validate(receipt)
      guard receipt.provider == brand, receipt.market == market else {
        throw EvidenceScopeError.mismatch(
          "\(receipt.verificationId) \(receipt.provider)/\(receipt.market) "
            + "vs \(brand)/\(market)"
        )
      }
      if let existing = byID[receipt.verificationId],
        existing != receipt
      {
        throw EvidenceScopeError.mismatch(
          "conflicting source product verification \(receipt.verificationId)"
        )
      }
      byID[receipt.verificationId] = receipt
    }
  }

  private static func makeOperation(
    fingerprint: String,
    group: [(CaptureReceipt, SanitizedExchange)],
    annotation: OperationAnnotation?,
    verifications: [TrustVerificationReceipt]
  ) throws -> ObservedOperation {
    guard let first = group.first else {
      throw CapturePipelineError.emptyInventory
    }
    var sourceRefs: Set<SourceReference> = []
    for (receipt, _) in group {
      sourceRefs.insert(
        SourceReference(
          captureId: receipt.captureId,
          sourceId: receipt.source.sourceId,
          sourceVersion: receipt.source.version
        )
      )
    }
    let operationID = annotation?.operationId ?? first.1.operationId
    let matchingVerifications = verifications.filter {
      $0.operationId == operationID && $0.fingerprint == fingerprint
    }
    let responseGroups = Dictionary(
      grouping: group.map(\.1.response) + matchingVerifications.map(\.response)
    ) {
      "\($0.status):\($0.contentType ?? ""):\($0.outcome.rawValue)"
    }
    let responses = responseGroups.keys.sorted().compactMap { key in
      responseGroups[key].map(mergeResponses)
    }.sorted {
      ($0.status, $0.contentType ?? "", $0.outcome.rawValue)
        < ($1.status, $1.contentType ?? "", $1.outcome.rawValue)
    }
    return ObservedOperation(
      operationId: operationID,
      fingerprint: fingerprint,
      method: first.1.method,
      urlTemplate: first.1.urlTemplate,
      protocol: first.1.protocol,
      serviceFamily: annotation?.serviceFamily ?? "unknown",
      productFamily: annotation?.productFamily ?? "unknown",
      classification: annotation?.classification ?? .unknown,
      safety: annotation?.safety ?? .unknown,
      authPolicy: annotation?.authPolicy ?? .unknown,
      routePolicy: annotation?.routePolicy ?? .unknown,
      routeDiscriminators: first.1.routeDiscriminators ?? [:],
      request: mergeRequests(group.map(\.1.request)),
      responses: responses,
      sourceRefs: sourceRefs.sorted {
        ($0.sourceId, $0.sourceVersion, $0.captureId)
          < ($1.sourceId, $1.sourceVersion, $1.captureId)
      },
      verificationIds: provenVerificationIDs(
        matchingVerifications,
        allReceipts: verifications,
        operationID: operationID,
        classification: annotation?.classification ?? .unknown,
        safety: annotation?.safety ?? .unknown,
        sourceRefs: sourceRefs
      )
    )
  }

  private static func provenVerificationIDs(
    _ receipts: [TrustVerificationReceipt],
    allReceipts: [TrustVerificationReceipt],
    operationID: String,
    classification: OperationClassification,
    safety: OperationSafety,
    sourceRefs: Set<SourceReference>
  ) -> [String] {
    let byID = allReceipts.reduce(
      into: [String: TrustVerificationReceipt]()
    ) {
      $0[$1.verificationId] = $1
    }
    return receipts.filter { receipt in
      guard receipt.operationId == operationID,
        Set(receipt.sourceRefs) == sourceRefs,
        (200..<300).contains(receipt.response.status),
        receipt.response.status != 401,
        receipt.response.status != 403,
        receipt.response.outcome == .success,
        receipt.response.status == 204
          || (receipt.response.bodySchema != nil
            && (receipt.effectiveResponseFixture != nil
              || receipt.fixtureOmissionReason?
                .trimmingCharacters(
                  in: .whitespacesAndNewlines
                ).isEmpty == false))
      else {
        return false
      }
      let expectedKind: EvidenceClass
      if safety == .reversibleWrite {
        expectedKind = .reversibleWriteReplay
      } else if classification == .sessionLifecycle {
        expectedKind = .lifecycleReplay
      } else {
        expectedKind = .directReplay
      }
      guard receipt.verificationKind == expectedKind else {
        return false
      }
      if safety == .reversibleWrite {
        return hasReciprocalRestoration(receipt, byID: byID)
      }
      return safety == .safeRead
    }.map(\.verificationId).sorted()
  }

  private static func hasReciprocalRestoration(
    _ receipt: TrustVerificationReceipt,
    byID: [String: TrustVerificationReceipt]
  ) -> Bool {
    guard let proof = receipt.restoration,
      proof.required,
      proof.proven,
      proof.beforeStateSHA256 == proof.restoredStateSHA256,
      proof.beforeStateSHA256 != proof.mutatedStateSHA256,
      proof.changedIdentityCount == 1,
      let pairID = proof.receiptId,
      pairID != receipt.verificationId,
      let pair = byID[pairID],
      pair.restoration?.receiptId == receipt.verificationId,
      pair.restoration
        == TrustRestorationProof(
          required: proof.required,
          proven: proof.proven,
          receiptId: receipt.verificationId,
          beforeStateSHA256: proof.beforeStateSHA256,
          mutatedStateSHA256: proof.mutatedStateSHA256,
          restoredStateSHA256: proof.restoredStateSHA256,
          changedIdentitySHA256: proof.changedIdentitySHA256,
          changedIdentityCount: proof.changedIdentityCount
        )
    else {
      return false
    }
    return true
  }

  private static func mergeRequests(_ requests: [RequestShape]) -> RequestShape {
    var headers: [String: HeaderPresence] = [:]
    for request in requests {
      for header in request.headers {
        let existing = headers[header.name]
        headers[header.name] = HeaderPresence(
          name: header.name,
          present: true,
          sensitive: existing?.sensitive == true || header.sensitive
        )
      }
    }
    let schemas = requests.compactMap(\.bodySchema)
    let encodedQuerySchemas = mergeNamedSchemas(
      requests.compactMap(\.encodedQuerySchemas)
    )
    let encodedBodySchemas = mergeNamedSchemas(
      requests.compactMap(\.encodedBodySchemas)
    )
    return RequestShape(
      contentType: requests.first?.contentType,
      queryNames: Array(Set(requests.flatMap(\.queryNames))).sorted(),
      headers: headers.values.sorted { $0.name < $1.name },
      cookieNames: Array(Set(requests.flatMap(\.cookieNames))).sorted(),
      bodySchema: schemas.isEmpty ? nil : JSONSchemaInference.merge(schemas),
      encodedQuerySchemas:
        encodedQuerySchemas.isEmpty ? nil : encodedQuerySchemas,
      encodedBodySchemas:
        encodedBodySchemas.isEmpty ? nil : encodedBodySchemas
    )
  }

  private static func mergeNamedSchemas(
    _ collections: [[String: JSONValue]]
  ) -> [String: JSONValue] {
    var values: [String: [JSONValue]] = [:]
    for collection in collections {
      for (name, schema) in collection {
        values[name, default: []].append(schema)
      }
    }
    return values.mapValues(JSONSchemaInference.merge)
  }

  private static func mergeResponses(_ responses: [ResponseShape]) -> ResponseShape {
    let schemas = responses.compactMap(\.bodySchema)
    return ResponseShape(
      status: responses[0].status,
      contentType: responses[0].contentType,
      bodySchema: schemas.isEmpty ? nil : JSONSchemaInference.merge(schemas),
      outcome: responses[0].outcome,
      businessErrorSignals: Array(
        Set(responses.flatMap(\.businessErrorSignals))
      ).sorted(),
      responseHeaderNames: mergeOptionalNames(
        responses.map(\.responseHeaderNames)
      ),
      setCookieNames: mergeOptionalNames(responses.map(\.setCookieNames))
    )
  }

  private static func mergeOptionalNames(
    _ collections: [[String]?]
  ) -> [String]? {
    guard collections.contains(where: { $0 != nil }) else {
      return nil
    }
    return Array(Set(collections.compactMap { $0 }.flatMap { $0 })).sorted()
  }

  private static func makeSourceLock(
    brand: String,
    market: String,
    receipts: [CaptureReceipt],
    operations: [ObservedOperation],
    manifest: SourceManifest?,
    sourceProductVerifications: [SourceProductVerificationReceipt]
  ) throws -> SourceLock {
    let declared = Set(
      manifest?.sources.map { sourceKey($0.sourceId, $0.version) } ?? []
    )
    var entries: [String: SourceLockEntry] = [:]
    for source in manifest?.sources ?? [] {
      let key = sourceKey(source.sourceId, source.version)
      entries[key] = SourceLockEntry(
        sourceId: source.sourceId,
        surface: source.surface,
        version: source.version,
        coverageAreas: try SourceCoverageContract.validateAreas(
          source.coverageAreas ?? [],
          scope: "source \(key)"
        ),
        coveragePolicy: source.coveragePolicy ?? .required,
        coverageRationale: source.coverageRationale,
        sha256: "",
        status: .missing,
        capturedAt: nil,
        captureIds: [],
        operationFingerprints: [],
        evidenceFingerprints: []
      )
    }
    for receipt in receipts.sorted(by: { $0.captureId < $1.captureId }) {
      let key = sourceKey(receipt.source.sourceId, receipt.source.version)
      if manifest != nil, !declared.contains(key) {
        throw CapturePipelineError.undeclaredSourceRevision(key)
      }
      let existing = entries[key]
      if let existing, !existing.sha256.isEmpty,
        existing.sha256 != receipt.source.sha256
      {
        throw CapturePipelineError.conflictingSourceSHA(key)
      }
      let expected = manifest?.sources.first {
        sourceKey($0.sourceId, $0.version) == key
      }
      if let expected, expected.surface != receipt.source.surface {
        throw CapturePipelineError.sourceSurfaceMismatch(
          source: key,
          expected: expected.surface,
          actual: receipt.source.surface
        )
      }
      let candidateFingerprints = operations.filter { operation in
        operation.sourceRefs.contains {
          $0.captureId == receipt.captureId
            && $0.sourceId == receipt.source.sourceId
            && $0.sourceVersion == receipt.source.version
        }
      }.map(\.fingerprint)
      entries[key] = SourceLockEntry(
        sourceId: receipt.source.sourceId,
        surface: receipt.source.surface,
        version: receipt.source.version,
        coverageAreas: existing?.coverageAreas,
        coveragePolicy: existing?.coveragePolicy ?? .required,
        coverageRationale: existing?.coverageRationale,
        sha256: receipt.source.sha256,
        status: expected?.status == .partial ? .partial : .captured,
        capturedAt: receipt.capturedAt,
        captureIds: Array(
          Set((existing?.captureIds ?? []) + [receipt.captureId])
        ).sorted(),
        operationFingerprints: Array(
          Set(
            (existing?.operationFingerprints ?? [])
              + candidateFingerprints
          )
        ).sorted(),
        evidenceFingerprints: existing?.evidenceFingerprints
      )
    }
    for verification in sourceProductVerifications.sorted(
      by: { $0.verificationId < $1.verificationId }
    ) {
      let key = sourceKey(
        verification.sourceId,
        verification.sourceVersion
      )
      guard manifest != nil, declared.contains(key) else {
        throw CapturePipelineError.undeclaredSourceRevision(key)
      }
      let existing = entries[key]
      if let existing, !existing.sha256.isEmpty,
        existing.sha256 != verification.sourceProductSHA256
      {
        throw CapturePipelineError.conflictingSourceSHA(key)
      }
      let expected = manifest?.sources.first {
        sourceKey($0.sourceId, $0.version) == key
      }
      entries[key] = SourceLockEntry(
        sourceId: verification.sourceId,
        surface: expected?.surface ?? existing?.surface ?? .unknown,
        version: verification.sourceVersion,
        coverageAreas: existing?.coverageAreas,
        coveragePolicy: existing?.coveragePolicy ?? .required,
        coverageRationale: existing?.coverageRationale,
        sha256: verification.sourceProductSHA256,
        status: .captured,
        capturedAt: verification.verifiedAt,
        captureIds: existing?.captureIds ?? [],
        operationFingerprints: existing?.operationFingerprints ?? [],
        evidenceFingerprints: Array(
          Set(
            (existing?.evidenceFingerprints ?? [])
              + [verification.evidenceFingerprint]
          )
        ).sorted()
      )
    }
    return SourceLock(
      schemaVersion: 1,
      kind: "web-api-reverse.source-lock",
      brand: brand,
      market: market,
      requiredCoverageAreas: try manifest.map {
        try SourceCoverageContract.validateAreas(
          $0.requiredCoverageAreas ?? [],
          scope: "requiredCoverageAreas"
        )
      },
      sources: entries.keys.sorted().compactMap { entries[$0] }
    )
  }

  private static func sameNavigationResource(
    _ entryURL: String,
    _ exchangeURL: String
  ) -> Bool {
    guard let entry = URLComponents(string: entryURL),
      let exchange = URLComponents(string: exchangeURL)
    else {
      return false
    }
    return entry.scheme == exchange.scheme
      && entry.host == exchange.host
      && entry.port == exchange.port
      && normalizedPath(entry.path) == normalizedPath(exchange.path)
  }

  private static func normalizedPath(_ path: String) -> String {
    let trimmed = path.replacingOccurrences(
      of: #"/+$"#,
      with: "",
      options: .regularExpression
    )
    return trimmed.isEmpty ? "/" : trimmed
  }

  private static func sourceKey(_ sourceId: String, _ version: String) -> String {
    "\(sourceId)@\(version)"
  }
}

enum JSONSchemaInference {
  static func infer(_ value: JSONValue) -> JSONValue {
    switch value {
    case .null:
      return schema(type: "null")
    case .bool:
      return schema(type: "boolean")
    case .number(let value):
      return schema(type: value.rounded() == value ? "integer" : "number")
    case .string:
      return schema(type: "string")
    case .array(let values):
      return .object([
        "type": .string("array"),
        "items": values.isEmpty ? .object([:]) : merge(values.map(infer)),
      ])
    case .object(let object):
      let keys = object.keys.sorted()
      let childSchemas = keys.compactMap { object[$0].map(infer) }
      if shouldGeneralize(keys: keys, schemas: childSchemas) {
        return .object([
          "type": .string("object"),
          "additionalProperties": merge(childSchemas),
        ])
      }
      return .object([
        "type": .string("object"),
        "properties": .object(
          Dictionary(
            uniqueKeysWithValues: zip(keys, childSchemas).map { ($0, $1) }
          )
        ),
        "required": .array(keys.map(JSONValue.string)),
        "additionalProperties": .bool(true),
      ])
    }
  }

  static func merge(_ schemas: [JSONValue]) -> JSONValue {
    let normalized = schemas.flatMap(flattenPureOneOf)
    var unique: [String: JSONValue] = [:]
    for schema in normalized {
      unique[(try? CanonicalEvidenceJSON.string(schema)) ?? String(describing: schema)] = schema
    }
    let values = unique.keys.sorted().compactMap { unique[$0] }
    if values.isEmpty {
      return .object([:])
    }
    if values.count == 1 {
      return values[0]
    }
    if values.allSatisfy({ type(of: $0) == "object" }) {
      return mergeObjects(values)
    }
    if values.allSatisfy({ type(of: $0) == "array" }) {
      return mergeArrays(values)
    }
    return .object(["oneOf": .array(values)])
  }

  static func generalizingDynamicObjects(in schema: JSONValue) -> JSONValue {
    switch schema {
    case .object(var object):
      if case .object(let properties) = object["properties"] {
        let generalizedProperties = Dictionary(
          uniqueKeysWithValues: properties.keys.sorted().compactMap { key in
            properties[key].map {
              (key, generalizingDynamicObjects(in: $0))
            }
          }
        )
        if isDynamicObjectKeySet(Array(generalizedProperties.keys)) {
          object.removeValue(forKey: "properties")
          object.removeValue(forKey: "required")
          object["type"] = .string("object")
          object["additionalProperties"] = merge(
            generalizedProperties.keys.sorted().compactMap {
              generalizedProperties[$0]
            }
          )
        } else {
          object["properties"] = .object(generalizedProperties)
        }
      }
      if let items = object["items"] {
        object["items"] = generalizingDynamicObjects(in: items)
      }
      if case .object = object["additionalProperties"] {
        object["additionalProperties"] = generalizingDynamicObjects(
          in: object["additionalProperties"]!
        )
      }
      for keyword in ["oneOf", "anyOf", "allOf"] {
        if case .array(let candidates) = object[keyword] {
          object[keyword] = .array(
            candidates.map(generalizingDynamicObjects)
          )
        }
      }
      return .object(object)
    case .array(let values):
      return .array(values.map(generalizingDynamicObjects))
    case .string, .number, .bool, .null:
      return schema
    }
  }

  private static func mergeObjects(_ schemas: [JSONValue]) -> JSONValue {
    let objects = schemas.compactMap { value -> [String: JSONValue]? in
      guard case .object(let object) = value else { return nil }
      return object
    }
    let propertyMaps = objects.map { object -> [String: JSONValue] in
      guard case .object(let properties) = object["properties"] else {
        return [:]
      }
      return properties
    }
    let keys = Array(Set(propertyMaps.flatMap(\.keys))).sorted()
    let requiredSets = objects.map { object -> Set<String> in
      guard case .array(let values) = object["required"] else { return [] }
      return Set(
        values.compactMap {
          guard case .string(let value) = $0 else { return nil }
          return value
        })
    }
    return .object([
      "type": .string("object"),
      "properties": .object(
        Dictionary(
          uniqueKeysWithValues: keys.map { key in
            (
              key,
              merge(propertyMaps.compactMap { $0[key] })
            )
          }
        )
      ),
      "required": .array(
        keys.filter { key in requiredSets.allSatisfy { $0.contains(key) } }
          .map(JSONValue.string)
      ),
      "additionalProperties": .bool(true),
    ])
  }

  private static func mergeArrays(_ schemas: [JSONValue]) -> JSONValue {
    let items = schemas.compactMap { value -> JSONValue? in
      guard case .object(let object) = value else { return nil }
      return object["items"]
    }.filter {
      if case .object(let object) = $0 {
        return !object.isEmpty
      }
      return true
    }
    return .object([
      "type": .string("array"),
      "items": items.isEmpty ? .object([:]) : merge(items),
    ])
  }

  private static func flattenPureOneOf(_ schema: JSONValue) -> [JSONValue] {
    guard case .object(let object) = schema,
      object.count == 1,
      case .array(let values) = object["oneOf"]
    else {
      return [schema]
    }
    return values.flatMap(flattenPureOneOf)
  }

  private static func type(of schema: JSONValue) -> String? {
    guard case .object(let object) = schema,
      case .string(let type) = object["type"]
    else {
      return nil
    }
    return type
  }

  private static func schema(type: String) -> JSONValue {
    .object(["type": .string(type)])
  }

  private static func shouldGeneralize(
    keys: [String],
    schemas: [JSONValue]
  ) -> Bool {
    guard !keys.isEmpty, keys.count == schemas.count else {
      return false
    }
    if isDynamicObjectKeySet(keys) {
      return true
    }
    guard keys.count >= 24 else {
      return false
    }
    let types = Set(schemas.compactMap(type).filter { $0 != "null" })
    let variants = Set(
      schemas.map {
        (try? CanonicalEvidenceJSON.string($0)) ?? String(describing: $0)
      })
    guard variants.count <= 4 else {
      return false
    }
    if types.count <= 1 {
      return true
    }
    guard keys.count >= 128 else {
      return false
    }
    let counts = Dictionary(grouping: schemas) {
      (try? CanonicalEvidenceJSON.string($0)) ?? String(describing: $0)
    }.values.map(\.count)
    return Double(counts.max() ?? 0) / Double(keys.count) >= 0.9
  }

  private static func isDynamicObjectKey(_ value: String) -> Bool {
    value.range(of: #"^\d{5,}$"#, options: .regularExpression) != nil
      || value.range(
        of: #"^[a-z]\d{8,}$"#,
        options: [.regularExpression, .caseInsensitive]
      ) != nil
      || value.range(
        of: #"^[a-f0-9]{16,}$"#,
        options: [.regularExpression, .caseInsensitive]
      ) != nil
      || value.range(
        of: #"^[0-9a-f]{8}-[0-9a-f-]{27,}$"#,
        options: [.regularExpression, .caseInsensitive]
      ) != nil
  }

  private static func isDynamicObjectKeySet(_ keys: [String]) -> Bool {
    guard !keys.isEmpty else { return false }
    if keys.allSatisfy(isDynamicObjectKey) {
      return true
    }
    let dynamicKeys = keys.filter { $0 != "0" }
    return keys.contains("0")
      && !dynamicKeys.isEmpty
      && dynamicKeys.allSatisfy(isDynamicObjectKey)
  }
}
