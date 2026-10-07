import Foundation

enum ReviewedResponseExtractionError: Error, Equatable, LocalizedError {
  case invalidPolicy
  case missingFixture
  case invalidCallback(String)
  case callbackMismatch(String)
  case htmlScriptJSONNotFound
  case htmlScriptJSONAmbiguous
  case javascriptAssignmentJSONNotFound
  case javascriptAssignmentJSONAmbiguous
  case invalidPayload

  var errorDescription: String? {
    switch self {
    case .invalidPolicy:
      "Reviewed response extraction policy is invalid."
    case .missingFixture:
      "Reviewed response extraction requires a response fixture."
    case .invalidCallback(let callback):
      "Reviewed JSONP callback is invalid: \(callback)"
    case .callbackMismatch(let callback):
      "Response does not match reviewed JSONP callback: \(callback)"
    case .htmlScriptJSONNotFound:
      "Response does not contain the reviewed HTML script JSON payload."
    case .htmlScriptJSONAmbiguous:
      "Response contains more than one reviewed HTML script JSON payload."
    case .javascriptAssignmentJSONNotFound:
      "Response does not contain the reviewed JavaScript JSON assignment."
    case .javascriptAssignmentJSONAmbiguous:
      "Response contains more than one reviewed JavaScript JSON assignment."
    case .invalidPayload:
      "Reviewed response extraction produced invalid JSON."
    }
  }
}

struct ReviewedResponseProjection: Equatable, Sendable {
  let response: ResponseShape
  let fixture: JSONValue?
}

enum ReviewedResponseExtractor {
  static func validatePolicy(_ policy: JSONValue?) throws {
    guard let policy, case .object(let fields) = policy else {
      throw ReviewedResponseExtractionError.invalidPolicy
    }
    guard case .string(let kind) = fields["kind"], !kind.isEmpty else {
      throw ReviewedResponseExtractionError.invalidPolicy
    }
    switch kind {
    case "jsonP":
      if case .string(let callback) = fields["callback"] {
        try validateJSONPCallback(callback)
      } else {
        guard
          case .string(let queryName) = fields["callbackQueryName"],
          queryName.range(
            of: #"^[A-Za-z_][A-Za-z0-9_.-]*$"#,
            options: .regularExpression
          ) != nil
        else {
          throw ReviewedResponseExtractionError.invalidPolicy
        }
      }
    case "htmlScriptJSON":
      guard
        case .string(let scriptType) = fields["scriptType"],
        !scriptType.isEmpty,
        case .object(let match) = fields["match"],
        case .string(let matchField) = match["field"],
        !matchField.isEmpty,
        match["equals"] != nil
      else {
        throw ReviewedResponseExtractionError.invalidPolicy
      }
    case "javascriptAssignmentJSON":
      guard
        case .string(let variable) = fields["variable"],
        variable.range(
          of: #"^[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*$"#,
          options: .regularExpression
        ) != nil
      else {
        throw ReviewedResponseExtractionError.invalidPolicy
      }
    default:
      break
    }
  }

