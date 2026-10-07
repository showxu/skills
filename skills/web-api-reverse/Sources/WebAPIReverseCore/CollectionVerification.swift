import Darwin
import Foundation

@_silgen_name("flock")
private func collectionReceiptFlock(
  _ descriptor: Int32,
  _ operation: Int32
) -> Int32

public enum CollectionMutationAction: String, Codable, Equatable, Sendable {
  case add
  case delete
}

public enum CollectionRemoteState: String, Codable, Equatable, Sendable {
  case absent
  case present
}

public enum CollectionTargetGrain: String, Codable, Equatable, Sendable {
  case product
  case sku
}

public struct CollectionMutationTranscriptData:
  Codable, Equatable, Sendable
{
  public let provider: String
  public let market: String
  public let platformProvider: String
  public let productExternalID: String
  public let targetGrain: CollectionTargetGrain
  public let skuExternalID: String?
  public let action: CollectionMutationAction
  public let verificationCode: String
  public let remoteState: CollectionRemoteState

  public init(
    provider: String,
    market: String,
    platformProvider: String,
    productExternalID: String,
    targetGrain: CollectionTargetGrain,
    skuExternalID: String? = nil,
    action: CollectionMutationAction,
    verificationCode: String,
    remoteState: CollectionRemoteState
  ) {
    self.provider = provider
    self.market = market
    self.platformProvider = platformProvider
    self.productExternalID = productExternalID
    self.targetGrain = targetGrain
    self.skuExternalID = skuExternalID
    self.action = action
    self.verificationCode = verificationCode
    self.remoteState = remoteState
  }
}

public struct CollectionMutationTranscript: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let ok: Bool
  public let command: String
  public let data: CollectionMutationTranscriptData?
  public let error: CommandErrorPayload?

  public init(
    ok: Bool,
    command: String,
    data: CollectionMutationTranscriptData? = nil,
    error: CommandErrorPayload? = nil
  ) {
    self.schemaVersion = 1
    self.ok = ok
    self.command = command
    self.data = data
    self.error = error
  }
}

public struct CollectionRestorationProof: Codable, Equatable, Sendable {
  public let initialState: CollectionRemoteState
  public let addedState: CollectionRemoteState
  public let finalState: CollectionRemoteState
  public let proven: Bool

  public init(
    initialState: CollectionRemoteState,
    addedState: CollectionRemoteState,
    finalState: CollectionRemoteState,
    proven: Bool
  ) {
    self.initialState = initialState
    self.addedState = addedState
    self.finalState = finalState
    self.proven = proven
  }
}

public struct CollectionVerificationReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let verificationId: String
  public let evidenceFingerprint: String
  public let verifiedAt: String
  public let platformProvider: String
  public let platformPublishLockSHA256: String
  public let sourceProductReceiptSHA256: String
  public let sourceProductVerificationId: String
  public let productExternalID: String
  public let targetGrain: CollectionTargetGrain
  public let skuExternalID: String?
  public let addTranscriptSHA256: String
  public let deleteTranscriptSHA256: String
  public let restoration: CollectionRestorationProof

  public init(
    provider: String,
    market: String,
    verificationId: String,
    evidenceFingerprint: String,
    verifiedAt: String,
    platformProvider: String,
    platformPublishLockSHA256: String,
    sourceProductReceiptSHA256: String,
    sourceProductVerificationId: String,
    productExternalID: String,
    targetGrain: CollectionTargetGrain,
    skuExternalID: String? = nil,
    addTranscriptSHA256: String,
    deleteTranscriptSHA256: String,
    restoration: CollectionRestorationProof
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.collection-verification"
    self.provider = provider
    self.market = market
    self.verificationId = verificationId
    self.evidenceFingerprint = evidenceFingerprint
    self.verifiedAt = verifiedAt
    self.platformProvider = platformProvider
    self.platformPublishLockSHA256 = platformPublishLockSHA256
    self.sourceProductReceiptSHA256 = sourceProductReceiptSHA256
    self.sourceProductVerificationId = sourceProductVerificationId
    self.productExternalID = productExternalID
    self.targetGrain = targetGrain
    self.skuExternalID = skuExternalID
    self.addTranscriptSHA256 = addTranscriptSHA256
    self.deleteTranscriptSHA256 = deleteTranscriptSHA256
    self.restoration = restoration
  }
}

