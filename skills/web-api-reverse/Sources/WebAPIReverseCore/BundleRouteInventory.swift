import Foundation

public enum BundleRouteInventory {
  public static func inventory(
    at harURL: URL,
    options: BundleRouteInventoryOptions
  ) throws -> BundleRouteInventoryReceipt {
    try inventory(data: Data(contentsOf: harURL), options: options)
  }

  public static func inventory(
    data: Data,
    options: BundleRouteInventoryOptions
  ) throws -> BundleRouteInventoryReceipt {
    guard
      options.maximumBundleBytes > 0,
      options.maximumTotalBytes >= options.maximumBundleBytes
    else {
      throw BundleRouteInventoryError.invalidLimits
    }

    let document: BundleHARDocument
    do {
      document = try JSONDecoder().decode(BundleHARDocument.self, from: data)
    } catch {
      throw BundleRouteInventoryError.invalidHAR
    }

    let selected = document.log.entries.filter(isEmbeddedJavaScript)
    guard !selected.isEmpty else {
      throw BundleRouteInventoryError.emptySelection
    }

    var totalBytes = 0
    var assetsByIdentity: [String: BundleRouteAsset] = [:]
    var bundleCandidates: [String: Set<NormalizedBundleRoute>] = [:]

    for entry in selected {
      let body = try decodedBody(entry)
      guard body.count <= options.maximumBundleBytes else {
        throw BundleRouteInventoryError.oversizedBundle(
          entry.request.url,
          body.count
        )
      }
      totalBytes += body.count
      guard totalBytes <= options.maximumTotalBytes else {
        throw BundleRouteInventoryError.oversizedInventory(totalBytes)
      }
      guard let source = String(data: body, encoding: .utf8) else {
        throw BundleRouteInventoryError.malformedBundle(entry.request.url)
      }

      let sanitizedURL: String
      do {
        sanitizedURL = try EvidenceRedactor.sanitizeURL(entry.request.url)
      } catch {
        throw BundleRouteInventoryError.malformedBundle(entry.request.url)
      }
      let sha256 = FileDigest.sha256(data: body)
      let assetIdentity = "\(sanitizedURL)\n\(sha256)"
      let bundleId =
        "bundle_\(FileDigest.sha256(data: Data(assetIdentity.utf8)).prefix(16))"
      assetsByIdentity[assetIdentity] = BundleRouteAsset(
        bundleId: bundleId,
        sanitizedURL: sanitizedURL,
        sha256: sha256,
        byteCount: body.count,
        contentType: responseContentType(entry.response)
      )
      bundleCandidates[bundleId, default: []].formUnion(
        BundleRouteLiteralScanner.literals(in: source).compactMap(
          normalizeRouteCandidate
        )
      )
    }

    let bundles = assetsByIdentity.values.sorted {
      ($0.sanitizedURL, $0.sha256) < ($1.sanitizedURL, $1.sha256)
    }
    var bundleIDsByRoute: [NormalizedBundleRoute: Set<String>] = [:]
    for (bundleId, routes) in bundleCandidates {
      for route in routes {
        bundleIDsByRoute[route, default: []].insert(bundleId)
      }
    }
    let candidates = bundleIDsByRoute.map { route, bundleIds in
      let identity = "\(route.form.rawValue)\n\(route.route)"
      return BundleRouteCandidate(
        candidateId:
          "candidate_\(FileDigest.sha256(data: Data(identity.utf8)).prefix(16))",
        route: route.route,
        form: route.form,
        queryNames: route.queryNames,
        bundleIds: bundleIds.sorted()
      )
    }.sorted {
      ($0.form.rawValue, $0.route, $0.candidateId)
        < ($1.form.rawValue, $1.route, $1.candidateId)
    }
    let capturedAt =
      options.capturedAt
      ?? selected.compactMap(\.startedDateTime).sorted().last
      ?? "1970-01-01T00:00:00.000Z"
    let source = CaptureSource(
      sourceId: options.sourceId,
      surface: options.surface,
      version: options.sourceVersion,
      sha256: FileDigest.sha256(data: data),
      entryURL: bundles.first?.sanitizedURL
    )
    let identity = BundleRouteReceiptIdentity(
      capturedAt: capturedAt,
      brand: options.brand,
      market: options.market,
      source: source,
      bundles: bundles,
      candidates: candidates
    )
    let receiptId =
      "bundle_routes_\(FileDigest.sha256(data: try DeterministicJSON.encode(identity)).prefix(16))"
    let receipt = BundleRouteInventoryReceipt(
      receiptId: receiptId,
      capturedAt: capturedAt,
      brand: options.brand,
      market: options.market,
      source: source,
      bundles: bundles,
      candidates: candidates
    )
    let durable = String(
      decoding: try DeterministicJSON.encode(receipt),
      as: UTF8.self
    )
    guard !EvidenceRedactor.containsRawSecrets(in: durable) else {
      throw BundleRouteInventoryError.secretMaterialDetected
    }
    return receipt
  }

