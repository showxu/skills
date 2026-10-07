import Foundation

public enum SourceProductProjection: String, Codable, Equatable, Sendable {
  case platformRaw
  case providerMapped
}

public struct SourceProductVerificationPolicy: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let sourceId: String
  public let sourceVersion: String
  public let platformProvider: String
  public let commercePlatform: String
  public let sourceProjection: SourceProductProjection?
  public let acceptedGarmentBrands: [String]
  public let acceptedSellerIDs: [String]
  public let acceptedShopIDs: [String]?
  public let acceptedStorefronts: [String]
  public let requiredProductCurrentFactFields: [String]
  public let requiredSKUCurrentFactFields: [String]
  public let minimumSKUCount: Int
  public let requireCompleteSKUSet: Bool

  public init(
    provider: String,
    market: String,
    sourceId: String,
    sourceVersion: String,
    platformProvider: String,
    commercePlatform: String,
    sourceProjection: SourceProductProjection? = nil,
    acceptedGarmentBrands: [String],
    acceptedSellerIDs: [String],
    acceptedShopIDs: [String]? = nil,
    acceptedStorefronts: [String],
    requiredProductCurrentFactFields: [String],
    requiredSKUCurrentFactFields: [String],
    minimumSKUCount: Int = 1,
    requireCompleteSKUSet: Bool
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.source-product-verification-policy"
    self.provider = provider
    self.market = market
    self.sourceId = sourceId
    self.sourceVersion = sourceVersion
    self.platformProvider = platformProvider
    self.commercePlatform = commercePlatform
    self.sourceProjection = sourceProjection
    self.acceptedGarmentBrands = acceptedGarmentBrands
    self.acceptedSellerIDs = acceptedSellerIDs
    self.acceptedShopIDs = acceptedShopIDs
    self.acceptedStorefronts = acceptedStorefronts
    self.requiredProductCurrentFactFields = requiredProductCurrentFactFields
    self.requiredSKUCurrentFactFields = requiredSKUCurrentFactFields
    self.minimumSKUCount = minimumSKUCount
    self.requireCompleteSKUSet = requireCompleteSKUSet
  }
}

public struct SourceProductVerificationReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let verificationId: String
  public let evidenceFingerprint: String
  public let verifiedAt: String
  public let sourceId: String
  public let sourceVersion: String
  public let platformProvider: String
  public let commercePlatform: String
  public let platformPublishLockSHA256: String
  public let policySHA256: String
  public let sourceProductSHA256: String
  public let garmentBrand: String
  public let sellerID: String
  public let shopID: String?
  public let storefront: String
  public let productExternalID: String
  public let skuExternalIDs: [String]?
  public let skuCount: Int
  public let hasCompleteSKUSet: Bool
  public let productCurrentFactFields: [String]
  public let commonSKUCurrentFactFields: [String]

  public init(
    provider: String,
    market: String,
    verificationId: String,
    evidenceFingerprint: String,
    verifiedAt: String,
    sourceId: String,
    sourceVersion: String,
    platformProvider: String,
    commercePlatform: String,
    platformPublishLockSHA256: String,
    policySHA256: String,
    sourceProductSHA256: String,
    garmentBrand: String,
    sellerID: String,
    shopID: String? = nil,
    storefront: String,
    productExternalID: String,
    skuExternalIDs: [String]? = nil,
    skuCount: Int,
    hasCompleteSKUSet: Bool,
    productCurrentFactFields: [String],
    commonSKUCurrentFactFields: [String],
    schemaVersion: Int = 1
  ) {
    self.schemaVersion = schemaVersion
    self.kind = "web-api-reverse.source-product-verification"
    self.provider = provider
    self.market = market
    self.verificationId = verificationId
    self.evidenceFingerprint = evidenceFingerprint
    self.verifiedAt = verifiedAt
    self.sourceId = sourceId
    self.sourceVersion = sourceVersion
    self.platformProvider = platformProvider
    self.commercePlatform = commercePlatform
    self.platformPublishLockSHA256 = platformPublishLockSHA256
    self.policySHA256 = policySHA256
    self.sourceProductSHA256 = sourceProductSHA256
    self.garmentBrand = garmentBrand
    self.sellerID = sellerID
    self.shopID = shopID
    self.storefront = storefront
    self.productExternalID = productExternalID
    self.skuExternalIDs = skuExternalIDs
    self.skuCount = skuCount
    self.hasCompleteSKUSet = hasCompleteSKUSet
    self.productCurrentFactFields = productCurrentFactFields
    self.commonSKUCurrentFactFields = commonSKUCurrentFactFields
  }
}

public struct SourceProductVerificationInput: Sendable {
  public let policy: SourceProductVerificationPolicy
  public let sourceProductData: Data
  public let platformProviderRoot: URL