public struct CollectionVerificationInput: Sendable {
  public let providerRoot: URL
  public let provider: String
  public let market: String
  public let sourceProductReceiptURL: URL
  public let platformProviderRoot: URL
  public let addTranscriptURL: URL
  public let deleteTranscriptURL: URL
  public let verifiedAt: String

  public init(
    providerRoot: URL,
    provider: String,
    market: String,
    sourceProductReceiptURL: URL,
    platformProviderRoot: URL,
    addTranscriptURL: URL,
    deleteTranscriptURL: URL,
    verifiedAt: String = ISO8601DateFormatter().string(from: Date())
  ) {
    self.providerRoot = providerRoot
    self.provider = provider
    self.market = market
    self.sourceProductReceiptURL = sourceProductReceiptURL
    self.platformProviderRoot = platformProviderRoot
    self.addTranscriptURL = addTranscriptURL
    self.deleteTranscriptURL = deleteTranscriptURL
    self.verifiedAt = verifiedAt
  }
}

public enum CollectionVerificationError:
  Error, Equatable, LocalizedError, Sendable
{
  case allowRemoteWriteRequired
  case invalidPath(String)
  case invalidTranscript(String)
  case identityMismatch(String)
  case invalidSourceReceipt(String)
  case invalidPlatformContract(String)
  case invalidReceipt(String)
  case ambiguousReceipts
  case sensitiveMaterial(String)

  public var errorDescription: String? {
    switch self {
    case .allowRemoteWriteRequired:
      "Collection verification requires explicit --allow-remote-write acknowledgement."
    case .invalidPath(let reason):
      "Invalid collection verification path: \(reason)"
    case .invalidTranscript(let reason):
      "Invalid collection mutation transcript: \(reason)"
    case .identityMismatch(let reason):
      "Collection target identity mismatch: \(reason)"
    case .invalidSourceReceipt(let reason):
      "Invalid source-product receipt for collection verification: \(reason)"
    case .invalidPlatformContract(let reason):
      "Invalid platform Published contract for collection verification: \(reason)"
    case .invalidReceipt(let reason):
      "Invalid collection verification receipt: \(reason)"
    case .ambiguousReceipts:
      "Remote collection authority requires exactly one canonical collection-verification receipt."
    case .sensitiveMaterial(let reason):
      "Collection verification input contains sensitive material: \(reason)"
    }
  }
}