  static func project(
    response: ResponseShape,
    fixture: JSONValue?,
    policy: JSONValue?
  ) throws -> ReviewedResponseProjection {
    guard let policy, case .object(let fields) = policy else {
      return ReviewedResponseProjection(response: response, fixture: fixture)
    }
    try validatePolicy(policy)
    guard case .string(let kind) = fields["kind"] else {
      throw ReviewedResponseExtractionError.invalidPolicy
    }
    let payload: JSONValue
    switch kind {
    case "jsonP":
      let callback: String
      if case .string(let reviewedCallback) = fields["callback"] {
        callback = reviewedCallback
      } else if case .string = fields["callbackQueryName"] {
        guard let fixture else {
          throw ReviewedResponseExtractionError.missingFixture
        }
        callback = try extractJSONPCallback(fixture)
      } else {
        throw ReviewedResponseExtractionError.invalidPolicy
      }
      guard let fixture else {
        throw ReviewedResponseExtractionError.missingFixture
      }
      payload = try extractJSONP(fixture, callback: callback)
    case "htmlScriptJSON":
      guard
        case .string(let scriptType) = fields["scriptType"],
        !scriptType.isEmpty,
        case .object(let match) = fields["match"],
        case .string(let matchField) = match["field"],
        !matchField.isEmpty,
        let matchValue = match["equals"],
        let fixture
      else {
        throw ReviewedResponseExtractionError.invalidPolicy
      }
      payload = try extractHTMLScriptJSON(
        fixture,
        scriptType: scriptType,
        matchField: matchField,
        matchValue: matchValue
      )
    case "javascriptAssignmentJSON":
      guard case .string(let variable) = fields["variable"], let fixture else {
        throw ReviewedResponseExtractionError.invalidPolicy
      }
      payload = try extractJavaScriptAssignmentJSON(
        fixture,
        variable: variable
      )
    default:
      return ReviewedResponseProjection(response: response, fixture: fixture)
    }
    return ReviewedResponseProjection(
      response: ResponseShape(
        status: response.status,
        contentType: "application/json",
        bodySchema: JSONSchemaInference.infer(payload),
        outcome: response.outcome,
        businessErrorSignals: response.businessErrorSignals,
        responseHeaderNames: response.responseHeaderNames,
        setCookieNames: response.setCookieNames
      ),
      fixture: EvidenceRedactor.redact(payload)
    )
  }

  private static func extractJSONP(
    _ fixture: JSONValue,
    callback: String
  ) throws -> JSONValue {
    try validateJSONPCallback(callback)
    guard case .string(let source) = fixture else {
      throw ReviewedResponseExtractionError.callbackMismatch(callback)
    }
    let escaped = NSRegularExpression.escapedPattern(for: callback)
    let expression = try NSRegularExpression(
      pattern: #"^\s*"# + escaped + #"\s*\(\s*([\s\S]*)\s*\)\s*;?\s*$"#
    )
    let fullRange = NSRange(source.startIndex..., in: source)
    guard
      let match = expression.firstMatch(in: source, range: fullRange),
      let payloadRange = Range(match.range(at: 1), in: source)
    else {
      throw ReviewedResponseExtractionError.callbackMismatch(callback)
    }
    do {
      return try JSONDecoder().decode(
        JSONValue.self,
        from: Data(source[payloadRange].utf8)
      )
    } catch {
      throw ReviewedResponseExtractionError.invalidPayload
    }
  }

  private static func extractJSONPCallback(_ fixture: JSONValue) throws
    -> String
  {
    guard case .string(let source) = fixture else {
      throw ReviewedResponseExtractionError.invalidPayload
    }
    let expression = try NSRegularExpression(
      pattern:
        #"^\s*([A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*)\s*\("#
    )
    let fullRange = NSRange(source.startIndex..., in: source)
    guard
      let match = expression.firstMatch(in: source, range: fullRange),
      let callbackRange = Range(match.range(at: 1), in: source)
    else {
      throw ReviewedResponseExtractionError.invalidPayload
    }
    return String(source[callbackRange])
  }

  private static func validateJSONPCallback(_ callback: String) throws {
    guard
      callback.range(
        of: #"^[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*$"#,
        options: .regularExpression
      ) != nil
    else {
      throw ReviewedResponseExtractionError.invalidCallback(callback)
    }
  }

  private static func extractHTMLScriptJSON(
    _ fixture: JSONValue,
    scriptType: String,
    matchField: String,
    matchValue: JSONValue
  ) throws -> JSONValue {
    guard case .string(let source) = fixture else {
      throw ReviewedResponseExtractionError.missingFixture
    }
    let scriptPayloads = try scriptPayloads(in: source, scriptType: scriptType)
    let matches = try scriptPayloads.compactMap { payload -> JSONValue? in
      let value: JSONValue
      do {
        value = try JSONDecoder().decode(JSONValue.self, from: Data(payload.utf8))
      } catch {
        throw ReviewedResponseExtractionError.invalidPayload
      }
      guard case .object(let fields) = value, fields[matchField] == matchValue else {
        return nil
      }
      return value
    }
    guard !matches.isEmpty else {
      throw ReviewedResponseExtractionError.htmlScriptJSONNotFound
    }
    guard matches.count == 1 else {
      throw ReviewedResponseExtractionError.htmlScriptJSONAmbiguous
    }
    return matches[0]
  }

