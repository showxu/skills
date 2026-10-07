import Foundation

public struct TrustedContractBuildSummary: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let brand: String
  public let market: String
  public let trustedDirectory: String
  public let operationCount: Int
  public let fixtureCount: Int
  public let files: [String]
  public let sha256: [String: String]

  public init(
    brand: String,
    market: String,
    trustedDirectory: String,
    operationCount: Int,
    fixtureCount: Int,
    files: [String],
    sha256: [String: String],
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.trusted-contract-build"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.brand = brand
    self.market = market
    self.trustedDirectory = trustedDirectory
    self.operationCount = operationCount
    self.fixtureCount = fixtureCount
    self.files = files
    self.sha256 = sha256
  }
}

public enum TrustedContractBuildError: Error, Equatable, LocalizedError {
  case invalidOutputDirectory(String)
  case invalidArtifactPath(String)
  case duplicateArtifact(String)
  case missingArtifact(String)
  case unexpectedArtifact(String)
  case unsupportedArtifact(String)
  case missingAcceptedVerification(String)
  case missingFixture(String)
  case secretMaterial(path: String, finding: String)
  case symbolicLink(String)
  case rollbackFailed(original: String, rollback: String)
  case transactionIndeterminate(String)

  public var errorDescription: String? {
    switch self {
    case .invalidOutputDirectory(let path):
      "Trusted output is not a directory: \(path)"
    case .invalidArtifactPath(let path):
      "Trusted artifact path is unsafe: \(path)"
    case .duplicateArtifact(let path):
      "Trusted artifact path is duplicated: \(path)"
    case .missingArtifact(let path):
      "Trusted artifact is missing: \(path)"
    case .unexpectedArtifact(let path):
      "Trusted artifact is unexpected or stale: \(path)"
    case .unsupportedArtifact(let path):
      "Trusted artifact is neither a regular file nor a directory: \(path)"
    case .missingAcceptedVerification(let verificationId):
      "Accepted verification was not provided: \(verificationId)"
    case .missingFixture(let verificationId):
      "Accepted verification has no declared response fixture: \(verificationId)"
    case .secretMaterial(let path, let finding):
      "Sensitive material found in \(path): \(finding)"
    case .symbolicLink(let path):
      "Symbolic links are not allowed in Trusted artifacts: \(path)"
    case .rollbackFailed(let original, let rollback):
      "Trusted replacement failed (\(original)) and rollback failed (\(rollback))"
    case .transactionIndeterminate(let path):
      "Trusted replacement transaction is indeterminate: \(path)"
    }
  }
}

public struct TrustedContractBuilder {
  private let fileManager: FileManager
  private let validator: TrustValidator
  private let projector: OpenAPIProjector
  private let interruptionPoint:
    DurableDirectoryReplacementInterruptionPoint?

  public init(
    fileManager: FileManager = .default,
    validator: TrustValidator = TrustValidator(),
    projector: OpenAPIProjector = OpenAPIProjector()
  ) {
    self.fileManager = fileManager
    self.validator = validator
    self.projector = projector
    interruptionPoint = nil
  }

  init(
    fileManager: FileManager = .default,
    validator: TrustValidator = TrustValidator(),
    projector: OpenAPIProjector = OpenAPIProjector(),
    interruptionPoint: DurableDirectoryReplacementInterruptionPoint
  ) {
    self.fileManager = fileManager
    self.validator = validator
    self.projector = projector
    self.interruptionPoint = interruptionPoint
  }

  public func build(
    _ input: TrustValidationInput,
    trustedDirectory: URL
  ) throws -> TrustedContractBuildSummary {
    let destination = trustedDirectory.standardizedFileURL
    try validateDestinationRoot(destination)
    try EvidencePathGuard.requireTrustedDirectory(destination)

    let policies = try validator.validate(input)
    let accepted = try acceptedVerifications(
      policies: policies,
      provided: input.verifications
    )
    let openAPI = try projector.project(
      OpenAPIProjectionInput(
        catalog: input.catalog,
        policies: policies,
        acceptedVerifications: accepted
      )
    )
    let payloads = try artifactPayloads(
      openAPI: openAPI,
      policies: policies,
      acceptedVerifications: accepted
    )
    let files = payloads.keys.sorted()
    let hashes = Dictionary(
      uniqueKeysWithValues: files.compactMap { path in
        payloads[path].map { (path, FileDigest.sha256(data: $0)) }
      }
    )

    let parent = destination.deletingLastPathComponent()
    try fileManager.createDirectory(
      at: parent,
      withIntermediateDirectories: true
    )

    let name = destination.lastPathComponent
    guard !name.isEmpty, name != ".", name != ".." else {
      throw TrustedContractBuildError.invalidOutputDirectory(destination.path)
    }
    do {
      let transaction = try DurableDirectoryReplacement(
        destination: destination,
        interruptionPoint: interruptionPoint
      )
      try EvidencePathGuard.requireTrustedDirectory(
        transaction.destinationURL
      )
      try transaction.replace(payloads: payloads) { findings in
        if let finding = findings.first {
          throw TrustedContractBuildError.secretMaterial(
            path: finding.path,
            finding: finding.reason
          )
        }
      }
    } catch let error as DurableDirectoryReplacementError {
      throw TrustedContractBuildError.transactionIndeterminate(
        String(describing: error)
      )
    } catch {
      throw error
    }

    return TrustedContractBuildSummary(
      brand: policies.brand,
      market: policies.market,
      trustedDirectory: destination.path,
      operationCount: policies.operations.count,
      fixtureCount: files.filter { $0.hasPrefix("fixtures/") }.count,
      files: files,
      sha256: hashes
    )
  }