public struct CollectionVerifier {
  private let fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func verify(
    _ input: CollectionVerificationInput,
    allowRemoteWrite: Bool
  ) throws -> CollectionVerificationReceipt {
    guard allowRemoteWrite else {
      throw CollectionVerificationError.allowRemoteWriteRequired
    }
    try CollectionVerificationPaths.requireCanonicalSourceReceipt(
      input.sourceProductReceiptURL,
      providerRoot: input.providerRoot,
      fileManager: fileManager
    )
    try requirePrivateTranscript(input.addTranscriptURL)
    try requirePrivateTranscript(input.deleteTranscriptURL)
    guard ISO8601DateFormatter().date(from: input.verifiedAt) != nil else {
      throw CollectionVerificationError.invalidReceipt(
        "verifiedAt is not ISO-8601"
      )
    }

    let sourceReceiptData = try Data(contentsOf: input.sourceProductReceiptURL)
    let sourceReceipt: SourceProductVerificationReceipt
    do {
      sourceReceipt = try DeterministicJSON.decode(
        SourceProductVerificationReceipt.self,
        from: sourceReceiptData
      )
      try SourceProductVerifier.validate(sourceReceipt)
    } catch {
      throw CollectionVerificationError.invalidSourceReceipt(
        error.localizedDescription
      )
    }
    guard sourceReceipt.provider == input.provider,
      sourceReceipt.market == input.market
    else {
      throw CollectionVerificationError.identityMismatch(
        "source receipt \(sourceReceipt.provider)/\(sourceReceipt.market), expected "
          + "\(input.provider)/\(input.market)"
      )
    }

    let lockURL = input.platformProviderRoot.appending(
      path: "API/Published/publish-lock.json"
    )
    do {
      try CollectionVerificationPaths.requireRegularNonSymbolicFile(
        lockURL,
        fileManager: fileManager
      )
      _ = try ContractValidator().validate(
        providerRoot: input.platformProviderRoot
      )
    } catch {
      throw CollectionVerificationError.invalidPlatformContract(
        error.localizedDescription
      )
    }
    let lockData = try Data(contentsOf: lockURL)
    let lock = try DeterministicJSON.decode(PublishLock.self, from: lockData)
    let platformLockSHA256 = try canonicalJSONSHA256(
      lockData,
      invalid: CollectionVerificationError.invalidPlatformContract
    )
    guard lock.provider == sourceReceipt.platformProvider,
      lock.market == sourceReceipt.market,
      sourceReceipt.platformPublishLockSHA256 == platformLockSHA256
    else {
      throw CollectionVerificationError.invalidPlatformContract(
        "current platform publish lock does not match the source-product receipt"
      )
    }

    let addData = try Data(contentsOf: input.addTranscriptURL)
    let deleteData = try Data(contentsOf: input.deleteTranscriptURL)
    let add = try decodeTranscript(
      addData,
      expectedProvider: input.provider,
      expectedAction: .add
    )
    let delete = try decodeTranscript(
      deleteData,
      expectedProvider: input.provider,
      expectedAction: .delete
    )
    guard let addResult = add.data, let deleteResult = delete.data else {
      throw CollectionVerificationError.invalidTranscript(
        "successful transcript data is missing"
      )
    }
    let expectedIdentity = (
      input.provider,
      input.market,
      sourceReceipt.platformProvider,
      sourceReceipt.productExternalID
    )
    for result in [addResult, deleteResult] {
      guard
        (
          result.provider,
          result.market,
          result.platformProvider,
          result.productExternalID
        ) == expectedIdentity
      else {
        throw CollectionVerificationError.identityMismatch(
          "brand, market, platform, or product differs from the source-product receipt"
        )
      }
    }
    guard addResult.targetGrain == deleteResult.targetGrain,
      addResult.skuExternalID == deleteResult.skuExternalID
    else {
      throw CollectionVerificationError.identityMismatch(
        "add and delete use a different target or grain"
      )
    }
    switch addResult.targetGrain {
    case .product:
      guard addResult.skuExternalID == nil else {
        throw CollectionVerificationError.identityMismatch(
          "product-grain collection target must not carry a SKU"
        )
      }
    case .sku:
      guard sourceReceipt.schemaVersion >= 2,
        let sourceSKUExternalIDs = sourceReceipt.skuExternalIDs,
        let skuExternalID = addResult.skuExternalID,
        !skuExternalID.trimmingCharacters(
          in: .whitespacesAndNewlines
        ).isEmpty,
        sourceSKUExternalIDs.contains(skuExternalID)
      else {
        throw CollectionVerificationError.invalidSourceReceipt(
          "SKU-grain collection qualification requires a v2+ source-product receipt that binds the exact SKU"
        )
      }
    }
    guard addResult.verificationCode == "platform-confirmed-change",
      addResult.remoteState == .present
    else {
      throw CollectionVerificationError.invalidTranscript(
        "add must report platform-confirmed-change and present state"
      )
    }
    guard deleteResult.verificationCode == "platform-confirmed-change",
      deleteResult.remoteState == .absent
    else {
      throw CollectionVerificationError.invalidTranscript(
        "delete must report platform-confirmed-change and restored absent state"
      )
    }

    let sourceReceiptSHA256 = FileDigest.sha256(data: sourceReceiptData)
    let addSHA256 = FileDigest.sha256(
      data: try DeterministicJSON.encode(add)
    )
    let deleteSHA256 = FileDigest.sha256(
      data: try DeterministicJSON.encode(delete)
    )
    let restoration = CollectionRestorationProof(
      initialState: .absent,
      addedState: .present,
      finalState: .absent,
      proven: true
    )
    let fingerprint = try Self.fingerprint(
      provider: input.provider,
      market: input.market,
      verifiedAt: input.verifiedAt,
      platformProvider: sourceReceipt.platformProvider,
      platformPublishLockSHA256: platformLockSHA256,
      sourceProductReceiptSHA256: sourceReceiptSHA256,
      sourceProductVerificationId: sourceReceipt.verificationId,
      productExternalID: sourceReceipt.productExternalID,
      targetGrain: addResult.targetGrain,
      skuExternalID: addResult.skuExternalID,
      addTranscriptSHA256: addSHA256,
      deleteTranscriptSHA256: deleteSHA256,
      restoration: restoration
    )
    let receipt = CollectionVerificationReceipt(
      provider: input.provider,
      market: input.market,
      verificationId: "cv_\(fingerprint.prefix(16))",
      evidenceFingerprint: fingerprint,
      verifiedAt: input.verifiedAt,
      platformProvider: sourceReceipt.platformProvider,
      platformPublishLockSHA256: platformLockSHA256,
      sourceProductReceiptSHA256: sourceReceiptSHA256,
      sourceProductVerificationId: sourceReceipt.verificationId,
      productExternalID: sourceReceipt.productExternalID,
      targetGrain: addResult.targetGrain,
      skuExternalID: addResult.skuExternalID,
      addTranscriptSHA256: addSHA256,
      deleteTranscriptSHA256: deleteSHA256,
      restoration: restoration
    )
    try Self.validate(receipt)
    return receipt
  }

