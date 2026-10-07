import Foundation

public enum EvidenceRedactor {
  public static let placeholder = "[REDACTED]"

  private static let sensitiveName = try! NSRegularExpression(
    pattern:
      #"(^|[-_.])(authorization|proxy-authorization|cookie|set-cookie|token|access[-_]?token|refresh[-_]?token|id[-_]?token|api[-_]?key|app[-_]?key|client[-_]?id|secret|secret[-_]?key|password|passwd|phone|mobile|email|mail|address|user[-_]?name|userid|user[-_]?id|member[-_]?id|idcard|card[-_]?number|session)([-_.]|$)"#,
    options: .caseInsensitive
  )
  private static let chineseIdentityNumber = try! NSRegularExpression(
    pattern: #"\b\d{17}[\dXx]\b"#
  )
  private static let replacements: [(NSRegularExpression, String)] = [
    (
      try! NSRegularExpression(
        pattern: #"(?<![A-Z0-9])(?:\+?86[-\s]?)?1[3-9]\d{9}(?![A-Z0-9])"#,
        options: .caseInsensitive
      ),
      placeholder
    ),
    (
      try! NSRegularExpression(
        pattern: #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
        options: .caseInsensitive
      ),
      placeholder
    ),
    (
      chineseIdentityNumber,
      placeholder
    ),
    (
      try! NSRegularExpression(
        pattern: #"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"#
      ),
      placeholder
    ),
    (
      try! NSRegularExpression(
        pattern: #"\bBearer\s+[A-Za-z0-9][A-Za-z0-9._~+/\-]{15,}=*"#,
        options: .caseInsensitive
      ),
      "Bearer \(placeholder)"
    ),
  ]
  private static let credentialAssignment = try! NSRegularExpression(
    pattern:
      #"((?:authorization|cookie|access[-_]?token|refresh[-_]?token|id[-_]?token|api[-_]?key|app[-_]?key|client[-_]?id|secret(?:[-_]?key)?|password|session)\b\\*["']?\s*[:=]\s*\\*["']?)([^&\s,"'<>\\]+)"#,
    options: .caseInsensitive
  )
  private static let reusableArtifactCredentialAssignment = try! NSRegularExpression(
    pattern:
      #"((?:authorization|cookie|access[-_]?token|refresh[-_]?token|id[-_]?token|api[-_]?key|app[-_]?key|client[-_]?id|secret(?:[-_]?key)?|password|session)\b\\*[\"']?\s*[:=]\s*\\*[\"']?)([A-Za-z0-9][A-Za-z0-9._~+/@\-]{7,}=*)"#,
    options: .caseInsensitive
  )
  private static let serializedCredential = try! NSRegularExpression(
    pattern:
      #""(?:authorization|cookie|access[-_]?token|refresh[-_]?token|id[-_]?token|api[-_]?key|app[-_]?key|client[-_]?id|secret(?:[-_]?key)?|password|session)"\s*:\s*"(?!\[REDACTED\])[^"]+""#,
    options: .caseInsensitive
  )

  private static let personalContexts: Set<String> = [
    "account", "address", "billing", "consignee", "contact", "customer",
    "member", "profile", "receiver", "recipient", "shipping", "user",
  ]
  private static let personalNames: Set<String> = [
    "consigneename", "displayname", "displaynick", "firstname", "fullname", "lastname",
    "name", "nick", "nickname", "realname", "receivername", "recipientname", "username",
  ]
  private static let personalContextSensitiveFields: Set<String> = [
    "identification", "identity",
  ]
  private static let strongPersonalIdentityFields: Set<String> = [
    "accountid", "address", "cardnumber", "email", "idcard", "mail", "memberid",
    "mobile", "phone", "userid", "usernumid", "username",
  ]
  private static let publicNumericIdentifierFields: Set<String> = [
    "barcode", "brandid", "ean", "externalid", "id", "itemid", "merchantid",
    "productcode", "productfeatures", "productid", "sellerid", "shopid",
    "skucode", "skuid", "spuid", "storeid", "traceid", "uniqueid", "upc",
  ]

  public static func isSensitiveName(_ name: String) -> Bool {
    sensitiveName.firstMatch(
      in: name,
      range: NSRange(name.startIndex..<name.endIndex, in: name)
    ) != nil
  }