  public init(
    policy: SourceProductVerificationPolicy,
    sourceProductData: Data,
    platformProviderRoot: URL
  ) {
    self.policy = policy
    self.sourceProductData = sourceProductData
    self.platformProviderRoot = platformProviderRoot
  }
}

public struct SourceProductReceiptValidation: Codable, Equatable, Sendable {
  public let provider: String
  public let market: String
  public let sourceId: String
  public let platformProvider: String
  public let platformPublishLockSHA256: String
  public let policySHA256: String
  public let sourceProductReceiptSHA256: String

  public init(
    provider: String,
    market: String,
    sourceId: String,
    platformProvider: String,
    platformPublishLockSHA256: String,
    policySHA256: String,
    sourceProductReceiptSHA256: String
  ) {
    self.provider = provider
    self.market = market
    self.sourceId = sourceId
    self.platformProvider = platformProvider
    self.platformPublishLockSHA256 = platformPublishLockSHA256
    self.policySHA256 = policySHA256
    self.sourceProductReceiptSHA256 = sourceProductReceiptSHA256
  }
}

public enum SourceProductVerificationError:
  Error, Equatable, LocalizedError, Sendable
{
  case invalidPolicy(String)
  case invalidSourceProduct(String)
  case identityMismatch(String)
  case missingCurrentFact(String)
  case insufficientSKUCount(expected: Int, actual: Int)
  case incompleteSKUSet
  case invalidReceipt(String)

  public var errorDescription: String? {
    switch self {
    case .invalidPolicy(let reason):
      "Invalid source product verification policy: \(reason)"
    case .invalidSourceProduct(let reason):
      "Invalid SourceProductImportV1: \(reason)"
    case .identityMismatch(let reason):
      "Source product identity mismatch: \(reason)"
    case .missingCurrentFact(let path):
      "Source product evidence is missing required current fact: \(path)"
    case .insufficientSKUCount(let expected, let actual):
      "Source product evidence requires at least \(expected) SKU(s), found \(actual)."
    case .incompleteSKUSet:
      "Source product evidence does not claim a complete SKU set."
    case .invalidReceipt(let reason):
      "Invalid source product verification receipt: \(reason)"
    }
  }
}

public struct SourceProductVerificationReceiptArtifact: Sendable {
  public let url: URL
  public let receipt: SourceProductVerificationReceipt

  public init(
    url: URL,
    receipt: SourceProductVerificationReceipt
  ) {
    self.url = url
    self.receipt = receipt
  }
}

public enum SourceProductVerificationReceiptLoader {
  public static func loadArtifacts(
    from directory: URL,
    fileManager: FileManager = .default
  ) throws -> [SourceProductVerificationReceiptArtifact] {
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
    if try directory.resourceValues(
      forKeys: [.isSymbolicLinkKey]
    ).isSymbolicLink == true {
      throw ContractError.symbolicLink(directory.path)
    }
    let files = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [
        .isRegularFileKey,
        .isSymbolicLinkKey,
      ],
      options: [.skipsHiddenFiles]
    ).sorted { $0.path < $1.path }

    return try files.compactMap { url in
      let values = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      if values.isSymbolicLink == true {
        throw ContractError.symbolicLink(url.path)
      }
      guard values.isRegularFile == true,
        url.pathExtension.lowercased() == "json"
      else {
        return nil
      }
      return SourceProductVerificationReceiptArtifact(
        url: url,
        receipt: try DeterministicJSON.decode(
          SourceProductVerificationReceipt.self,
          from: Data(contentsOf: url)
        )
      )
    }.sorted {
      (
        $0.receipt.verificationId,
        $0.receipt.sourceId,
        $0.receipt.sourceVersion,
        $0.url.lastPathComponent
      )
        < (
          $1.receipt.verificationId,
          $1.receipt.sourceId,
          $1.receipt.sourceVersion,
          $1.url.lastPathComponent
        )
    }
  }

  public static func load(
    from directory: URL,
    fileManager: FileManager = .default
  ) throws -> [SourceProductVerificationReceipt] {
    try loadArtifacts(
      from: directory,
      fileManager: fileManager
    ).map(\.receipt)
  }
}

public struct SourceProductVerifier: Sendable {
  public init() {}