  public static func validate(
    _ receipt: CollectionVerificationReceipt
  ) throws {
    guard receipt.schemaVersion == 1,
      receipt.kind == "web-api-reverse.collection-verification"
    else {
      throw CollectionVerificationError.invalidReceipt(
        "unsupported schema or kind"
      )
    }
    for (name, value) in [
      ("provider", receipt.provider),
      ("market", receipt.market),
      ("platformProvider", receipt.platformProvider),
      ("sourceProductVerificationId", receipt.sourceProductVerificationId),
      ("productExternalID", receipt.productExternalID),
    ] where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw CollectionVerificationError.invalidReceipt("\(name) is blank")
    }
    switch receipt.targetGrain {
    case .product:
      guard receipt.skuExternalID == nil else {
        throw CollectionVerificationError.invalidReceipt(
          "product-grain receipt must not carry a SKU"
        )
      }
    case .sku:
      guard let skuExternalID = receipt.skuExternalID,
        !skuExternalID.trimmingCharacters(
          in: .whitespacesAndNewlines
        ).isEmpty
      else {
        throw CollectionVerificationError.invalidReceipt(
          "SKU-grain receipt requires a nonempty SKU"
        )
      }
    }
    for (name, hash) in [
      ("evidenceFingerprint", receipt.evidenceFingerprint),
      ("platformPublishLockSHA256", receipt.platformPublishLockSHA256),
      ("sourceProductReceiptSHA256", receipt.sourceProductReceiptSHA256),
      ("addTranscriptSHA256", receipt.addTranscriptSHA256),
      ("deleteTranscriptSHA256", receipt.deleteTranscriptSHA256),
    ] where !isSHA256(hash) {
      throw CollectionVerificationError.invalidReceipt(
        "\(name) is not SHA-256"
      )
    }
    guard ISO8601DateFormatter().date(from: receipt.verifiedAt) != nil else {
      throw CollectionVerificationError.invalidReceipt(
        "verifiedAt is not ISO-8601"
      )
    }
    guard
      receipt.restoration
        == CollectionRestorationProof(
          initialState: .absent,
          addedState: .present,
          finalState: .absent,
          proven: true
        )
    else {
      throw CollectionVerificationError.invalidReceipt(
        "restoration proof must establish absent -> present -> absent"
      )
    }
    let expected = try fingerprint(
      provider: receipt.provider,
      market: receipt.market,
      verifiedAt: receipt.verifiedAt,
      platformProvider: receipt.platformProvider,
      platformPublishLockSHA256: receipt.platformPublishLockSHA256,
      sourceProductReceiptSHA256: receipt.sourceProductReceiptSHA256,
      sourceProductVerificationId: receipt.sourceProductVerificationId,
      productExternalID: receipt.productExternalID,
      targetGrain: receipt.targetGrain,
      skuExternalID: receipt.skuExternalID,
      addTranscriptSHA256: receipt.addTranscriptSHA256,
      deleteTranscriptSHA256: receipt.deleteTranscriptSHA256,
      restoration: receipt.restoration
    )
    guard receipt.evidenceFingerprint == expected,
      receipt.verificationId == "cv_\(expected.prefix(16))"
    else {
      throw CollectionVerificationError.invalidReceipt(
        "identifier does not match the bound evidence"
      )
    }
  }

  private func requirePrivateTranscript(_ url: URL) throws {
    try EvidencePathGuard.requirePrivateStateOutsideAPI(url)
    try CollectionVerificationPaths.requireRegularNonSymbolicFile(
      url,
      fileManager: fileManager
    )
    let findings = try ArtifactScanner().scanFile(url)
    if let finding = findings.first {
      throw CollectionVerificationError.sensitiveMaterial(finding.reason)
    }
  }

  private func decodeTranscript(
    _ data: Data,
    expectedProvider: String,
    expectedAction: CollectionMutationAction
  ) throws -> CollectionMutationTranscript {
    let transcript: CollectionMutationTranscript
    do {
      let value = try DeterministicJSON.decode(JSONValue.self, from: data)
      try validateTranscriptShape(value)
      transcript = try DeterministicJSON.decode(
        CollectionMutationTranscript.self,
        from: data
      )
    } catch let error as CollectionVerificationError {
      throw error
    } catch {
      throw CollectionVerificationError.invalidTranscript(
        error.localizedDescription
      )
    }
    guard transcript.schemaVersion == 1,
      transcript.ok,
      transcript.error == nil,
      let result = transcript.data,
      result.action == expectedAction,
      transcript.command
        == "\(expectedProvider).wishlist.\(expectedAction.rawValue)"
    else {
      throw CollectionVerificationError.invalidTranscript(
        "expected a successful \(expectedAction.rawValue) command envelope in the exact provider wishlist namespace"
      )
    }
    return transcript
  }

  private func validateTranscriptShape(_ value: JSONValue) throws {
    guard case .object(let root) = value,
      Set(root.keys).isSubset(of: [
        "schemaVersion", "ok", "command", "data", "error",
      ]),
      case .object(let data)? = root["data"],
      Set([
        "provider",
        "market",
        "platformProvider",
        "productExternalID",
        "targetGrain",
        "action",
        "verificationCode",
        "remoteState",
      ]).isSubset(of: Set(data.keys)),
      Set(data.keys).isSubset(
        of: Set([
          "provider",
          "market",
          "platformProvider",
          "productExternalID",
          "targetGrain",
          "skuExternalID",
          "action",
          "verificationCode",
          "remoteState",
        ])),
      let targetGrain = data["targetGrain"]?.stringValue,
      targetGrain == CollectionTargetGrain.product.rawValue
        && data["skuExternalID"] == nil
        || targetGrain == CollectionTargetGrain.sku.rawValue
          && data["skuExternalID"]?.stringValue != nil
    else {
      throw CollectionVerificationError.invalidTranscript(
        "unexpected or missing command-envelope fields"
      )
    }
  }

  private struct FingerprintInput: Codable {
    let schemaVersion: Int
    let provider: String
    let market: String
    let verifiedAt: String
    let platformProvider: String
    let platformPublishLockSHA256: String
    let sourceProductReceiptSHA256: String
    let sourceProductVerificationId: String
    let productExternalID: String
    let targetGrain: CollectionTargetGrain
    let skuExternalID: String?
    let addTranscriptSHA256: String
    let deleteTranscriptSHA256: String
    let restoration: CollectionRestorationProof
  }

  private static func fingerprint(
    provider: String,
    market: String,
    verifiedAt: String,
    platformProvider: String,
    platformPublishLockSHA256: String,
    sourceProductReceiptSHA256: String,
    sourceProductVerificationId: String,
    productExternalID: String,
    targetGrain: CollectionTargetGrain,
    skuExternalID: String?,
    addTranscriptSHA256: String,
    deleteTranscriptSHA256: String,
    restoration: CollectionRestorationProof
  ) throws -> String {
    FileDigest.sha256(
      data: try DeterministicJSON.encode(
        FingerprintInput(
          schemaVersion: 1,
          provider: provider,
          market: market,
          verifiedAt: verifiedAt,
          platformProvider: platformProvider,
          platformPublishLockSHA256: platformPublishLockSHA256,
          sourceProductReceiptSHA256: sourceProductReceiptSHA256,
          sourceProductVerificationId: sourceProductVerificationId,
          productExternalID: productExternalID,
          targetGrain: targetGrain,
          skuExternalID: skuExternalID,
          addTranscriptSHA256: addTranscriptSHA256,
          deleteTranscriptSHA256: deleteTranscriptSHA256,
          restoration: restoration
        )
      )
    )
  }
}

