import Foundation

struct SourceProductPolicyAuthority {
  let policy: SourceProductVerificationPolicy
  let sha256: String
}

private struct SourceReceiptAuthorityArtifact {
  let fileName: String
  let receipt: SourceProductVerificationReceipt
  let sha256: String
}

enum PlatformSourceEvidenceAuthority {
  static let receiptPathPrefix =
    "API/Observed/source-verifications/"

  static func platformAreas(
    in requiredAreas: [String]?
  ) -> Set<String> {
    Set(requiredAreas ?? []).intersection(
      SourceCoverageContract.sourceProductVerificationAreas
    )
  }

  static func loadPolicies(
    providerRoot: URL,
    provider: String,
    market: String,
    fileManager: FileManager = .default
  ) throws -> [SourceProductPolicyAuthority] {
    let config = providerRoot.appending(
      path: "API/Config",
      directoryHint: .isDirectory
    )
    guard fileManager.fileExists(atPath: config.path) else { return [] }
    let policyURLs = try fileManager.contentsOfDirectory(
      at: config,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ).filter {
      $0.lastPathComponent.hasSuffix("source-product-policy.json")
    }.sorted { $0.path < $1.path }

    return try policyURLs.map { policyURL in
      try policyAuthority(
        data: Data(contentsOf: policyURL),
        fileName: policyURL.lastPathComponent,
        provider: provider,
        market: market
      )
    }
  }

  static func loadPolicies(
    snapshot: ProviderAPIAuthoritySnapshot,
    provider: String,
    market: String
  ) throws -> [SourceProductPolicyAuthority] {
    try snapshot.directFiles(in: "API/Config").compactMap { artifact in
      let fileName = String(artifact.path.split(separator: "/").last ?? "")
      guard fileName.hasSuffix("source-product-policy.json") else {
        return nil
      }
      return try policyAuthority(
        data: artifact.data,
        fileName: fileName,
        provider: provider,
        market: market
      )
    }
  }

  private static func policyAuthority(
    data: Data,
    fileName: String,
    provider: String,
    market: String
  ) throws -> SourceProductPolicyAuthority {
    let policy = try DeterministicJSON.decode(
      SourceProductVerificationPolicy.self,
      from: data
    )
    try SourceProductVerifier.validate(policy)
    guard policy.provider == provider, policy.market == market else {
      throw ContractError.scopeMismatch(
        "\(fileName) declares "
          + "\(policy.provider)/\(policy.market), expected "
          + "\(provider)/\(market)"
      )
    }
    return SourceProductPolicyAuthority(
      policy: policy,
      sha256: FileDigest.sha256(
        data: try DeterministicJSON.encode(policy)
      )
    )
  }

  static func collectRequiredReceiptHashes(
    providerRoot: URL,
    provider: String,
    market: String,
    requiredAreas: [String]?,
    sourceLock: SourceLock,
    policies: [SourceProductPolicyAuthority],
    fileManager: FileManager = .default
  ) throws -> [String: String] {
    let receiptDirectory = providerRoot.appending(
      path: receiptPathPrefix,
      directoryHint: .isDirectory
    )
    let artifacts = try SourceProductVerificationReceiptLoader.loadArtifacts(
      from: receiptDirectory,
      fileManager: fileManager
    ).map {
      SourceReceiptAuthorityArtifact(
        fileName: $0.url.lastPathComponent,
        receipt: $0.receipt,
        sha256: try FileDigest.sha256(fileAt: $0.url)
      )
    }
    return try collectRequiredReceiptHashes(
      provider: provider,
      market: market,
      requiredAreas: requiredAreas,
      sourceLock: sourceLock,
      policies: policies,
      artifacts: artifacts
    )
  }

  static func collectRequiredReceiptHashes(
    snapshot: ProviderAPIAuthoritySnapshot,
    provider: String,
    market: String,
    requiredAreas: [String]?,
    sourceLock: SourceLock,
    policies: [SourceProductPolicyAuthority]
  ) throws -> [String: String] {
    let artifacts = try snapshot.directFiles(
      in: String(receiptPathPrefix.dropLast())
    ).compactMap { artifact -> SourceReceiptAuthorityArtifact? in
      guard artifact.path.hasSuffix(".json") else { return nil }
      return SourceReceiptAuthorityArtifact(
        fileName: String(artifact.path.split(separator: "/").last ?? ""),
        receipt: try DeterministicJSON.decode(
          SourceProductVerificationReceipt.self,
          from: artifact.data
        ),
        sha256: FileDigest.sha256(data: artifact.data)
      )
    }
    return try collectRequiredReceiptHashes(
      provider: provider,
      market: market,
      requiredAreas: requiredAreas,
      sourceLock: sourceLock,
      policies: policies,
      artifacts: artifacts
    )
  }