  public func verify(
    _ input: SourceProductVerificationInput
  ) throws -> SourceProductVerificationReceipt {
    try Self.validate(input.policy)
    let sourceProduct = try decodeSourceProduct(input.sourceProductData)
    let shopID = try validate(
      sourceProduct: sourceProduct,
      policy: input.policy
    )

    let publishLockSHA = try platformPublishLockSHA256(
      providerRoot: input.platformProviderRoot,
      provider: input.policy.platformProvider,
      market: input.policy.market,
      mismatch: { actualProvider, actualMarket in
        SourceProductVerificationError.identityMismatch(
          "Published \(actualProvider)/\(actualMarket) does not match "
            + "\(input.policy.platformProvider)/\(input.policy.market)"
        )
      }
    )

    let policySHA = FileDigest.sha256(
      data: try DeterministicJSON.encode(input.policy)
    )
    let sourceProductSHA = try canonicalJSONSHA256(input.sourceProductData)
    let verifiedAt = ISO8601DateFormatter().string(
      from: sourceProduct.observedAt
    )
    let productFields = sourceProduct.product.currentFacts?.presentFields ?? []
    let commonSKUFields = commonCurrentFactFields(sourceProduct.skus)
    let skuExternalIDs = sourceProduct.skus.map(\.externalID).sorted()
    let schemaVersion = shopID == nil ? 2 : 3
    let fingerprint =
      if let shopID {
        try evidenceFingerprintV3(
          provider: input.policy.provider,
          market: input.policy.market,
          sourceId: input.policy.sourceId,
          sourceVersion: input.policy.sourceVersion,
          platformProvider: input.policy.platformProvider,
          platformPublishLockSHA256: publishLockSHA,
          policySHA256: policySHA,
          sourceProductSHA256: sourceProductSHA,
          productExternalID: sourceProduct.product.externalID,
          skuExternalIDs: skuExternalIDs,
          shopID: shopID
        )
      } else {
        try evidenceFingerprintV2(
          provider: input.policy.provider,
          market: input.policy.market,
          sourceId: input.policy.sourceId,
          sourceVersion: input.policy.sourceVersion,
          platformProvider: input.policy.platformProvider,
          platformPublishLockSHA256: publishLockSHA,
          policySHA256: policySHA,
          sourceProductSHA256: sourceProductSHA,
          productExternalID: sourceProduct.product.externalID,
          skuExternalIDs: skuExternalIDs
        )
      }
    let receipt = SourceProductVerificationReceipt(
      provider: input.policy.provider,
      market: input.policy.market,
      verificationId: "spv_\(fingerprint.prefix(16))",
      evidenceFingerprint: fingerprint,
      verifiedAt: verifiedAt,
      sourceId: input.policy.sourceId,
      sourceVersion: input.policy.sourceVersion,
      platformProvider: input.policy.platformProvider,
      commercePlatform: input.policy.commercePlatform,
      platformPublishLockSHA256: publishLockSHA,
      policySHA256: policySHA,
      sourceProductSHA256: sourceProductSHA,
      garmentBrand: sourceProduct.source.brand,
      sellerID: sourceProduct.source.seller ?? "",
      shopID: shopID,
      storefront: sourceProduct.source.storefront ?? "",
      productExternalID: sourceProduct.product.externalID,
      skuExternalIDs: skuExternalIDs,
      skuCount: sourceProduct.skus.count,
      hasCompleteSKUSet: sourceProduct.hasCompleteSKUSet,
      productCurrentFactFields: productFields.sorted(),
      commonSKUCurrentFactFields: commonSKUFields.sorted(),
      schemaVersion: schemaVersion
    )
    try Self.validate(receipt)
    return receipt
  }

  public func validateReceipt(
    receiptData: Data,
    policy: SourceProductVerificationPolicy,
    platformProviderRoot: URL
  ) throws -> SourceProductReceiptValidation {
    let receipt = try DeterministicJSON.decode(
      SourceProductVerificationReceipt.self,
      from: receiptData
    )
    try Self.validate(receipt, against: policy)

    let currentLockSHA = try platformPublishLockSHA256(
      providerRoot: platformProviderRoot,
      provider: policy.platformProvider,
      market: policy.market
    ) { _, _ in
      SourceProductVerificationError.invalidReceipt(
        "platform Published scope does not match the current source product policy"
      )
    }
    guard receipt.platformPublishLockSHA256 == currentLockSHA else {
      throw SourceProductVerificationError.invalidReceipt(
        "platform Published lock digest does not match the current contract"
      )
    }

    return SourceProductReceiptValidation(
      provider: receipt.provider,
      market: receipt.market,
      sourceId: receipt.sourceId,
      platformProvider: receipt.platformProvider,
      platformPublishLockSHA256: currentLockSHA,
      policySHA256: receipt.policySHA256,
      sourceProductReceiptSHA256: FileDigest.sha256(data: receiptData)
    )
  }

  private func platformPublishLockSHA256(
    providerRoot: URL,
    provider: String,
    market: String,
    mismatch: (String, String) -> SourceProductVerificationError = { _, _ in
      .invalidReceipt(
        "platform Published scope does not match the current source product policy"
      )
    }
  ) throws -> String {
    try ProviderAPIAuthorityReader.withSharedSnapshot(
      providerRoot: providerRoot,
      includePublished: true
    ) { snapshot in
      let publishedDirectory = providerRoot.appending(
        path: "API/Published",
        directoryHint: .isDirectory
      ).path
      let validation = try ContractValidator().validate(
        snapshot: snapshot,
        publishedDirectory: publishedDirectory
      )
      let lock = try DeterministicJSON.decode(
        PublishLock.self,
        from: snapshot.requiredData("API/Published/publish-lock.json")
      )
      guard lock.provider == provider, lock.market == market else {
        throw mismatch(lock.provider, lock.market)
      }
      return validation.publishLockSHA256
    }
  }

