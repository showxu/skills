import Foundation

enum MediaTypeFacts {
  static func canonical(_ rawValue: String?) -> String {
    let mediaType = normalized(rawValue)
    return isJSON(mediaType) ? "application/json" : mediaType
  }

  static func isValidOpenAPIMediaType(_ value: String) -> Bool {
    value.range(
      of: #"^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$"#,
      options: .regularExpression
    ) != nil
  }

  static func responseAliases(
    observed: [ResponseShape],
    verified: [TrustVerificationReceipt]
  ) -> [String: String] {
    let contentTypes =
      observed.compactMap(\.contentType)
      + verified.compactMap(\.response.contentType)
    return contentTypes.reduce(into: [String: String]()) { aliases, rawValue in
      let wire = normalized(rawValue)
      let canonical = canonical(rawValue)
      if wire != canonical {
        aliases[wire] = canonical
      }
    }
  }

  static func normalized(_ rawValue: String?) -> String {
    let mediaType =
      rawValue?
      .split(separator: ";", maxSplits: 1)
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      ?? ""
    return mediaType.isEmpty ? "application/json" : mediaType
  }

  private static func isJSON(_ mediaType: String) -> Bool {
    mediaType == "application/json"
      || mediaType == "text/json"
      || mediaType.hasSuffix("+json")
  }
}