  private static func collectRequiredReceiptHashes(
    provider: String,
    market: String,
    requiredAreas: [String]?,
    sourceLock: SourceLock,
    policies: [SourceProductPolicyAuthority],
    artifacts: [SourceReceiptAuthorityArtifact]
  ) throws -> [String: String] {
    let required = Set(requiredAreas ?? [])
    let platform = platformAreas(in: requiredAreas)
    guard !platform.isEmpty else { return [:] }
    guard sourceLock.schemaVersion == 1,
      sourceLock.kind == "web-api-reverse.source-lock"
        || sourceLock.kind == "lifeware.source-lock",
      sourceLock.brand == provider,
      sourceLock.market == market
    else {
      throw ContractError.invalidObservedEvidence(
        "source-lock.json does not match \(provider)/\(market)"
      )
    }
    guard Set(sourceLock.requiredCoverageAreas ?? []) == required else {
      throw ContractError.invalidObservedEvidence(
        "current source-lock coverage areas do not match the approval"
      )
    }

    guard !artifacts.isEmpty else {
      throw ContractError.invalidObservedEvidence(
        "platform semantic areas "
          + "\(platform.sorted().joined(separator: ", ")) require a "
          + "sanitized receipt in \(receiptPathPrefix.dropLast())"
      )
    }

    var artifactByFingerprint: [String: SourceReceiptAuthorityArtifact] = [:]
    for artifact in artifacts {
      let fingerprint = artifact.receipt.evidenceFingerprint
      guard artifactByFingerprint[fingerprint] == nil else {
        throw ContractError.invalidObservedEvidence(
          "source verification fingerprint \(fingerprint) appears in "
            + "multiple receipt files"
        )
      }
      artifactByFingerprint[fingerprint] = artifact
    }

    var provenAreas: Set<String> = []
    var hashes: [String: String] = [:]
    var platformSourceCount = 0
    for source in sourceLock.sources where source.coveragePolicy == .required {
      let sourceAreas = Set(source.coverageAreas ?? []).intersection(platform)
      guard !sourceAreas.isEmpty else { continue }
      platformSourceCount += 1
      guard source.status == .captured else {
        throw ContractError.invalidObservedEvidence(
          "\(source.sourceId)@\(source.version) is not captured"
        )
      }
      let fingerprints = source.evidenceFingerprints ?? []
      guard !fingerprints.isEmpty else {
        throw ContractError.invalidObservedEvidence(
          "\(source.sourceId)@\(source.version) has no bound "
            + "source-verification fingerprint"
        )
      }
      for fingerprint in fingerprints {
        guard let artifact = artifactByFingerprint[fingerprint] else {
          throw ContractError.invalidObservedEvidence(
            "\(source.sourceId)@\(source.version) is missing its bound "
              + "source-verification receipt for \(fingerprint)"
          )
        }
        let receipt = artifact.receipt
        guard receipt.provider == provider,
          receipt.market == market,
          receipt.sourceId == source.sourceId,
          receipt.sourceVersion == source.version,
          receipt.sourceProductSHA256 == source.sha256
        else {
          throw ContractError.invalidObservedEvidence(
            "\(receipt.verificationId) does not match its current source-lock entry"
          )
        }
        let matchingPolicies = policies.filter {
          $0.policy.sourceId == receipt.sourceId
            && $0.policy.sourceVersion == receipt.sourceVersion
            && $0.policy.platformProvider == receipt.platformProvider
        }
        guard
          let policy = matchingPolicies.first(where: {
            $0.sha256 == receipt.policySHA256
          })
        else {
          throw ContractError.invalidObservedEvidence(
            "\(receipt.verificationId) policy digest does not match a current "
              + "source product policy"
          )
        }
        if sourceAreas.contains("selected-platform-current-facts") {
          guard
            !policy.policy.requiredProductCurrentFactFields.isEmpty,
            !policy.policy.requiredSKUCurrentFactFields.isEmpty
          else {
            throw ContractError.invalidObservedEvidence(
              "\(receipt.verificationId) is identity-only and cannot prove "
                + "selected-platform-current-facts"
            )
          }
        }
        do {
          try SourceProductVerifier.validate(
            receipt,
            against: policy.policy
          )
        } catch {
          throw ContractError.invalidObservedEvidence(
            "\(receipt.verificationId) does not prove the current source "
              + "product policy and exact platform Published lock: "
              + error.localizedDescription
          )
        }
        let relativePath =
          receiptPathPrefix + artifact.fileName
        hashes[relativePath] = artifact.sha256
      }
      provenAreas.formUnion(sourceAreas)
    }
    guard platformSourceCount > 0 else {
      throw ContractError.invalidObservedEvidence(
        "source-lock.json assigns no required source to platform semantic "
          + "areas: \(platform.sorted().joined(separator: ", "))"
      )
    }
    let missingAreas = platform.subtracting(provenAreas)
    guard missingAreas.isEmpty else {
      throw ContractError.invalidObservedEvidence(
        "current source-lock.json has no bound source-verification proving "
          + "platform semantic areas: "
          + missingAreas.sorted().joined(separator: ", ")
      )
    }
    return hashes
  }

