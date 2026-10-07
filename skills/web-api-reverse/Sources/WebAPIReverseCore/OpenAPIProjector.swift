import Foundation

public enum OpenAPIProjectionError: Error, Equatable, LocalizedError {
  case unsupportedSchema(Int)
  case invalidKind(String)
  case scopeMismatch(String)
  case duplicateIdentifier(String)
  case missingOperation(String)
  case policyMismatch(operationId: String, reason: String)
  case missingVerification(String)
  case fixtureMismatch(operationId: String)
  case duplicateRoute(method: String, path: String)
  case invalidFixedBaseURL(String)
  case componentCollision(String)
  case invalidOpaqueResponsePointer(operationId: String, pointer: String)

  public var errorDescription: String? {
    switch self {
    case .unsupportedSchema(let version):
      "Unsupported OpenAPI projection schema version: \(version)"
    case .invalidKind(let kind):
      "Invalid OpenAPI projection artifact kind: \(kind)"
    case .scopeMismatch(let message):
      "OpenAPI projection scope mismatch: \(message)"
    case .duplicateIdentifier(let identifier):
      "Duplicate OpenAPI projection identifier: \(identifier)"
    case .missingOperation(let operationId):
      "Validated operation is absent from Observed catalog: \(operationId)"
    case .policyMismatch(let operationId, let reason):
      "Validated operation \(operationId) does not match Observed facts: \(reason)"
    case .missingVerification(let verificationId):
      "Accepted verification was not provided: \(verificationId)"
    case .fixtureMismatch(let operationId):
      "Accepted verification fixtures do not match policy \(operationId)"
    case .duplicateRoute(let method, let path):
      "Duplicate OpenAPI route: \(method) \(path)"
    case .invalidFixedBaseURL(let baseURL):
      "Invalid fixed server base URL: \(baseURL)"
    case .componentCollision(let name):
      "OpenAPI component name collision: \(name)"
    case .invalidOpaqueResponsePointer(let operationId, let pointer):
      "Opaque response pointer \(pointer) does not resolve to a stable schema field for \(operationId)"
    }
  }
}

public struct OpenAPIProjectionInput: Sendable {
  public let catalog: ObservedCatalog
  public let policies: ValidatedOperationPolicies
  public let acceptedVerifications: [TrustVerificationReceipt]

  public init(
    catalog: ObservedCatalog,
    policies: ValidatedOperationPolicies,
    acceptedVerifications: [TrustVerificationReceipt]
  ) {
    self.catalog = catalog
    self.policies = policies
    self.acceptedVerifications = acceptedVerifications
  }
}

public struct OpenAPIProjector: Sendable {
  public static let namedComponentByteThreshold = 512 * 1_000
  public static let namedComponentDepthThreshold = 16

  public init() {}

  public func project(_ input: OpenAPIProjectionInput) throws -> JSONValue {
    try validateScope(input)

    let operationById = try uniqueDictionary(
      input.catalog.operations,
      id: \.operationId
    )
    let receiptById = try uniqueDictionary(
      input.acceptedVerifications,
      id: \.verificationId
    )
    _ = try uniqueDictionary(input.policies.operations, id: \.operationId)
    _ = try uniqueDictionary(input.policies.operations, id: \.clientOperationId)

    var paths: [String: JSONValue] = [:]
    var serverOrigins = Set<String>()
    var components = ComponentRegistry()

    for policy in input.policies.operations.sorted(by: {
      $0.operationId < $1.operationId
    }) {
      guard let operation = operationById[policy.operationId] else {
        throw OpenAPIProjectionError.missingOperation(policy.operationId)
      }
      try validate(policy: policy, against: operation)
      let receipts = try acceptedReceipts(
        for: policy,
        operation: operation,
        receiptById: receiptById
      )
      if let baseURL = policy.routePolicy.baseURL {
        serverOrigins.insert(try fixedServerOrigin(baseURL))
      }

      let path = normalizePath(policy.path)
      let method = operation.method.lowercased()
      var pathItem = paths[path]?.objectValue ?? [:]
      guard pathItem[method] == nil else {
        throw OpenAPIProjectionError.duplicateRoute(
          method: operation.method.uppercased(),
          path: path
        )
      }
      pathItem[method] = try makeOperation(
        operation: operation,
        policy: policy,
        receipts: receipts,
        components: &components
      )
      paths[path] = .object(pathItem)
    }

    var componentDocument: [String: JSONValue] = [
      "securitySchemes": .object([
        "webAPIReverseSession": .object([
          "description": .string(
            "Concrete provider authentication material is injected by provider runtime policy."
          ),
          "in": .string("header"),
          "name": .string("Authorization"),
          "type": .string("apiKey"),
        ])
      ])
    ]
    if !components.schemas.isEmpty {
      componentDocument["schemas"] = .object(components.schemas)
    }

    return .object([
      "components": .object(componentDocument),
      "info": .object([
        "description": .string(
          "Only evidence-backed operations projected from validated operation policies."
        ),
        "title": .string(
          "\(input.catalog.brand.uppercased()) "
            + "\(input.catalog.market.uppercased()) Storefront API"
        ),
        "version": .string(input.catalog.updatedAt),
      ]),
      "openapi": .string("3.1.0"),
      "paths": .object(paths),
      "servers": .array(
        serverOrigins.sorted().map {
          .object(["url": .string($0)])
        }
      ),
    ])
  }