  public static func validate(
    _ receipt: SourceProductVerificationReceipt
  ) throws {
    guard (1...3).contains(receipt.schemaVersion),
      receipt.kind == "web-api-reverse.source-product-verification"
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "unsupported schema or kind"
      )
    }
    for (name, value) in [
      ("provider", receipt.provider),
      ("market", receipt.market),
      ("sourceId", receipt.sourceId),
      ("sourceVersion", receipt.sourceVersion),
      ("platformProvider", receipt.platformProvider),
      ("commercePlatform", receipt.commercePlatform),
      ("garmentBrand", receipt.garmentBrand),
      ("sellerID", receipt.sellerID),
      ("storefront", receipt.storefront),
      ("productExternalID", receipt.productExternalID),
    ] where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw SourceProductVerificationError.invalidReceipt("\(name) is blank")
    }
    for (name, hash) in [
      ("evidenceFingerprint", receipt.evidenceFingerprint),
      ("platformPublishLockSHA256", receipt.platformPublishLockSHA256),
      ("policySHA256", receipt.policySHA256),
      ("sourceProductSHA256", receipt.sourceProductSHA256),
    ] where !isSHA256(hash) {
      throw SourceProductVerificationError.invalidReceipt(
        "\(name) is not SHA-256"
      )
    }
    let expectedFingerprint: String
    if receipt.schemaVersion >= 2 {
      guard let skuExternalIDs = receipt.skuExternalIDs,
        !skuExternalIDs.isEmpty,
        skuExternalIDs == Set(skuExternalIDs).sorted(),
        skuExternalIDs.allSatisfy({
          !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }),
        skuExternalIDs.count == receipt.skuCount
      else {
        throw SourceProductVerificationError.invalidReceipt(
          "v2+ SKU identities must be nonempty, unique, sorted, and match skuCount"
        )
      }
      if receipt.schemaVersion == 3 {
        guard let shopID = receipt.shopID,
          !shopID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
          throw SourceProductVerificationError.invalidReceipt(
            "v3 receipt requires a nonblank shopID"
          )
        }
        expectedFingerprint = try evidenceFingerprintV3(
          provider: receipt.provider,
          market: receipt.market,
          sourceId: receipt.sourceId,
          sourceVersion: receipt.sourceVersion,
          platformProvider: receipt.platformProvider,
          platformPublishLockSHA256: receipt.platformPublishLockSHA256,
          policySHA256: receipt.policySHA256,
          sourceProductSHA256: receipt.sourceProductSHA256,
          productExternalID: receipt.productExternalID,
          skuExternalIDs: skuExternalIDs,
          shopID: shopID
        )
      } else {
        guard receipt.shopID == nil else {
          throw SourceProductVerificationError.invalidReceipt(
            "v2 receipt cannot carry an unbound shopID"
          )
        }
        expectedFingerprint = try evidenceFingerprintV2(
          provider: receipt.provider,
          market: receipt.market,
          sourceId: receipt.sourceId,
          sourceVersion: receipt.sourceVersion,
          platformProvider: receipt.platformProvider,
          platformPublishLockSHA256: receipt.platformPublishLockSHA256,
          policySHA256: receipt.policySHA256,
          sourceProductSHA256: receipt.sourceProductSHA256,
          productExternalID: receipt.productExternalID,
          skuExternalIDs: skuExternalIDs
        )
      }
    } else {
      guard receipt.skuExternalIDs == nil, receipt.shopID == nil else {
        throw SourceProductVerificationError.invalidReceipt(
          "v1 receipt cannot carry unbound SKU or shop identities"
        )
      }
      expectedFingerprint = try evidenceFingerprint(
        provider: receipt.provider,
        market: receipt.market,
        sourceId: receipt.sourceId,
        sourceVersion: receipt.sourceVersion,
        platformProvider: receipt.platformProvider,
        platformPublishLockSHA256: receipt.platformPublishLockSHA256,
        policySHA256: receipt.policySHA256,
        sourceProductSHA256: receipt.sourceProductSHA256
      )
    }
    guard receipt.evidenceFingerprint == expectedFingerprint,
      receipt.verificationId == "spv_\(expectedFingerprint.prefix(16))"
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "identifier does not match the bound evidence"
      )
    }
    guard receipt.skuCount > 0 else {
      throw SourceProductVerificationError.invalidReceipt(
        "skuCount must be positive"
      )
    }
    let productFields = Set(receipt.productCurrentFactFields)
    let skuFields = Set(receipt.commonSKUCurrentFactFields)
    guard receipt.productCurrentFactFields == productFields.sorted(),
      receipt.commonSKUCurrentFactFields == skuFields.sorted(),
      productFields.isSubset(of: SourceCurrentFactsEvidence.allowedFields),
      skuFields.isSubset(of: SourceCurrentFactsEvidence.allowedFields)
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "current fact fields must be unique, sorted, and supported"
      )
    }
  }

  public static func validate(
    _ receipt: SourceProductVerificationReceipt,
    against policy: SourceProductVerificationPolicy
  ) throws {
    try validate(receipt)
    try validate(policy)
    guard receipt.provider == policy.provider,
      receipt.market == policy.market,
      receipt.sourceId == policy.sourceId,
      receipt.sourceVersion == policy.sourceVersion,
      receipt.platformProvider == policy.platformProvider,
      receipt.commercePlatform == policy.commercePlatform
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "scope does not match the source product policy"
      )
    }
    let policySHA = FileDigest.sha256(
      data: try DeterministicJSON.encode(policy)
    )
    guard receipt.policySHA256 == policySHA else {
      throw SourceProductVerificationError.invalidReceipt(
        "policy digest does not match the current source product policy"
      )
    }
    guard
      policy.acceptedGarmentBrands.map(normalizedIdentity)
        .contains(normalizedIdentity(receipt.garmentBrand)),
      policy.acceptedSellerIDs.map(normalizedIdentity)
        .contains(normalizedIdentity(receipt.sellerID)),
      policy.acceptedStorefronts.map(normalizedIdentity)
        .contains(normalizedIdentity(receipt.storefront))
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "identity summary is not allowed by the current source product policy"
      )
    }
    if let acceptedShopIDs = policy.acceptedShopIDs {
      guard receipt.schemaVersion == 3,
        let shopID = receipt.shopID,
        acceptedShopIDs.map(normalizedIdentity)
          .contains(normalizedIdentity(shopID))
      else {
        throw SourceProductVerificationError.invalidReceipt(
          "shop identity summary is not allowed by the current source product policy"
        )
      }
    } else if receipt.shopID != nil {
      throw SourceProductVerificationError.invalidReceipt(
        "shop identity is not constrained by the current source product policy"
      )
    }
    guard receipt.skuCount >= policy.minimumSKUCount else {
      throw SourceProductVerificationError.insufficientSKUCount(
        expected: policy.minimumSKUCount,
        actual: receipt.skuCount
      )
    }
    if policy.requireCompleteSKUSet && !receipt.hasCompleteSKUSet {
      throw SourceProductVerificationError.incompleteSKUSet
    }
    guard
      Set(policy.requiredProductCurrentFactFields)
        .isSubset(of: Set(receipt.productCurrentFactFields)),
      Set(policy.requiredSKUCurrentFactFields)
        .isSubset(of: Set(receipt.commonSKUCurrentFactFields))
    else {
      throw SourceProductVerificationError.invalidReceipt(
        "current fact summary does not satisfy the current source product policy"
      )
    }
  }

  public static func validate(
    _ policy: SourceProductVerificationPolicy
  ) throws {
    guard policy.schemaVersion == 1,
      policy.kind == "web-api-reverse.source-product-verification-policy"
    else {
      throw SourceProductVerificationError.invalidPolicy(
        "unsupported schema or kind"
      )
    }
    for (name, value) in [
      ("provider", policy.provider),
      ("market", policy.market),
      ("sourceId", policy.sourceId),
      ("sourceVersion", policy.sourceVersion),
      ("platformProvider", policy.platformProvider),
      ("commercePlatform", policy.commercePlatform),
    ] where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw SourceProductVerificationError.invalidPolicy("\(name) is blank")
    }
    guard policy.minimumSKUCount > 0 else {
      throw SourceProductVerificationError.invalidPolicy(
        "minimumSKUCount must be positive"
      )
    }
    guard !policy.acceptedGarmentBrands.isEmpty,
      !policy.acceptedSellerIDs.isEmpty,
      !policy.acceptedStorefronts.isEmpty
    else {
      throw SourceProductVerificationError.invalidPolicy(
        "brand, seller, and storefront allowlists must all be nonempty"
      )
    }
    if let acceptedShopIDs = policy.acceptedShopIDs,
      acceptedShopIDs.isEmpty
    {
      throw SourceProductVerificationError.invalidPolicy(
        "acceptedShopIDs must be omitted or nonempty"
      )
    }
    if policy.sourceProjection == .providerMapped,
      policy.provider == policy.platformProvider
    {
      throw SourceProductVerificationError.invalidPolicy(
        "providerMapped requires distinct provider and platformProvider values"
      )
    }
    let allowedFields = SourceCurrentFactsEvidence.allowedFields
    for field in policy.requiredProductCurrentFactFields
      + policy.requiredSKUCurrentFactFields
    where !allowedFields.contains(field) {
      throw SourceProductVerificationError.invalidPolicy(
        "unsupported current fact field \(field)"
      )
    }
  }

  private func validate(
    sourceProduct: SourceProductImportEvidence,
    policy: SourceProductVerificationPolicy
  ) throws -> String? {
    guard sourceProduct.schemaVersion == 1 else {
      throw SourceProductVerificationError.invalidSourceProduct(
        "unsupported schema version \(sourceProduct.schemaVersion)"
      )
    }
    let source = sourceProduct.source
    let sourceOwnerMatchesProviderID =
      policy.sourceProjection == .providerMapped
      || source.sourceTool == source.providerID.brand
    guard
      !source.providerID.brand.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).isEmpty,
      sourceOwnerMatchesProviderID,
      source.market == source.providerID.market,
      source.providerID.storefront == nil
        || source.providerID.storefront == source.storefront
    else {
      throw SourceProductVerificationError.invalidSourceProduct(
        "sourceTool/providerID and market/providerID do not match"
      )
    }
    let expectedSourceOwner =
      policy.sourceProjection == .providerMapped
      ? policy.provider
      : policy.platformProvider
    guard source.sourceTool == expectedSourceOwner,
      source.commercePlatform == policy.commercePlatform,
      source.market == policy.market
    else {
      throw SourceProductVerificationError.identityMismatch(
        "source \(source.sourceTool)/\(source.commercePlatform)/\(source.market) "
          + "does not match \(expectedSourceOwner)/\(policy.commercePlatform)/"
          + policy.market
      )
    }
    try requireAllowed(
      source.brand,
      in: policy.acceptedGarmentBrands,
      name: "garment brand"
    )
    try requireAllowed(
      source.seller,
      in: policy.acceptedSellerIDs,
      name: "seller"
    )
    try requireAllowed(
      source.storefront,
      in: policy.acceptedStorefronts,
      name: "storefront"
    )
    guard
      !sourceProduct.product.externalID
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw SourceProductVerificationError.invalidSourceProduct(
        "product.externalID is blank"
      )
    }
    try validateAliases(
      sourceProduct.product.aliases,
      path: "product.aliases"
    )
    let shopID = try verifiedShopID(
      in: sourceProduct.product.aliases,
      acceptedShopIDs: policy.acceptedShopIDs
    )
    try validateCurrentFacts(
      sourceProduct.product.currentFacts,
      path: "product.currentFacts"
    )
    guard sourceProduct.skus.count >= policy.minimumSKUCount else {
      throw SourceProductVerificationError.insufficientSKUCount(
        expected: policy.minimumSKUCount,
        actual: sourceProduct.skus.count
      )
    }
    if policy.requireCompleteSKUSet && !sourceProduct.hasCompleteSKUSet {
      throw SourceProductVerificationError.incompleteSKUSet
    }
    var skuIDs = Set<String>()
    for sku in sourceProduct.skus {
      guard !sku.externalID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw SourceProductVerificationError.invalidSourceProduct(
          "SKU externalID is blank"
        )
      }
      guard skuIDs.insert(sku.externalID).inserted else {
        throw SourceProductVerificationError.invalidSourceProduct(
          "duplicate SKU \(sku.externalID)"
        )
      }
      if let productExternalID = sku.productExternalID,
        productExternalID != sourceProduct.product.externalID
      {
        throw SourceProductVerificationError.invalidSourceProduct(
          "SKU \(sku.externalID) references another product"
        )
      }
      try validateAliases(
        sku.aliases,
        path: "skus[\(sku.externalID)].aliases"
      )
      try validateCurrentFacts(
        sku.currentFacts,
        path: "skus[\(sku.externalID)].currentFacts"
      )
    }
    let productFields =
      sourceProduct.product.currentFacts?.presentFields ?? []
    for field in policy.requiredProductCurrentFactFields
    where !productFields.contains(field) {
      throw SourceProductVerificationError.missingCurrentFact(
        "product.\(field)"
      )
    }
    for (index, sku) in sourceProduct.skus.enumerated() {
      let fields = sku.currentFacts?.presentFields ?? []
      for field in policy.requiredSKUCurrentFactFields
      where !fields.contains(field) {
        throw SourceProductVerificationError.missingCurrentFact(
          "skus[\(index)].\(field)"
        )
      }
    }
    return shopID
  }

  private func verifiedShopID(
    in aliases: SourceAliasSetEvidence,
    acceptedShopIDs: [String]?
  ) throws -> String? {
    guard let acceptedShopIDs else { return nil }
    let values = aliases.aliases.compactMap { alias -> String? in
      guard normalizedIdentity(alias.kind) == "shopid" else { return nil }
      let value = alias.value.trimmingCharacters(in: .whitespacesAndNewlines)
      return value.isEmpty ? nil : value
    }
    guard values.count == 1, let shopID = values.first else {
      throw SourceProductVerificationError.identityMismatch(
        "product aliases must contain exactly one shopId"
      )
    }
    try requireAllowed(shopID, in: acceptedShopIDs, name: "shop")
    return shopID
  }

  private func decodeSourceProduct(
    _ data: Data
  ) throws -> SourceProductImportEvidence {
    do {
      return try DeterministicJSON.decode(
        SourceProductImportEvidence.self,
        from: data
      )
    } catch {
      throw SourceProductVerificationError.invalidSourceProduct(
        error.localizedDescription
      )
    }
  }

  private func requireAllowed(
    _ value: String?,
    in accepted: [String],
    name: String
  ) throws {
    guard let value,
      accepted.map(normalizedIdentity).contains(normalizedIdentity(value))
    else {
      throw SourceProductVerificationError.identityMismatch(
        "\(name) is not allowlisted"
      )
    }
  }

  private func validateAliases(
    _ aliases: SourceAliasSetEvidence,
    path: String
  ) throws {
    var seen = Set<String>()
    for alias in aliases.aliases {
      let kind = alias.kind.trimmingCharacters(in: .whitespacesAndNewlines)
      let value = alias.value.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !kind.isEmpty, !value.isEmpty else {
        throw SourceProductVerificationError.invalidSourceProduct(
          "\(path) contains a blank alias"
        )
      }
      let identity = "\(kind)\u{0}\(value)"
      guard seen.insert(identity).inserted else {
        throw SourceProductVerificationError.invalidSourceProduct(
          "\(path) contains duplicate alias \(kind):\(value)"
        )
      }
    }
  }

  private func validateCurrentFacts(
    _ facts: SourceCurrentFactsEvidence?,
    path: String
  ) throws {
    guard let facts else { return }
    guard
      SourceCurrentFactsEvidence.allowedStockStatuses.contains(
        facts.stockStatus
      )
    else {
      throw SourceProductVerificationError.invalidSourceProduct(
        "\(path).stockStatus is invalid"
      )
    }
    for money in [facts.currentPrice, facts.listPrice].compactMap({ $0 })
    where money.currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw SourceProductVerificationError.invalidSourceProduct(
        "\(path) contains a blank currency"
      )
    }
  }

  private func commonCurrentFactFields(
    _ skus: [SourceProductSKUEvidence]
  ) -> Set<String> {
    guard let first = skus.first else { return [] }
    return skus.dropFirst().reduce(
      first.currentFacts?.presentFields ?? []
    ) { partial, sku in
      partial.intersection(sku.currentFacts?.presentFields ?? [])
    }
  }
}