  public static func isSensitiveHeaderName(_ name: String) -> Bool {
    let normalized = name.lowercased()
    if normalized == "sec-ch-ua" || normalized.hasPrefix("sec-ch-ua-") {
      return false
    }
    return isSensitiveName(name)
  }

  public static func redact(_ string: String) -> String {
    var result = string
    for (expression, replacement) in replacements {
      result = replace(expression, in: result, with: replacement)
    }
    return replace(
      credentialAssignment,
      in: result,
      with: "$1\(placeholder)"
    )
  }

  public static func redact(_ value: JSONValue, key: String = "") -> JSONValue {
    redact(value, path: key.isEmpty ? [] : [key], inheritedPersonalContext: false)
  }

  public static func sanitizeURL(_ rawURL: String) throws -> String {
    guard var components = URLComponents(string: rawURL),
      components.scheme != nil,
      components.host != nil
    else {
      throw CapturePipelineError.invalidURL(rawURL)
    }

    let entries = normalizedQueryEntries(
      (components.queryItems ?? []).map(\.name)
    )
    components.queryItems =
      entries.isEmpty
      ? nil
      : entries.map { entry in
        URLQueryItem(
          name: entry.normalized,
          value: isSensitiveName(entry.raw) ? placeholder : "{value}"
        )
      }
    components.fragment = nil
    components.user = nil
    components.password = nil

    let decodedPath =
      components.percentEncodedPath.removingPercentEncoding
      ?? components.path
    let sanitizedSegments = decodedPath.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map { segment in
      redact(String(segment))
        .addingPercentEncoding(withAllowedCharacters: .urlPathSegmentAllowed)
        ?? placeholder
    }
    components.percentEncodedPath = sanitizedSegments.joined(separator: "/")

    guard let result = components.url?.absoluteString else {
      throw CapturePipelineError.invalidURL(rawURL)
    }
    return result
  }

  public static func normalizeQueryNames(_ names: [String]) -> [String] {
    normalizedQueryEntries(names).map(\.normalized)
  }

  public static func headerPresence(
    _ headers: [String: String]
  ) -> [HeaderPresence] {
    headers.keys
      .map { name in
        HeaderPresence(
          name: name.lowercased(),
          present: true,
          sensitive: isSensitiveHeaderName(name)
        )
      }
      .sorted { $0.name < $1.name }
  }

  public static func cookieNames(_ headers: [String: String]) -> [String] {
    guard
      let cookie = headers.first(where: {
        $0.key.caseInsensitiveCompare("cookie") == .orderedSame
      })?.value
    else {
      return []
    }
    return Array(
      Set(
        cookie.split(separator: ";").compactMap { part in
          let name = part.split(separator: "=", maxSplits: 1).first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
          return name?.isEmpty == false ? name : nil
        }
      )
    ).sorted()
  }

  public static func containsRawSecrets(in text: String) -> Bool {
    // Durable evidence is redacted structurally before this check. Numeric
    // identity-shaped values under reviewed public Product/SKU identifier
    // fields are intentionally preserved, while raw artifact scans retain
    // their independent Chinese-identity-number rule.
    let expressions =
      replacements.enumerated().compactMap { index, replacement in
        index == 2 ? nil : replacement.0
      } + [serializedCredential]
    return expressions.contains { expression in
      expression.firstMatch(
        in: text,
        range: NSRange(text.startIndex..<text.endIndex, in: text)
      ) != nil
    }
  }

  public static func containsStructuredPersonalMaterial(in value: JSONValue) -> Bool {
    switch value {
    case .object(let object):
      let hasConcreteIdentity = object.contains { key, child in
        strongPersonalIdentityFields.contains(normalizeFieldName(key))
          && !isRedactedSensitiveShape(child)
          && isScalar(child)
      }
      if hasConcreteIdentity {
        return true
      }
      let hasIdentityField = object.contains { key, child in
        strongPersonalIdentityFields.contains(normalizeFieldName(key))
          && isScalar(child)
      }
      if hasIdentityField,
        object.contains(where: { key, child in
          personalNames.contains(normalizeFieldName(key))
            && !isRedactedSensitiveShape(child)
            && isScalar(child)
        })
      {
        return true
      }
      return object.values.contains(where: containsStructuredPersonalMaterial)
    case .array(let values):
      return values.contains(where: containsStructuredPersonalMaterial)
    case .string, .number, .bool, .null:
      return false
    }
  }

