import Foundation

public enum ReversibleVerificationPhase:
  String,
  Codable,
  Equatable,
  Sendable
{
  case readBefore = "read-before"
  case add
  case readMutated = "read-mutated"
  case remove
  case readRestored = "read-restored"
}

public struct ReversibleIdentityProjection:
  Codable,
  Equatable,
  Sendable
{
  public let path: String
  public let missingValue: JSONValue?

  public init(
    path: String,
    missingValue: JSONValue? = nil
  ) {
    self.path = path
    self.missingValue = missingValue
  }
}

public struct ReversibleTextCollectionProjection:
  Codable,
  Equatable,
  Sendable
{
  public let pattern: String
  public let identityCaptureGroups: [Int]

  public init(
    pattern: String,
    identityCaptureGroups: [Int]
  ) {
    self.pattern = pattern
    self.identityCaptureGroups = identityCaptureGroups
  }
}

public struct ReversibleCollectionProjection:
  Codable,
  Equatable,
  Sendable
{
  public let collectionPointer: String
  public let identityPointers: [ReversibleIdentityProjection]
  public let intendedIdentity: [JSONValue]
  public let textCollection: ReversibleTextCollectionProjection?

  public init(
    collectionPointer: String,
    identityPointers: [ReversibleIdentityProjection],
    intendedIdentity: [JSONValue],
    textCollection: ReversibleTextCollectionProjection? = nil
  ) {
    self.collectionPointer = collectionPointer
    self.identityPointers = identityPointers
    self.intendedIdentity = intendedIdentity
    self.textCollection = textCollection
  }
}

public struct ReversibleVerificationStep:
  Codable,
  Equatable,
  Sendable
{
  public let operationId: String
  public let request: PrivateVerificationRequestSpec

  public init(
    operationId: String,
    request: PrivateVerificationRequestSpec
  ) {
    self.operationId = operationId
    self.request = request
  }
}

public struct ReversibleVerificationPlan:
  Codable,
  Equatable,
  Sendable
{
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let readBefore: ReversibleVerificationStep
  public let add: ReversibleVerificationStep
  public let readMutated: ReversibleVerificationStep
  public let remove: ReversibleVerificationStep
  public let readRestored: ReversibleVerificationStep
  public let stateProjection: ReversibleCollectionProjection

  public init(
    provider: String,
    market: String,
    readBefore: ReversibleVerificationStep,
    add: ReversibleVerificationStep,
    readMutated: ReversibleVerificationStep,
    remove: ReversibleVerificationStep,
    readRestored: ReversibleVerificationStep,
    stateProjection: ReversibleCollectionProjection,
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.reversible-verification-plan"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.provider = provider
    self.market = market
    self.readBefore = readBefore
    self.add = add
    self.readMutated = readMutated
    self.remove = remove
    self.readRestored = readRestored
    self.stateProjection = stateProjection
  }
}

public struct ReversibleVerificationOperationIDs:
  Codable,
  Equatable,
  Sendable
{
  public let readBefore: String
  public let add: String
  public let readMutated: String
  public let remove: String
  public let readRestored: String
}

public struct ReversibleVerificationReceiptIDs:
  Codable,
  Equatable,
  Sendable
{
  public let readBefore: String
  public let add: String
  public let readMutated: String
  public let remove: String
  public let readRestored: String
}

public struct ReversibleProjectedStateReceipt:
  Codable,
  Equatable,
  Sendable
{
  public let beforeSHA256: String
  public let mutatedSHA256: String
  public let restoredSHA256: String
  public let changedIdentitySHA256: String
  public let changedIdentityCount: Int
  public let beforeCount: Int
  public let mutatedCount: Int
  public let restoredCount: Int
}

public struct ReversibleSequenceRestoration:
  Codable,
  Equatable,
  Sendable
{
  public let required: Bool
  public let proven: Bool
}

public struct ReversibleVerificationSequenceReceipt:
  Codable,
  Equatable,
  Sendable
{
  public let schemaVersion: Int
  public let kind: String
  public let sequenceId: String
  public let verifiedAt: String
  public let provider: String
  public let market: String
  public let operationIds: ReversibleVerificationOperationIDs
  public let verificationIds: ReversibleVerificationReceiptIDs
  public let collectionPointer: String
  public let identityPointers: [ReversibleIdentityProjection]
  public let textPatternSHA256: String?
  public let textIdentityCaptureGroups: [Int]?
  public let state: ReversibleProjectedStateReceipt
  public let restoration: ReversibleSequenceRestoration

  public init(
    sequenceId: String,
    verifiedAt: String,
    provider: String,
    market: String,
    operationIds: ReversibleVerificationOperationIDs,
    verificationIds: ReversibleVerificationReceiptIDs,
    collectionPointer: String,
    identityPointers: [ReversibleIdentityProjection],
    textPatternSHA256: String? = nil,
    textIdentityCaptureGroups: [Int]? = nil,
    state: ReversibleProjectedStateReceipt,
    schemaVersion: Int = 1,
    kind: String = "web-api-reverse.reversible-verification-sequence"
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.sequenceId = sequenceId
    self.verifiedAt = verifiedAt
    self.provider = provider
    self.market = market
    self.operationIds = operationIds
    self.verificationIds = verificationIds
    self.collectionPointer = collectionPointer
    self.identityPointers = identityPointers
    self.textPatternSHA256 = textPatternSHA256
    self.textIdentityCaptureGroups = textIdentityCaptureGroups
    self.state = state
    self.restoration = ReversibleSequenceRestoration(
      required: true,
      proven: true
    )
  }
}