private struct SourceProductImportEvidence: Codable {
  let schemaVersion: Int
  let source: SourceProductIdentityEvidence
  let product: SourceProductEvidence
  let skus: [SourceProductSKUEvidence]
  let observedAt: Date
  let hasCompleteSKUSet: Bool
}

private struct SourceProductIdentityEvidence: Codable {
  let sourceTool: String
  let commercePlatform: String
  let providerID: SourceProductProviderIDEvidence
  let brand: String
  let market: String
  let storefront: String?
  let seller: String?
}

private struct SourceProductProviderIDEvidence: Codable {
  let brand: String
  let market: String
  let storefront: String?
}

private struct SourceProductEvidence: Codable {
  let externalID: String
  let aliases: SourceAliasSetEvidence
  let imageURLs: [URL]
  let currentFacts: SourceCurrentFactsEvidence?
}

private struct SourceProductSKUEvidence: Codable {
  let externalID: String
  let productExternalID: String?
  let aliases: SourceAliasSetEvidence
  let currentFacts: SourceCurrentFactsEvidence?
}

private struct SourceAliasSetEvidence: Codable {
  let aliases: [SourceAliasEvidence]
}

private struct SourceAliasEvidence: Codable {
  let kind: String
  let value: String
}

private struct SourceCurrentFactsEvidence: Codable {
  static let allowedFields: Set<String> = [
    "currentPrice",
    "discountPercentage",
    "isDiscounted",
    "listPrice",
    "promotionText",
    "sourceRevision",
    "stockStatus",
  ]
  static let allowedStockStatuses: Set<String> = [
    "inStock",
    "lowStock",
    "outOfStock",
    "unavailable",
    "unknown",
  ]

