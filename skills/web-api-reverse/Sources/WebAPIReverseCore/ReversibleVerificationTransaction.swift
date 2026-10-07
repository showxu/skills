import Foundation

public struct ReversibleVerificationTransactionStore: @unchecked Sendable {
  static let checkpointFileName = "reversible-transaction.json"
  static let lockFileName = "reversible-transaction.lock"
  static let maximumCheckpointBytes = 32 * 1_024 * 1_024

  private let artifacts: PrivateArtifactStore

  public init(
    privateRoot: URL,
    createPrivateRoot: Bool = true
  ) throws {
    artifacts = try PrivateArtifactStore(
      privateRoot: privateRoot,
      createPrivateRoot: createPrivateRoot
    )
  }

  init(artifacts: PrivateArtifactStore) {
    self.artifacts = artifacts
  }

  func withExclusiveLock<Result: Sendable>(
    _ operation: @Sendable () async throws -> Result
  ) async throws -> Result {
    try await artifacts.withExclusiveLock(
      named: Self.lockFileName,
      operation
    )
  }

  func load() throws -> ReversibleVerificationCheckpoint? {
    guard try artifacts.contains(Self.checkpointFileName) else {
      return nil
    }
    do {
      let checkpoint = try DeterministicJSON.decode(
        ReversibleVerificationCheckpoint.self,
        from: artifacts.read(
          named: Self.checkpointFileName,
          maximumBytes: Self.maximumCheckpointBytes
        )
      )
      guard
        checkpoint.schemaVersion == 1,
        checkpoint.kind
          == "web-api-reverse.reversible-verification-transaction"
      else {
        throw ReversibleVerificationError.invalidTransactionCheckpoint
      }
      return checkpoint
    } catch let error as ReversibleVerificationError {
      throw error
    } catch {
      throw ReversibleVerificationError.invalidTransactionCheckpoint
    }
  }

  func save(_ checkpoint: ReversibleVerificationCheckpoint) throws {
    try artifacts.write(
      DeterministicJSON.encode(checkpoint),
      named: Self.checkpointFileName,
      maximumBytes: Self.maximumCheckpointBytes
    )
  }

  func clear() throws {
    guard try artifacts.contains(Self.checkpointFileName) else { return }
    try artifacts.remove(named: Self.checkpointFileName)
  }

  public func acknowledgeCompletion(sequenceId: String) async throws {
    try await withExclusiveLock {
      guard
        let checkpoint = try load(),
        checkpoint.phase == .completed,
        checkpoint.result?.sequence.sequenceId == sequenceId
      else {
        throw ReversibleVerificationError.invalidTransactionCheckpoint
      }
      try clear()
    }
  }
}

enum ReversibleVerificationTransactionPhase:
  String,
  Codable,
  Sendable
{
  case prepared
  case addDispatchUnknown = "add-dispatch-unknown"
  case addConfirmed = "add-confirmed"
  case restoreDispatchUnknown = "restore-dispatch-unknown"
  case completed
}

struct ReversibleVerificationCheckpoint: Codable, Sendable {
  let schemaVersion: Int
  let kind: String
  let phase: ReversibleVerificationTransactionPhase
  let catalog: ObservedCatalog
  let plan: ReversibleVerificationPlan
  let sessionSeed: PrivateSessionSeed?
  let verifiedAt: String
  let beforeIdentities: [String]
  let beforeDigest: String
  let targetIdentity: String
  let result: ReversibleVerificationResult?

  init(
    phase: ReversibleVerificationTransactionPhase,
    catalog: ObservedCatalog,
    plan: ReversibleVerificationPlan,
    sessionSeed: PrivateSessionSeed?,
    verifiedAt: String,
    beforeIdentities: [String],
    beforeDigest: String,
    targetIdentity: String,
    result: ReversibleVerificationResult? = nil
  ) {
    schemaVersion = 1
    kind = "web-api-reverse.reversible-verification-transaction"
    self.phase = phase
    self.catalog = catalog
    self.plan = plan
    self.sessionSeed = sessionSeed
    self.verifiedAt = verifiedAt
    self.beforeIdentities = beforeIdentities
    self.beforeDigest = beforeDigest
    self.targetIdentity = targetIdentity
    self.result = result
  }

  func updating(
    phase: ReversibleVerificationTransactionPhase
  ) -> Self {
    Self(
      phase: phase,
      catalog: catalog,
      plan: plan,
      sessionSeed: sessionSeed,
      verifiedAt: verifiedAt,
      beforeIdentities: beforeIdentities,
      beforeDigest: beforeDigest,
      targetIdentity: targetIdentity,
      result: result
    )
  }

  func completing(_ result: ReversibleVerificationResult) -> Self {
    Self(
      phase: .completed,
      catalog: catalog,
      plan: plan,
      sessionSeed: sessionSeed,
      verifiedAt: verifiedAt,
      beforeIdentities: beforeIdentities,
      beforeDigest: beforeDigest,
      targetIdentity: targetIdentity,
      result: result
    )
  }
}