  private func validateScope(_ input: OpenAPIProjectionInput) throws {
    let versions =
      [
        input.catalog.schemaVersion,
        input.policies.schemaVersion,
      ] + input.acceptedVerifications.map(\.schemaVersion)
    if let unsupported = versions.first(where: { $0 != 1 }) {
      throw OpenAPIProjectionError.unsupportedSchema(unsupported)
    }
    guard
      input.catalog.kind == "lifewear.observed-catalog"
        || input.catalog.kind == "web-api-reverse.observed-catalog"
    else {
      throw OpenAPIProjectionError.invalidKind(input.catalog.kind)
    }
    guard
      input.policies.kind == "lifewear.operation-policies"
        || input.policies.kind == "web-api-reverse.operation-policies"
    else {
      throw OpenAPIProjectionError.invalidKind(input.policies.kind)
    }
    let expected = "\(input.catalog.brand)/\(input.catalog.market)"
    guard input.policies.brand == input.catalog.brand,
      input.policies.market == input.catalog.market
    else {
      throw OpenAPIProjectionError.scopeMismatch(
        "operation policies \(input.policies.brand)/\(input.policies.market) != \(expected)"
      )
    }
    for receipt in input.acceptedVerifications {
      guard receipt.brand == input.catalog.brand,
        receipt.market == input.catalog.market
      else {
        throw OpenAPIProjectionError.scopeMismatch(
          "verification \(receipt.verificationId) "
            + "\(receipt.brand)/\(receipt.market) != \(expected)"
        )
      }
    }
  }