  let observedAt: Date
  let currentPrice: SourceMoneyEvidence?
  let listPrice: SourceMoneyEvidence?
  let isDiscounted: Bool?
  let discountPercentage: Decimal?
  let promotionText: String?
  let stockStatus: String
  let sourceRevision: String?

  var presentFields: Set<String> {
    var fields: Set<String> = []
    if currentPrice != nil { fields.insert("currentPrice") }
    if listPrice != nil { fields.insert("listPrice") }
    if isDiscounted != nil { fields.insert("isDiscounted") }
    if discountPercentage != nil { fields.insert("discountPercentage") }
    if promotionText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
      fields.insert("promotionText")
    }
    if sourceRevision?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
      fields.insert("sourceRevision")
    }
    if stockStatus != "unknown" { fields.insert("stockStatus") }
    return fields
  }
}

private struct SourceMoneyEvidence: Codable {
  let amount: Decimal
  let currency: String
}

private struct SourceProductEvidenceFingerprint: Codable {
  let provider: String
  let market: String
  let sourceId: String
  let sourceVersion: String
  let platformProvider: String
  let platformPublishLockSHA256: String
  let policySHA256: String
  let sourceProductSHA256: String
}

private struct SourceProductEvidenceFingerprintV2: Codable {
  let schemaVersion: Int
  let provider: String
  let market: String
  let sourceId: String
  let sourceVersion: String
  let platformProvider: String
  let platformPublishLockSHA256: String
  let policySHA256: String
  let sourceProductSHA256: String
  let productExternalID: String
  let skuExternalIDs: [String]
}