public struct ReversibleVerificationReceipts:
  Codable,
  Equatable,
  Sendable
{
  public let readBefore: TrustVerificationReceipt
  public let add: TrustVerificationReceipt
  public let readMutated: TrustVerificationReceipt
  public let remove: TrustVerificationReceipt
  public let readRestored: TrustVerificationReceipt
}

public struct ReversibleVerificationResult:
  Codable,
  Equatable,
  Sendable
{
  public let sequence: ReversibleVerificationSequenceReceipt
  public let receipts: ReversibleVerificationReceipts
}

public enum ReversibleVerificationError:
  Error,
  Equatable,
  LocalizedError
{
  case allowRemoteWriteRequired
  case invalidPlan(String)
  case scopeMismatch(String)
  case observedOperationMissing(String)
  case observedOperationAmbiguous(String)
  case readMustBeSafe(ReversibleVerificationPhase)
  case highRiskMutationRejected(ReversibleVerificationPhase)
  case mutationMustBeReversible(ReversibleVerificationPhase)
  case requestShapeMismatch(
    phase: ReversibleVerificationPhase,
    fields: [String]
  )
  case unsuccessfulResponse(ReversibleVerificationPhase)
  case responseBodyMissing(ReversibleVerificationPhase)
  case projectionPathMissing(String)
  case projectionNotCollection(String)
  case identityValueNotScalar(String)
  case duplicateProjectedIdentity
  case intendedIdentityAlreadyPresent
  case mutationIdentityMismatch
  case restorationStateMismatch
  case restorationFailed(primary: String?, reason: String)
  case durableSecretMaterial
  case transactionStoreRequired
  case invalidTransactionCheckpoint
  case transactionInputMismatch
  case pendingTransactionReconciled
  case pendingTransactionRecoveryRequired(String)

  public var errorDescription: String? {
    switch self {
    case .allowRemoteWriteRequired:
      "Reversible verification requires explicit allowRemoteWrite approval."
    case .invalidPlan(let reason):
      "Invalid reversible verification plan: \(reason)"
    case .scopeMismatch(let scope):
      "Reversible verification scope does not match: \(scope)"
    case .observedOperationMissing(let operationId):
      "Observed operation not found: \(operationId)"
    case .observedOperationAmbiguous(let operationId):
      "Observed operation ID is ambiguous: \(operationId)"
    case .readMustBeSafe(let phase):
      "\(phase.rawValue) must use a safe-read operation."
    case .highRiskMutationRejected(let phase):
      "\(phase.rawValue) is high-risk and cannot be verified."
    case .mutationMustBeReversible(let phase):
      "\(phase.rawValue) must be classified as reversible-write."
    case .requestShapeMismatch(let phase, let fields):
      "\(phase.rawValue) request shape differs from Observed fields: "
        + fields.joined(separator: ", ")
    case .unsuccessfulResponse(let phase):
      "\(phase.rawValue) did not produce a successful business response."
    case .responseBodyMissing(let phase):
      "\(phase.rawValue) did not produce a JSON response body."
    case .projectionPathMissing(let path):
      "Projection path does not exist: \(path)"
    case .projectionNotCollection(let path):
      "Projection path does not resolve to an array: \(path)"
    case .identityValueNotScalar(let path):
      "Projected identity value must be a non-null scalar: \(path)"
    case .duplicateProjectedIdentity:
      "Projected remote state contains duplicate identities."
    case .intendedIdentityAlreadyPresent:
      "The intended identity already exists before the add operation."
    case .mutationIdentityMismatch:
      "The add operation did not change exactly the intended identity."
    case .restorationStateMismatch:
      "The final projected collection does not equal the preflight state."
    case .restorationFailed(let primary, let reason):
      if let primary {
        "Verification failed (\(primary)); restoration also failed: \(reason)"
      } else {
        "Restoration failed: \(reason)"
      }
    case .durableSecretMaterial:
      "Reversible verification receipts contain secret or personal material."
    case .transactionStoreRequired:
      "Reversible verification requires a durable private transaction store."
    case .invalidTransactionCheckpoint:
      "The durable reversible verification checkpoint is invalid."
    case .transactionInputMismatch:
      "The durable reversible verification checkpoint belongs to different inputs."
    case .pendingTransactionReconciled:
      "A pending reversible write was reconciled; rerun to start a new verification."
    case .pendingTransactionRecoveryRequired(let reason):
      "A pending reversible write could not be reconciled: \(reason)"
    }
  }
}

public struct ReversibleOperationVerifier: Sendable {
  private let executor: any VerificationHTTPExecuting

  public init(
    executor: any VerificationHTTPExecuting = URLSessionVerificationExecutor()
  ) {
    self.executor = executor
  }

  public func verify(
    catalog: ObservedCatalog,
    plan: ReversibleVerificationPlan,
    sessionSeed: PrivateSessionSeed? = nil,
    allowRemoteWrite: Bool = false,
    verifiedAt: String = ISO8601DateFormatter().string(from: Date()),
    transactionStore: ReversibleVerificationTransactionStore? = nil
  ) async throws -> ReversibleVerificationResult {
    guard allowRemoteWrite else {
      throw ReversibleVerificationError.allowRemoteWriteRequired
    }
    let resolvedPlan = try resolve(plan: plan, from: catalog)
    try preflight(plan: resolvedPlan, sessionSeed: sessionSeed)
    guard let transactionStore else {
      throw ReversibleVerificationError.transactionStoreRequired
    }
    return try await transactionStore.withExclusiveLock {
      try await verifyLocked(
        catalog: catalog,
        plan: plan,
        resolvedPlan: resolvedPlan,
        sessionSeed: sessionSeed,
        verifiedAt: verifiedAt,
        transactionStore: transactionStore
      )
    }
  }

