import Foundation

public enum VerificationReceiptLoader {
  public static let canonicalDirectoryName = "verifications"
  public static let legacyDirectoryName = "verification"

  public static func loadObserved(
    from observedDirectory: URL,
    fileManager: FileManager = .default
  ) throws -> [TrustVerificationReceipt] {
    let canonical = observedDirectory.appending(
      path: canonicalDirectoryName,
      directoryHint: .isDirectory
    )
    let legacy = observedDirectory.appending(
      path: legacyDirectoryName,
      directoryHint: .isDirectory
    )
    if fileManager.fileExists(atPath: legacy.path) {
      throw ContractError.invalidObservedEvidence(
        "legacy directory \(legacy.path) is unsupported; move its receipts "
          + "to \(canonical.path), remove the singular directory, and rerun inventory"
      )
    }
    return try load(from: canonical, fileManager: fileManager)
  }

  static func loadObserved(
    snapshot: ProviderAPIAuthoritySnapshot
  ) throws -> [TrustVerificationReceipt] {
    let canonical = "API/Observed/\(canonicalDirectoryName)"
    let legacy = "API/Observed/\(legacyDirectoryName)"
    if snapshot.containsDirectory(legacy) {
      throw ContractError.invalidObservedEvidence(
        "legacy directory \(legacy) is unsupported; move its receipts "
          + "to \(canonical), remove the singular directory, and rerun inventory"
      )
    }
    var receipts: [TrustVerificationReceipt] = []
    var verificationIDs = Set<String>()
    for artifact in snapshot.recursiveFiles(in: canonical)
    where artifact.path.hasSuffix(".json") {
      let discriminator = try DeterministicJSON.decode(
        VerificationArtifactDiscriminator.self,
        from: artifact.data
      )
      guard
        discriminator.kind == "web-api-reverse.verification-receipt"
      else { continue }
      let receipt = try DeterministicJSON.decode(
        TrustVerificationReceipt.self,
        from: artifact.data
      )
      guard verificationIDs.insert(receipt.verificationId).inserted else {
        throw ContractError.invalidObservedEvidence(
          "duplicate verification receipt ID \(receipt.verificationId)"
        )
      }
      receipts.append(receipt)
    }
    return receipts.sorted {
      ($0.verificationId, $0.operationId)
        < ($1.verificationId, $1.operationId)
    }
  }

  public static func load(
    from directory: URL,
    fileManager: FileManager = .default
  ) throws -> [TrustVerificationReceipt] {
    var isDirectory: ObjCBool = false
    guard
      fileManager.fileExists(
        atPath: directory.path,
        isDirectory: &isDirectory
      )
    else {
      return []
    }
    guard isDirectory.boolValue else {
      throw ContractError.invalidDirectory(directory.path)
    }
    let rootValues = try directory.resourceValues(
      forKeys: [.isSymbolicLinkKey]
    )
    if rootValues.isSymbolicLink == true {
      throw ContractError.symbolicLink(directory.path)
    }
    guard
      let enumerator = fileManager.enumerator(
        at: directory,
        includingPropertiesForKeys: [
          .isRegularFileKey,
          .isSymbolicLinkKey,
        ],
        options: [.skipsHiddenFiles]
      )
    else {
      throw ContractError.invalidDirectory(directory.path)
    }

    var receipts: [TrustVerificationReceipt] = []
    var verificationIDs = Set<String>()
    for case let url as URL in enumerator {
      let values = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      if values.isSymbolicLink == true {
        throw ContractError.symbolicLink(url.path)
      }
      guard values.isRegularFile == true,
        url.pathExtension.lowercased() == "json"
      else {
        continue
      }
      let data = try Data(contentsOf: url)
      let discriminator = try DeterministicJSON.decode(
        VerificationArtifactDiscriminator.self,
        from: data
      )
      guard
        discriminator.kind
          == "web-api-reverse.verification-receipt"
      else {
        continue
      }
      let receipt = try DeterministicJSON.decode(
        TrustVerificationReceipt.self,
        from: data
      )
      guard verificationIDs.insert(receipt.verificationId).inserted else {
        throw ContractError.invalidObservedEvidence(
          "duplicate verification receipt ID \(receipt.verificationId)"
        )
      }
      receipts.append(receipt)
    }
    return receipts.sorted {
      ($0.verificationId, $0.operationId)
        < ($1.verificationId, $1.operationId)
    }
  }
}

private struct VerificationArtifactDiscriminator: Decodable {
  let kind: String?
}