private struct SourceProductEvidenceFingerprintV3: Codable {
  let schemaVersion: Int
  let provider: String
  let market: String
  let sourceId: String
  let sourceVersion: String
  let platformProvider: String
  let platformPublishLockSHA256: String
  let policySHA256: String
  let sourceProductSHA256: String
  let productExternalID: String
  let skuExternalIDs: [String]
  let shopID: String
}

private func evidenceFingerprint(
  provider: String,
  market: String,
  sourceId: String,
  sourceVersion: String,
  platformProvider: String,
  platformPublishLockSHA256: String,
  policySHA256: String,
  sourceProductSHA256: String
) throws -> String {
  FileDigest.sha256(
    data: try DeterministicJSON.encode(
      SourceProductEvidenceFingerprint(
        provider: provider,
        market: market,
        sourceId: sourceId,
        sourceVersion: sourceVersion,
        platformProvider: platformProvider,
        platformPublishLockSHA256: platformPublishLockSHA256,
        policySHA256: policySHA256,
        sourceProductSHA256: sourceProductSHA256
      )
    )
  )
}

private func evidenceFingerprintV2(
  provider: String,
  market: String,
  sourceId: String,
  sourceVersion: String,
  platformProvider: String,
  platformPublishLockSHA256: String,
  policySHA256: String,
  sourceProductSHA256: String,
  productExternalID: String,
  skuExternalIDs: [String]
) throws -> String {
  FileDigest.sha256(
    data: try DeterministicJSON.encode(
      SourceProductEvidenceFingerprintV2(
        schemaVersion: 2,
        provider: provider,
        market: market,
        sourceId: sourceId,
        sourceVersion: sourceVersion,
        platformProvider: platformProvider,
        platformPublishLockSHA256: platformPublishLockSHA256,
        policySHA256: policySHA256,
        sourceProductSHA256: sourceProductSHA256,
        productExternalID: productExternalID,
        skuExternalIDs: skuExternalIDs
      )
    )
  )
}