  private func verifyLocked(
    catalog: ObservedCatalog,
    plan: ReversibleVerificationPlan,
    resolvedPlan: ResolvedReversiblePlan,
    sessionSeed: PrivateSessionSeed?,
    verifiedAt: String,
    transactionStore: ReversibleVerificationTransactionStore
  ) async throws -> ReversibleVerificationResult {
    if let checkpoint = try transactionStore.load() {
      if checkpoint.phase == .completed,
        let result = checkpoint.result,
        checkpoint.catalog == catalog,
        checkpoint.plan == plan,
        checkpoint.sessionSeed == sessionSeed,
        result.sequence.provider == checkpoint.plan.provider,
        result.sequence.market == checkpoint.plan.market
      {
        return result
      }
      if checkpoint.phase == .completed {
        throw ReversibleVerificationError.transactionInputMismatch
      }
      try await reconcile(
        checkpoint,
        transactionStore: transactionStore
      )
      throw ReversibleVerificationError.pendingTransactionReconciled
    }

    let native = NativeOperationVerifier(executor: executor)
    let beforeResult = try await native.verify(
      operation: resolvedPlan.readBefore.operation,
      requestSpec: resolvedPlan.readBefore.request,
      sessionSeed: sessionSeed,
      verifiedAt: verifiedAt
    )
    try requireSuccess(beforeResult, phase: .readBefore)
    let before = try project(
      result: beforeResult,
      phase: .readBefore,
      projection: plan.stateProjection
    )
    let targetIdentity = try canonicalIdentity(
      plan.stateProjection.intendedIdentity,
      paths: plan.stateProjection.identityPointers.map(\.path)
    )
    guard !before.identities.contains(targetIdentity) else {
      throw ReversibleVerificationError.intendedIdentityAlreadyPresent
    }
    var checkpoint = ReversibleVerificationCheckpoint(
      phase: .prepared,
      catalog: catalog,
      plan: plan,
      sessionSeed: sessionSeed,
      verifiedAt: verifiedAt,
      beforeIdentities: before.identities,
      beforeDigest: before.digest,
      targetIdentity: targetIdentity
    )
    try transactionStore.save(checkpoint)

    let addProbe = AttemptTrackingExecutor(base: executor)
    var addResult: NativeVerificationResult?
    var mutatedReadResult: NativeVerificationResult?
    var mutatedState: ProjectedCollectionState?
    var primaryFailure: Error?

    do {
      checkpoint = checkpoint.updating(phase: .addDispatchUnknown)
      try transactionStore.save(checkpoint)
      let result = try await NativeOperationVerifier(
        executor: addProbe
      ).verifyReversibleTransactionStep(
        operation: resolvedPlan.add.operation,
        requestSpec: resolvedPlan.add.request,
        sessionSeed: sessionSeed,
        verifiedAt: verifiedAt
      )
      try requireSuccess(result, phase: .add)
      addResult = result
      checkpoint = checkpoint.updating(phase: .addConfirmed)
      try transactionStore.save(checkpoint)

      let readResult = try await native.verify(
        operation: resolvedPlan.readMutated.operation,
        requestSpec: resolvedPlan.readMutated.request,
        sessionSeed: sessionSeed,
        verifiedAt: verifiedAt
      )
      try requireSuccess(readResult, phase: .readMutated)
      let projected = try project(
        result: readResult,
        phase: .readMutated,
        projection: plan.stateProjection
      )
      try requireSingleAddition(
        before: before,
        mutated: projected,
        targetIdentity: targetIdentity
      )
      mutatedReadResult = readResult
      mutatedState = projected
    } catch {
      primaryFailure = error
    }

    guard await addProbe.didExecute else {
      try transactionStore.clear()
      throw primaryFailure
        ?? ReversibleVerificationError.invalidPlan(
          "the add verifier did not reach the transport"
        )
    }

    checkpoint = checkpoint.updating(phase: .restoreDispatchUnknown)
    try transactionStore.save(checkpoint)
    let cleanup = await restore(
      plan: resolvedPlan,
      before: before,
      sessionSeed: sessionSeed,
      verifiedAt: verifiedAt
    )

    if let primaryFailure {
      if cleanup.stateRestored {
        try transactionStore.clear()
        throw primaryFailure
      }
      throw ReversibleVerificationError.restorationFailed(
        primary: String(describing: primaryFailure),
        reason: cleanup.failureDescription
      )
    }

    guard let addResult,
      let mutatedReadResult,
      let mutatedState
    else {
      throw ReversibleVerificationError.invalidPlan(
        "the mutation phase did not produce complete evidence"
      )
    }
    guard cleanup.isFullyVerified,
      let removeResult = cleanup.removeResult,
      let restoredReadResult = cleanup.readResult,
      let restoredState = cleanup.state
    else {
      throw ReversibleVerificationError.restorationFailed(
        primary: nil,
        reason: cleanup.failureDescription
      )
    }

    try requireExactRestoration(
      before: before,
      mutated: mutatedState,
      restored: restoredState,
      targetIdentity: targetIdentity
    )
    let result = try makeResult(
      plan: resolvedPlan,
      verifiedAt: verifiedAt,
      beforeResult: beforeResult,
      addResult: addResult,
      mutatedReadResult: mutatedReadResult,
      removeResult: removeResult,
      restoredReadResult: restoredReadResult,
      before: before,
      mutated: mutatedState,
      restored: restoredState,
      targetIdentity: targetIdentity
    )
    try transactionStore.save(checkpoint.completing(result))
    return result
  }