  private func validate(
    policy: ValidatedOperationPolicy,
    against operation: ObservedOperation
  ) throws {
    guard policy.method.caseInsensitiveCompare(operation.method) == .orderedSame else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason: "method differs"
      )
    }
    guard policy.classification.rawValue == operation.classification.rawValue,
      policy.serviceFamily == operation.serviceFamily,
      policy.authPolicy.rawValue == operation.authPolicy.rawValue,
      policy.routePolicy == operation.routePolicy,
      policy.safety.rawValue == operation.safety.rawValue
    else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason: "route, auth, safety, classification, or family differs"
      )
    }
    let observedRoutePath = try observedRoutePath(
      operation: operation,
      policy: policy
    )
    if let wirePath = policy.wirePath,
      normalizePath(wirePath) != normalizePath(observedRoutePath)
    {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason: "wire path differs from Observed evidence"
      )
    }
    let reviewedPath = normalizePath(policy.path)
    guard reviewedPath.hasPrefix("/") else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason: "published path must be absolute"
      )
    }
    if case .provider = policy.routePolicy {
      return
    }
    let observedParameterCount = pathParameterOccurrences(
      observedRoutePath
    ).count
    let reviewedParameterCount = pathParameterOccurrences(
      reviewedPath
    ).count
    guard reviewedParameterCount == observedParameterCount else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason:
          "path parameter alias count differs: "
          + "\(reviewedParameterCount) reviewed for "
          + "\(observedParameterCount) observed"
      )
    }
    guard pathTemplateShape(reviewedPath) == pathTemplateShape(observedRoutePath)
    else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operation.operationId,
        reason: "reviewed path changes observed static route segments"
      )
    }
  }

  private func acceptedReceipts(
    for policy: ValidatedOperationPolicy,
    operation: ObservedOperation,
    receiptById: [String: TrustVerificationReceipt]
  ) throws -> [TrustVerificationReceipt] {
    let verificationIds = policy.evidenceIds
      .filter { $0.hasPrefix("ver_") }
      .sorted()
    var receipts: [TrustVerificationReceipt] = []
    for verificationId in verificationIds {
      guard let receipt = receiptById[verificationId] else {
        throw OpenAPIProjectionError.missingVerification(verificationId)
      }
      guard receipt.operationId == operation.operationId,
        receipt.fingerprint == operation.fingerprint
      else {
        throw OpenAPIProjectionError.policyMismatch(
          operationId: operation.operationId,
          reason: "verification \(verificationId) belongs to another operation"
        )
      }
      receipts.append(receipt)
    }

    let expectedFixturePaths =
      receipts
      .filter {
        policy.authPolicy == .none && $0.effectiveResponseFixture != nil
      }
      .map {
        "fixtures/\(safePathComponent(operation.operationId))/\($0.verificationId).json"
      }
      .sorted()
    guard expectedFixturePaths == policy.fixturePaths.sorted() else {
      throw OpenAPIProjectionError.fixtureMismatch(
        operationId: operation.operationId
      )
    }
    return receipts
  }

  private func makeOperation(
    operation: ObservedOperation,
    policy: ValidatedOperationPolicy,
    receipts: [TrustVerificationReceipt],
    components: inout ComponentRegistry
  ) throws -> JSONValue {
    let inferredNamedComponents = try operationRequiresNamedComponents(operation)
    let useNamedComponents =
      policy.useNamedComponents == true || inferredNamedComponents
    var nullPaths: [String] = []
    var fields: [String: JSONValue] = [
      "operationId": .string(policy.clientOperationId),
      "responses": try makeResponses(
        operation: operation,
        policy: policy,
        receipts: receipts,
        useNamedComponents: useNamedComponents,
        nullPaths: &nullPaths,
        components: &components
      ),
      "summary": .string(operation.operationId),
      "x-web-api-reverse-auth-policy": .string(policy.authPolicy.rawValue),
      "x-web-api-reverse-classification": .string(policy.classification.rawValue),
      "x-web-api-reverse-evidence-ids": .array(
        policy.evidenceIds.sorted().map(JSONValue.string)
      ),
      "x-web-api-reverse-fingerprint": .string(operation.fingerprint),
      "x-web-api-reverse-fixture-paths": .array(
        policy.fixturePaths.sorted().map(JSONValue.string)
      ),
      "x-web-api-reverse-operation-id": .string(operation.operationId),
      "x-web-api-reverse-wire-path": .string(
        policy.wirePath ?? observedPath(operation)
      ),
      "x-web-api-reverse-product-family": .string(operation.productFamily),
      "x-web-api-reverse-protocol": .string(operation.protocol.rawValue),
      "x-web-api-reverse-reversible-mutation": .bool(policy.reversibleMutation),
      "x-web-api-reverse-route-policy": try jsonValue(policy.routePolicy),
      "x-web-api-reverse-safety": .string(policy.safety.rawValue),
      "x-web-api-reverse-service-family": .string(policy.serviceFamily),
      "x-web-api-reverse-source-revisions": .array(
        policy.sourceRevisions.sorted().map(JSONValue.string)
      ),
    ]
    if !policy.runtimeManagedQueryNames.isEmpty {
      fields["x-web-api-reverse-runtime-managed-query-names"] = .array(
        policy.runtimeManagedQueryNames.sorted().map(JSONValue.string)
      )
    }
    if !policy.runtimeManagedHeaderNames.isEmpty {
      fields["x-web-api-reverse-runtime-managed-header-names"] = .array(
        policy.runtimeManagedHeaderNames.sorted().map(JSONValue.string)
      )
    }
    if !policy.runtimeManagedCookieNames.isEmpty {
      fields["x-web-api-reverse-runtime-managed-cookie-names"] = .array(
        policy.runtimeManagedCookieNames.sorted().map(JSONValue.string)
      )
    }
    if let pathParameterNames = policy.pathParameterNames {
      fields["x-web-api-reverse-path-parameter-names"] = .array(
        pathParameterNames.sorted().map(JSONValue.string)
      )
    }
    if let responseExtraction = policy.responseExtraction {
      fields["x-web-api-reverse-response-extraction"] = responseExtraction
    }
    if let opaqueResponsePointers = policy.opaqueResponsePointers {
      fields["x-web-api-reverse-opaque-response-pointers"] = .array(
        opaqueResponsePointers.sorted().map(JSONValue.string)
      )
    }
    if let aliases = policy.responseContentTypeAliases {
      fields["x-web-api-reverse-response-content-type-aliases"] = .object(
        aliases.mapValues(JSONValue.string)
      )
    }

    let parameters = makeParameters(
      path: normalizePath(policy.path),
      request: operation.request,
      policy: policy
    )
    if !parameters.isEmpty {
      fields["parameters"] = .array(parameters)
    }

    if let requestBody = logicalRequestBody(operation.request) {
      let requestSchema = requestBody.schema
      let projection = try projectSchema(requestSchema, path: "request.body")
      nullPaths.append(contentsOf: projection.nullPaths)
      let schema =
        useNamedComponents
        ? try components.hoist(
          projection.schema,
          nameHint: "\(operationTypeStem(policy.clientOperationId))Request"
        )
        : projection.schema
      fields["requestBody"] = .object([
        "content": .object([
          requestBody.contentType: .object([
            "schema": schema
          ])
        ]),
        "required": .bool(true),
      ])
      if let encodedLocation = requestBody.encodedLocation {
        fields["x-web-api-reverse-encoded-\(encodedLocation)-body-names"] =
          .array(requestBody.encodedNames.map(JSONValue.string))
        if requestBody.encodedNames.count == 1,
          let encodedName = requestBody.encodedNames.first
        {
          fields["x-web-api-reverse-encoded-\(encodedLocation)-body-name"] =
            .string(encodedName)
        }
      }
    }

    if policy.authPolicy != .none {
      fields["security"] = .array([
        .object(["webAPIReverseSession": .array([])])
      ])
    }
    if let action = policy.sessionAction {
      fields["x-web-api-reverse-session-lifecycle"] = .object([
        "action": .string(action.rawValue)
      ])
    }
    let uniqueNullPaths = Array(Set(nullPaths)).sorted()
    if !uniqueNullPaths.isEmpty {
      fields["x-web-api-reverse-observed-null-paths"] = .array(
        uniqueNullPaths.map(JSONValue.string)
      )
    }
    if useNamedComponents {
      fields["x-web-api-reverse-named-components"] = .bool(true)
    }
    let nonHTTPStatuses = Set(
      (operation.responses.map(\.status) + receipts.map(\.response.status))
        .filter { !(100...599).contains($0) }
    ).sorted()
    if !nonHTTPStatuses.isEmpty {
      fields["x-web-api-reverse-observed-non-http-statuses"] = .array(
        nonHTTPStatuses.map { .number(Double($0)) }
      )
    }
    return .object(fields)
  }

  private func makeParameters(
    path: String,
    request: RequestShape,
    policy: ValidatedOperationPolicy
  ) -> [JSONValue] {
    var parameters: [JSONValue] = []
    for name in pathParameterNames(path) {
      parameters.append(
        parameter(name: name, location: "path", required: true)
      )
    }
    let runtimeManaged = Set(
      policy.runtimeManagedQueryNames.map { $0.lowercased() }
    )
    let encodedQueryNames = Set(
      request.encodedQuerySchemas?.keys.map { $0.lowercased() } ?? []
    )
    for name in Array(Set(request.queryNames)).sorted()
    where !runtimeManaged.contains(name.lowercased())
      && !encodedQueryNames.contains(name.lowercased())
    {
      parameters.append(
        parameter(name: name, location: "query", required: false)
      )
    }
    return parameters
  }

  private func logicalRequestBody(
    _ request: RequestShape
  ) -> LogicalRequestBody? {
    if let schemas = request.encodedQuerySchemas, !schemas.isEmpty {
      return encodedRequestBody(schemas, location: "query")
    }
    if let schemas = request.encodedBodySchemas, !schemas.isEmpty {
      return encodedRequestBody(schemas, location: "body")
    }
    guard let schema = request.bodySchema else {
      return nil
    }
    if isEmptyFormBody(
      schema,
      contentType: request.contentType
    ) {
      return nil
    }
    return LogicalRequestBody(
      schema: schema,
      contentType: request.contentType ?? "application/json",
      encodedLocation: nil,
      encodedNames: []
    )
  }

  private func isEmptyFormBody(
    _ schema: JSONValue,
    contentType: String?
  ) -> Bool {
    guard
      contentType?.lowercased().contains(
        "application/x-www-form-urlencoded"
      ) == true,
      case .object(let fields) = schema,
      fields["type"] == .string("object"),
      case .object(let properties) = fields["properties"],
      properties.isEmpty
    else {
      return false
    }
    if case .array(let required) = fields["required"] {
      return required.isEmpty
    }
    return fields["required"] == nil
  }

  private func encodedRequestBody(
    _ schemas: [String: JSONValue],
    location: String
  ) -> LogicalRequestBody {
    let names = schemas.keys.sorted()
    let schema: JSONValue
    if names.count == 1, let name = names.first, let value = schemas[name] {
      schema = value
    } else {
      schema = .object([
        "additionalProperties": .bool(false),
        "properties": .object(
          Dictionary(
            uniqueKeysWithValues: names.compactMap { name in
              schemas[name].map { (name, $0) }
            }
          )
        ),
        "required": .array(names.map(JSONValue.string)),
        "type": .string("object"),
      ])
    }
    return LogicalRequestBody(
      schema: schema,
      contentType: "application/json",
      encodedLocation: location,
      encodedNames: names
    )
  }

  private func parameter(
    name: String,
    location: String,
    required: Bool
  ) -> JSONValue {
    .object(
      parameterFields(
        name: name,
        location: location,
        required: required
      )
    )
  }

  private func parameterFields(
    name: String,
    location: String,
    required: Bool
  ) -> [String: JSONValue] {
    [
      "in": .string(location),
      "name": .string(name),
      "required": .bool(required),
      "schema": .object(["type": .string("string")]),
    ]
  }

  private func makeResponses(
    operation: ObservedOperation,
    policy: ValidatedOperationPolicy,
    receipts: [TrustVerificationReceipt],
    useNamedComponents: Bool,
    nullPaths: inout [String],
    components: inout ComponentRegistry
  ) throws -> JSONValue {
    var evidence = operation.responses.map {
      ResponseEvidence(response: $0, verificationId: nil, fixture: nil)
    }
    for receipt in receipts {
      let omittedReviewedFixture =
        policy.responseExtraction != nil
        && receipt.effectiveResponseFixture == nil
        && receipt.fixtureOmissionReason?
          .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        && (policy.authPolicy != .none
          || receipt.response.contentType?.lowercased().hasPrefix("text/")
            == true)
      let projection: ReviewedResponseProjection
      if omittedReviewedFixture {
        try ReviewedResponseExtractor.validatePolicy(
          policy.responseExtraction
        )
        projection = ReviewedResponseProjection(
          response: receipt.response,
          fixture: nil
        )
      } else {
        projection = try ReviewedResponseExtractor.project(
          response: receipt.response,
          fixture: receipt.effectiveResponseFixture,
          policy: policy.responseExtraction
        )
      }
      evidence.append(
        ResponseEvidence(
          response: projection.response,
          verificationId: receipt.verificationId,
          fixture: projection.fixture
        )
      )
    }

    evidence = evidence.filter { (100...599).contains($0.response.status) }
    let byStatus = Dictionary(grouping: evidence, by: { $0.response.status })
    var responses: [String: JSONValue] = [:]
    for status in byStatus.keys.sorted() {
      let observedStatusEvidence = byStatus[status] ?? []
      let acceptedStatusEvidence = observedStatusEvidence.filter {
        $0.verificationId != nil
      }
      let statusEvidence =
        acceptedStatusEvidence.isEmpty
        ? observedStatusEvidence
        : acceptedStatusEvidence
      var responseFields: [String: JSONValue] = [
        "description": .string(responseDescription(statusEvidence))
      ]
      let observedOutcomes = Set(
        observedStatusEvidence.map(\.response.outcome.rawValue)
      ).sorted()
      if !observedOutcomes.isEmpty {
        responseFields["x-web-api-reverse-observed-outcomes"] = .array(
          observedOutcomes.map(JSONValue.string)
        )
      }
      let byContentType = Dictionary(
        grouping: statusEvidence.filter {
          guard $0.response.bodySchema != nil || $0.fixture != nil else {
            return false
          }
          return MediaTypeFacts.isValidOpenAPIMediaType(
            canonicalResponseContentType(
              $0.response.contentType,
              aliases: policy.responseContentTypeAliases
            )
          )
        },
        by: {
          canonicalResponseContentType(
            $0.response.contentType,
            aliases: policy.responseContentTypeAliases
          )
        }
      )
      var content: [String: JSONValue] = [:]
      for contentType in byContentType.keys.sorted() {
        let mediaEvidence = byContentType[contentType] ?? []
        var mediaFields: [String: JSONValue] = [:]
        var projectedSchemas: [JSONValue] = []
        for item in mediaEvidence {
          guard let rawSchema = item.response.bodySchema else {
            continue
          }
          let generalizedSchema = JSONSchemaInference.generalizingDynamicObjects(
            in: rawSchema
          )
          let reviewedSchema =
            if item.response.outcome == .success {
              try applyingOpaqueResponsePointers(
                policy.opaqueResponsePointers ?? [],
                to: generalizedSchema,
                operationId: operation.operationId
              )
            } else {
              generalizedSchema
            }
          let projection = try projectSchema(
            reviewedSchema,
            path: "response.\(status)"
          )
          nullPaths.append(contentsOf: projection.nullPaths)
          if !projection.nullOnly {
            projectedSchemas.append(
              softeningResponseSchema(projection.schema)
            )
          }
        }
        let schemas = try uniqueSchemas(projectedSchemas)
        if !schemas.isEmpty {
          var schema: JSONValue =
            schemas.count == 1
            ? schemas[0]
            : JSONSchemaInference.merge(schemas)
          if useNamedComponents {
            schema = try components.hoist(
              schema,
              nameHint: responseComponentName(
                clientOperationId: policy.clientOperationId,
                status: status
              )
            )
          }
          mediaFields["schema"] = schema
        }

        if policy.authPolicy == .none {
          var examples: [String: JSONValue] = [:]
          for item in mediaEvidence.sorted(by: {
            ($0.verificationId ?? "") < ($1.verificationId ?? "")
          }) {
            if let verificationId = item.verificationId,
              let fixture = item.fixture
            {
              examples[verificationId] = .object(["value": fixture])
            }
          }
          if !examples.isEmpty {
            mediaFields["examples"] = .object(examples)
          }
        }
        content[contentType] = .object(mediaFields)
      }
      if !content.isEmpty {
        responseFields["content"] = .object(content)
      }
      responses[String(status)] = .object(responseFields)
    }
    return .object(responses)
  }

  private func canonicalResponseContentType(
    _ rawValue: String?,
    aliases: [String: String]?
  ) -> String {
    let canonical = MediaTypeFacts.canonical(rawValue)
    guard let aliases else { return canonical }
    for (source, destination) in aliases
    where MediaTypeFacts.canonical(source) == canonical {
      return MediaTypeFacts.canonical(destination)
    }
    return canonical
  }

  private func responseDescription(_ evidence: [ResponseEvidence]) -> String {
    let outcomes = Set(evidence.map(\.response.outcome.rawValue))
    if outcomes == [ResponseOutcome.success.rawValue] {
      return "Observed and verified successful response"
    }
    if !outcomes.contains(ResponseOutcome.success.rawValue) {
      return "Observed error response"
    }
    return "Observed response"
  }

  private func applyingOpaqueResponsePointers(
    _ pointers: [String],
    to schema: JSONValue,
    operationId: String
  ) throws -> JSONValue {
    try pointers.sorted().reduce(schema) { result, pointer in
      let components = pointer.dropFirst().split(
        separator: "/",
        omittingEmptySubsequences: false
      ).map {
        String($0)
          .replacingOccurrences(of: "~1", with: "/")
          .replacingOccurrences(of: "~0", with: "~")
      }
      guard !components.isEmpty, components.allSatisfy({ !$0.isEmpty }) else {
        throw OpenAPIProjectionError.invalidOpaqueResponsePointer(
          operationId: operationId,
          pointer: pointer
        )
      }
      return try replacingResponseSchema(
        result,
        at: components[...],
        operationId: operationId,
        pointer: pointer
      )
    }
  }

  private func replacingResponseSchema(
    _ schema: JSONValue,
    at components: ArraySlice<String>,
    operationId: String,
    pointer: String
  ) throws -> JSONValue {
    guard
      let component = components.first,
      case .object(var fields) = schema,
      case .object(var properties) = fields["properties"],
      let property = properties[component]
    else {
      throw OpenAPIProjectionError.invalidOpaqueResponsePointer(
        operationId: operationId,
        pointer: pointer
      )
    }
    if components.count == 1 {
      properties[component] = try opaqueSchema(
        property,
        operationId: operationId,
        pointer: pointer
      )
    } else {
      properties[component] = try replacingResponseSchema(
        property,
        at: components.dropFirst(),
        operationId: operationId,
        pointer: pointer
      )
    }
    fields["properties"] = .object(properties)
    return .object(fields)
  }

  private func opaqueSchema(
    _ schema: JSONValue,
    operationId: String,
    pointer: String
  ) throws -> JSONValue {
    guard case .object(let fields) = schema else {
      throw OpenAPIProjectionError.invalidOpaqueResponsePointer(
        operationId: operationId,
        pointer: pointer
      )
    }
    if fields["type"] == .string("object") || fields["properties"] != nil {
      return .object([
        "additionalProperties": .bool(true),
        "type": .string("object"),
      ])
    }
    if fields["type"] == .string("array") {
      return .object([
        "items": .object([:]),
        "type": .string("array"),
      ])
    }
    throw OpenAPIProjectionError.invalidOpaqueResponsePointer(
      operationId: operationId,
      pointer: pointer
    )
  }

  private func operationRequiresNamedComponents(
    _ operation: ObservedOperation
  ) throws -> Bool {
    let schemas =
      [operation.request.bodySchema]
      + (operation.request.encodedQuerySchemas?.values.map { $0 } ?? [])
      + (operation.request.encodedBodySchemas?.values.map { $0 } ?? [])
      + operation.responses.map(\.bodySchema)
    for schema in schemas.compactMap({ $0 }) {
      if try compactData(schema).count
        > Self.namedComponentByteThreshold
        || schemaDepth(schema) > Self.namedComponentDepthThreshold
      {
        return true
      }
    }
    return false
  }

  private func projectSchema(
    _ schema: JSONValue,
    path: String
  ) throws -> SchemaProjection {
    guard case .object(var projected) = schema else {
      return SchemaProjection(
        schema: schema,
        acceptsNull: schema == .null,
        nullOnly: schema == .null,
        nullPaths: schema == .null ? [path] : []
      )
    }
    if isNullOnlySchema(projected) {
      return nullOnlyProjection(path: path)
    }

    var acceptsNull = false
    var nullPaths: [String] = []
    if case .array(let types) = projected["type"] {
      let nonNullTypes = types.filter { $0 != .string("null") }
      if nonNullTypes.count != types.count {
        acceptsNull = true
        nullPaths.append(path)
        if nonNullTypes.isEmpty {
          return nullOnlyProjection(path: path)
        }
        projected["type"] =
          nonNullTypes.count == 1
          ? nonNullTypes[0]
          : .array(nonNullTypes)
        projected["x-web-api-reverse-observed-nullable"] = .bool(true)
      }
    }

    if case .array(let candidates) = projected["oneOf"] {
      let projections = try candidates.enumerated().map {
        try projectSchema($0.element, path: "\(path).oneOf[\($0.offset)]")
      }
      let nonNull = projections.filter { !$0.nullOnly }
      if nonNull.count != projections.count
        || projections.contains(where: \.acceptsNull)
      {
        acceptsNull = true
        nullPaths.append(path)
        projected["x-web-api-reverse-observed-nullable"] = .bool(true)
      }
      nullPaths.append(contentsOf: projections.flatMap(\.nullPaths))
      let schemas = try uniqueSchemas(
        nonNull.map {
          removingTopLevelNullableMarker($0.schema)
        }
      )
      if schemas.isEmpty {
        return nullOnlyProjection(path: path)
      } else if schemas.count == 1 {
        projected.removeValue(forKey: "oneOf")
        if case .object(let candidate) = schemas[0] {
          for (key, value) in candidate {
            projected[key] = value
          }
        } else {
          projected["oneOf"] = .array(schemas)
        }
      } else {
        projected["oneOf"] = .array(schemas)
      }
    }

    if case .object(let properties) = projected["properties"] {
      var required = Set(projected["required"]?.stringArray ?? [])
      var projectedProperties: [String: JSONValue] = [:]
      for key in properties.keys.sorted() {
        guard let value = properties[key] else {
          continue
        }
        let child = try projectSchema(value, path: "\(path).\(key)")
        nullPaths.append(contentsOf: child.nullPaths)
        if child.nullOnly || child.acceptsNull {
          required.remove(key)
        }
        projectedProperties[key] = child.schema
      }
      projected["properties"] = .object(projectedProperties)
      projected["required"] = .array(required.sorted().map(JSONValue.string))
    }

    if let items = projected["items"] {
      let itemProjection = try projectSchema(items, path: "\(path)[]")
      projected["items"] = itemProjection.schema
      if itemProjection.nullOnly {
        projected["x-web-api-reverse-observed-null-items-only"] = .bool(true)
      }
      nullPaths.append(contentsOf: itemProjection.nullPaths)
    }
    if case .object = projected["additionalProperties"] {
      let additional = try projectSchema(
        projected["additionalProperties"]!,
        path: "\(path).*"
      )
      projected["additionalProperties"] = additional.schema
      nullPaths.append(contentsOf: additional.nullPaths)
    }
    for keyword in ["anyOf", "allOf"] {
      if case .array(let candidates) = projected[keyword] {
        let candidateProjections = try candidates.enumerated().map {
          try projectSchema(
            $0.element,
            path: "\(path).\(keyword)[\($0.offset)]"
          )
        }
        projected[keyword] = .array(candidateProjections.map(\.schema))
        nullPaths.append(
          contentsOf: candidateProjections.flatMap(\.nullPaths)
        )
      }
    }

    return SchemaProjection(
      schema: .object(projected),
      acceptsNull: acceptsNull,
      nullOnly: false,
      nullPaths: Array(Set(nullPaths)).sorted()
    )
  }

  private func softeningResponseSchema(_ schema: JSONValue) -> JSONValue {
    switch schema {
    case .object(var object):
      object.removeValue(forKey: "required")
      if case .object(let properties) = object["properties"] {
        object["properties"] = .object(
          Dictionary(
            uniqueKeysWithValues: properties.keys.sorted().compactMap { key in
              guard let property = properties[key],
                !isNullOnlyPublishedSchema(property),
                !isNullItemsOnlyArraySchema(property)
              else {
                return nil
              }
              return (key, softeningResponseSchema(property))
            }
          )
        )
        if object["additionalProperties"] == nil
          || object["additionalProperties"] == .bool(false)
        {
          object["additionalProperties"] = .bool(true)
        }
      }
      if let items = object["items"] {
        object["items"] = softeningResponseSchema(items)
      }
      if case .object = object["additionalProperties"] {
        object["additionalProperties"] = softeningResponseSchema(
          object["additionalProperties"]!
        )
      }
      for keyword in ["oneOf", "anyOf", "allOf"] {
        if case .array(let candidates) = object[keyword] {
          object[keyword] = .array(
            candidates.map(softeningResponseSchema)
          )
        }
      }
      return .object(object)
    case .array(let values):
      return .array(values.map(softeningResponseSchema))
    case .string, .number, .bool, .null:
      return schema
    }
  }

  private func isNullOnlyPublishedSchema(_ schema: JSONValue) -> Bool {
    guard case .object(let object) = schema else {
      return false
    }
    return object["x-web-api-reverse-observed-null-only"] == .bool(true)
  }

  private func isNullItemsOnlyArraySchema(_ schema: JSONValue) -> Bool {
    guard case .object(let object) = schema else {
      return false
    }
    return object["type"] == .string("array")
      && object["x-web-api-reverse-observed-null-items-only"] == .bool(true)
  }

  private func nullOnlyProjection(path: String) -> SchemaProjection {
    SchemaProjection(
      schema: .object([
        "x-web-api-reverse-observed-null-only": .bool(true)
      ]),
      acceptsNull: true,
      nullOnly: true,
      nullPaths: [path]
    )
  }

  private func isNullOnlySchema(_ schema: [String: JSONValue]) -> Bool {
    schema["type"] == .string("null")
      || schema["const"] == .null
      || schema["enum"] == .array([.null])
  }

  private func removingTopLevelNullableMarker(
    _ schema: JSONValue
  ) -> JSONValue {
    guard case .object(var object) = schema else {
      return schema
    }
    object.removeValue(
      forKey: "x-web-api-reverse-observed-nullable"
    )
    return .object(object)
  }

  private func uniqueSchemas(_ values: [JSONValue]) throws -> [JSONValue] {
    var seen = Set<Data>()
    var result: [JSONValue] = []
    for value in values {
      let data = try compactData(value)
      if seen.insert(data).inserted {
        result.append(value)
      }
    }
    return result
  }

  private func compactData(_ value: JSONValue) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  private func schemaDepth(_ value: JSONValue, depth: Int = 0) -> Int {
    switch value {
    case .object(let object):
      return object.values.reduce(depth) {
        max($0, schemaDepth($1, depth: depth + 1))
      }
    case .array(let array):
      return array.reduce(depth) {
        max($0, schemaDepth($1, depth: depth + 1))
      }
    case .string, .number, .bool, .null:
      return depth
    }
  }

  private func fixedServerOrigin(_ baseURL: String) throws -> String {
    guard let components = URLComponents(string: baseURL),
      let scheme = components.scheme,
      let host = components.host
    else {
      throw OpenAPIProjectionError.invalidFixedBaseURL(baseURL)
    }
    var origin = "\(scheme)://\(host)"
    if let port = components.port {
      origin += ":\(port)"
    }
    return origin
  }

  private func normalizePath(_ path: String) -> String {
    path
      .replacingOccurrences(
        of: "%7B",
        with: "{",
        options: .caseInsensitive
      )
      .replacingOccurrences(
        of: "%7D",
        with: "}",
        options: .caseInsensitive
      )
  }

  private func observedPath(_ operation: ObservedOperation) -> String {
    let path =
      URLComponents(string: operation.urlTemplate)?.percentEncodedPath
      ?? operation.urlTemplate
    return normalizePath(path)
  }

  private func observedRoutePath(
    operation: ObservedOperation,
    policy: ValidatedOperationPolicy
  ) throws -> String {
    let path = observedPath(operation)
    switch policy.routePolicy {
    case .fixed(let baseURL):
      return try relativeObservedPath(
        path,
        baseURL: baseURL,
        operationId: operation.operationId
      )
    case .provider(_, let fields):
      guard case .string(let baseURL) = fields["baseURL"] else {
        return path
      }
      return try relativeObservedPath(
        path,
        baseURL: baseURL,
        operationId: operation.operationId
      )
    case .sessionEnvironment(let routePath):
      return normalizePath(routePath)
    case .unknown:
      return path
    }
  }

  private func relativeObservedPath(
    _ path: String,
    baseURL: String,
    operationId: String
  ) throws -> String {
    let parsedBasePath =
      URLComponents(string: baseURL)?.percentEncodedPath ?? ""
    let basePath = parsedBasePath.isEmpty ? "/" : parsedBasePath
    let normalizedBasePath = normalizePath(basePath)
    guard normalizedBasePath != "/" else {
      return path
    }
    guard
      path == normalizedBasePath
        || path.hasPrefix(normalizedBasePath + "/")
    else {
      throw OpenAPIProjectionError.policyMismatch(
        operationId: operationId,
        reason: "fixed base URL path does not prefix the observed route"
      )
    }
    let relative = path.dropFirst(normalizedBasePath.count)
    return relative.isEmpty ? "/" : String(relative)
  }

  private func pathTemplateShape(_ path: String) -> String {
    var shape = ""
    var cursor = path.startIndex
    while let open = path[cursor...].firstIndex(of: "{"),
      let close = path[open...].firstIndex(of: "}")
    {
      shape += path[cursor..<open]
      shape += "{}"
      cursor = path.index(after: close)
    }
    shape += path[cursor...]
    return shape
  }

  private func pathParameterNames(_ path: String) -> [String] {
    let names = pathParameterOccurrences(path)
    return Array(NSOrderedSet(array: names)) as? [String] ?? names
  }

  private func pathParameterOccurrences(_ path: String) -> [String] {
    var names: [String] = []
    var searchStart = path.startIndex
    while let open = path[searchStart...].firstIndex(of: "{"),
      let close = path[open...].firstIndex(of: "}")
    {
      let nameStart = path.index(after: open)
      if nameStart < close {
        names.append(String(path[nameStart..<close]))
      }
      searchStart = path.index(after: close)
    }
    return names
  }

  private func responseComponentName(
    clientOperationId: String,
    status: Int
  ) -> String {
    let stem = operationTypeStem(clientOperationId)
    return status == 200 ? "\(stem)Response" : "\(stem)Response\(status)"
  }

  private func operationTypeStem(_ operationId: String) -> String {
    let verbs = [
      "create", "delete", "fetch", "list", "patch",
      "post", "put", "read", "update", "get",
    ]
    let lowered = operationId.lowercased()
    let verb = verbs.first {
      lowered.hasPrefix($0)
        && operationId.count > $0.count
    }
    let remainder =
      verb.map {
        String(operationId.dropFirst($0.count))
      } ?? operationId
    return typeName(remainder).isEmpty ? "Operation" : typeName(remainder)
  }

  private func typeName(_ value: String) -> String {
    var words: [String] = []
    var current = ""
    for character in value {
      if character.isLetter || character.isNumber {
        if character.isUppercase,
          let last = current.last,
          last.isLowercase || last.isNumber
        {
          words.append(current)
          current = ""
        }
        current.append(character)
      } else if !current.isEmpty {
        words.append(current)
        current = ""
      }
    }
    if !current.isEmpty {
      words.append(current)
    }
    return words.map {
      guard let first = $0.first else {
        return ""
      }
      return String(first).uppercased() + $0.dropFirst()
    }.joined()
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

  private func jsonValue<T: Encodable>(_ value: T) throws -> JSONValue {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try JSONDecoder().decode(
      JSONValue.self,
      from: encoder.encode(value)
    )
  }

  private func uniqueDictionary<Element>(
    _ values: [Element],
    id: KeyPath<Element, String>
  ) throws -> [String: Element] {
    var result: [String: Element] = [:]
    for value in values {
      let identifier = value[keyPath: id]
      guard result.updateValue(value, forKey: identifier) == nil else {
        throw OpenAPIProjectionError.duplicateIdentifier(identifier)
      }
    }
    return result
  }
}