  private static func isEmbeddedJavaScript(
    _ entry: BundleHAREntry
  ) -> Bool {
    guard
      (200..<300).contains(entry.response.status),
      entry.response.content?.text != nil
    else {
      return false
    }
    let contentType = responseContentType(entry.response)?.lowercased() ?? ""
    if contentType.contains("javascript")
      || contentType.contains("ecmascript")
    {
      return true
    }
    guard
      let components = URLComponents(string: entry.request.url)
    else {
      return false
    }
    let path = components.path.lowercased()
    return path.hasSuffix(".js") || path.hasSuffix(".mjs")
  }

  private static func decodedBody(
    _ entry: BundleHAREntry
  ) throws -> Data {
    guard let content = entry.response.content, let text = content.text else {
      throw BundleRouteInventoryError.malformedBundle(entry.request.url)
    }
    switch content.encoding?.lowercased() {
    case nil, "", "utf8", "utf-8":
      return Data(text.utf8)
    case "base64":
      guard let decoded = Data(base64Encoded: text) else {
        throw BundleRouteInventoryError.malformedBundle(entry.request.url)
      }
      return decoded
    default:
      throw BundleRouteInventoryError.malformedBundle(entry.request.url)
    }
  }

  private static func responseContentType(
    _ response: BundleHARResponse
  ) -> String? {
    if let mimeType = response.content?.mimeType, !mimeType.isEmpty {
      return mimeType
    }
    return response.headers?.first {
      $0.name.caseInsensitiveCompare("content-type") == .orderedSame
    }?.value
  }

  private static func normalizeRouteCandidate(
    _ literal: String
  ) -> NormalizedBundleRoute? {
    let value = literal.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      value.count > 1,
      value.utf8.count <= 2_048,
      !value.contains(where: \.isNewline),
      !value.contains(where: \.isWhitespace)
    else {
      return nil
    }

    let form: BundleRouteForm
    let pathAndQuery: String
    let absoluteOrigin: String?
    if value.hasPrefix("https://") || value.hasPrefix("http://") {
      let validationValue = value.replacingOccurrences(
        of: "{template}",
        with: "template"
      )
      guard
        let components = URLComponents(string: validationValue),
        let scheme = components.scheme?.lowercased(),
        scheme == "http" || scheme == "https",
        let host = components.host?.lowercased(),
        !host.isEmpty
      else {
        return nil
      }
      form = .absolute
      absoluteOrigin =
        "\(scheme)://\(host)\(components.port.map { ":\($0)" } ?? "")"
      let originLength =
        value.firstIndex(of: "/", offsetBy: value.range(of: "://")!.upperBound)
        .map { value.distance(from: value.startIndex, to: $0) }
        ?? value.count
      pathAndQuery = String(value.dropFirst(originLength))
    } else if value.hasPrefix("/"), !value.hasPrefix("//") {
      form = .rootRelative
      absoluteOrigin = nil
      pathAndQuery = value
    } else {
      return nil
    }

    let withoutFragment =
      pathAndQuery.split(separator: "#", maxSplits: 1).first.map(String.init)
      ?? pathAndQuery
    let parts = withoutFragment.split(
      separator: "?",
      maxSplits: 1,
      omittingEmptySubsequences: false
    )
    var path = String(parts[0])
    guard
      path.hasPrefix("/"),
      path != "/",
      path.unicodeScalars.contains(where: {
        CharacterSet.letters.contains($0)
      }),
      !isStaticAsset(path)
    else {
      return nil
    }
    path = path.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map {
      EvidenceRedactor.redact(
        String($0).removingPercentEncoding ?? String($0)
      )
    }.joined(separator: "/")
    let rawQueryNames: [String] =
      parts.count == 2
      ? parts[1].split(separator: "&").compactMap { field in
        let rawName =
          field.split(
            separator: "=",
            maxSplits: 1,
            omittingEmptySubsequences: false
          ).first.map(String.init) ?? ""
        return rawName.removingPercentEncoding ?? rawName
      }
      : []
    let queryNames = EvidenceRedactor.normalizeQueryNames(rawQueryNames)
    let query = queryNames.map { name in
      let parameter = name.map {
        $0.isLetter || $0.isNumber || $0 == "_" ? $0 : "_"
      }
      let placeholder = String(parameter).isEmpty ? "query" : String(parameter)
      return "\(name)={\(placeholder)}"
    }.joined(separator: "&")
    let route =
      "\(absoluteOrigin ?? "")\(path)\(query.isEmpty ? "" : "?\(query)")"
    return NormalizedBundleRoute(
      route: route,
      form: form,
      queryNames: queryNames
    )
  }

