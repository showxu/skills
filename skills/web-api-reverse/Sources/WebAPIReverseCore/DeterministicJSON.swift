import CryptoKit
import Foundation

public enum DeterministicJSON {
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    var data = try encoder.encode(value)
    if data.last != 0x0A {
      data.append(0x0A)
    }
    return data
  }

  public static func decode<T: Decodable>(
    _ type: T.Type,
    from data: Data
  ) throws -> T {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(type, from: data)
  }

  public static func write<T: Encodable>(
    _ value: T,
    to url: URL,
    fileManager: FileManager = .default
  ) throws {
    let data = try encode(value)
    try fileManager.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
  }

  public static func canonicalSHA256(_ data: Data) throws -> String {
    let value = try JSONSerialization.jsonObject(with: data)
    let canonical = try JSONSerialization.data(
      withJSONObject: value,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    return SHA256.hash(data: canonical)
      .map { String(format: "%02x", $0) }
      .joined()
  }

  public static func canonicalSHA256(fileAt url: URL) throws -> String {
    try canonicalSHA256(Data(contentsOf: url))
  }
}