private struct ResponseEvidence {
  let response: ResponseShape
  let verificationId: String?
  let fixture: JSONValue?
}

private struct LogicalRequestBody {
  let schema: JSONValue
  let contentType: String
  let encodedLocation: String?
  let encodedNames: [String]
}

private struct SchemaProjection {
  let schema: JSONValue
  let acceptsNull: Bool
  let nullOnly: Bool
  let nullPaths: [String]
}

private struct ComponentRegistry {
  var schemas: [String: JSONValue] = [:]

  mutating func hoist(
    _ schema: JSONValue,
    nameHint: String
  ) throws -> JSONValue {
    guard case .object(var projected) = schema,
      projected["$ref"] == nil
    else {
      return schema
    }

    if case .object(let properties) = projected["properties"] {
      var hoisted: [String: JSONValue] = [:]
      for key in properties.keys.sorted() {
        if let child = properties[key] {
          hoisted[key] = try hoist(
            child,
            nameHint: "\(typeName(nameHint))\(typeName(key))"
          )
        }
      }
      projected["properties"] = .object(hoisted)
    }
    if let items = projected["items"] {
      projected["items"] = try hoist(
        items,
        nameHint: "\(singularTypeName(nameHint))Item"
      )
    }
    if case .object = projected["additionalProperties"] {
      projected["additionalProperties"] = try hoist(
        projected["additionalProperties"]!,
        nameHint: "\(nameHint)AdditionalProperty"
      )
    }
    for keyword in ["oneOf", "anyOf", "allOf"] {
      if case .array(let candidates) = projected[keyword] {
        projected[keyword] = .array(
          try candidates.enumerated().map {
            try hoist(
              $0.element,
              nameHint: "\(nameHint)Option\($0.offset + 1)"
            )
          }
        )
      }
    }

    guard isObjectSchema(projected) else {
      return .object(projected)
    }
    let projectedValue = JSONValue.object(projected)
    let serialized = try compactData(projectedValue)
    let preferred = typeName(nameHint).isEmpty ? "Schema" : typeName(nameHint)
    let componentName: String
    if let existing = schemas[preferred],
      try compactData(existing) != serialized
    {
      componentName = "\(preferred)_\(FileDigest.sha256(data: serialized).prefix(12))"
    } else {
      componentName = preferred
    }
    if let existing = schemas[componentName],
      try compactData(existing) != serialized
    {
      throw OpenAPIProjectionError.componentCollision(componentName)
    }
    schemas[componentName] = projectedValue
    return .object([
      "$ref": .string("#/components/schemas/\(componentName)")
    ])
  }