  private static func isStaticAsset(_ path: String) -> Bool {
    let lowercased = path.lowercased()
    return [
      ".css", ".gif", ".ico", ".jpeg", ".jpg", ".js", ".json.map",
      ".mjs", ".png", ".svg", ".webp", ".woff", ".woff2",
    ].contains { lowercased.hasSuffix($0) }
  }
}

enum BundleRouteLiteralScanner {
  static func literals(in source: String) -> [String] {
    let scalars = Array(source.unicodeScalars)
    var result: [String] = []
    var index = 0
    while index < scalars.count {
      if scalars[index] == "/",
        index + 1 < scalars.count,
        !isEscaped(scalars, at: index),
        scalars[index + 1] == "/"
      {
        index = skipLineComment(scalars, from: index + 2)
      } else if scalars[index] == "/",
        index + 1 < scalars.count,
        !isEscaped(scalars, at: index),
        scalars[index + 1] == "*"
      {
        index = skipBlockComment(scalars, from: index + 2)
      } else if scalars[index] == "'" || scalars[index] == "\"" {
        let parsed = parseQuoted(
          scalars,
          from: index,
          delimiter: scalars[index]
        )
        if let value = parsed.value {
          result.append(value)
        }
        index = parsed.nextIndex
      } else if scalars[index] == "`" {
        let parsed = parseTemplate(scalars, from: index)
        if let value = parsed.value {
          result.append(value)
        }
        index = parsed.nextIndex
      } else if scalars[index] == "/",
        canStartRegexLiteral(scalars, at: index)
      {
        index = skipRegexLiteral(scalars, from: index)
      } else {
        index += 1
      }
    }
    return result
  }

  private static func parseQuoted(
    _ scalars: [UnicodeScalar],
    from start: Int,
    delimiter: UnicodeScalar
  ) -> (value: String?, nextIndex: Int) {
    var value = ""
    var index = start + 1
    while index < scalars.count {
      let scalar = scalars[index]
      if scalar == delimiter {
        return (value, index + 1)
      }
      if scalar == "\n" || scalar == "\r" {
        return (nil, index + 1)
      }
      if scalar == "\\" {
        let escaped = decodeEscape(scalars, from: index)
        guard let decoded = escaped.value else {
          return (nil, escaped.nextIndex)
        }
        value.append(contentsOf: decoded)
        index = escaped.nextIndex
      } else {
        value.unicodeScalars.append(scalar)
        index += 1
      }
    }
    return (nil, scalars.count)
  }