  public static func containsStructuredChineseIdentityNumber(
    in value: JSONValue,
    key: String = ""
  ) -> Bool {
    switch value {
    case .object(let object):
      return object.contains { key, child in
        containsStructuredChineseIdentityNumber(
          in: child,
          key: key
        )
      }
    case .array(let values):
      return values.contains {
        containsStructuredChineseIdentityNumber(
          in: $0,
          key: key
        )
      }
    case .string(let string):
      guard !preservesPublicValue(key) else {
        return false
      }
      return chineseIdentityNumber.firstMatch(
        in: string,
        range: NSRange(string.startIndex..<string.endIndex, in: string)
      ) != nil
    case .number, .bool, .null:
      return false
    }
  }

  public static func redactStructuredPersonalMaterial(_ value: JSONValue) -> JSONValue {
    switch value {
    case .object(let object):
      let hasIdentityField = object.contains { key, child in
        strongPersonalIdentityFields.contains(normalizeFieldName(key))
          && isScalar(child)
      }
      return .object(
        object.reduce(into: [String: JSONValue]()) { result, entry in
          let normalizedKey = normalizeFieldName(entry.key)
          if isScalar(entry.value),
            strongPersonalIdentityFields.contains(normalizedKey)
              || (hasIdentityField && personalNames.contains(normalizedKey))
          {
            result[entry.key] = redactSensitiveShape(entry.value)
          } else {
            result[entry.key] = redactStructuredPersonalMaterial(entry.value)
          }
        }
      )
    case .array(let values):
      return .array(values.map(redactStructuredPersonalMaterial))
    case .string, .number, .bool, .null:
      return value
    }
  }

  public static func redactReusableArtifactMaterial(
    _ value: JSONValue
  ) -> JSONValue {
    redactArtifactStrings(
      redactStructuredPersonalMaterial(value),
      key: ""
    )
  }

  private static func redactArtifactStrings(
    _ value: JSONValue,
    key: String
  ) -> JSONValue {
    switch value {
    case .object(let object):
      return .object(
        object.reduce(into: [String: JSONValue]()) { result, entry in
          if isScalar(entry.value),
            isSensitiveName(entry.key),
            !isPublicNumericApplicationIdentifier(
              entry.value,
              key: entry.key
            )
          {
            result[entry.key] = redactSensitiveShape(entry.value)
          } else {
            result[entry.key] = redactArtifactStrings(
              entry.value,
              key: entry.key
            )
          }
        }
      )
    case .array(let values):
      return .array(
        values.map { redactArtifactStrings($0, key: key) }
      )
    case .string(let string):
      return .string(
        preservesPublicValue(key)
          ? redactReusableArtifactNonNumericSecrets(string)
          : redactReusableArtifactString(string)
      )
    case .number, .bool, .null:
      return value
    }
  }

  private static func redactReusableArtifactString(
    _ string: String
  ) -> String {
    var result = string
    for (expression, replacement) in replacements {
      result = replace(expression, in: result, with: replacement)
    }
    return replace(
      reusableArtifactCredentialAssignment,
      in: result,
      with: "$1\(placeholder)"
    )
  }

  private static func redactReusableArtifactNonNumericSecrets(
    _ string: String
  ) -> String {
    var result = string
    for (index, entry) in replacements.enumerated()
    where index != 0 && index != 2
    {
      result = replace(entry.0, in: result, with: entry.1)
    }
    return replace(
      reusableArtifactCredentialAssignment,
      in: result,
      with: "$1\(placeholder)"
    )
  }

  private static func isPublicNumericApplicationIdentifier(
    _ value: JSONValue,
    key: String
  ) -> Bool {
    guard normalizeFieldName(key) == "appkey" else { return false }
    let text: String
    switch value {
    case .string(let string):
      text = string
    case .number(let number):
      guard let integer = Int64(exactly: number) else { return false }
      text = String(integer)
    case .object, .array, .bool, .null:
      return false
    }
    return text.count == 8 && text.allSatisfy(\.isNumber)
  }