  static func validateApprovalReceiptHashes(
    providerRoot: URL,
    provider: String,
    market: String,
    approval: ApprovalReceipt,
    sourceLock: SourceLock,
    policies: [SourceProductPolicyAuthority],
    fileManager: FileManager = .default
  ) throws {
    let requiredHashes = try collectRequiredReceiptHashes(
      providerRoot: providerRoot,
      provider: provider,
      market: market,
      requiredAreas: approval.requiredCoverageAreas,
      sourceLock: sourceLock,
      policies: policies,
      fileManager: fileManager
    )
    try validateApprovedHashes(requiredHashes, approval: approval)
  }

  static func validateApprovalReceiptHashes(
    snapshot: ProviderAPIAuthoritySnapshot,
    provider: String,
    market: String,
    approval: ApprovalReceipt,
    sourceLock: SourceLock,
    policies: [SourceProductPolicyAuthority]
  ) throws {
    let requiredHashes = try collectRequiredReceiptHashes(
      snapshot: snapshot,
      provider: provider,
      market: market,
      requiredAreas: approval.requiredCoverageAreas,
      sourceLock: sourceLock,
      policies: policies
    )
    try validateApprovedHashes(
      requiredHashes,
      approval: approval
    )
  }

  private static func validateApprovedHashes(
    _ requiredHashes: [String: String],
    approval: ApprovalReceipt
  ) throws {
    let approvedHashes = approval.inputHashes.filter {
      $0.key.hasPrefix(receiptPathPrefix)
    }
    guard Set(approvedHashes.keys) == Set(requiredHashes.keys) else {
      let missing = Set(requiredHashes.keys)
        .subtracting(approvedHashes.keys).sorted()
      throw ContractError.invalidApproval(
        "inputHashes does not contain the exact required source-verification "
          + "receipt set; missing: \(missing.joined(separator: ", "))"
      )
    }
    for (path, hash) in requiredHashes {
      guard approvedHashes[path] == hash else {
        throw ContractError.invalidObservedEvidence(
          "\(path) no longer matches the Published approval"
        )
      }
    }
  }

  static func requireCurrentApprovalInput(
    _ relativePath: String,
    providerRoot: URL,
    approval: ApprovalReceipt,
    fileManager: FileManager = .default
  ) throws {
    let url = providerRoot.appending(path: relativePath)
    guard fileManager.fileExists(atPath: url.path) else {
      throw ContractError.missingFile(relativePath)
    }
    guard let expected = approval.inputHashes[relativePath] else {
      throw ContractError.invalidApproval(
        "inputHashes is missing \(relativePath)"
      )
    }
    let current = try FileDigest.sha256(fileAt: url)
    guard current == expected else {
      throw ContractError.invalidObservedEvidence(
        "\(relativePath) no longer matches the Published approval"
      )
    }
  }

  static func requireCurrentApprovalInput(
    _ relativePath: String,
    snapshot: ProviderAPIAuthoritySnapshot,
    approval: ApprovalReceipt
  ) throws {
    guard let expected = approval.inputHashes[relativePath] else {
      throw ContractError.invalidApproval(
        "inputHashes is missing \(relativePath)"
      )
    }
    let current = FileDigest.sha256(
      data: try snapshot.requiredData(relativePath)
    )
    guard current == expected else {
      throw ContractError.invalidObservedEvidence(
        "\(relativePath) no longer matches the Published approval"
      )
    }
  }
}