  private static func parseTemplate(
    _ scalars: [UnicodeScalar],
    from start: Int
  ) -> (value: String?, nextIndex: Int) {
    var value = ""
    var index = start + 1
    while index < scalars.count {
      let scalar = scalars[index]
      if scalar == "`" {
        return (value, index + 1)
      }
      if scalar == "\\",
        index + 1 < scalars.count
      {
        let escaped = decodeEscape(scalars, from: index)
        guard let decoded = escaped.value else {
          return (nil, escaped.nextIndex)
        }
        value.append(contentsOf: decoded)
        index = escaped.nextIndex
      } else if scalar == "$",
        index + 1 < scalars.count,
        scalars[index + 1] == "{"
      {
        value.append("{template}")
        index = skipTemplateExpression(scalars, from: index + 2)
      } else {
        value.unicodeScalars.append(scalar)
        index += 1
      }
    }
    return (nil, scalars.count)
  }

  private static func skipTemplateExpression(
    _ scalars: [UnicodeScalar],
    from start: Int
  ) -> Int {
    var depth = 1
    var index = start
    while index < scalars.count, depth > 0 {
      let scalar = scalars[index]
      if scalar == "'" || scalar == "\"" {
        index =
          parseQuoted(
            scalars,
            from: index,
            delimiter: scalar
          ).nextIndex
      } else if scalar == "`" {
        index = parseTemplate(scalars, from: index).nextIndex
      } else if scalar == "/",
        index + 1 < scalars.count,
        scalars[index + 1] == "/"
      {
        index = skipLineComment(scalars, from: index + 2)
      } else if scalar == "/",
        index + 1 < scalars.count,
        scalars[index + 1] == "*"
      {
        index = skipBlockComment(scalars, from: index + 2)
      } else if scalar == "/",
        canStartRegexLiteral(scalars, at: index)
      {
        index = skipRegexLiteral(scalars, from: index)
      } else {
        if scalar == "{" {
          depth += 1
        } else if scalar == "}" {
          depth -= 1
        }
        index += 1
      }
    }
    return index
  }

  private static func decodeEscape(
    _ scalars: [UnicodeScalar],
    from slash: Int
  ) -> (value: String?, nextIndex: Int) {
    guard slash + 1 < scalars.count else {
      return (nil, scalars.count)
    }
    let escaped = scalars[slash + 1]
    switch escaped {
    case "\n":
      return ("", slash + 2)
    case "\r":
      let next =
        slash + 2 < scalars.count && scalars[slash + 2] == "\n"
        ? slash + 3
        : slash + 2
      return ("", next)
    case "n":
      return ("\n", slash + 2)
    case "r":
      return ("\r", slash + 2)
    case "t":
      return ("\t", slash + 2)
    case "b":
      return ("\u{0008}", slash + 2)
    case "f":
      return ("\u{000C}", slash + 2)
    case "v":
      return ("\u{000B}", slash + 2)
    case "x":
      return decodeHexEscape(scalars, from: slash + 2, length: 2)
    case "u":
      if slash + 2 < scalars.count, scalars[slash + 2] == "{" {
        guard
          let close = scalars[(slash + 3)...].firstIndex(of: "}")
        else {
          return (nil, scalars.count)
        }
        let digits = String(String.UnicodeScalarView(scalars[(slash + 3)..<close]))
        guard
          let value = UInt32(digits, radix: 16),
          let scalar = UnicodeScalar(value)
        else {
          return (nil, close + 1)
        }
        return (String(scalar), close + 1)
      }
      return decodeHexEscape(scalars, from: slash + 2, length: 4)
    default:
      return (String(escaped), slash + 2)
    }
  }

  private static func decodeHexEscape(
    _ scalars: [UnicodeScalar],
    from start: Int,
    length: Int
  ) -> (value: String?, nextIndex: Int) {
    guard start + length <= scalars.count else {
      return (nil, scalars.count)
    }
    let digits = String(
      String.UnicodeScalarView(scalars[start..<(start + length)])
    )
    guard
      let value = UInt32(digits, radix: 16),
      let scalar = UnicodeScalar(value)
    else {
      return (nil, start + length)
    }
    return (String(scalar), start + length)
  }

  private static func skipLineComment(
    _ scalars: [UnicodeScalar],
    from start: Int
  ) -> Int {
    var index = start
    while index < scalars.count,
      scalars[index] != "\n",
      scalars[index] != "\r"
    {
      index += 1
    }
    return index
  }

