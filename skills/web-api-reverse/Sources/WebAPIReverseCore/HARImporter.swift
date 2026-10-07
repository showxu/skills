import Foundation

public struct HARImportOptions: Equatable, Sendable {
  public let brand: String
  public let market: String
  public let surface: SourceSurface
  public let sourceId: String
  public let sourceVersion: String
  public let flow: String
  public let capturedAt: String?
  public let captureContext: CaptureContext?
  public let includeURLPatterns: [String]
  public let routeDiscriminatorQueryNames: [String]

  public init(
    brand: String,
    market: String,
    surface: SourceSurface,
    sourceId: String,
    sourceVersion: String,
    flow: String,
    capturedAt: String? = nil,
    captureContext: CaptureContext? = nil,
    includeURLPatterns: [String] = [],
    routeDiscriminatorQueryNames: [String] = []
  ) {
    self.brand = brand
    self.market = market
    self.surface = surface
    self.sourceId = sourceId
    self.sourceVersion = sourceVersion
    self.flow = flow
    self.capturedAt = capturedAt
    self.captureContext = captureContext
    self.includeURLPatterns = includeURLPatterns
    self.routeDiscriminatorQueryNames = Array(
      Set(routeDiscriminatorQueryNames)
    ).sorted()
  }
}

public enum HARImporter {
  public static func importHAR(
    at url: URL,
    options: HARImportOptions
  ) throws -> CaptureReceipt {
    try importHAR(data: Data(contentsOf: url), options: options)
  }

  public static func importHAR(
    data: Data,
    options: HARImportOptions
  ) throws -> CaptureReceipt {
    let document: HARDocument
    do {
      document = try JSONDecoder().decode(HARDocument.self, from: data)
    } catch {
      throw CapturePipelineError.invalidHAR
    }

    let patterns = Array(Set(options.includeURLPatterns)).sorted()
    let matchers = try patterns.map { pattern -> NSRegularExpression in
      do {
        return try NSRegularExpression(pattern: pattern)
      } catch {
        throw CapturePipelineError.invalidIncludePattern(pattern)
      }
    }
    let httpEntries = document.log.entries.filter {
      guard
        let scheme = URLComponents(string: $0.request.url)?.scheme?
          .lowercased()
      else {
        return false
      }
      return scheme == "http" || scheme == "https"
    }
    let selected =
      matchers.isEmpty
      ? httpEntries
      : httpEntries.filter { entry in
        matchers.contains { expression in
          expression.firstMatch(
            in: entry.request.url,
            range: NSRange(
              entry.request.url.startIndex..<entry.request.url.endIndex,
              in: entry.request.url
            )
          ) != nil
        }
      }
    guard !selected.isEmpty else {
      throw CapturePipelineError.emptySelection
    }

    let rawExchanges = try selected.map(rawExchange)
    let capturedAt =
      options.capturedAt
      ?? selected.compactMap(\.startedDateTime).sorted().last
      ?? "1970-01-01T00:00:00.000Z"
    let entryURL = try sourceEntryURL(selected[0].request.url)
    let normalized = try rawExchanges.map {
      try normalize(
        $0,
        routeDiscriminatorQueryNames:
          options.routeDiscriminatorQueryNames
      )
    }.sorted {
      ($0.fingerprint, $0.exchangeId) < ($1.fingerprint, $1.exchangeId)
    }
    let source = CaptureSource(
      sourceId: options.sourceId,
      surface: options.surface,
      version: options.sourceVersion,
      sha256: FileDigest.sha256(data: data),
      entryURL: entryURL
    )
    let selection =
      patterns.isEmpty
      ? nil
      : CaptureSelection(
        patterns: patterns,
        totalExchangeCount: document.log.entries.count,
        selectedExchangeCount: selected.count
      )
    let captureId = try makeCaptureId(
      brand: options.brand,
      market: options.market,
      source: source,
      flow: options.flow,
      context: options.captureContext,
      selection: selection,
      exchanges: normalized
    )
    let receipt = CaptureReceipt(
      captureId: captureId,
      capturedAt: capturedAt,
      brand: options.brand,
      market: options.market,
      source: source,
      flow: options.flow,
      captureContext: options.captureContext,
      captureSelection: selection,
      exchanges: normalized
    )
    let receiptText = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    guard !EvidenceRedactor.containsRawSecrets(in: receiptText) else {
      throw CapturePipelineError.secretMaterialDetected
    }
    return receipt
  }