  private static func extractJavaScriptAssignmentJSON(
    _ fixture: JSONValue,
    variable: String
  ) throws -> JSONValue {
    guard
      variable.range(
        of: #"^[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*$"#,
        options: .regularExpression
      ) != nil
    else {
      throw ReviewedResponseExtractionError.invalidPolicy
    }
    guard case .string(let source) = fixture else {
      throw ReviewedResponseExtractionError.missingFixture
    }
    let matches = try scriptPayloads(in: source, scriptType: nil).flatMap {
      try javaScriptAssignments(in: $0, variable: variable)
    }
    guard !matches.isEmpty else {
      throw ReviewedResponseExtractionError.javascriptAssignmentJSONNotFound
    }
    guard matches.count == 1 else {
      throw ReviewedResponseExtractionError.javascriptAssignmentJSONAmbiguous
    }
    return matches[0]
  }

  private static func scriptPayloads(
    in source: String,
    scriptType: String?
  ) throws -> [String] {
    var payloads: [String] = []
    var searchStart = source.startIndex
    while let openRange = source.range(
      of: "<script",
      options: .caseInsensitive,
      range: searchStart..<source.endIndex
    ) {
      guard
        let openEnd = source[openRange.upperBound...].firstIndex(of: ">")
      else {
        throw ReviewedResponseExtractionError.invalidPayload
      }
      let openTag = String(source[openRange.lowerBound...openEnd])
      let contentStart = source.index(after: openEnd)
      guard
        let closeRange = source.range(
          of: "</script",
          options: .caseInsensitive,
          range: contentStart..<source.endIndex
        ),
        let closeEnd = source[closeRange.upperBound...].firstIndex(of: ">")
      else {
        throw ReviewedResponseExtractionError.invalidPayload
      }
      if scriptType == nil
        || scriptTypeAttribute(in: openTag)?.caseInsensitiveCompare(scriptType!)
          == .orderedSame
      {
        payloads.append(
          source[contentStart..<closeRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        )
      }
      searchStart = source.index(after: closeEnd)
    }
    return payloads
  }

  private static func javaScriptAssignments(
    in source: String,
    variable: String
  ) throws -> [JSONValue] {
    enum LexicalState {
      case normal
      case singleQuote
      case doubleQuote
      case templateQuote
      case lineComment
      case blockComment
    }

    let bytes = Array(source.utf8)
    let variableBytes = Array(variable.utf8)
    var values: [JSONValue] = []
    var state = LexicalState.normal
    var index = 0

    while index < bytes.count {
      let byte = bytes[index]
      switch state {
      case .singleQuote, .doubleQuote, .templateQuote:
        if byte == 0x5C {
          index = min(index + 2, bytes.count)
          continue
        }
        let terminator: UInt8 =
          state == .singleQuote ? 0x27 : (state == .doubleQuote ? 0x22 : 0x60)
        if byte == terminator {
          state = .normal
        }
        index += 1
      case .lineComment:
        if byte == 0x0A || byte == 0x0D {
          state = .normal
        }
        index += 1
      case .blockComment:
        if byte == 0x2A, bytes[safe: index + 1] == 0x2F {
          state = .normal
          index += 2
        } else {
          index += 1
        }
      case .normal:
        if byte == 0x27 {
          state = .singleQuote
          index += 1
          continue
        }
        if byte == 0x22 {
          state = .doubleQuote
          index += 1
          continue
        }
        if byte == 0x60 {
          state = .templateQuote
          index += 1
          continue
        }
        if byte == 0x2F, bytes[safe: index + 1] == 0x2F {
          state = .lineComment
          index += 2
          continue
        }
        if byte == 0x2F, bytes[safe: index + 1] == 0x2A {
          state = .blockComment
          index += 2
          continue
        }
        guard matches(variableBytes, in: bytes, at: index) else {
          index += 1
          continue
        }
        let end = index + variableBytes.count
        let beforeIsIdentifier =
          index > 0 && isJavaScriptIdentifierByte(bytes[index - 1])
        let afterIsIdentifier =
          end < bytes.count
          && (isJavaScriptIdentifierByte(bytes[end]) || bytes[end] == 0x2E)
        guard !beforeIsIdentifier, !afterIsIdentifier else {
          index += 1
          continue
        }
        var cursor = skipWhitespace(in: bytes, from: end)
        guard bytes[safe: cursor] == 0x3D,
          bytes[safe: cursor + 1] != 0x3D,
          bytes[safe: cursor + 1] != 0x3E
        else {
          index += 1
          continue
        }
        cursor = skipWhitespace(in: bytes, from: cursor + 1)
        guard bytes[safe: cursor] == 0x7B || bytes[safe: cursor] == 0x5B else {
          index += 1
          continue
        }
        let payloadEnd = try balancedJSONEnd(in: bytes, from: cursor)
        do {
          values.append(
            try JSONDecoder().decode(
              JSONValue.self,
              from: Data(bytes[cursor..<payloadEnd])
            )
          )
        } catch {
          throw ReviewedResponseExtractionError.invalidPayload
        }
        index = payloadEnd
      }
    }
    return values
  }

  private static func balancedJSONEnd(
    in bytes: [UInt8],
    from start: Int
  ) throws -> Int {
    var expectedClosures: [UInt8] = []
    var inString = false
    var escaped = false
    var index = start
    while index < bytes.count {
      let byte = bytes[index]
      if inString {
        if escaped {
          escaped = false
        } else if byte == 0x5C {
          escaped = true
        } else if byte == 0x22 {
          inString = false
        }
      } else {
        switch byte {
        case 0x22:
          inString = true
        case 0x7B:
          expectedClosures.append(0x7D)
        case 0x5B:
          expectedClosures.append(0x5D)
        case 0x7D, 0x5D:
          guard expectedClosures.popLast() == byte else {
            throw ReviewedResponseExtractionError.invalidPayload
          }
          if expectedClosures.isEmpty {
            return index + 1
          }
        default:
          break
        }
      }
      index += 1
    }
    throw ReviewedResponseExtractionError.invalidPayload
  }

  private static func matches(
    _ needle: [UInt8],
    in bytes: [UInt8],
    at index: Int
  ) -> Bool {
    guard index + needle.count <= bytes.count else {
      return false
    }
    return bytes[index..<(index + needle.count)].elementsEqual(needle)
  }

  private static func skipWhitespace(
    in bytes: [UInt8],
    from start: Int
  ) -> Int {
    var index = start
    while let byte = bytes[safe: index],
      byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
    {
      index += 1
    }
    return index
  }

  private static func isJavaScriptIdentifierByte(_ byte: UInt8) -> Bool {
    (byte >= 0x41 && byte <= 0x5A)
      || (byte >= 0x61 && byte <= 0x7A)
      || (byte >= 0x30 && byte <= 0x39)
      || byte == 0x5F
      || byte == 0x24
  }

  private static func scriptTypeAttribute(in openTag: String) -> String? {
    let expression = try? NSRegularExpression(
      pattern: #"(?i)(?:^|\s)type\s*=\s*([\"'])(.*?)\1"#
    )
    let range = NSRange(openTag.startIndex..., in: openTag)
    guard
      let match = expression?.firstMatch(in: openTag, range: range),
      let valueRange = Range(match.range(at: 2), in: openTag)
    else {
      return nil
    }
    return String(openTag[valueRange])
  }
}

extension Array {
  fileprivate subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
