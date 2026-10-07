import Foundation

enum OpenAPIInspection {
  static func operationIds(at url: URL) throws -> Set<String> {
    try operationIds(data: Data(contentsOf: url))
  }

  static func operationIds(data: Data) throws -> Set<String> {
    if let root = try? JSONSerialization.jsonObject(with: data),
      let object = root as? [String: Any]
    {
      return operationIds(inJSON: object)
    }

    let text = String(decoding: data, as: UTF8.self)
    let expression = try NSRegularExpression(
      pattern: #"(?m)^\s*operationId:\s*["']?([^"'#\s]+)["']?\s*(?:#.*)?$"#
    )
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return Set(
      expression.matches(in: text, range: range).compactMap { match in
        Range(match.range(at: 1), in: text).map { String(text[$0]) }
      }
    )
  }

  private static func operationIds(inJSON root: [String: Any]) -> Set<String> {
    guard let paths = root["paths"] as? [String: Any] else {
      return []
    }
    let methods = Set([
      "delete", "get", "head", "options", "patch", "post", "put", "trace",
    ])
    var result = Set<String>()
    for pathItem in paths.values {
      guard let operations = pathItem as? [String: Any] else {
        continue
      }
      for (method, value) in operations where methods.contains(method.lowercased()) {
        guard let operation = value as? [String: Any],
          let operationId = operation["operationId"] as? String,
          !operationId.isEmpty
        else {
          continue
        }
        result.insert(operationId)
      }
    }
    return result
  }
}