  public static func normalizeURLTemplate(_ rawURL: String) throws -> String {
    guard let components = URLComponents(string: rawURL),
      let scheme = components.scheme,
      let host = components.host
    else {
      throw CapturePipelineError.invalidURL(rawURL)
    }
    let origin = "\(scheme)://\(host)\(components.port.map { ":\($0)" } ?? "")"
    var dynamicIndex = 0
    let decodedPath =
      components.percentEncodedPath.removingPercentEncoding
      ?? components.path
    let path = decodedPath.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map { rawSegment -> String in
      let segment = String(rawSegment)
      guard let suffix = dynamicSegmentSuffix(segment) else {
        return segment
      }
      dynamicIndex += 1
      return "{segment\(dynamicIndex)}\(suffix)"
    }.joined(separator: "/")
    let queryNames = EvidenceRedactor.normalizeQueryNames(
      (components.queryItems ?? []).map(\.name)
    )
    let query = queryNames.map { name in
      let encoded =
        name.addingPercentEncoding(
          withAllowedCharacters: .urlQueryNameAllowed
        ) ?? name
      let parameter =
        name
        .map { $0.isLetter || $0.isNumber || $0 == "_" ? $0 : "_" }
      return "\(encoded)={\(String(parameter).isEmpty ? "query" : String(parameter))}"
    }.joined(separator: "&")
    return "\(origin)\(path)\(query.isEmpty ? "" : "?\(query)")"
  }

  static func urlTemplatesHaveEquivalentStructure(
    _ lhs: String,
    _ rhs: String
  ) -> Bool {
    canonicalPlaceholderNames(in: lhs) == canonicalPlaceholderNames(in: rhs)
  }

  static func normalize(
    _ raw: RawExchange,
    routeDiscriminatorQueryNames: [String] = [],
    urlTemplateOverride: String? = nil
  ) throws -> SanitizedExchange {
    let method = raw.method.uppercased()
    let inferredURLTemplate = try normalizeURLTemplate(raw.url)
    let urlTemplate = urlTemplateOverride ?? inferredURLTemplate
    let operationProtocol = detectProtocol(raw)
    let routeDiscriminators = try routeDiscriminators(
      raw,
      names: routeDiscriminatorQueryNames
    )
    let discriminator = protocolDiscriminator(raw, operationProtocol)
    let encodedQuerySchemas = encodedJSONSchemas(
      URLComponents(string: raw.url)?.queryItems ?? []
    )
    let encodedBodySchemas = encodedJSONSchemas(raw.requestBody)
    let fingerprintInput = [
      method,
      urlTemplate,
      operationProtocol.rawValue,
      raw.requestContentType ?? "",
      discriminator,
      try canonicalRouteDiscriminators(routeDiscriminators),
      try canonicalSchemas(encodedQuerySchemas),
      try canonicalSchemas(encodedBodySchemas),
    ].joined(separator: "\n")
    let fingerprint = FileDigest.sha256(data: Data(fingerprintInput.utf8))
    let operationId = try makeOperationId(
      method: method,
      urlTemplate: urlTemplate,
      fingerprint: fingerprint,
      routeDiscriminators: routeDiscriminators
    )
    let outcome = assessOutcome(
      status: raw.responseStatus,
      headers: raw.responseHeaders,
      body: raw.responseBody
    )
    let exchangeIdentity =
      "\(fingerprint)\n\(raw.responseStatus)\n\(raw.startedAt ?? "")"
    return SanitizedExchange(
      exchangeId:
        "ex_\(FileDigest.sha256(data: Data(exchangeIdentity.utf8)).prefix(16))",
      operationId: operationId,
      fingerprint: fingerprint,
      method: method,
      sanitizedURL: try EvidenceRedactor.sanitizeURL(raw.url),
      urlTemplate: urlTemplate,
      protocol: operationProtocol,
      routeDiscriminators: routeDiscriminators,
      request: RequestShape(
        contentType: raw.requestContentType,
        queryNames: EvidenceRedactor.normalizeQueryNames(
          URLComponents(string: raw.url)?.queryItems?.map(\.name) ?? []
        ),
        headers: EvidenceRedactor.headerPresence(raw.requestHeaders),
        cookieNames: EvidenceRedactor.cookieNames(raw.requestHeaders),
        bodySchema: raw.requestBody.map(JSONSchemaInference.infer),
        encodedQuerySchemas:
          encodedQuerySchemas.isEmpty ? nil : encodedQuerySchemas,
        encodedBodySchemas:
          encodedBodySchemas.isEmpty ? nil : encodedBodySchemas
      ),
      response: ResponseShape(
        status: raw.responseStatus,
        contentType: raw.responseContentType,
        bodySchema: raw.responseBody.map(JSONSchemaInference.infer),
        outcome: outcome.outcome,
        businessErrorSignals: outcome.signals,
        responseHeaderNames: Array(
          Set(raw.responseHeaders.keys.map { $0.lowercased() })
        ).sorted(),
        setCookieNames: Array(
          Set(
            (raw.responseCookieNames ?? [])
              + responseSetCookieNames(raw.responseHeaders)
          )
        ).sorted()
      ),
      startedAt: raw.startedAt,
      durationMs: raw.durationMs
    )
  }

