import Foundation

enum ApprovalInputPathPolicy {
  static let requiredPaths: Set<String> = [
    "API/Config/source-manifest.json",
    "API/Config/trust-manifest.json",
    "API/Observed/catalog.json",
    "API/Observed/source-lock.json",
    "API/Trusted/openapi.yaml",
    "API/Trusted/operation-policies.json",
  ]

  static func validate(_ paths: some Collection<String>) throws {
    let pathSet = Set(paths)
    guard requiredPaths.isSubset(of: pathSet) else {
      let missing = requiredPaths.subtracting(pathSet).sorted()
      throw ContractError.invalidApproval(
        "input hashes are missing canonical authority: \(missing.joined(separator: ", "))"
      )
    }
    for path in pathSet.sorted() where !isAllowed(path) {
      throw ContractError.invalidApproval(
        "input hash path is not canonical provider authority: \(path)"
      )
    }
  }

  static func isAllowed(_ path: String) -> Bool {
    requiredPaths.contains(path)
      || isReceipt(
        path,
        prefix: "API/Observed/source-verifications/"
      )
      || isReceipt(
        path,
        prefix: "API/Observed/collection-verifications/"
      )
  }

  private static func isReceipt(_ path: String, prefix: String) -> Bool {
    guard path.hasPrefix(prefix) else { return false }
    let fileName = path.dropFirst(prefix.count)
    return fileName.count > ".json".count
      && !fileName.hasPrefix(".")
      && !fileName.contains("/")
      && !fileName.contains("\\")
      && !fileName.contains("..")
      && fileName.hasSuffix(".json")
  }
}