public struct CollectionVerificationReceiptArtifact: Sendable {
  public let url: URL
  public let receipt: CollectionVerificationReceipt
}

public enum CollectionVerificationReceiptLoader {
  public static func loadArtifacts(
    from directory: URL,
    fileManager: FileManager = .default
  ) throws -> [CollectionVerificationReceiptArtifact] {
    guard fileManager.fileExists(atPath: directory.path) else { return [] }
    var isDirectory: ObjCBool = false
    guard
      fileManager.fileExists(
        atPath: directory.path,
        isDirectory: &isDirectory
      ), isDirectory.boolValue
    else {
      throw ContractError.invalidDirectory(directory.path)
    }
    if try directory.resourceValues(
      forKeys: [.isSymbolicLinkKey]
    ).isSymbolicLink == true {
      throw ContractError.symbolicLink(directory.path)
    }
    let entries = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [
        .isRegularFileKey,
        .isSymbolicLinkKey,
      ],
      options: [.skipsHiddenFiles]
    ).sorted { $0.path < $1.path }
    return try entries.map { url in
      let values = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      if values.isSymbolicLink == true {
        throw ContractError.symbolicLink(url.path)
      }
      guard values.isRegularFile == true,
        url.pathExtension.lowercased() == "json"
      else {
        throw CollectionVerificationError.invalidPath(
          "collection-verifications may contain only direct JSON receipt files"
        )
      }
      let receipt = try DeterministicJSON.decode(
        CollectionVerificationReceipt.self,
        from: Data(contentsOf: url)
      )
      try CollectionVerifier.validate(receipt)
      return CollectionVerificationReceiptArtifact(
        url: url,
        receipt: receipt
      )
    }
  }
}