  static func rawExchange(_ entry: HAREntry) throws -> RawExchange {
    var requestHeaders = headerRecord(entry.request.headers ?? [])
    if headerValue(requestHeaders, "cookie") == nil {
      let cookieHeader = (entry.request.cookies ?? [])
        .filter { !$0.name.isEmpty }
        .map { "\($0.name)=\($0.value)" }
        .joined(separator: "; ")
      if !cookieHeader.isEmpty {
        requestHeaders["cookie"] = cookieHeader
      }
    }
    let responseHeaders = headerRecord(entry.response.headers ?? [])
    let requestContentType =
      entry.request.postData?.mimeType
      ?? headerValue(requestHeaders, "content-type")
    let responseContentType =
      entry.response.content?.mimeType
      ?? headerValue(responseHeaders, "content-type")
    return RawExchange(
      method: entry.request.method,
      url: entry.request.url,
      requestHeaders: requestHeaders,
      requestBody: entry.request.postData.flatMap {
        parseBody(
          text: $0.text,
          contentType: requestContentType,
          parameters: $0.params
        )
      },
      requestContentType: requestContentType,
      responseStatus: entry.response.status,
      responseHeaders: responseHeaders,
      responseCookieNames: (entry.response.cookies ?? []).map(\.name),
      responseBody: entry.response.content?.text.flatMap {
        parseBody(
          text: decodeContent($0, encoding: entry.response.content?.encoding),
          contentType: responseContentType,
          parameters: nil
        )
      },
      responseContentType: responseContentType,
      startedAt: entry.startedDateTime,
      durationMs: entry.time
    )
  }