private func evidenceFingerprintV3(
  provider: String,
  market: String,
  sourceId: String,
  sourceVersion: String,
  platformProvider: String,
  platformPublishLockSHA256: String,
  policySHA256: String,
  sourceProductSHA256: String,
  productExternalID: String,
  skuExternalIDs: [String],
  shopID: String
) throws -> String {
  FileDigest.sha256(
    data: try DeterministicJSON.encode(
      SourceProductEvidenceFingerprintV3(
        schemaVersion: 3,
        provider: provider,
        market: market,
        sourceId: sourceId,
        sourceVersion: sourceVersion,
        platformProvider: platformProvider,
        platformPublishLockSHA256: platformPublishLockSHA256,
        policySHA256: policySHA256,
        sourceProductSHA256: sourceProductSHA256,
        productExternalID: productExternalID,
        skuExternalIDs: skuExternalIDs,
        shopID: shopID
      )
    )
  )
}

private func canonicalJSONSHA256(_ data: Data) throws -> String {
  let object = try JSONSerialization.jsonObject(with: data)
  guard JSONSerialization.isValidJSONObject(object) else {
    throw SourceProductVerificationError.invalidSourceProduct(
      "root is not a JSON object"
    )
  }
  return FileDigest.sha256(
    data: try JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  )
}

private func normalizedIdentity(_ value: String) -> String {
  value.trimmingCharacters(in: .whitespacesAndNewlines)
    .folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )
}

private func isSHA256(_ value: String) -> Bool {
  value.range(
    of: #"^[a-f0-9]{64}$"#,
    options: .regularExpression
  ) != nil
}