public struct CollectionVerificationReceiptWriter {
  private let fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func write(
    _ receipt: CollectionVerificationReceipt,
    to output: URL,
    providerRoot: URL
  ) throws {
    try CollectionVerifier.validate(receipt)
    try CollectionVerificationPaths.requireCanonicalCollectionReceipt(
      output,
      providerRoot: providerRoot,
      mayNotExist: true,
      fileManager: fileManager
    )
    let encoded = try DeterministicJSON.encode(receipt)
    if let finding = ArtifactScanner().scan(
      data: encoded,
      path: output.path
    ).first {
      throw CollectionVerificationError.sensitiveMaterial(finding.reason)
    }
    try fileManager.createDirectory(
      at: output.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try AtomicCollectionReceiptFile.write(
      encoded,
      to: output,
      providerRoot: providerRoot
    )
  }
}

private enum AtomicCollectionReceiptFile {
  static func write(
    _ data: Data,
    to output: URL,
    providerRoot: URL
  ) throws {
    let canonicalProviderRoot = try canonicalDirectory(providerRoot)
    let parent = canonicalProviderRoot.appending(
      path: CollectionVerificationPaths.collectionReceiptPrefix,
      directoryHint: .isDirectory
    )
    let fileName = output.lastPathComponent
    guard
      !fileName.isEmpty,
      fileName != ".",
      fileName != "..",
      !fileName.contains("/")
    else {
      throw CollectionVerificationError.invalidPath(output.path)
    }
    let parentDescriptor = try openDirectoryWithoutSymbolicLinks(parent)
    defer { _ = Darwin.close(parentDescriptor) }
    guard collectionReceiptFlock(parentDescriptor, LOCK_EX) == 0 else {
      throw CollectionVerificationError.invalidPath(
        "could not lock receipt directory"
      )
    }
    defer { _ = collectionReceiptFlock(parentDescriptor, LOCK_UN) }

    var existing = stat()
    let existingStatus = fileName.withCString {
      Darwin.fstatat(
        parentDescriptor,
        $0,
        &existing,
        AT_SYMLINK_NOFOLLOW
      )
    }
    if existingStatus == 0 {
      guard
        existing.st_mode & S_IFMT == S_IFREG,
        existing.st_uid == geteuid()
      else {
        throw ContractError.symbolicLink(output.path)
      }
    } else if errno != ENOENT {
      throw CollectionVerificationError.invalidPath(output.path)
    }

    let temporaryName =
      ".collection-receipt-\(getpid())-"
      + UUID().uuidString.lowercased()
    let temporaryDescriptor = temporaryName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
        mode_t(S_IRUSR | S_IWUSR)
      )
    }
    guard temporaryDescriptor >= 0 else {
      throw CollectionVerificationError.invalidPath(output.path)
    }
    var temporaryMetadata = stat()
    var removeTemporary = true
    defer {
      _ = Darwin.close(temporaryDescriptor)
      if removeTemporary {
        _ = temporaryName.withCString {
          Darwin.unlinkat(parentDescriptor, $0, 0)
        }
      }
    }
    guard fstat(temporaryDescriptor, &temporaryMetadata) == 0 else {
      throw CollectionVerificationError.invalidPath(output.path)
    }
    try writeAll(
      data,
      to: temporaryDescriptor,
      outputPath: output.path
    )
    guard Darwin.fsync(temporaryDescriptor) == 0 else {
      throw CollectionVerificationError.invalidPath(output.path)
    }