  private static func isEscaped(
    _ scalars: [UnicodeScalar],
    at index: Int
  ) -> Bool {
    guard index > 0 else {
      return false
    }
    var backslashCount = 0
    var cursor = index - 1
    while scalars[cursor] == "\\" {
      backslashCount += 1
      guard cursor > 0 else {
        break
      }
      cursor -= 1
    }
    return backslashCount.isMultiple(of: 2) == false
  }

  private static func canStartRegexLiteral(
    _ scalars: [UnicodeScalar],
    at index: Int
  ) -> Bool {
    guard
      scalars[index] == "/",
      index + 1 < scalars.count,
      scalars[index + 1] != "/",
      scalars[index + 1] != "*"
    else {
      return false
    }

    var cursor = index
    var foundPreviousToken = false
    while cursor > 0 {
      cursor -= 1
      if !CharacterSet.whitespacesAndNewlines.contains(scalars[cursor]) {
        foundPreviousToken = true
        break
      }
    }
    guard foundPreviousToken else {
      return true
    }
    let previous = scalars[cursor]
    if "([{=:,;!?&|+-*%^~<>".unicodeScalars.contains(previous) {
      return true
    }
    guard isIdentifierScalar(previous) else {
      return false
    }
    let end = cursor + 1
    var start = cursor
    while start > 0, isIdentifierScalar(scalars[start - 1]) {
      start -= 1
    }
    let keyword = String(String.UnicodeScalarView(scalars[start..<end]))
    return [
      "await", "case", "delete", "do", "else", "in", "instanceof", "new",
      "of", "return", "throw", "typeof", "void", "yield",
    ].contains(keyword)
  }

  private static func isIdentifierScalar(
    _ scalar: UnicodeScalar
  ) -> Bool {
    CharacterSet.alphanumerics.contains(scalar)
      || scalar == "_"
      || scalar == "$"
  }

  private static func skipRegexLiteral(
    _ scalars: [UnicodeScalar],
    from start: Int
  ) -> Int {
    var index = start + 1
    var inCharacterClass = false
    while index < scalars.count {
      let scalar = scalars[index]
      if scalar == "\n" || scalar == "\r" {
        return index
      }
      if scalar == "\\" {
        index = min(index + 2, scalars.count)
        continue
      }
      if scalar == "[" {
        inCharacterClass = true
        index += 1
        continue
      }
      if scalar == "]", inCharacterClass {
        inCharacterClass = false
        index += 1
        continue
      }
      if scalar == "/", !inCharacterClass {
        index += 1
        while index < scalars.count,
          CharacterSet.letters.contains(scalars[index])
        {
          index += 1
        }
        return index
      }
      index += 1
    }
    return scalars.count
  }

  private static func skipBlockComment(
    _ scalars: [UnicodeScalar],
    from start: Int
  ) -> Int {
    var index = start
    while index + 1 < scalars.count {
      if scalars[index] == "*", scalars[index + 1] == "/" {
        return index + 2
      }
      index += 1
    }
    return scalars.count
  }
}

private struct NormalizedBundleRoute: Hashable, Sendable {
  let route: String
  let form: BundleRouteForm
  let queryNames: [String]
}

private struct BundleRouteReceiptIdentity:
  Codable, Equatable, Sendable
{
  let capturedAt: String
  let brand: String
  let market: String
  let source: CaptureSource
  let bundles: [BundleRouteAsset]
  let candidates: [BundleRouteCandidate]
}

private struct BundleHARDocument: Decodable {
  let log: BundleHARLog
}

private struct BundleHARLog: Decodable {
  let entries: [BundleHAREntry]
}

private struct BundleHAREntry: Decodable {
  let startedDateTime: String?
  let request: BundleHARRequest
  let response: BundleHARResponse
}

private struct BundleHARRequest: Decodable {
  let url: String
}

private struct BundleHARResponse: Decodable {
  let status: Int
  let headers: [BundleHARHeader]?
  let content: BundleHARContent?
}

private struct BundleHARHeader: Decodable {
  let name: String
  let value: String
}

private struct BundleHARContent: Decodable {
  let mimeType: String?
  let text: String?
  let encoding: String?
}

extension String {
  fileprivate func firstIndex(
    of character: Character,
    offsetBy start: Index
  ) -> Index? {
    self[start...].firstIndex(of: character)
  }
}