  private func resolve(
    plan: ReversibleVerificationPlan,
    from catalog: ObservedCatalog
  ) throws -> ResolvedReversiblePlan {
    guard plan.schemaVersion == 1,
      plan.kind == "web-api-reverse.reversible-verification-plan"
    else {
      throw ReversibleVerificationError.invalidPlan(
        "unsupported schemaVersion or kind"
      )
    }
    guard catalog.schemaVersion == 1,
      catalog.kind == "web-api-reverse.observed-catalog"
    else {
      throw ReversibleVerificationError.invalidPlan(
        "unsupported Observed catalog schemaVersion or kind"
      )
    }
    guard !plan.provider.isEmpty, !plan.market.isEmpty else {
      throw ReversibleVerificationError.invalidPlan(
        "provider and market are required"
      )
    }
    guard plan.provider == catalog.brand,
      plan.market == catalog.market
    else {
      throw ReversibleVerificationError.scopeMismatch(
        "plan \(plan.provider)/\(plan.market) "
          + "vs catalog \(catalog.brand)/\(catalog.market)"
      )
    }

    func step(
      _ value: ReversibleVerificationStep
    ) throws -> ResolvedReversibleStep {
      let matches = catalog.operations.filter {
        $0.operationId == value.operationId
      }
      guard !matches.isEmpty else {
        throw ReversibleVerificationError.observedOperationMissing(
          value.operationId
        )
      }
      guard matches.count == 1, let operation = matches.first else {
        throw ReversibleVerificationError.observedOperationAmbiguous(
          value.operationId
        )
      }
      return ResolvedReversibleStep(
        operation: operation,
        request: value.request
      )
    }

    return ResolvedReversiblePlan(
      provider: plan.provider,
      market: plan.market,
      readBefore: try step(plan.readBefore),
      add: try step(plan.add),
      readMutated: try step(plan.readMutated),
      remove: try step(plan.remove),
      readRestored: try step(plan.readRestored),
      stateProjection: plan.stateProjection
    )
  }

  private func preflight(
    plan: ResolvedReversiblePlan,
    sessionSeed: PrivateSessionSeed?
  ) throws {
    if let sessionSeed,
      sessionSeed.brand != plan.provider
        || sessionSeed.market != plan.market
    {
      throw ReversibleVerificationError.scopeMismatch(
        "session \(sessionSeed.brand)/\(sessionSeed.market) "
          + "vs plan \(plan.provider)/\(plan.market)"
      )
    }
    try validateProjection(plan.stateProjection)

    let readSteps: [(ReversibleVerificationPhase, ResolvedReversibleStep)] = [
      (.readBefore, plan.readBefore),
      (.readMutated, plan.readMutated),
      (.readRestored, plan.readRestored),
    ]
    for (phase, step) in readSteps {
      guard step.operation.safety == .safeRead else {
        throw ReversibleVerificationError.readMustBeSafe(phase)
      }
      try preflight(
        step: step,
        phase: phase,
        provider: plan.provider,
        market: plan.market,
        sessionSeed: sessionSeed
      )
    }

    let mutationSteps: [(ReversibleVerificationPhase, ResolvedReversibleStep)] = [
      (.add, plan.add),
      (.remove, plan.remove),
    ]
    for (phase, step) in mutationSteps {
      if step.operation.safety == .highRiskWrite {
        throw ReversibleVerificationError.highRiskMutationRejected(phase)
      }
      guard step.operation.safety == .reversibleWrite else {
        throw ReversibleVerificationError.mutationMustBeReversible(phase)
      }
      try preflight(
        step: step,
        phase: phase,
        provider: plan.provider,
        market: plan.market,
        sessionSeed: sessionSeed
      )
    }
  }

  private func preflight(
    step: ResolvedReversibleStep,
    phase: ReversibleVerificationPhase,
    provider: String,
    market: String,
    sessionSeed: PrivateSessionSeed?
  ) throws {
    let request = step.request
    guard request.schemaVersion == 1,
      request.kind == "web-api-reverse.private-verification-request"
        || request.kind == "lifewear.verification-request"
    else {
      throw ReversibleVerificationError.invalidPlan(
        "\(phase.rawValue) has an unsupported request schema or kind"
      )
    }
    guard request.brand == provider, request.market == market else {
      throw ReversibleVerificationError.scopeMismatch(
        "\(phase.rawValue) request \(request.brand)/\(request.market) "
          + "vs plan \(provider)/\(market)"
      )
    }
    guard
      request.safety == nil
        || request.safety == step.operation.safety
    else {
      throw ReversibleVerificationError.invalidPlan(
        "\(phase.rawValue) request safety does not match its operation"
      )
    }

    do {
      _ = try NativeOperationVerifier(executor: executor).prepare(
        operation: step.operation,
        requestSpec: request,
        sessionSeed: sessionSeed,
        allowRemoteWrite: true
      )
    } catch NativeVerificationError.requestShapeMismatch(let fields) {
      throw ReversibleVerificationError.requestShapeMismatch(
        phase: phase,
        fields: fields
      )
    }
  }