  static func makeCaptureId(
    brand: String,
    market: String,
    source: CaptureSource,
    flow: String,
    context: CaptureContext?,
    selection: CaptureSelection?,
    exchanges: [SanitizedExchange]
  ) throws -> String {
    var sourceObject: [String: JSONValue] = [
      "sourceId": .string(source.sourceId),
      "surface": .string(source.surface.rawValue),
      "version": .string(source.version),
      "sha256": .string(source.sha256),
    ]
    if let entryURL = source.entryURL {
      sourceObject["entryURL"] = .string(entryURL)
    }
    var identity: [String: JSONValue] = [
      "brand": .string(brand),
      "market": .string(market),
      "source": .object(sourceObject),
      "flow": .string(flow),
      "exchanges": .array(
        exchanges.map {
          .object([
            "fingerprint": .string($0.fingerprint),
            "status": .number(Double($0.response.status)),
            "outcome": .string($0.response.outcome.rawValue),
          ])
        }
      ),
    ]
    if let context {
      var object: [String: JSONValue] = [
        "kind": .string(context.kind),
        "browser": .string(context.browser),
        "browserVersion": .string(context.browserVersion),
        "headless": .bool(context.headless),
      ]
      if let device = context.device {
        object["device"] = .string(device)
      }
      identity["captureContext"] = .object(object)
    }
    if let selection {
      identity["captureSelection"] = .object([
        "kind": .string(selection.kind),
        "patterns": .array(selection.patterns.map(JSONValue.string)),
        "totalExchangeCount": .number(Double(selection.totalExchangeCount)),
        "selectedExchangeCount": .number(Double(selection.selectedExchangeCount)),
      ])
    }
    let digest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(.object(identity))
    )
    return "cap_\(digest.prefix(16))"
  }

  private static func detectProtocol(_ raw: RawExchange) -> OperationProtocol {
    let contentType = raw.requestContentType?.lowercased() ?? ""
    if contentType.contains("multipart/form-data") {
      return .multipart
    }
    if contentType.contains("application/x-www-form-urlencoded") {
      return .form
    }
    if case .object(let body) = raw.requestBody,
      body["query"] != nil || body["operationName"] != nil || body["extensions"] != nil
    {
      if case .object(let extensions) = body["extensions"],
        extensions["persistedQuery"] != nil
      {
        return .persistedQuery
      }
      return .graphql
    }
    if raw.method.uppercased() == "GET",
      matchesStaticAsset(raw.url)
    {
      return .static
    }
    return .rest
  }

  private static func protocolDiscriminator(
    _ raw: RawExchange,
    _ operationProtocol: OperationProtocol
  ) -> String {
    guard operationProtocol == .graphql || operationProtocol == .persistedQuery,
      case .object(let body) = raw.requestBody
    else {
      return ""
    }
    if case .string(let name) = body["operationName"], !name.isEmpty {
      return "operation:\(name)"
    }
    if case .string(let query) = body["query"], !query.isEmpty {
      return "query:\(FileDigest.sha256(data: Data(query.utf8)))"
    }
    if case .object(let extensions) = body["extensions"],
      case .object(let persisted) = extensions["persistedQuery"],
      case .string(let hash) = persisted["sha256Hash"],
      !hash.isEmpty
    {
      return "persisted:\(hash)"
    }
    return ""
  }

  private static func makeOperationId(
    method: String,
    urlTemplate: String,
    fingerprint: String,
    routeDiscriminators: [String: String]
  ) throws -> String {
    guard let components = URLComponents(string: urlTemplate) else {
      throw CapturePipelineError.invalidURL(urlTemplate)
    }
    let segments = components.path
      .replacingOccurrences(
        of: #"\{[^}]+\}"#,
        with: "by-id",
        options: .regularExpression
      )
      .split(separator: "/")
      .suffix(4)
    let path = segments.joined(separator: "-")
      .replacingOccurrences(
        of: #"[^A-Za-z0-9]+"#,
        with: "-",
        options: .regularExpression
      )
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
      .lowercased()
    let route = routeDiscriminators.keys.sorted().map {
      "\($0)-\(routeDiscriminators[$0] ?? "")"
    }.joined(separator: "-")
    let stem = [
      method.lowercased(),
      path.isEmpty ? "root" : path,
      route,
    ].filter { !$0.isEmpty }.joined(separator: "-")
    return "\(stem.prefix(64))-\(fingerprint.prefix(8))"
  }

  private static func routeDiscriminators(
    _ raw: RawExchange,
    names: [String]
  ) throws -> [String: String] {
    guard !names.isEmpty else {
      return [:]
    }
    let queryItems = URLComponents(string: raw.url)?.queryItems ?? []
    let bodyValues: [String: JSONValue]
    if case .object(let object) = raw.requestBody {
      bodyValues = object
    } else {
      bodyValues = [:]
    }
    var result: [String: String] = [:]
    for requestedName in Array(Set(names)).sorted() {
      let queryValue = queryItems.first {
        $0.name.caseInsensitiveCompare(requestedName) == .orderedSame
      }?.value
      let bodyValue = bodyValues.first {
        $0.key.caseInsensitiveCompare(requestedName) == .orderedSame
      }?.value.stringValue
      guard let value = queryValue ?? bodyValue else {
        continue
      }
      guard isSafeRouteDiscriminator(value) else {
        throw CapturePipelineError.unsafeRouteDiscriminator(requestedName)
      }
      result[requestedName] = value
    }
    return result
  }

  private static func isSafeRouteDiscriminator(_ value: String) -> Bool {
    !value.isEmpty
      && value.count <= 256
      && value.range(
        of: #"^[A-Za-z0-9._-]+$"#,
        options: .regularExpression
      ) != nil
  }

  private static func encodedJSONSchemas(
    _ queryItems: [URLQueryItem]
  ) -> [String: JSONValue] {
    queryItems.reduce(into: [String: JSONValue]()) { schemas, item in
      guard let value = item.value,
        let parsed = parseEncodedJSON(value)
      else {
        return
      }
      schemas[item.name] = JSONSchemaInference.infer(parsed)
    }
  }

  private static func encodedJSONSchemas(
    _ body: JSONValue?
  ) -> [String: JSONValue] {
    guard case .object(let object) = body else {
      return [:]
    }
    return object.reduce(into: [String: JSONValue]()) { schemas, entry in
      guard case .string(let value) = entry.value,
        let parsed = parseEncodedJSON(value)
      else {
        return
      }
      schemas[entry.key] = JSONSchemaInference.infer(parsed)
    }
  }

  private static func parseEncodedJSON(_ value: String) -> JSONValue? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("{") || trimmed.hasPrefix("["),
      let data = trimmed.data(using: .utf8)
    else {
      return nil
    }
    return try? JSONDecoder().decode(JSONValue.self, from: data)
  }

  private static func canonicalRouteDiscriminators(
    _ values: [String: String]
  ) throws -> String {
    try canonicalSchemas(values.mapValues(JSONValue.string))
  }

  private static func canonicalSchemas(
    _ values: [String: JSONValue]
  ) throws -> String {
    guard !values.isEmpty else {
      return ""
    }
    return String(
      decoding: try CanonicalEvidenceJSON.data(.object(values)),
      as: UTF8.self
    )
  }

  private static func assessOutcome(
    status: Int,
    headers: [String: String],
    body: JSONValue?
  ) -> (outcome: ResponseOutcome, signals: [String]) {
    guard (200..<300).contains(status) else {
      return (
        .httpError,
        status == 401 || status == 403
          ? ["authentication-status"]
          : ["http-status"]
      )
    }
    guard status == 204 || body != nil else {
      return (.unknown, ["response-body-unavailable"])
    }
    var signals: [String] = []
    if let punish = headerValue(headers, "bxpunish")?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !punish.isEmpty,
      punish != "0"
    {
      signals.append("response-header.bxpunish=present")
    }
    inspectBusinessErrors(
      jsonPPayload(body) ?? body,
      path: "",
      depth: 0,
      signals: &signals
    )
    let unique = Array(Set(signals)).sorted()
    return unique.isEmpty ? (.success, []) : (.businessError, unique)
  }

  private static func inspectBusinessErrors(
    _ value: JSONValue?,
    path: String,
    depth: Int,
    signals: inout [String]
  ) {
    guard depth <= 3, case .object(let object) = value else {
      return
    }
    func qualified(_ key: String) -> String {
      path.isEmpty ? key : "\(path).\(key)"
    }
    for key in ["success", "successful", "ok"] {
      if object[key] == .bool(false) {
        signals.append("\(qualified(key))=false")
      }
    }
    for key in ["error", "errors", "errorMessage", "error_message"] {
      if let value = object[key], isPresentError(value) {
        signals.append("\(qualified(key))=present")
      }
    }
    if case .array(let values) = object["ret"] {
      let statuses = values.compactMap { value -> String? in
        guard case .string(let status) = value else { return nil }
        return status.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      if statuses.contains(where: {
        !$0.uppercased().hasPrefix("SUCCESS::")
      }) {
        signals.append("\(qualified("ret"))=non-success")
      }
    }
    let message = ["message", "msg", "errorMessage", "error_message"]
      .compactMap { key -> String? in
        guard case .string(let value) = object[key],
          !value.trimmingCharacters(
            in: .whitespacesAndNewlines
          ).isEmpty
        else {
          return nil
        }
        return value
      }.first
    if let code = object["code"],
      !isSuccessCode(code),
      object["disposal"] != nil || object["echo"] != nil
    {
      signals.append("\(qualified("code"))=non-success")
    }
    if message != nil {
      for key in ["code", "errorCode", "error_code", "resultCode", "result_code"]
      where object[key] != nil && !isSuccessCode(object[key]) {
        signals.append("\(qualified(key))=non-success")
        break
      }
      for key in ["statusCode", "status_code"]
      where object[key] != nil && !isSuccessCode(object[key]) {
        signals.append("\(qualified(key))=non-success")
        break
      }
    }
    for key in ["body", "data", "payload", "response", "result"] {
      inspectBusinessErrors(
        object[key],
        path: qualified(key),
        depth: depth + 1,
        signals: &signals
      )
    }
  }

  private static func isPresentError(_ value: JSONValue) -> Bool {
    switch value {
    case .null, .bool(false), .string(""):
      false
    case .array(let values):
      !values.isEmpty
    default:
      true
    }
  }

  private static func jsonPPayload(_ value: JSONValue?) -> JSONValue? {
    guard case .string(let source) = value else { return nil }
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let open = trimmed.firstIndex(of: "("),
      let close = trimmed.lastIndex(of: ")"),
      open < close
    else { return nil }
    let callback = trimmed[..<open].trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard
      callback.range(
        of: #"^[A-Za-z_$][A-Za-z0-9_$.]*$"#,
        options: .regularExpression
      ) != nil
    else { return nil }
    return try? JSONDecoder().decode(
      JSONValue.self,
      from: Data(trimmed[trimmed.index(after: open)..<close].utf8)
    )
  }

  private static func isSuccessCode(_ value: JSONValue?) -> Bool {
    let code: String?
    switch value {
    case .string(let value):
      code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    case .number(let value):
      code =
        value.rounded() == value
        ? String(Int(value))
        : String(value)
    default:
      code = nil
    }
    return code.map {
      ($0.allSatisfy { $0 == "0" } && !$0.isEmpty)
        || ["200", "OK", "SUCCESS"].contains($0)
    } ?? false
  }

  private static func parseBody(
    text: String?,
    contentType: String?,
    parameters: [HARParameter]?
  ) -> JSONValue? {
    if let parameters, !parameters.isEmpty {
      return .object(
        parameters.reduce(into: [String: JSONValue]()) {
          $0[$1.name] = .string($1.value ?? "")
        })
    }
    guard let text, !text.isEmpty else {
      return nil
    }
    let normalizedType = contentType?.lowercased() ?? ""
    if normalizedType.contains("json")
      || normalizedType.contains("graphql")
      || text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{")
      || text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[")
    {
      if let data = text.data(using: .utf8),
        let value = try? JSONDecoder().decode(JSONValue.self, from: data)
      {
        return value
      }
      return .string(text)
    }
    if normalizedType.contains("application/x-www-form-urlencoded") {
      return .object(parseFormURLEncoded(text))
    }
    return .string(text)
  }

  private static func parseFormURLEncoded(
    _ text: String
  ) -> [String: JSONValue] {
    text.split(
      separator: "&",
      omittingEmptySubsequences: false
    ).reduce(into: [String: JSONValue]()) { result, field in
      let pair = field.split(
        separator: "=",
        maxSplits: 1,
        omittingEmptySubsequences: false
      )
      guard let rawName = pair.first else { return }
      let name = decodeFormComponent(String(rawName))
      let value =
        pair.count == 2
        ? decodeFormComponent(String(pair[1]))
        : ""
      result[name] = .string(value)
    }
  }

  private static func decodeFormComponent(_ raw: String) -> String {
    let spaceNormalized = raw.replacingOccurrences(of: "+", with: " ")
    return spaceNormalized.removingPercentEncoding ?? spaceNormalized
  }

  private static func decodeContent(_ text: String, encoding: String?) -> String {
    guard encoding == "base64",
      let data = Data(base64Encoded: text)
    else {
      return text
    }
    return String(decoding: data, as: UTF8.self)
  }

  private static func canonicalPlaceholderNames(in template: String) -> String {
    template.replacingOccurrences(
      of: #"\{[^{}]+\}"#,
      with: "{}",
      options: .regularExpression
    )
  }

  private static func headerRecord(_ headers: [HARHeader]) -> [String: String] {
    headers.sorted {
      $0.name.lowercased() < $1.name.lowercased()
    }.reduce(into: [String: String]()) { result, header in
      result[header.name.lowercased()] = header.value
    }
  }

  private static func headerValue(
    _ headers: [String: String],
    _ name: String
  ) -> String? {
    headers[name.lowercased()]
  }

  private static func responseSetCookieNames(
    _ headers: [String: String]
  ) -> [String] {
    guard let value = headerValue(headers, "set-cookie") else {
      return []
    }
    let expression = try! NSRegularExpression(
      pattern: #"(?:^|\n|,\s*)([^=;,\s]+)="#
    )
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    return expression.matches(in: value, range: range).compactMap { match in
      guard let nameRange = Range(match.range(at: 1), in: value) else {
        return nil
      }
      return String(value[nameRange])
    }
  }

  private static func sourceEntryURL(_ rawURL: String) throws -> String {
    let template = try normalizeURLTemplate(rawURL)
    return String(template.split(separator: "?", maxSplits: 1)[0])
  }

  private static func dynamicSegmentSuffix(_ segment: String) -> String? {
    if isDynamicIdentifier(segment) {
      return ""
    }
    guard let dot = segment.lastIndex(of: ".") else {
      return nil
    }
    let stem = String(segment[..<dot])
    let suffix = String(segment[dot...])
    guard suffix.count >= 2, suffix.count <= 9,
      suffix.dropFirst().allSatisfy({ $0.isLetter || $0.isNumber })
    else {
      return nil
    }
    if isDynamicIdentifier(stem) {
      return suffix
    }
    let documentSuffixes = [".htm", ".html"]
    guard documentSuffixes.contains(suffix.lowercased()),
      let trailingComponent = stem.split(separator: "-").last,
      isDynamicIdentifier(String(trailingComponent))
    else {
      return nil
    }
    return suffix
  }

  private static func isDynamicIdentifier(_ value: String) -> Bool {
    matches(#"^\d{5,}$"#, value)
      || matches(#"^[a-f0-9]{16,}$"#, value, caseInsensitive: true)
      || matches(
        #"^[0-9a-f]{8}-[0-9a-f-]{27,}$"#,
        value,
        caseInsensitive: true
      )
      || matches(#"^[a-z]\d{8,}$"#, value, caseInsensitive: true)
      || (value.count >= 28 && value.contains(where: \.isNumber)
        && (value.contains("-") || value.contains("_")))
  }

  private static func matchesStaticAsset(_ value: String) -> Bool {
    matches(
      #"\.(?:js|css|png|jpe?g|webp|svg|woff2?|ico)(?:\?|$)"#,
      value,
      caseInsensitive: true
    )
  }

  private static func matches(
    _ pattern: String,
    _ value: String,
    caseInsensitive: Bool = false
  ) -> Bool {
    let expression = try! NSRegularExpression(
      pattern: pattern,
      options: caseInsensitive ? .caseInsensitive : []
    )
    return expression.firstMatch(
      in: value,
      range: NSRange(value.startIndex..<value.endIndex, in: value)
    ) != nil
  }
}

struct HARDocument: Decodable {
  let log: HARLog
}

struct HARLog: Decodable {
  let entries: [HAREntry]
}

struct HAREntry: Decodable {
  let startedDateTime: String?
  let time: Double?
  let request: HARRequest
  let response: HARResponse
}

struct HARRequest: Decodable {
  let method: String
  let url: String
  let headers: [HARHeader]?
  let cookies: [HARCookie]?
  let postData: HARPostData?
}

struct HARResponse: Decodable {
  let status: Int
  let headers: [HARHeader]?
  let cookies: [HARCookie]?
  let content: HARContent?
}

struct HARHeader: Decodable {
  let name: String
  let value: String
}

struct HARCookie: Decodable {
  let name: String
  let value: String
}

struct HARPostData: Decodable {
  let mimeType: String?
  let text: String?
  let params: [HARParameter]?
}

struct HARParameter: Decodable {
  let name: String
  let value: String?
}

struct HARContent: Decodable {
  let mimeType: String?
  let text: String?
  let encoding: String?
}

extension CharacterSet {
  fileprivate static var urlQueryNameAllowed: CharacterSet {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=+?#{}")
    return allowed
  }
}