  private func isObjectSchema(_ schema: [String: JSONValue]) -> Bool {
    schema["type"] == .string("object")
      || schema["properties"]?.objectValue != nil
      || schema["additionalProperties"]?.objectValue != nil
  }

  private func compactData(_ value: JSONValue) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  private func typeName(_ value: String) -> String {
    let parts = value.split {
      !$0.isLetter && !$0.isNumber
    }
    return parts.map {
      guard let first = $0.first else {
        return ""
      }
      return String(first).uppercased() + $0.dropFirst()
    }.joined()
  }

  private func singularTypeName(_ value: String) -> String {
    if value.lowercased().hasSuffix("ies") {
      return String(value.dropLast(3)) + "y"
    }
    if value.lowercased().hasSuffix("sses") {
      return String(value.dropLast(2))
    }
    if value.lowercased().hasSuffix("s"),
      !value.lowercased().hasSuffix("ss")
    {
      return String(value.dropLast())
    }
    return value
  }
}

extension JSONValue {
  fileprivate var objectValue: [String: JSONValue]? {
    guard case .object(let value) = self else {
      return nil
    }
    return value
  }

  fileprivate var stringArray: [String]? {
    guard case .array(let values) = self else {
      return nil
    }
    return values.compactMap {
      guard case .string(let value) = $0 else {
        return nil
      }
      return value
    }
  }
}