  private func validateProjection(
    _ projection: ReversibleCollectionProjection
  ) throws {
    guard projection.collectionPointer.hasPrefix("/") else {
      throw ReversibleVerificationError.invalidPlan(
        "collectionPointer must be a non-empty JSON Pointer"
      )
    }
    guard !projection.identityPointers.isEmpty,
      projection.identityPointers.count
        == projection.intendedIdentity.count
    else {
      throw ReversibleVerificationError.invalidPlan(
        "identity pointers and intended identity must have equal nonzero counts"
      )
    }
    for identity in projection.identityPointers {
      guard identity.path.hasPrefix("/") else {
        throw ReversibleVerificationError.invalidPlan(
          "identity pointer must be a non-empty JSON Pointer"
        )
      }
      if let missingValue = identity.missingValue {
        try requireScalar(missingValue, path: identity.path)
      }
    }
    if let textCollection = projection.textCollection {
      guard
        !textCollection.pattern.isEmpty,
        textCollection.identityCaptureGroups.count
          == projection.identityPointers.count,
        textCollection.identityCaptureGroups.allSatisfy({ $0 > 0 })
      else {
        throw ReversibleVerificationError.invalidPlan(
          "text collection capture groups must match the identity projection"
        )
      }
      let expression: NSRegularExpression
      do {
        expression = try NSRegularExpression(
          pattern: textCollection.pattern
        )
      } catch {
        throw ReversibleVerificationError.invalidPlan(
          "text collection pattern is not a valid regular expression"
        )
      }
      guard
        textCollection.identityCaptureGroups.allSatisfy({
          $0 <= expression.numberOfCaptureGroups
        })
      else {
        throw ReversibleVerificationError.invalidPlan(
          "text collection capture group is outside the pattern"
        )
      }
    }
    _ = try canonicalIdentity(
      projection.intendedIdentity,
      paths: projection.identityPointers.map(\.path)
    )
  }

  private func requireSuccess(
    _ result: NativeVerificationResult,
    phase: ReversibleVerificationPhase
  ) throws {
    let response = result.receipt.response
    guard (200..<300).contains(response.status),
      response.status != 401,
      response.status != 403,
      response.outcome == .success
    else {
      throw ReversibleVerificationError.unsuccessfulResponse(phase)
    }
  }