  private func acceptedVerifications(
    policies: ValidatedOperationPolicies,
    provided: [TrustVerificationReceipt]
  ) throws -> [TrustVerificationReceipt] {
    let acceptedIds = Set(
      policies.operations.flatMap(\.evidenceIds)
        .filter { $0.hasPrefix("ver_") }
    )
    let byId = Dictionary(
      uniqueKeysWithValues: provided.map { ($0.verificationId, $0) }
    )
    return try acceptedIds.sorted().map { verificationId in
      guard let receipt = byId[verificationId] else {
        throw
          TrustedContractBuildError
          .missingAcceptedVerification(verificationId)
      }
      return receipt
    }
  }

  private func artifactPayloads(
    openAPI: JSONValue,
    policies: ValidatedOperationPolicies,
    acceptedVerifications: [TrustVerificationReceipt]
  ) throws -> [String: Data] {
    var payloads: [String: Data] = [
      "openapi.yaml": try DeterministicJSON.encode(openAPI),
      "operation-policies.json": try DeterministicJSON.encode(policies),
    ]
    let receiptById = Dictionary(
      uniqueKeysWithValues: acceptedVerifications.map {
        ($0.verificationId, $0)
      }
    )
    let declaredPaths = Set(policies.operations.flatMap(\.fixturePaths))

    for path in declaredPaths.sorted() {
      try validateFixturePath(path)
    }

    for policy in policies.operations {
      for verificationId in policy.evidenceIds
      where verificationId.hasPrefix("ver_") {
        guard let receipt = receiptById[verificationId] else {
          throw
            TrustedContractBuildError
            .missingAcceptedVerification(verificationId)
        }
        if policy.authPolicy != .none {
          continue
        }
        let omittedReviewedTextFixture =
          policy.responseExtraction != nil
          && receipt.effectiveResponseFixture == nil
          && receipt.fixtureOmissionReason?
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
          && receipt.response.contentType?.lowercased().hasPrefix("text/") == true
        if omittedReviewedTextFixture {
          try ReviewedResponseExtractor.validatePolicy(
            policy.responseExtraction
          )
          continue
        }
        let projection = try ReviewedResponseExtractor.project(
          response: receipt.response,
          fixture: receipt.effectiveResponseFixture,
          policy: policy.responseExtraction
        )
        guard let fixture = projection.fixture else {
          continue
        }
        let path =
          "fixtures/\(safePathComponent(policy.operationId))/"
          + "\(verificationId).json"
        guard declaredPaths.contains(path) else {
          throw TrustedContractBuildError.missingFixture(verificationId)
        }
        guard payloads[path] == nil else {
          throw TrustedContractBuildError.duplicateArtifact(path)
        }
        payloads[path] = try DeterministicJSON.encode(fixture)
      }
    }

    let emittedFixtures = Set(
      payloads.keys.filter {
        $0.hasPrefix("fixtures/")
      })
    if let missing = declaredPaths.subtracting(emittedFixtures).sorted().first {
      throw TrustedContractBuildError.missingArtifact(missing)
    }
    if let unexpected = emittedFixtures.subtracting(declaredPaths).sorted().first {
      throw TrustedContractBuildError.unexpectedArtifact(unexpected)
    }
    return payloads
  }

  private func validateDestinationRoot(_ destination: URL) throws {
    guard fileManager.fileExists(atPath: destination.path) else { return }
    let values = try destination.resourceValues(
      forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
    )
    if values.isSymbolicLink == true {
      throw TrustedContractBuildError.symbolicLink(destination.path)
    }
    guard values.isDirectory == true else {
      throw TrustedContractBuildError.invalidOutputDirectory(destination.path)
    }
  }

  private func validateFixturePath(_ path: String) throws {
    let components = path.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map(String.init)
    guard components.count == 3,
      components.first == "fixtures",
      components.allSatisfy(isSafePathComponent),
      components.last?.hasSuffix(".json") == true
    else {
      throw TrustedContractBuildError.invalidArtifactPath(path)
    }
  }

  private func safePathComponent(_ value: String) -> String {
    String(
      value.map {
        $0.isLetter || $0.isNumber || $0 == "." || $0 == "-"
          || $0 == "_"
          ? $0
          : "_"
      }
    )
  }

  private func isSafePathComponent(_ value: String) -> Bool {
    !value.isEmpty
      && value != "."
      && value != ".."
      && value.allSatisfy {
        $0.isLetter || $0.isNumber || $0 == "." || $0 == "-"
          || $0 == "_"
      }
  }
}