    if existingStatus == 0 {
      guard temporaryName.withCString({ temporaryPointer in
        fileName.withCString { filePointer in
          Darwin.renameatx_np(
            parentDescriptor,
            temporaryPointer,
            parentDescriptor,
            filePointer,
            UInt32(RENAME_SWAP)
          )
        }
      }) == 0 else {
        throw CollectionVerificationError.invalidPath(output.path)
      }
      do {
        var installed = stat()
        var displaced = stat()
        guard
          fileName.withCString({
            Darwin.fstatat(
              parentDescriptor,
              $0,
              &installed,
              AT_SYMLINK_NOFOLLOW
            )
          }) == 0,
          temporaryName.withCString({
            Darwin.fstatat(
              parentDescriptor,
              $0,
              &displaced,
              AT_SYMLINK_NOFOLLOW
            )
          }) == 0,
          sameIdentity(installed, temporaryMetadata),
          sameIdentity(displaced, existing),
          Darwin.fsync(parentDescriptor) == 0
        else {
          throw CollectionVerificationError.invalidPath(output.path)
        }
      } catch {
        _ = temporaryName.withCString { temporaryPointer in
          fileName.withCString { filePointer in
            Darwin.renameatx_np(
              parentDescriptor,
              temporaryPointer,
              parentDescriptor,
              filePointer,
              UInt32(RENAME_SWAP)
            )
          }
        }
        _ = Darwin.fsync(parentDescriptor)
        throw error
      }
      guard temporaryName.withCString({
        Darwin.unlinkat(parentDescriptor, $0, 0)
      }) == 0 else {
        throw CollectionVerificationError.invalidPath(output.path)
      }
    } else {
      guard temporaryName.withCString({ temporaryPointer in
        fileName.withCString { filePointer in
          Darwin.renameatx_np(
            parentDescriptor,
            temporaryPointer,
            parentDescriptor,
            filePointer,
            UInt32(RENAME_EXCL)
          )
        }
      }) == 0 else {
        throw CollectionVerificationError.invalidPath(output.path)
      }
      do {
        var installed = stat()
        guard
          fileName.withCString({
            Darwin.fstatat(
              parentDescriptor,
              $0,
              &installed,
              AT_SYMLINK_NOFOLLOW
            )
          }) == 0,
          sameIdentity(installed, temporaryMetadata),
          Darwin.fsync(parentDescriptor) == 0
        else {
          throw CollectionVerificationError.invalidPath(output.path)
        }
      } catch {
        _ = fileName.withCString {
          Darwin.unlinkat(parentDescriptor, $0, 0)
        }
        _ = Darwin.fsync(parentDescriptor)
        throw error
      }
    }
    removeTemporary = false
  }

  private static func writeAll(
    _ data: Data,
    to descriptor: Int32,
    outputPath: String
  ) throws {
    try data.withUnsafeBytes { bytes in
      guard let base = bytes.baseAddress else { return }
      var offset = 0
      while offset < bytes.count {
        let count = Darwin.write(
          descriptor,
          base.advanced(by: offset),
          bytes.count - offset
        )
        if count < 0, errno == EINTR { continue }
        guard count > 0 else {
          throw CollectionVerificationError.invalidPath(outputPath)
        }
        offset += count
      }
    }
  }

  private static func openDirectoryWithoutSymbolicLinks(
    _ directory: URL
  ) throws -> Int32 {
    let components = directory.pathComponents
      .filter { $0 != "/" }
    var descriptor = Darwin.open(
      "/",
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard descriptor >= 0 else {
      throw CollectionVerificationError.invalidPath(directory.path)
    }
    var current = URL(fileURLWithPath: "/", isDirectory: true)
    for component in components {
      current.append(path: component, directoryHint: .isDirectory)
      let next = component.withCString {
        Darwin.openat(
          descriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
      }
      if next < 0 {
        var metadata = stat()
        let isSymbolicLink = component.withCString {
          Darwin.fstatat(
            descriptor,
            $0,
            &metadata,
            AT_SYMLINK_NOFOLLOW
          ) == 0 && metadata.st_mode & S_IFMT == S_IFLNK
        }
        _ = Darwin.close(descriptor)
        if isSymbolicLink {
          throw ContractError.symbolicLink(current.path)
        }
        throw CollectionVerificationError.invalidPath(directory.path)
      }
      _ = Darwin.close(descriptor)
      descriptor = next
    }
    return descriptor
  }

  private static func canonicalDirectory(_ directory: URL) throws -> URL {
    let pointer = directory.withUnsafeFileSystemRepresentation { path in
      guard let path else { return UnsafeMutablePointer<CChar>?.none }
      return Darwin.realpath(path, nil)
    }
    guard let pointer else {
      throw CollectionVerificationError.invalidPath(directory.path)
    }
    defer { Darwin.free(pointer) }
    return URL(
      fileURLWithPath: String(cString: pointer),
      isDirectory: true
    )
  }

  private static func sameIdentity(_ lhs: stat, _ rhs: stat) -> Bool {
    lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
  }
}

enum CollectionVerificationPaths {
  static let sourceReceiptPrefix = "API/Observed/source-verifications"
  static let collectionReceiptPrefix =
    "API/Observed/collection-verifications"

  static func requireCanonicalSourceReceipt(
    _ url: URL,
    providerRoot: URL,
    fileManager: FileManager
  ) throws {
    try requireCanonicalReceipt(
      url,
      providerRoot: providerRoot,
      directory: sourceReceiptPrefix,
      mayNotExist: false,
      fileManager: fileManager
    )
  }

  static func requireCanonicalCollectionReceipt(
    _ url: URL,
    providerRoot: URL,
    mayNotExist: Bool,
    fileManager: FileManager
  ) throws {
    try requireCanonicalReceipt(
      url,
      providerRoot: providerRoot,
      directory: collectionReceiptPrefix,
      mayNotExist: mayNotExist,
      fileManager: fileManager
    )
  }

  static func requireRegularNonSymbolicFile(
    _ url: URL,
    fileManager: FileManager
  ) throws {
    let values = try url.resourceValues(
      forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
    if values.isSymbolicLink == true {
      throw ContractError.symbolicLink(url.path)
    }
    guard values.isRegularFile == true else {
      throw CollectionVerificationError.invalidPath(
        "expected a regular file at \(url.path)"
      )
    }
  }

  private static func requireCanonicalReceipt(
    _ url: URL,
    providerRoot: URL,
    directory: String,
    mayNotExist: Bool,
    fileManager: FileManager
  ) throws {
    let expectedDirectory = providerRoot.appending(
      path: directory,
      directoryHint: .isDirectory
    ).standardizedFileURL
    let candidate = url.standardizedFileURL
    guard candidate.deletingLastPathComponent() == expectedDirectory,
      candidate.pathExtension.lowercased() == "json",
      !candidate.deletingPathExtension().lastPathComponent.isEmpty
    else {
      throw CollectionVerificationError.invalidPath(
        "receipt must be one JSON file directly under \(directory)"
      )
    }
    try rejectSymbolicComponents(
      from: providerRoot,
      through: mayNotExist ? expectedDirectory : candidate,
      fileManager: fileManager
    )
    if fileManager.fileExists(atPath: candidate.path) {
      try requireRegularNonSymbolicFile(
        candidate,
        fileManager: fileManager
      )
    } else if !mayNotExist {
      throw CollectionVerificationError.invalidPath(
        "missing receipt at \(candidate.path)"
      )
    }
  }

  private static func rejectSymbolicComponents(
    from root: URL,
    through target: URL,
    fileManager: FileManager
  ) throws {
    let root = root.standardizedFileURL
    let target = target.standardizedFileURL
    guard target.pathComponents.starts(with: root.pathComponents) else {
      throw CollectionVerificationError.invalidPath(
        "path is outside the provider root"
      )
    }
    var current = root
    for component in target.pathComponents.dropFirst(root.pathComponents.count) {
      current.append(path: component)
      guard fileManager.fileExists(atPath: current.path) else { continue }
      if try current.resourceValues(
        forKeys: [.isSymbolicLinkKey]
      ).isSymbolicLink == true {
        throw ContractError.symbolicLink(current.path)
      }
    }
  }
}

private func canonicalJSONSHA256(
  _ data: Data,
  invalid: (String) -> CollectionVerificationError
) throws -> String {
  let object: Any
  do {
    object = try JSONSerialization.jsonObject(with: data)
  } catch {
    throw invalid(error.localizedDescription)
  }
  guard JSONSerialization.isValidJSONObject(object) else {
    throw invalid("root is not a JSON object")
  }
  return FileDigest.sha256(
    data: try JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  )
}

private func isSHA256(_ value: String) -> Bool {
  value.range(
    of: #"^[a-f0-9]{64}$"#,
    options: .regularExpression
  ) != nil
}