  private func project(
    result: NativeVerificationResult,
    phase: ReversibleVerificationPhase,
    projection: ReversibleCollectionProjection
  ) throws -> ProjectedCollectionState {
    guard let body = result.privateResponse.body else {
      throw ReversibleVerificationError.responseBodyMissing(phase)
    }
    if let textCollection = projection.textCollection {
      return try projectTextCollection(
        body: body,
        projection: projection,
        textCollection: textCollection
      )
    }
    let value = try pointer(
      body,
      rawPointer: projection.collectionPointer
    )
    guard case .array(let collection) = value else {
      throw ReversibleVerificationError.projectionNotCollection(
        projection.collectionPointer
      )
    }
    var identities: [String] = []
    for item in collection {
      let values = try projection.identityPointers.map { identity in
        do {
          return try pointer(item, rawPointer: identity.path)
        } catch ReversibleVerificationError.projectionPathMissing {
          if let missingValue = identity.missingValue {
            return missingValue
          }
          throw ReversibleVerificationError.projectionPathMissing(
            identity.path
          )
        }
      }
      identities.append(
        try canonicalIdentity(
          values,
          paths: projection.identityPointers.map(\.path)
        )
      )
    }
    identities.sort()
    guard Set(identities).count == identities.count else {
      throw ReversibleVerificationError.duplicateProjectedIdentity
    }
    let digest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(
        .array(identities.map(JSONValue.string))
      )
    )
    return ProjectedCollectionState(
      identities: identities,
      digest: digest
    )
  }

  private func projectTextCollection(
    body: JSONValue,
    projection: ReversibleCollectionProjection,
    textCollection: ReversibleTextCollectionProjection
  ) throws -> ProjectedCollectionState {
    guard case .string(let text) = body else {
      throw ReversibleVerificationError.projectionNotCollection(
        projection.collectionPointer
      )
    }
    let expression: NSRegularExpression
    do {
      expression = try NSRegularExpression(
        pattern: textCollection.pattern
      )
    } catch {
      throw ReversibleVerificationError.invalidPlan(
        "text collection pattern is not a valid regular expression"
      )
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let source = text as NSString
    var identities: [String] = []
    for match in expression.matches(in: text, range: range) {
      let values = try textCollection.identityCaptureGroups
        .enumerated()
        .map { index, captureGroup -> JSONValue in
          let captureRange = match.range(at: captureGroup)
          guard captureRange.location != NSNotFound else {
            throw
              ReversibleVerificationError
              .projectionPathMissing(
                projection.identityPointers[index].path
              )
          }
          return .string(source.substring(with: captureRange))
        }
      identities.append(
        try canonicalIdentity(
          values,
          paths: projection.identityPointers.map(\.path)
        )
      )
    }
    identities.sort()
    guard Set(identities).count == identities.count else {
      throw ReversibleVerificationError.duplicateProjectedIdentity
    }
    let digest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(
        .array(identities.map(JSONValue.string))
      )
    )
    return ProjectedCollectionState(
      identities: identities,
      digest: digest
    )
  }

  private func canonicalIdentity(
    _ values: [JSONValue],
    paths: [String]
  ) throws -> String {
    guard values.count == paths.count else {
      throw ReversibleVerificationError.invalidPlan(
        "identity value and pointer counts differ"
      )
    }
    for (index, value) in values.enumerated() {
      try requireScalar(value, path: paths[index])
    }
    return try CanonicalEvidenceJSON.string(.array(values))
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func requireScalar(
    _ value: JSONValue,
    path: String
  ) throws {
    switch value {
    case .string, .number, .bool:
      return
    case .object, .array, .null:
      throw ReversibleVerificationError.identityValueNotScalar(path)
    }
  }

  private func pointer(
    _ value: JSONValue,
    rawPointer: String
  ) throws -> JSONValue {
    guard rawPointer.hasPrefix("/") else {
      throw ReversibleVerificationError.invalidPlan(
        "invalid JSON Pointer: \(rawPointer)"
      )
    }
    var current = value
    for rawComponent in rawPointer.dropFirst().split(
      separator: "/",
      omittingEmptySubsequences: false
    ) {
      let component =
        rawComponent
        .replacingOccurrences(of: "~1", with: "/")
        .replacingOccurrences(of: "~0", with: "~")
      switch current {
      case .object(let object):
        guard let next = object[component] else {
          throw ReversibleVerificationError.projectionPathMissing(
            rawPointer
          )
        }
        current = next
      case .array(let array):
        guard let index = Int(component),
          index >= 0,
          index < array.count
        else {
          throw ReversibleVerificationError.projectionPathMissing(
            rawPointer
          )
        }
        current = array[index]
      case .string, .number, .bool, .null:
        throw ReversibleVerificationError.projectionPathMissing(
          rawPointer
        )
      }
    }
    return current
  }

  private func requireSingleAddition(
    before: ProjectedCollectionState,
    mutated: ProjectedCollectionState,
    targetIdentity: String
  ) throws {
    let beforeSet = Set(before.identities)
    let mutatedSet = Set(mutated.identities)
    let added = mutatedSet.subtracting(beforeSet)
    let removed = beforeSet.subtracting(mutatedSet)
    guard added == Set([targetIdentity]), removed.isEmpty else {
      throw ReversibleVerificationError.mutationIdentityMismatch
    }
  }

  private func requireExactRestoration(
    before: ProjectedCollectionState,
    mutated: ProjectedCollectionState,
    restored: ProjectedCollectionState,
    targetIdentity: String
  ) throws {
    guard before.digest == restored.digest,
      before.identities == restored.identities
    else {
      throw ReversibleVerificationError.restorationStateMismatch
    }
    let mutatedSet = Set(mutated.identities)
    let restoredSet = Set(restored.identities)
    guard mutatedSet.subtracting(restoredSet) == Set([targetIdentity]),
      restoredSet.subtracting(mutatedSet).isEmpty
    else {
      throw ReversibleVerificationError.restorationStateMismatch
    }
  }

  private func reconcile(
    _ checkpoint: ReversibleVerificationCheckpoint,
    transactionStore: ReversibleVerificationTransactionStore
  ) async throws {
    do {
      let resolved = try resolve(
        plan: checkpoint.plan,
        from: checkpoint.catalog
      )
      try preflight(
        plan: resolved,
        sessionSeed: checkpoint.sessionSeed
      )
      let native = NativeOperationVerifier(executor: executor)
      let currentResult = try await native.verify(
        operation: resolved.readRestored.operation,
        requestSpec: resolved.readRestored.request,
        sessionSeed: checkpoint.sessionSeed,
        verifiedAt: checkpoint.verifiedAt
      )
      try requireSuccess(currentResult, phase: .readRestored)
      let current = try project(
        result: currentResult,
        phase: .readRestored,
        projection: checkpoint.plan.stateProjection
      )
      let before = ProjectedCollectionState(
        identities: checkpoint.beforeIdentities,
        digest: checkpoint.beforeDigest
      )
      let isExactBefore = current.identities == before.identities
        && current.digest == before.digest

      switch checkpoint.phase {
      case .prepared:
        guard isExactBefore else {
          throw ReversibleVerificationError.restorationStateMismatch
        }
        try transactionStore.clear()
        return
      case .addDispatchUnknown:
        guard isExactBefore else {
          throw ReversibleVerificationError.invalidPlan(
            "add dispatch outcome is ambiguous; automatic deletion is unsafe"
          )
        }
        try transactionStore.clear()
        return
      case .addConfirmed, .restoreDispatchUnknown:
        guard current.identities.contains(checkpoint.targetIdentity) else {
          try transactionStore.clear()
          return
        }
      case .completed:
        throw ReversibleVerificationError.invalidTransactionCheckpoint
      }
      let cleanup = await restore(
        plan: resolved,
        before: before,
        sessionSeed: checkpoint.sessionSeed,
        verifiedAt: checkpoint.verifiedAt
      )
      guard cleanup.stateRestored else {
        throw ReversibleVerificationError.restorationFailed(
          primary: "interrupted reversible verification",
          reason: cleanup.failureDescription
        )
      }
      try transactionStore.clear()
    } catch let error as ReversibleVerificationError {
      if error == .pendingTransactionReconciled {
        throw error
      }
      throw ReversibleVerificationError.pendingTransactionRecoveryRequired(
        String(describing: error)
      )
    } catch {
      throw ReversibleVerificationError.pendingTransactionRecoveryRequired(
        String(describing: error)
      )
    }
  }

  private func restore(
    plan: ResolvedReversiblePlan,
    before: ProjectedCollectionState,
    sessionSeed: PrivateSessionSeed?,
    verifiedAt: String
  ) async -> CleanupResult {
    let native = NativeOperationVerifier(executor: executor)
    var removeResult: NativeVerificationResult?
    var removeFailure: Error?
    do {
      let result = try await native.verifyReversibleTransactionStep(
        operation: plan.remove.operation,
        requestSpec: plan.remove.request,
        sessionSeed: sessionSeed,
        verifiedAt: verifiedAt
      )
      try requireSuccess(result, phase: .remove)
      removeResult = result
    } catch {
      removeFailure = error
    }

    var readResult: NativeVerificationResult?
    var state: ProjectedCollectionState?
    var readFailure: Error?
    do {
      let result = try await native.verify(
        operation: plan.readRestored.operation,
        requestSpec: plan.readRestored.request,
        sessionSeed: sessionSeed,
        verifiedAt: verifiedAt
      )
      try requireSuccess(result, phase: .readRestored)
      let projected = try project(
        result: result,
        phase: .readRestored,
        projection: plan.stateProjection
      )
      readResult = result
      state = projected
      if projected.digest != before.digest
        || projected.identities != before.identities
      {
        readFailure = ReversibleVerificationError.restorationStateMismatch
      }
    } catch {
      readFailure = error
    }

    return CleanupResult(
      removeResult: removeResult,
      readResult: readResult,
      state: state,
      removeFailure: removeFailure,
      readFailure: readFailure
    )
  }

  private func makeResult(
    plan: ResolvedReversiblePlan,
    verifiedAt: String,
    beforeResult: NativeVerificationResult,
    addResult: NativeVerificationResult,
    mutatedReadResult: NativeVerificationResult,
    removeResult: NativeVerificationResult,
    restoredReadResult: NativeVerificationResult,
    before: ProjectedCollectionState,
    mutated: ProjectedCollectionState,
    restored: ProjectedCollectionState,
    targetIdentity: String
  ) throws -> ReversibleVerificationResult {
    let changedIdentitySHA256 = FileDigest.sha256(
      data: Data(targetIdentity.utf8)
    )
    let sequenceIdentity: JSONValue = .object([
      "provider": .string(plan.provider),
      "market": .string(plan.market),
      "verifiedAt": .string(verifiedAt),
      "operationIds": .array(
        [
          plan.readBefore.operation.operationId,
          plan.add.operation.operationId,
          plan.readMutated.operation.operationId,
          plan.remove.operation.operationId,
          plan.readRestored.operation.operationId,
        ].map(JSONValue.string)),
      "verificationIds": .array(
        [
          beforeResult.receipt.verificationId,
          addResult.receipt.verificationId,
          mutatedReadResult.receipt.verificationId,
          removeResult.receipt.verificationId,
          restoredReadResult.receipt.verificationId,
        ].map(JSONValue.string)),
      "stateHashes": .array(
        [
          before.digest,
          mutated.digest,
          restored.digest,
        ].map(JSONValue.string)),
      "changedIdentitySHA256": .string(changedIdentitySHA256),
    ])
    let sequenceDigest = FileDigest.sha256(
      data: try CanonicalEvidenceJSON.data(sequenceIdentity)
    )
    let sequenceId = "rev_\(sequenceDigest.prefix(16))"
    let readBeforeReceipt = withVerificationId(
      beforeResult.receipt,
      verificationId: derivedReceiptId(
        base: beforeResult.receipt.verificationId,
        role: ReversibleVerificationPhase.readBefore.rawValue,
        sequenceId: sequenceId
      )
    )
    let readMutatedReceipt = withVerificationId(
      mutatedReadResult.receipt,
      verificationId: derivedReceiptId(
        base: mutatedReadResult.receipt.verificationId,
        role: ReversibleVerificationPhase.readMutated.rawValue,
        sequenceId: sequenceId
      )
    )
    let readRestoredReceipt = withVerificationId(
      restoredReadResult.receipt,
      verificationId: derivedReceiptId(
        base: restoredReadResult.receipt.verificationId,
        role: ReversibleVerificationPhase.readRestored.rawValue,
        sequenceId: sequenceId
      )
    )
    let addReceiptId = derivedReceiptId(
      base: addResult.receipt.verificationId,
      role: "add",
      sequenceId: sequenceId
    )
    let removeReceiptId = derivedReceiptId(
      base: removeResult.receipt.verificationId,
      role: "remove",
      sequenceId: sequenceId
    )
    let commonProof = (
      before: before.digest,
      mutated: mutated.digest,
      restored: restored.digest,
      changed: changedIdentitySHA256
    )
    let addProof = TrustRestorationProof(
      required: true,
      proven: true,
      receiptId: removeReceiptId,
      beforeStateSHA256: commonProof.before,
      mutatedStateSHA256: commonProof.mutated,
      restoredStateSHA256: commonProof.restored,
      changedIdentitySHA256: commonProof.changed,
      changedIdentityCount: 1
    )
    let removeProof = TrustRestorationProof(
      required: true,
      proven: true,
      receiptId: addReceiptId,
      beforeStateSHA256: commonProof.before,
      mutatedStateSHA256: commonProof.mutated,
      restoredStateSHA256: commonProof.restored,
      changedIdentitySHA256: commonProof.changed,
      changedIdentityCount: 1
    )
    let addReceipt = withRestoration(
      addResult.receipt,
      verificationId: addReceiptId,
      proof: addProof
    )
    let removeReceipt = withRestoration(
      removeResult.receipt,
      verificationId: removeReceiptId,
      proof: removeProof
    )
    let state = ReversibleProjectedStateReceipt(
      beforeSHA256: before.digest,
      mutatedSHA256: mutated.digest,
      restoredSHA256: restored.digest,
      changedIdentitySHA256: changedIdentitySHA256,
      changedIdentityCount: 1,
      beforeCount: before.identities.count,
      mutatedCount: mutated.identities.count,
      restoredCount: restored.identities.count
    )
    let sequence = ReversibleVerificationSequenceReceipt(
      sequenceId: sequenceId,
      verifiedAt: verifiedAt,
      provider: plan.provider,
      market: plan.market,
      operationIds: ReversibleVerificationOperationIDs(
        readBefore: plan.readBefore.operation.operationId,
        add: plan.add.operation.operationId,
        readMutated: plan.readMutated.operation.operationId,
        remove: plan.remove.operation.operationId,
        readRestored: plan.readRestored.operation.operationId
      ),
      verificationIds: ReversibleVerificationReceiptIDs(
        readBefore: readBeforeReceipt.verificationId,
        add: addReceipt.verificationId,
        readMutated: readMutatedReceipt.verificationId,
        remove: removeReceipt.verificationId,
        readRestored: readRestoredReceipt.verificationId
      ),
      collectionPointer: plan.stateProjection.collectionPointer,
      identityPointers: plan.stateProjection.identityPointers,
      textPatternSHA256:
        plan.stateProjection.textCollection.map {
          FileDigest.sha256(data: Data($0.pattern.utf8))
        },
      textIdentityCaptureGroups:
        plan.stateProjection.textCollection?
        .identityCaptureGroups,
      state: state
    )
    let receipts = ReversibleVerificationReceipts(
      readBefore: readBeforeReceipt,
      add: addReceipt,
      readMutated: readMutatedReceipt,
      remove: removeReceipt,
      readRestored: readRestoredReceipt
    )
    let result = ReversibleVerificationResult(
      sequence: sequence,
      receipts: receipts
    )
    try assertSanitized(result)
    return result
  }

  private func derivedReceiptId(
    base: String,
    role: String,
    sequenceId: String
  ) -> String {
    let identity = "\(base)\n\(role)\n\(sequenceId)\n"
    let digest = FileDigest.sha256(data: Data(identity.utf8))
    return "ver_\(digest.prefix(16))"
  }

  private func withRestoration(
    _ receipt: TrustVerificationReceipt,
    verificationId: String,
    proof: TrustRestorationProof
  ) -> TrustVerificationReceipt {
    TrustVerificationReceipt(
      brand: receipt.brand,
      market: receipt.market,
      verificationId: verificationId,
      verificationKind: .reversibleWriteReplay,
      verifiedAt: receipt.verifiedAt,
      operationId: receipt.operationId,
      fingerprint: receipt.fingerprint,
      sourceRefs: receipt.sourceRefs,
      requestEvidence: receipt.requestEvidence,
      response: receipt.response,
      responseFixture: receipt.responseFixture,
      fixtureOmissionReason: receipt.fixtureOmissionReason,
      restoration: proof,
      schemaVersion: receipt.schemaVersion,
      kind: receipt.kind
    )
  }

  private func withVerificationId(
    _ receipt: TrustVerificationReceipt,
    verificationId: String
  ) -> TrustVerificationReceipt {
    TrustVerificationReceipt(
      brand: receipt.brand,
      market: receipt.market,
      verificationId: verificationId,
      verificationKind: receipt.verificationKind,
      verifiedAt: receipt.verifiedAt,
      operationId: receipt.operationId,
      fingerprint: receipt.fingerprint,
      sourceRefs: receipt.sourceRefs,
      requestEvidence: receipt.requestEvidence,
      response: receipt.response,
      responseFixture: receipt.responseFixture,
      fixtureOmissionReason: receipt.fixtureOmissionReason,
      restoration: receipt.restoration,
      schemaVersion: receipt.schemaVersion,
      kind: receipt.kind
    )
  }

  private func assertSanitized(
    _ result: ReversibleVerificationResult
  ) throws {
    let text = String(
      decoding: try DeterministicJSON.encode(result),
      as: UTF8.self
    )
    guard !EvidenceRedactor.containsRawSecrets(in: text) else {
      throw ReversibleVerificationError.durableSecretMaterial
    }
  }

}