  private static func redact(
    _ value: JSONValue,
    path: [String],
    inheritedPersonalContext: Bool
  ) -> JSONValue {
    let key = path.last ?? ""
    let normalizedKey = normalizeFieldName(key)
    let personalContext =
      inheritedPersonalContext
      || path.dropLast().contains {
        personalContexts.contains(normalizeFieldName($0))
      }

    if isSensitiveName(key)
      || strongPersonalIdentityFields.contains(normalizedKey)
      || ((personalNames.contains(normalizedKey)
        || personalContextSensitiveFields.contains(normalizedKey))
        && personalContext)
    {
      return redactSensitiveShape(value)
    }

    switch value {
    case .object(let object):
      let objectHasPersonalIdentity = object.keys.contains {
        strongPersonalIdentityFields.contains(normalizeFieldName($0))
      }
      return .object(
        object.mapValues { child in child }
          .reduce(into: [String: JSONValue]()) { result, entry in
            result[entry.key] = redact(
              entry.value,
              path: path + [entry.key],
              inheritedPersonalContext: personalContext || objectHasPersonalIdentity
            )
          }
      )
    case .array(let array):
      return .array(
        array.map {
          redact(
            $0,
            path: path,
            inheritedPersonalContext: personalContext
          )
        }
      )
    case .string(let string):
      return .string(
        preservesPublicValue(key)
          ? redactNonNumericSecrets(string)
          : redact(string)
      )
    case .number, .bool, .null:
      return value
    }
  }

  private static func redactSensitiveShape(_ value: JSONValue) -> JSONValue {
    switch value {
    case .object(let object):
      return .object(object.mapValues(redactSensitiveShape))
    case .array(let array):
      return .array(array.map(redactSensitiveShape))
    case .string:
      return .string(placeholder)
    case .number:
      return .number(0)
    case .bool:
      return .bool(false)
    case .null:
      return .null
    }
  }

  private static func isScalar(_ value: JSONValue) -> Bool {
    switch value {
    case .string, .number, .bool, .null:
      true
    case .object, .array:
      false
    }
  }

  private static func isRedactedSensitiveShape(_ value: JSONValue) -> Bool {
    switch value {
    case .string(let value):
      value == placeholder
    case .number(let value):
      value == 0
    case .bool(let value):
      value == false
    case .null:
      true
    case .object, .array:
      false
    }
  }

  private static func normalizedQueryEntries(
    _ names: [String]
  ) -> [(raw: String, normalized: String)] {
    var dynamicIndex = 0
    return Array(Set(names)).sorted().map { raw in
      guard isDynamicQueryName(raw) else {
        return (raw, raw)
      }
      dynamicIndex += 1
      return (raw, "dynamicQuery\(dynamicIndex)")
    }
  }

  private static func isDynamicQueryName(_ value: String) -> Bool {
    redact(value) != value
      || matches(#"^\d{5,}$"#, value)
      || matches(#"^[a-f0-9]{16,}$"#, value, caseInsensitive: true)
      || matches(
        #"^[0-9a-f]{8}-[0-9a-f-]{27,}$"#,
        value,
        caseInsensitive: true
      )
      || (value.count >= 28 && value.contains(where: \.isNumber)
        && (value.contains("-") || value.contains("_")))
  }

  private static func preservesPublicValue(_ fieldName: String) -> Bool {
    let normalized = normalizeFieldName(fieldName)
    return publicNumericIdentifierFields.contains(normalized)
      || normalized == "required"
      || normalized == "entryurltemplate"
      || normalized == "finalurltemplate"
      || normalized == "imgurl"
      || normalized == "images"
      || normalized == "imageurls"
      || normalized == "url"
      || normalized.hasSuffix("imageurl")
      || normalized.hasSuffix("photourl")
      || normalized.hasSuffix("thumbnailurl")
      || normalized.hasSuffix("videourl")
  }

  private static func redactNonNumericSecrets(_ value: String) -> String {
    var result = value
    for (index, entry) in replacements.enumerated() where index != 0 && index != 2 {
      result = replace(entry.0, in: result, with: entry.1)
    }
    return replace(
      credentialAssignment,
      in: result,
      with: "$1\(placeholder)"
    )
  }

  private static func normalizeFieldName(_ value: String) -> String {
    value.filter { $0.isLetter || $0.isNumber }.lowercased()
  }

  private static func replace(
    _ expression: NSRegularExpression,
    in value: String,
    with replacement: String
  ) -> String {
    expression.stringByReplacingMatches(
      in: value,
      range: NSRange(value.startIndex..<value.endIndex, in: value),
      withTemplate: replacement
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

extension CharacterSet {
  fileprivate static var urlPathSegmentAllowed: CharacterSet {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove(charactersIn: "/?#")
    return allowed
  }
}
