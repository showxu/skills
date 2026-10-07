import Foundation

struct CollectionReceiptAuthority: Sendable {
  let relativePath: String
  let sha256: String
  let sourceReceiptRelativePath: String
  let sourceReceiptSHA256: String
  let receipt: CollectionVerificationReceipt
}

enum PlatformCollectionEvidenceAuthority {
  static let capabilityID = "remote-collection"
  static let receiptPathPrefix =
    "API/Observed/collection-verifications/"

  static func collectCurrentAuthority(
    providerRoot: URL,
    provider: String,
    market: String,
    approvedSourceReceiptHashes: [String: String],
    fileManager: FileManager = .default
  ) throws -> CollectionReceiptAuthority? {
    let directory = providerRoot.appending(
      path: String(receiptPathPrefix.dropLast()),
      directoryHint: .isDirectory
    )
    let artifacts = try CollectionVerificationReceiptLoader.loadArtifacts(
      from: directory,
      fileManager: fileManager
    )
    guard !artifacts.isEmpty else { return nil }
    guard artifacts.count == 1, let artifact = artifacts.first else {
      throw CollectionVerificationError.ambiguousReceipts
    }
    let receipt = artifact.receipt
    guard receipt.provider == provider, receipt.market == market else {
      throw CollectionVerificationError.identityMismatch(
        "receipt \(receipt.provider)/\(receipt.market), expected \(provider)/\(market)"
      )
    }

    let sourceDirectory = providerRoot.appending(
      path: CollectionVerificationPaths.sourceReceiptPrefix,
      directoryHint: .isDirectory
    )
    let sourceArtifacts = try SourceProductVerificationReceiptLoader.loadArtifacts(
      from: sourceDirectory,
      fileManager: fileManager
    )
    let matchingSourceArtifacts = try sourceArtifacts.filter {
      try FileDigest.sha256(fileAt: $0.url)
        == receipt.sourceProductReceiptSHA256
    }
    guard matchingSourceArtifacts.count == 1,
      let sourceArtifact = matchingSourceArtifacts.first
    else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "receipt hash does not resolve to exactly one current source-product receipt"
      )
    }
    let sourceReceipt = sourceArtifact.receipt
    do {
      try SourceProductVerifier.validate(sourceReceipt)
    } catch {
      throw CollectionVerificationError.invalidSourceReceipt(
        error.localizedDescription
      )
    }
    guard sourceReceipt.provider == provider,
      sourceReceipt.market == market,
      sourceReceipt.platformProvider == receipt.platformProvider,
      sourceReceipt.platformPublishLockSHA256
        == receipt.platformPublishLockSHA256,
      sourceReceipt.verificationId == receipt.sourceProductVerificationId,
      sourceReceipt.productExternalID == receipt.productExternalID
    else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "current source-product receipt does not match the collection target or platform lock"
      )
    }
    switch receipt.targetGrain {
    case .product:
      guard receipt.skuExternalID == nil else {
        throw CollectionVerificationError.invalidSourceReceipt(
          "product-grain collection receipt must not carry a SKU"
        )
      }
    case .sku:
      guard sourceReceipt.schemaVersion >= 2,
        let sourceSKUExternalIDs = sourceReceipt.skuExternalIDs,
        let skuExternalID = receipt.skuExternalID,
        sourceSKUExternalIDs.contains(skuExternalID)
      else {
        throw CollectionVerificationError.invalidSourceReceipt(
          "SKU-grain collection authority requires the exact SKU in a current v2+ source-product receipt"
        )
      }
    }

    let sourceRelativePath =
      PlatformSourceEvidenceAuthority.receiptPathPrefix
      + sourceArtifact.url.lastPathComponent
    let sourceSHA256 = try FileDigest.sha256(fileAt: sourceArtifact.url)
    guard approvedSourceReceiptHashes[sourceRelativePath] == sourceSHA256 else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "the matching source-product receipt is not a current approval input"
      )
    }
    let relativePath = receiptPathPrefix + artifact.url.lastPathComponent
    return CollectionReceiptAuthority(
      relativePath: relativePath,
      sha256: try FileDigest.sha256(fileAt: artifact.url),
      sourceReceiptRelativePath: sourceRelativePath,
      sourceReceiptSHA256: sourceSHA256,
      receipt: receipt
    )
  }

  static func collectCurrentAuthority(
    snapshot: ProviderAPIAuthoritySnapshot,
    provider: String,
    market: String,
    approvedSourceReceiptHashes: [String: String]
  ) throws -> CollectionReceiptAuthority? {
    let collectionArtifacts = try snapshot.directFiles(
      in: String(receiptPathPrefix.dropLast())
    ).map { artifact -> (String, Data, CollectionVerificationReceipt) in
      guard artifact.path.hasSuffix(".json") else {
        throw CollectionVerificationError.invalidPath(
          "collection-verifications may contain only direct JSON receipt files"
        )
      }
      let receipt = try DeterministicJSON.decode(
        CollectionVerificationReceipt.self,
        from: artifact.data
      )
      try CollectionVerifier.validate(receipt)
      return (
        String(artifact.path.split(separator: "/").last ?? ""),
        artifact.data,
        receipt
      )
    }
    guard !collectionArtifacts.isEmpty else { return nil }
    guard collectionArtifacts.count == 1,
      let collectionArtifact = collectionArtifacts.first
    else {
      throw CollectionVerificationError.ambiguousReceipts
    }
    let receipt = collectionArtifact.2
    guard receipt.provider == provider, receipt.market == market else {
      throw CollectionVerificationError.identityMismatch(
        "receipt \(receipt.provider)/\(receipt.market), expected \(provider)/\(market)"
      )
    }

    let sourceArtifacts = try snapshot.directFiles(
      in: String(
        PlatformSourceEvidenceAuthority.receiptPathPrefix.dropLast()
      )
    ).compactMap { artifact
      -> (String, Data, SourceProductVerificationReceipt)? in
      guard artifact.path.hasSuffix(".json") else { return nil }
      return (
        String(artifact.path.split(separator: "/").last ?? ""),
        artifact.data,
        try DeterministicJSON.decode(
          SourceProductVerificationReceipt.self,
          from: artifact.data
        )
      )
    }
    let matchingSourceArtifacts = sourceArtifacts.filter {
      FileDigest.sha256(data: $0.1) == receipt.sourceProductReceiptSHA256
    }
    guard matchingSourceArtifacts.count == 1,
      let sourceArtifact = matchingSourceArtifacts.first
    else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "receipt hash does not resolve to exactly one current source-product receipt"
      )
    }
    let sourceReceipt = sourceArtifact.2
    do {
      try SourceProductVerifier.validate(sourceReceipt)
    } catch {
      throw CollectionVerificationError.invalidSourceReceipt(
        error.localizedDescription
      )
    }
    guard sourceReceipt.provider == provider,
      sourceReceipt.market == market,
      sourceReceipt.platformProvider == receipt.platformProvider,
      sourceReceipt.platformPublishLockSHA256
        == receipt.platformPublishLockSHA256,
      sourceReceipt.verificationId == receipt.sourceProductVerificationId,
      sourceReceipt.productExternalID == receipt.productExternalID
    else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "current source-product receipt does not match the collection target or platform lock"
      )
    }
    switch receipt.targetGrain {
    case .product:
      guard receipt.skuExternalID == nil else {
        throw CollectionVerificationError.invalidSourceReceipt(
          "product-grain collection receipt must not carry a SKU"
        )
      }
    case .sku:
      guard sourceReceipt.schemaVersion >= 2,
        let sourceSKUExternalIDs = sourceReceipt.skuExternalIDs,
        let skuExternalID = receipt.skuExternalID,
        sourceSKUExternalIDs.contains(skuExternalID)
      else {
        throw CollectionVerificationError.invalidSourceReceipt(
          "SKU-grain collection authority requires the exact SKU in a current v2+ source-product receipt"
        )
      }
    }

    let sourceRelativePath =
      PlatformSourceEvidenceAuthority.receiptPathPrefix + sourceArtifact.0
    let sourceSHA256 = FileDigest.sha256(data: sourceArtifact.1)
    guard approvedSourceReceiptHashes[sourceRelativePath] == sourceSHA256 else {
      throw CollectionVerificationError.invalidSourceReceipt(
        "the matching source-product receipt is not a current approval input"
      )
    }
    return CollectionReceiptAuthority(
      relativePath: receiptPathPrefix + collectionArtifact.0,
      sha256: FileDigest.sha256(data: collectionArtifact.1),
      sourceReceiptRelativePath: sourceRelativePath,
      sourceReceiptSHA256: sourceSHA256,
      receipt: receipt
    )
  }

  static func validateApprovalReceiptHashes(
    providerRoot: URL,
    provider: String,
    market: String,
    capabilityClaim: CapabilityClaim,
    approval: ApprovalReceipt,
    fileManager: FileManager = .default
  ) throws {
    let remoteClaims = capabilityClaim.capabilities.filter {
      $0.id == capabilityID && $0.availability == .supported
    }
    guard remoteClaims.count <= 1 else {
      throw ContractError.invalidApproval(
        "remote-collection capability is duplicated"
      )
    }
    let zeroOperationClaim = remoteClaims.first?.operationIds.isEmpty == true
    let approvedCollectionHashes = approval.inputHashes.filter {
      $0.key.hasPrefix(receiptPathPrefix)
    }
    guard zeroOperationClaim else {
      guard approvedCollectionHashes.isEmpty else {
        throw ContractError.invalidApproval(
          "collection-verification inputs require a supported zero-operation remote-collection capability"
        )
      }
      return
    }
    let approvedSourceHashes = approval.inputHashes.filter {
      $0.key.hasPrefix(
        PlatformSourceEvidenceAuthority.receiptPathPrefix
      )
    }
    guard
      let authority = try collectCurrentAuthority(
        providerRoot: providerRoot,
        provider: provider,
        market: market,
        approvedSourceReceiptHashes: approvedSourceHashes,
        fileManager: fileManager
      )
    else {
      throw ContractError.invalidApproval(
        "supported zero-operation remote-collection requires one current collection-verification receipt"
      )
    }
    guard
      approvedCollectionHashes == [
        authority.relativePath: authority.sha256
      ]
    else {
      throw ContractError.invalidApproval(
        "inputHashes does not contain the exact current collection-verification receipt"
      )
    }
  }

  static func validateApprovalReceiptHashes(
    snapshot: ProviderAPIAuthoritySnapshot,
    provider: String,
    market: String,
    capabilityClaim: CapabilityClaim,
    approval: ApprovalReceipt
  ) throws {
    let remoteClaims = capabilityClaim.capabilities.filter {
      $0.id == capabilityID && $0.availability == .supported
    }
    guard remoteClaims.count <= 1 else {
      throw ContractError.invalidApproval(
        "remote-collection capability is duplicated"
      )
    }
    let zeroOperationClaim = remoteClaims.first?.operationIds.isEmpty == true
    let approvedCollectionHashes = approval.inputHashes.filter {
      $0.key.hasPrefix(receiptPathPrefix)
    }
    guard zeroOperationClaim else {
      guard approvedCollectionHashes.isEmpty else {
        throw ContractError.invalidApproval(
          "collection-verification inputs require a supported zero-operation remote-collection capability"
        )
      }
      return
    }
    let approvedSourceHashes = approval.inputHashes.filter {
      $0.key.hasPrefix(
        PlatformSourceEvidenceAuthority.receiptPathPrefix
      )
    }
    guard
      let authority = try collectCurrentAuthority(
        snapshot: snapshot,
        provider: provider,
        market: market,
        approvedSourceReceiptHashes: approvedSourceHashes
      )
    else {
      throw ContractError.invalidApproval(
        "supported zero-operation remote-collection requires one current collection-verification receipt"
      )
    }
    guard
      approvedCollectionHashes == [
        authority.relativePath: authority.sha256
      ]
    else {
      throw ContractError.invalidApproval(
        "inputHashes does not contain the exact current collection-verification receipt"
      )
    }
  }
}