private struct ProjectedCollectionState {
  let identities: [String]
  let digest: String
}

private struct ResolvedReversibleStep {
  let operation: ObservedOperation
  let request: PrivateVerificationRequestSpec
}

private struct ResolvedReversiblePlan {
  let provider: String
  let market: String
  let readBefore: ResolvedReversibleStep
  let add: ResolvedReversibleStep
  let readMutated: ResolvedReversibleStep
  let remove: ResolvedReversibleStep
  let readRestored: ResolvedReversibleStep
  let stateProjection: ReversibleCollectionProjection
}

private struct CleanupResult {
  let removeResult: NativeVerificationResult?
  let readResult: NativeVerificationResult?
  let state: ProjectedCollectionState?
  let removeFailure: Error?
  let readFailure: Error?

  var stateRestored: Bool {
    state != nil && readFailure == nil
  }

  var isFullyVerified: Bool {
    removeResult != nil
      && readResult != nil
      && state != nil
      && removeFailure == nil
      && readFailure == nil
  }

  var failureDescription: String {
    let failures = [
      removeFailure.map { "remove: \(String(describing: $0))" },
      readFailure.map { "read-restored: \(String(describing: $0))" },
    ].compactMap { $0 }
    return failures.isEmpty
      ? "restoration evidence is incomplete"
      : failures.joined(separator: "; ")
  }
}

private actor AttemptTrackingExecutor: VerificationHTTPExecuting {
  private let base: any VerificationHTTPExecuting
  private(set) var didExecute = false

  init(base: any VerificationHTTPExecuting) {
    self.base = base
  }

  func execute(
    _ request: URLRequest
  ) async throws -> VerificationHTTPResponse {
    didExecute = true
    return try await base.execute(request)
  }
}
