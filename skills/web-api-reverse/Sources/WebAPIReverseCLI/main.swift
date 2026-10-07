import Darwin
import Foundation
import WebAPIReverseCore

@main
enum WebAPIReverseCLI {
  static func main() async {
    do {
      try await run(Array(CommandLine.arguments.dropFirst()))
    } catch {
      writeFailure(error)
      Foundation.exit(exitCode(for: error))
    }
  }

  private static func run(_ arguments: [String]) async throws {
    guard let command = arguments.first else {
      print(help)
      return
    }
    let parser = Arguments(Array(arguments.dropFirst()))
    switch command {
    case "--help", "help":
      print(help)
    case "--version", "version":
      print("0.1.0")
    case "doctor":
      try doctor(json: parser.flag("--json"))
    case "scaffold":
      try scaffold(parser)
    case "publish":
      try publish(parser)
    case "approve":
      try approve(parser)
    case "trust":
      try trust(parser)
    case "extract-request":
      try extractRequest(parser)
    case "verify":
      try await verify(parser)
    case "verify-reversible":
      try await verifyReversible(parser)
    case "verify-source-product":
      try verifySourceProduct(parser)
    case "validate-source-product-policy":
      try validateSourceProductPolicy(parser)
    case "validate-source-product":
      try validateSourceProduct(parser)
    case "verify-collection":
      try verifyCollection(parser)
    case "validate":
      try validate(parser)
    case "scan-artifacts":
      try scanArtifacts(parser)
    case "sanitize-artifacts":
      try sanitizeArtifacts(parser)
    case "import-har":
      try importHAR(parser)
    case "inventory-bundles":
      try inventoryBundles(parser)
    case "inventory-source-candidates":
      try inventorySourceCandidates(parser)
    case "inventory":
      try inventory(parser)
    case "coverage":
      try coverage(parser)
    case "diff":
      try diff(parser)
    case "capture":
      try capture(parser)
    case "capture-request":
      try await captureRequest(parser)
    case "auth":
      switch parser.positional.first {
      case "bootstrap":
        try authBootstrap(parser.droppingFirstPositional())
      case "inspect":
        try authInspect(parser.droppingFirstPositional())
      case "restore":
        try authRestore(parser.droppingFirstPositional())
      case "profile-session":
        try authProfileSession(parser.droppingFirstPositional())
      default:
        throw CLIError.invalidArguments(
          "auth requires the bootstrap, inspect, restore, or profile-session subcommand"
        )
      }
    case "codegen":
      guard parser.positional.first == "swift" else {
        throw CLIError.invalidArguments("codegen requires the swift subcommand")
      }
      try codegenSwift(parser.droppingFirstPositional())
    default:
      throw CLIError.invalidArguments("Unknown command: \(command)")
    }
  }

  private static func doctor(json: Bool) throws {
    let worker = try? BrowserWorker.resourceURL()
    let node = executable(named: "node")
    let result = DoctorResult(
      swiftAvailable: true,
      nodeAvailable: node != nil,
      playwrightWorkerAvailable: node.flatMap { node in
        worker.map { workerIsReady(node: node, worker: $0) }
      } ?? false
    )
    try write(command: "doctor", data: result, json: json) {
      """
      Swift: available
      Node.js: \(result.nodeAvailable ? "available" : "missing")
      Playwright worker: \(result.playwrightWorkerAvailable ? "available" : "missing")
      """
    }
  }

  private static func scaffold(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--provider-root")
    let result = try ProviderScaffolder().scaffold(
      providerRoot: root,
      provider: try parser.requiredValue("--provider"),
      market: parser.value("--market") ?? "cn"
    )
    try write(command: "scaffold", data: result, json: parser.flag("--json")) {
      "Created API evidence directories at \(result.providerRoot)"
    }
  }

  private static func publish(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--provider-root")
    let provider = try parser.requiredValue("--provider")
    let market = parser.value("--market") ?? "cn"
    let result = try EvidencePublisher().publish(
      PublishInputs(
        providerRoot: root,
        provider: provider,
        market: market,
        publishedAt: parser.value("--published-at")
      )
    )
    try write(command: "publish", data: result, json: parser.flag("--json")) {
      "Published contract at \(result.publishedDirectory)"
    }
  }

  private static func approve(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--provider-root")
    let provider = try parser.requiredValue("--provider")
    let reviewer = try parser.requiredValue("--reviewer")
    let market = parser.value("--market") ?? "cn"
    let result = try ApprovalBuilder().build(
      ApprovalBuildInput(
        providerRoot: root,
        provider: provider,
        market: market,
        reviewer: reviewer,
        approvedAt: parser.value("--approved-at")
          ?? ISO8601DateFormatter().string(from: Date()),
        zeroUnknown: parser.flag("--zero-unknown")
      )
    )
    try write(command: "approve", data: result, json: parser.flag("--json")) {
      "Approved \(result.operationCount) operations for publication."
    }
  }

  private static func trust(_ parser: Arguments) throws {
    let observedDirectory = try parser.requiredURL("--observed-dir")
    let trustedDirectory = try parser.requiredURL("--trusted-dir")
    let manifestURL = try parser.requiredURL("--manifest")
    try EvidencePathGuard.requireTrustedDirectory(trustedDirectory)

    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: observedDirectory.appending(path: "catalog.json"))
    )
    let sourceLock = try DeterministicJSON.decode(
      SourceLock.self,
      from: Data(
        contentsOf: observedDirectory.appending(path: "source-lock.json")
      )
    )
    let manifest = try DeterministicJSON.decode(
      TrustManifest.self,
      from: Data(contentsOf: manifestURL)
    )
    let verificationPaths = parser.values("--verification")
    guard manifest.operations.isEmpty || !verificationPaths.isEmpty else {
      throw CLIError.invalidArguments(
        "trust requires at least one --verification receipt"
      )
    }
    let verifications = try verificationPaths.map {
      try DeterministicJSON.decode(
        TrustVerificationReceipt.self,
        from: Data(contentsOf: URL(fileURLWithPath: $0))
      )
    }
    let result = try TrustedContractBuilder().build(
      TrustValidationInput(
        catalog: catalog,
        sourceLock: sourceLock,
        manifest: manifest,
        verifications: verifications
      ),
      trustedDirectory: trustedDirectory
    )
    try write(command: "trust", data: result, json: parser.flag("--json")) {
      "Trusted \(result.operationCount) operations at \(result.trustedDirectory)"
    }
  }

  private static func verify(_ parser: Arguments) async throws {
    let catalogURL = try parser.requiredURL("--catalog")
    let operationID = try parser.requiredValue("--operation-id")
    let receiptOutput = try parser.requiredURL("--receipt-output")
    let requestEvidenceOutput = try parser.requiredURL(
      "--request-evidence-output"
    )
    try EvidencePathGuard.requireObservedWrite(receiptOutput)
    try EvidencePathGuard.requireObservedWrite(requestEvidenceOutput)

    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: catalogURL)
    )
    guard
      let operation = catalog.operations.first(where: {
        $0.operationId == operationID
      })
    else {
      throw CLIError.operationNotFound(operationID)
    }

    let requestPath = parser.value("--request")
    let capturePath = parser.value("--capture-receipt")
    guard (requestPath == nil) != (capturePath == nil) else {
      throw CLIError.invalidArguments(
        "verify requires exactly one of --request or --capture-receipt"
      )
    }

    let requestSpec: PrivateVerificationRequestSpec
    if let requestPath {
      let requestURL = URL(fileURLWithPath: requestPath)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(requestURL)
      requestSpec = try DeterministicJSON.decode(
        PrivateVerificationRequestSpec.self,
        from: Data(contentsOf: requestURL)
      )
    } else {
      let captureURL = URL(fileURLWithPath: capturePath!)
      let capture = try DeterministicJSON.decode(
        CaptureReceipt.self,
        from: Data(contentsOf: captureURL)
      )
      requestSpec = try NativeOperationVerifier.requestFromCapture(
        operation: operation,
        receipt: capture
      )
    }
    guard requestSpec.brand == catalog.brand,
      requestSpec.market == catalog.market
    else {
      throw NativeVerificationError.scopeMismatch(
        "request \(requestSpec.brand)/\(requestSpec.market) "
          + "vs catalog \(catalog.brand)/\(catalog.market)"
      )
    }

    let sessionSeed: PrivateSessionSeed?
    if let sessionPath = parser.value("--session-seed") {
      let sessionURL = URL(fileURLWithPath: sessionPath)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(sessionURL)
      sessionSeed = try DeterministicJSON.decode(
        PrivateSessionSeed.self,
        from: Data(contentsOf: sessionURL)
      )
    } else {
      sessionSeed = nil
    }

    let result = try await NativeOperationVerifier().verify(
      operation: operation,
      requestSpec: requestSpec,
      sessionSeed: sessionSeed,
      allowRemoteWrite: parser.flag("--allow-remote-write"),
      verifiedAt: parser.value("--verified-at")
        ?? ISO8601DateFormatter().string(from: Date())
    )
    try DeterministicJSON.write(result.receipt, to: receiptOutput)
    try DeterministicJSON.write(
      result.requestEvidence,
      to: requestEvidenceOutput
    )
    if let privateResponsePath = parser.value("--private-response") {
      let privateResponseURL = URL(fileURLWithPath: privateResponsePath)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(privateResponseURL)
      try writePrivate(result.privateResponse, to: privateResponseURL)
    }
    try write(
      command: "verify",
      data: VerifyCommandResult(
        operationId: operation.operationId,
        verificationId: result.receipt.verificationId,
        outcome: result.receipt.response.outcome,
        receiptPath: receiptOutput.path,
        requestEvidencePath: requestEvidenceOutput.path,
        privateResponsePath: parser.value("--private-response")
      ),
      json: parser.flag("--json")
    ) {
      "Verified \(operation.operationId) as \(result.receipt.response.outcome.rawValue)."
    }
  }

  private static func extractRequest(_ parser: Arguments) throws {
    let harURL = try parser.requiredURL("--har")
    let captureReceiptURL = try parser.requiredURL(
      "--capture-receipt"
    )
    let catalogURL = try parser.requiredURL("--catalog")
    let operationID = try parser.requiredValue("--operation-id")
    let outputURL = try parser.requiredURL("--output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(harURL)
    try EvidencePathGuard.requirePrivateStateOutsideAPI(outputURL)

    let captureReceipt = try DeterministicJSON.decode(
      CaptureReceipt.self,
      from: Data(contentsOf: captureReceiptURL)
    )
    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: catalogURL)
    )
    guard
      let operation = catalog.operations.first(where: {
        $0.operationId == operationID
      })
    else {
      throw CLIError.operationNotFound(operationID)
    }
    guard
      captureReceipt.brand == catalog.brand,
      captureReceipt.market == catalog.market
    else {
      throw PrivateHARRequestExtractionError.scopeMismatch
    }
    let result = try PrivateHARRequestExtractor().extract(
      harURL: harURL,
      captureReceipt: captureReceipt,
      operation: operation
    )
    try writePrivate(result.requestSpec, to: outputURL)
    try write(
      command: "extract-request",
      data: ExtractRequestCommandResult(
        operationId: operation.operationId,
        matchedExchangeCount: result.matchedExchangeCount,
        privateRequestPath: outputURL.path
      ),
      json: parser.flag("--json")
    ) {
      "Extracted private replay request for \(operation.operationId)."
    }
  }

  private static func verifyReversible(
    _ parser: Arguments
  ) async throws {
    let catalogURL = try parser.requiredURL("--catalog")
    let planURL = try parser.requiredURL("--plan")
    let outputDirectory = try parser.requiredURL("--output-dir")
    let transactionDirectory = try parser.requiredURL(
      "--private-transaction-dir"
    )
    try EvidencePathGuard.requirePrivateStateOutsideAPI(planURL)
    try EvidencePathGuard.requirePrivateStateOutsideAPI(
      transactionDirectory
    )
    try EvidencePathGuard.requireObservedWrite(outputDirectory)
    guard parser.flag("--allow-remote-write") else {
      throw ReversibleVerificationError.allowRemoteWriteRequired
    }

    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: catalogURL)
    )
    let plan = try DeterministicJSON.decode(
      ReversibleVerificationPlan.self,
      from: Data(contentsOf: planURL)
    )
    let sessionSeed: PrivateSessionSeed?
    if let sessionPath = parser.value("--session-seed") {
      let sessionURL = URL(fileURLWithPath: sessionPath)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(sessionURL)
      sessionSeed = try DeterministicJSON.decode(
        PrivateSessionSeed.self,
        from: Data(contentsOf: sessionURL)
      )
    } else {
      sessionSeed = nil
    }

    let transactionStore = try ReversibleVerificationTransactionStore(
      privateRoot: transactionDirectory
    )
    let result = try await ReversibleOperationVerifier().verify(
      catalog: catalog,
      plan: plan,
      sessionSeed: sessionSeed,
      allowRemoteWrite: true,
      verifiedAt: parser.value("--verified-at")
        ?? ISO8601DateFormatter().string(from: Date()),
      transactionStore: transactionStore
    )
    let paths = try ReversibleVerificationArtifactWriter().write(
      result,
      under: outputDirectory
    )
    try await transactionStore.acknowledgeCompletion(
      sequenceId: result.sequence.sequenceId
    )
    try write(
      command: "verify-reversible",
      data: ReversibleVerifyCommandResult(
        sequenceId: result.sequence.sequenceId,
        restorationProven: result.sequence.restoration.proven,
        artifacts: paths
      ),
      json: parser.flag("--json")
    ) {
      "Verified and restored reversible sequence \(result.sequence.sequenceId)."
    }
  }

  private static func validate(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--provider-root")
    let result = try ContractValidator().validate(providerRoot: root)
    try write(command: "validate", data: result, json: parser.flag("--json")) {
      "Published contract is valid at \(result.publishedDirectory)"
    }
  }

  private static func scanArtifacts(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--root")
    let findings = try ArtifactScanner().scan(root: root)
    if !findings.isEmpty {
      throw CLIError.secretFindings(findings)
    }
    try write(
      command: "scan-artifacts",
      data: ScanResult(root: root.path, findings: findings),
      json: parser.flag("--json")
    ) {
      "No sensitive material found under \(root.path)"
    }
  }

  private static func sanitizeArtifacts(_ parser: Arguments) throws {
    let root = try parser.requiredURL("--root")
    let result = try ArtifactSanitizer().sanitize(root: root)
    try write(
      command: "sanitize-artifacts",
      data: result,
      json: parser.flag("--json")
    ) {
      "Sanitized \(result.sanitizedPaths.count) artifact(s) under \(root.path)"
    }
  }

  private static func importHAR(_ parser: Arguments) throws {
    let har = try parser.requiredURL("--har")
    let output = try parser.requiredURL("--output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(har)
    try EvidencePathGuard.requireObservedWrite(output)
    let surfaceValue = try parser.requiredValue("--surface")
    guard let surface = SourceSurface(rawValue: surfaceValue) else {
      throw CLIError.invalidArguments(
        "Unsupported source surface: \(surfaceValue)"
      )
    }
    let receipt = try HARImporter.importHAR(
      at: har,
      options: HARImportOptions(
        brand: try parser.requiredValue("--brand"),
        market: parser.value("--market") ?? "cn",
        surface: surface,
        sourceId: try parser.requiredValue("--source-id"),
        sourceVersion: try parser.requiredValue("--source-version"),
        flow: parser.value("--flow") ?? "har-import",
        includeURLPatterns: parser.values("--include-url-regex"),
        routeDiscriminatorQueryNames:
          parser.values("--route-discriminator-query")
      )
    )
    try DeterministicJSON.write(receipt, to: output)
    try write(
      command: "import-har",
      data: ImportHARResult(
        receiptPath: output.path,
        captureId: receipt.captureId,
        exchangeCount: receipt.exchanges.count
      ),
      json: parser.flag("--json")
    ) {
      "Imported \(receipt.exchanges.count) sanitized exchanges to \(output.path)"
    }
  }

  private static func inventoryBundles(
    _ parser: Arguments
  ) throws {
    let har = try parser.requiredURL("--har")
    let output = try parser.requiredURL("--output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(har)
    try EvidencePathGuard.requireObservedWrite(output)
    let surfaceValue = try parser.requiredValue("--surface")
    guard let surface = SourceSurface(rawValue: surfaceValue) else {
      throw CLIError.invalidArguments(
        "Unsupported source surface: \(surfaceValue)"
      )
    }
    let maximumBundleBytes = try positiveInteger(
      parser.value("--max-bundle-bytes"),
      option: "--max-bundle-bytes",
      defaultValue: 8 * 1_024 * 1_024
    )
    let maximumTotalBytes = try positiveInteger(
      parser.value("--max-total-bytes"),
      option: "--max-total-bytes",
      defaultValue: 64 * 1_024 * 1_024
    )
    let receipt = try BundleRouteInventory.inventory(
      at: har,
      options: BundleRouteInventoryOptions(
        brand: try parser.requiredValue("--brand"),
        market: parser.value("--market") ?? "cn",
        surface: surface,
        sourceId: try parser.requiredValue("--source-id"),
        sourceVersion: try parser.requiredValue("--source-version"),
        capturedAt: parser.value("--captured-at"),
        maximumBundleBytes: maximumBundleBytes,
        maximumTotalBytes: maximumTotalBytes
      )
    )
    try DeterministicJSON.write(receipt, to: output)
    try write(
      command: "inventory-bundles",
      data: BundleInventoryCommandResult(
        receiptPath: output.path,
        receiptId: receipt.receiptId,
        bundleCount: receipt.bundles.count,
        candidateCount: receipt.candidates.count
      ),
      json: parser.flag("--json")
    ) {
      """
      Inventoried \(receipt.candidates.count) static route candidates from \
      \(receipt.bundles.count) JavaScript bundles.
      """
    }
  }

  private static func inventorySourceCandidates(
    _ parser: Arguments
  ) throws {
    let har = try parser.requiredURL("--har")
    let policyURL = try parser.requiredURL("--policy")
    let output = try parser.requiredURL("--output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(har)
    try EvidencePathGuard.requirePrivateStateOutsideAPI(output)
    let policy = try DeterministicJSON.decode(
      SourceCandidateInventoryPolicy.self,
      from: Data(contentsOf: policyURL)
    )
    let inventory = try SourceCandidateInventoryBuilder().inventory(
      harURL: har,
      policy: policy
    )
    try PrivateSourceCandidateInventoryWriter().write(
      inventory,
      to: output
    )
    try write(
      command: "inventory-source-candidates",
      data: SourceCandidateInventoryCommandResult(
        outputPath: output.path,
        provider: inventory.provider,
        platformProvider: inventory.platformProvider,
        scannedExchangeCount: inventory.scannedExchangeCount,
        candidateCount: inventory.candidates.count,
        harSHA256: inventory.harSHA256
      ),
      json: parser.flag("--json")
    ) {
      "Inventoried \(inventory.candidates.count) private source-product candidate(s)."
    }
  }

  private static func positiveInteger(
    _ rawValue: String?,
    option: String,
    defaultValue: Int
  ) throws -> Int {
    guard let rawValue else {
      return defaultValue
    }
    guard let value = Int(rawValue), value > 0 else {
      throw CLIError.invalidArguments(
        "\(option) must be a positive integer"
      )
    }
    return value
  }

  private static func inventory(_ parser: Arguments) throws {
    let observedDirectory = try parser.requiredURL("--observed-dir")
    try EvidencePathGuard.requireObservedWrite(observedDirectory)
    let sourceManifest: SourceManifest? = try parser.value("--source-manifest").map {
      try DeterministicJSON.decode(
        SourceManifest.self,
        from: Data(contentsOf: URL(fileURLWithPath: $0))
      )
    }
    let persistedReceiptPaths = try existingJSONFiles(
      in: observedDirectory.appending(path: "captures")
    )
    let explicitReceiptPaths = parser.values("--receipt").map(
      URL.init(fileURLWithPath:)
    )
    let persistedReceipts = try SourceManifestCaptureSelector.selectPersisted(
      persistedReceiptPaths.map {
        try DeterministicJSON.decode(
          CaptureReceipt.self,
          from: Data(contentsOf: $0)
        )
      },
      manifest: sourceManifest
    )
    let explicitReceipts = try explicitReceiptPaths.map {
      try DeterministicJSON.decode(
        CaptureReceipt.self,
        from: Data(contentsOf: $0)
      )
    }
    guard !persistedReceipts.isEmpty || !explicitReceipts.isEmpty else {
      throw CLIError.invalidArguments(
        "inventory requires at least one --receipt"
      )
    }
    let receipts = try deduplicated(
      persistedReceipts + explicitReceipts,
      id: \.captureId
    )
    let persistedVerifications = try VerificationReceiptLoader.loadObserved(
      from: observedDirectory
    )
    let explicitVerifications = try parser.values("--verification").map {
      try DeterministicJSON.decode(
        TrustVerificationReceipt.self,
        from: Data(contentsOf: URL(fileURLWithPath: $0))
      )
    }
    let verifications = try deduplicated(
      persistedVerifications + explicitVerifications,
      id: \.verificationId
    )
    let persistedSourceProductVerifications =
      try SourceProductVerificationReceiptLoader.load(
        from: observedDirectory.appending(path: "source-verifications")
      )
    let explicitSourceProductVerifications =
      try parser.values("--source-verification").map {
        try DeterministicJSON.decode(
          SourceProductVerificationReceipt.self,
          from: Data(contentsOf: URL(fileURLWithPath: $0))
        )
      }
    let sourceProductVerifications = try deduplicated(
      persistedSourceProductVerifications
        + explicitSourceProductVerifications,
      id: \.verificationId
    )
    let annotations: AnnotationFile? = try parser.value("--annotations").map {
      try DeterministicJSON.decode(
        AnnotationFile.self,
        from: Data(contentsOf: URL(fileURLWithPath: $0))
      )
    }
    let result = try InventoryBuilder.build(
      receipts: receipts,
      annotations: annotations,
      sourceManifest: sourceManifest,
      verifications: verifications,
      sourceProductVerifications: sourceProductVerifications
    )
    let coverage = try CoverageCalculator.compute(
      catalog: result.catalog,
      sourceLock: result.sourceLock,
      verifications: verifications
    )
    try FileManager.default.createDirectory(
      at: observedDirectory,
      withIntermediateDirectories: true
    )
    let capturesDirectory = observedDirectory.appending(path: "captures")
    let verificationsDirectory = observedDirectory.appending(
      path: "verifications"
    )
    let sourceVerificationsDirectory = observedDirectory.appending(
      path: "source-verifications"
    )
    try FileManager.default.createDirectory(
      at: capturesDirectory,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: verificationsDirectory,
      withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
      at: sourceVerificationsDirectory,
      withIntermediateDirectories: true
    )
    for receipt in receipts {
      try DeterministicJSON.write(
        receipt,
        to: capturesDirectory.appending(
          path: "\(receipt.captureId).json"
        )
      )
    }
    let persistedVerificationIDs = Set(
      persistedVerifications.map(\.verificationId)
    )
    for verification in explicitVerifications
    where !persistedVerificationIDs.contains(verification.verificationId) {
      try DeterministicJSON.write(
        verification,
        to: verificationsDirectory.appending(
          path: "\(verification.verificationId).json"
        )
      )
    }
    let persistedSourceProductVerificationIDs = Set(
      persistedSourceProductVerifications.map(\.verificationId)
    )
    for verification in explicitSourceProductVerifications
    where !persistedSourceProductVerificationIDs.contains(
      verification.verificationId
    ) {
      try DeterministicJSON.write(
        verification,
        to: sourceVerificationsDirectory.appending(
          path: "\(verification.verificationId).json"
        )
      )
    }
    try DeterministicJSON.write(
      result.catalog,
      to: observedDirectory.appending(path: "catalog.json")
    )
    try DeterministicJSON.write(
      result.sourceLock,
      to: observedDirectory.appending(path: "source-lock.json")
    )
    try DeterministicJSON.write(
      coverage,
      to: observedDirectory.appending(path: "coverage.json")
    )
    try write(
      command: "inventory",
      data: InventoryCommandResult(
        observedDirectory: observedDirectory.path,
        captureCount: receipts.count,
        verificationCount: verifications.count,
        sourceProductVerificationCount: sourceProductVerifications.count,
        operationCount: result.catalog.operations.count,
        zeroUnknown: coverage.zeroUnknown,
        requiredCoverageAreaCount:
          coverage.requiredCoverageAreas?.count ?? 0,
        missingCoverageAreaCount:
          coverage.missingCoverageAreas?.count ?? 0,
        unverifiedSafeCount: coverage.unverifiedSafeOperationIds.count
      ),
      json: parser.flag("--json")
    ) {
      "Inventoried \(result.catalog.operations.count) operations at \(observedDirectory.path)"
    }
  }

  private static func verifySourceProduct(_ parser: Arguments) throws {
    let sourceProductURL = try parser.requiredURL("--source-product")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(sourceProductURL)
    let policyURL = try parser.requiredURL("--policy")
    let output = try parser.requiredURL("--output")
    try EvidencePathGuard.requireObservedWrite(output)
    let policy = try DeterministicJSON.decode(
      SourceProductVerificationPolicy.self,
      from: Data(contentsOf: policyURL)
    )
    let receipt = try SourceProductVerifier().verify(
      SourceProductVerificationInput(
        policy: policy,
        sourceProductData: try Data(contentsOf: sourceProductURL),
        platformProviderRoot: try parser.requiredURL(
          "--platform-provider-root"
        )
      )
    )
    try DeterministicJSON.write(receipt, to: output)
    try write(
      command: "verify-source-product",
      data: receipt,
      json: parser.flag("--json")
    ) {
      """
      Verified \(receipt.platformProvider) product \(receipt.productExternalID) \
      for \(receipt.provider) source \(receipt.sourceId)@\(receipt.sourceVersion).
      """
    }
  }

  private static func validateSourceProduct(_ parser: Arguments) throws {
    let receiptURL = try parser.requiredURL("--receipt")
    let policyURL = try parser.requiredURL("--policy")
    let policy = try DeterministicJSON.decode(
      SourceProductVerificationPolicy.self,
      from: Data(contentsOf: policyURL)
    )
    let result = try SourceProductVerifier().validateReceipt(
      receiptData: try Data(contentsOf: receiptURL),
      policy: policy,
      platformProviderRoot: try parser.requiredURL(
        "--platform-provider-root"
      )
    )
    try write(
      command: "validate-source-product",
      data: result,
      json: parser.flag("--json")
    ) {
      "Validated current source-product receipt for \(result.provider)/\(result.sourceId)."
    }
  }

  private static func validateSourceProductPolicy(_ parser: Arguments) throws {
    let policy = try DeterministicJSON.decode(
      SourceProductVerificationPolicy.self,
      from: Data(contentsOf: try parser.requiredURL("--policy"))
    )
    try SourceProductVerifier.validate(policy)
    let result = SourceProductPolicyValidationPayload(
      provider: policy.provider,
      market: policy.market,
      sourceId: policy.sourceId,
      platformProvider: policy.platformProvider,
      sourceProjection: policy.sourceProjection ?? .platformRaw,
      acceptedShopIDCount: policy.acceptedShopIDs?.count ?? 0
    )
    try write(
      command: "validate-source-product-policy",
      data: result,
      json: parser.flag("--json")
    ) {
      "Validated source-product policy for \(result.provider)/\(result.sourceId)."
    }
  }

  private static func verifyCollection(_ parser: Arguments) throws {
    guard parser.flag("--allow-remote-write") else {
      throw CollectionVerificationError.allowRemoteWriteRequired
    }
    let providerRoot = try parser.requiredURL("--provider-root")
    let output = try parser.requiredURL("--output")
    let receipt = try CollectionVerifier().verify(
      CollectionVerificationInput(
        providerRoot: providerRoot,
        provider: try parser.requiredValue("--provider"),
        market: parser.value("--market") ?? "cn",
        sourceProductReceiptURL: try parser.requiredURL(
          "--source-product-receipt"
        ),
        platformProviderRoot: try parser.requiredURL(
          "--platform-provider-root"
        ),
        addTranscriptURL: try parser.requiredURL("--add-transcript"),
        deleteTranscriptURL: try parser.requiredURL(
          "--delete-transcript"
        ),
        verifiedAt: parser.value("--verified-at")
          ?? ISO8601DateFormatter().string(from: Date())
      ),
      allowRemoteWrite: true
    )
    try CollectionVerificationReceiptWriter().write(
      receipt,
      to: output,
      providerRoot: providerRoot
    )
    try write(
      command: "verify-collection",
      data: receipt,
      json: parser.flag("--json")
    ) {
      let target = receipt.skuExternalID ?? receipt.productExternalID
      return
        "Verified and restored \(receipt.provider) \(receipt.targetGrain.rawValue)-grain remote collection target \(target)."
    }
  }

  private static func coverage(_ parser: Arguments) throws {
    let catalogURL = try parser.requiredURL("--catalog")
    let sourceLockURL = try parser.requiredURL("--source-lock")
    let strict = parser.flag("--strict")
    let catalog = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: catalogURL)
    )
    let sourceLock = try DeterministicJSON.decode(
      SourceLock.self,
      from: Data(contentsOf: sourceLockURL)
    )
    let verifications: [TrustVerificationReceipt]?
    if strict {
      let observedDirectory = catalogURL.deletingLastPathComponent()
      guard
        sourceLockURL.deletingLastPathComponent().standardizedFileURL
          == observedDirectory.standardizedFileURL
      else {
        throw CLIError.invalidArguments(
          "--strict requires catalog.json and source-lock.json from the same "
            + "Observed directory so verification receipts can be discovered"
        )
      }
      verifications = try VerificationReceiptLoader.loadObserved(
        from: observedDirectory
      )
    } else {
      verifications = nil
    }
    let result = try CoverageCalculator.compute(
      catalog: catalog,
      sourceLock: sourceLock,
      verifications: verifications
    )
    if let output = parser.value("--output") {
      let outputURL = URL(fileURLWithPath: output)
      try EvidencePathGuard.requireObservedWrite(outputURL)
      try DeterministicJSON.write(
        result,
        to: outputURL
      )
    }
    try write(command: "coverage", data: result, json: parser.flag("--json")) {
      """
      Operations: \(result.operationCount)
      Classified: \(result.classifiedCount)
      Coverage areas: \(result.coveredCoverageAreas?.count ?? 0)/\(result.requiredCoverageAreas?.count ?? 0)
      Missing areas: \((result.missingCoverageAreas ?? []).joined(separator: ", "))
      Zero unknown: \(result.zeroUnknown)
      Strict: \(result.passesStrict)
      """
    }
    if strict && !result.passesStrict {
      Foundation.exit(65)
    }
  }

  private static func diff(_ parser: Arguments) throws {
    let fromURL = try parser.requiredURL("--from")
    let toURL = try parser.requiredURL("--to")
    let from = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: fromURL)
    )
    let to = try DeterministicJSON.decode(
      ObservedCatalog.self,
      from: Data(contentsOf: toURL)
    )
    let result = try CatalogDiffer.diff(from: from, to: to)
    try write(command: "diff", data: result, json: parser.flag("--json")) {
      """
      Added: \(result.addedOperationIds.count)
      Removed: \(result.removedOperationIds.count)
      Changed: \(result.changedOperationIds.count)
      Unchanged: \(result.unchangedCount)
      """
    }
  }

  private static func capture(_ parser: Arguments) throws {
    try EvidencePathGuard.requirePrivateStateOutsideAPI(
      parser.requiredURL("--private-output")
    )
    try EvidencePathGuard.requireObservedWrite(
      parser.requiredURL("--receipt-output")
    )
    let workerResult = try runBrowserWorker(name: "capture", parser: parser)
    let receiptOutput = try parser.requiredURL("--receipt-output")
    let receipt = try importWorkerHAR(
      workerResult,
      parser: parser,
      flow: parser.value("--flow") ?? "browser-capture"
    )
    try DeterministicJSON.write(receipt, to: receiptOutput)
    try write(
      command: "capture",
      data: BrowserCaptureResult(
        privateCapturePath: workerResult.rawCapturePath,
        privateHARPath: workerResult.rawHARPath,
        receiptPath: receiptOutput.path,
        captureId: receipt.captureId,
        exchangeCount: receipt.exchanges.count
      ),
      json: parser.flag("--json")
    ) {
      "Captured \(receipt.exchanges.count) sanitized exchanges to \(receiptOutput.path)"
    }
  }

  private static func captureRequest(_ parser: Arguments) async throws {
    let requestURL = try parser.requiredURL("--request")
    let outputURL = try parser.requiredURL("--output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(requestURL)
    try EvidencePathGuard.requireObservedWrite(outputURL)
    let requestSpec = try DeterministicJSON.decode(
      PrivateVerificationRequestSpec.self,
      from: Data(contentsOf: requestURL)
    )
    let surfaceValue = try parser.requiredValue("--surface")
    guard let surface = SourceSurface(rawValue: surfaceValue) else {
      throw CLIError.invalidArguments(
        "Unsupported source surface: \(surfaceValue)"
      )
    }
    let sessionSeed: PrivateSessionSeed?
    if let path = parser.value("--session-seed") {
      let url = URL(fileURLWithPath: path)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(url)
      sessionSeed = try DeterministicJSON.decode(
        PrivateSessionSeed.self,
        from: Data(contentsOf: url)
      )
    } else {
      sessionSeed = nil
    }
    let result = try await NativeRequestCapturer().capture(
      requestSpec: requestSpec,
      source: NativeRequestCaptureSource(
        surface: surface,
        sourceId: try parser.requiredValue("--source-id"),
        sourceVersion: try parser.requiredValue("--source-version"),
        flow: parser.value("--flow") ?? "native-request-capture"
      ),
      sessionSeed: sessionSeed,
      allowRemoteWrite: parser.flag("--allow-remote-write"),
      routeDiscriminatorQueryNames:
        parser.values("--route-discriminator-query"),
      capturedAt: parser.value("--captured-at")
        ?? ISO8601DateFormatter().string(from: Date())
    )
    try DeterministicJSON.write(result.receipt, to: outputURL)
    if let privateResponsePath = parser.value("--private-response") {
      let privateResponseURL = URL(fileURLWithPath: privateResponsePath)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(privateResponseURL)
      try writePrivate(result.privateResponse, to: privateResponseURL)
    }
    try write(
      command: "capture-request",
      data: NativeCaptureCommandResult(
        captureId: result.receipt.captureId,
        receiptPath: outputURL.path,
        privateResponsePath: parser.value("--private-response")
      ),
      json: parser.flag("--json")
    ) {
      "Captured native request evidence \(result.receipt.captureId)."
    }
  }

  private static func authBootstrap(_ parser: Arguments) throws {
    let sessionOnly = parser.flag("--session-only")
    let sessionDomains = parser.values("--session-domain")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(
      parser.requiredURL("--private-output")
    )
    if sessionOnly {
      if parser.value("--receipt-output") != nil {
        throw CLIError.invalidArguments(
          "--session-only must not write a reusable evidence receipt"
        )
      }
      guard !sessionDomains.isEmpty else {
        throw CLIError.invalidArguments(
          "--session-only requires at least one --session-domain"
        )
      }
    } else {
      try EvidencePathGuard.requireObservedWrite(
        parser.requiredURL("--receipt-output")
      )
    }
    let workerResult: BrowserWorkerData
    do {
      workerResult = try runBrowserWorker(
        name: "auth.bootstrap",
        parser: parser
      )
    } catch CLIError.browserWorkerFailed(
      let code,
      let message,
      let checkpoint?
    ) {
      if let checkpointPath = try? persistBrowserSessionSeed(
        from: checkpoint,
        parser: parser,
        sessionDomains: sessionDomains
      ) {
        throw CLIError.browserCheckpointPreserved(
          code: code,
          message:
            message
            + " The private session checkpoint was preserved at "
            + checkpointPath.path
            + ".",
          path: checkpointPath.path
        )
      }
      throw CLIError.browserWorkerFailed(
        code: code,
        message: message,
        checkpoint: nil
      )
    }
    let sessionSeedOutput = try persistBrowserSessionSeed(
      from: workerResult,
      parser: parser,
      sessionDomains: sessionDomains
    )
    let receipt: CaptureReceipt?
    let receiptOutput: URL?
    if sessionOnly {
      receipt = nil
      receiptOutput = nil
    } else {
      let output = try parser.requiredURL("--receipt-output")
      let imported = try importWorkerHAR(
        workerResult,
        parser: parser,
        flow: parser.value("--flow") ?? "auth-bootstrap"
      )
      try DeterministicJSON.write(imported, to: output)
      receipt = imported
      receiptOutput = output
    }
    try write(
      command: "auth.bootstrap",
      data: BrowserCaptureResult(
        privateCapturePath: workerResult.rawCapturePath,
        privateHARPath: workerResult.rawHARPath,
        receiptPath: receiptOutput?.path,
        captureId: receipt?.captureId,
        exchangeCount: receipt?.exchanges.count
          ?? workerResult.exchangeCount,
        privateSessionSeedPath: sessionSeedOutput.path
      ),
      json: parser.flag("--json")
    ) {
      "Captured private session seed and sanitized auth receipt."
    }
  }

  private static func authProfileSession(_ parser: Arguments) throws {
    let profileDirectory = try parser.requiredURL("--profile")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(profileDirectory)
    let urls = parser.values("--url")
    guard !urls.isEmpty else {
      throw CLIError.invalidArguments(
        "auth profile-session requires at least one --url"
      )
    }
    let auditDirectory = try PrivateArtifactStore.makeTemporaryRoot(
      prefix: "web-api-reverse-profile-audit"
    )
    let auditStore = try PrivateArtifactStore(privateRoot: auditDirectory)
    defer { try? auditStore.removeRoot() }
    let profileSnapshot = try BrowserProfileSnapshot.create(
      from: profileDirectory,
      under: auditDirectory
    )
    let label = parser.value("--profile-label") ?? "default"
    let result = try runBrowserProfileSessionWorker(
      profileDirectory: profileSnapshot.directory,
      profileLabel: label,
      urls: urls,
      browser: parser.value("--browser") ?? "chromium"
    )
    try write(
      command: "auth.profile-session",
      data: result,
      json: parser.flag("--json")
    ) {
      "Audited a disposable snapshot of browser profile \(result.profileLabel). Provider account validation still requires provider-owned handoff."
    }
  }

  private static func authInspect(_ parser: Arguments) throws {
    let candidateOnly = parser.flag("--candidate-only")
    let privateOutput = try parser.requiredURL("--private-output")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(privateOutput)
    let privateStore = try PrivateArtifactStore(
      privateRoot: privateOutput,
      createPrivateRoot: true
    )
    let browserProfile = try parser.requiredValue("--profile")
    let sessionProfileLabel = try sessionProfileLabel(parser)
    var isDirectory: ObjCBool = false
    guard
      FileManager.default.fileExists(
        atPath: browserProfile,
        isDirectory: &isDirectory
      ),
      isDirectory.boolValue
    else {
      throw CLIError.invalidArguments(
        "--profile must reference an existing persistent browser profile"
      )
    }
    let sessionDomains = parser.values("--session-domain")
    guard !sessionDomains.isEmpty else {
      throw CLIError.invalidArguments(
        "auth inspect requires at least one --session-domain"
      )
    }
    let snapshotRoot = try PrivateArtifactStore.makeTemporaryRoot(
      prefix: "web-api-reverse-inspection"
    )
    let snapshotStore = try PrivateArtifactStore(
      privateRoot: snapshotRoot
    )
    defer { try? snapshotStore.removeRoot() }
    let profileSnapshot = try BrowserProfileSnapshot.create(
      from: URL(fileURLWithPath: browserProfile),
      under: snapshotStore.privateRoot
    )
    let workerResult: BrowserWorkerData
    do {
      workerResult = try runBrowserWorker(
        name: "auth.inspect",
        parser: parser,
        profileDirectoryOverride: profileSnapshot.directory.path
      )
    } catch CLIError.browserWorkerFailed(
      let code,
      let message,
      let checkpoint?
    ) {
      if let checkpointPath = try? persistBrowserSessionSeed(
        from: checkpoint,
        parser: parser,
        sessionDomains: sessionDomains
      ) {
        throw CLIError.browserCheckpointPreserved(
          code: code,
          message:
            message
            + " The private session checkpoint was preserved at "
            + checkpointPath.path
            + ".",
          path: checkpointPath.path
        )
      }
      throw CLIError.browserWorkerFailed(
        code: code,
        message: message,
        checkpoint: nil
      )
    }
    let browserCapture = try decodePrivateCapture(from: workerResult)
    let sessionSeed = try BrowserWorker.extractScopedSessionSeed(
      capture: browserCapture,
      brand: try parser.requiredValue("--brand"),
      market: parser.value("--market") ?? "cn",
      profile: sessionProfileLabel,
      sourceURL: try parser.requiredValue("--url"),
      allowedDomains: sessionDomains
    )
    let sessionSeedOutput = privateStore.privateRoot.appending(
      path: "session-seed.json"
    )
    try privateStore.write(
      DeterministicJSON.encode(sessionSeed),
      named: "session-seed.json",
      maximumBytes: maximumPrivateSessionSeedBytes
    )
    try write(
      command: "auth.inspect",
      data: BrowserCaptureResult(
        privateCapturePath: workerResult.rawCapturePath,
        privateHARPath: workerResult.rawHARPath,
        receiptPath: nil,
        captureId: nil,
        exchangeCount: workerResult.exchangeCount,
        privateSessionSeedPath: sessionSeedOutput.path
      ),
      json: parser.flag("--json")
    ) {
      candidateOnly
        ? "Extracted a scoped private session candidate without navigation."
        : "Inspected the existing browser profile and wrote a scoped private session seed."
    }
  }

  private static func persistBrowserSessionSeed(
    from workerResult: BrowserWorkerData,
    parser: Arguments,
    sessionDomains: [String]
  ) throws -> URL {
    let browserCapture = try decodePrivateCapture(from: workerResult)
    let brand = try parser.requiredValue("--brand")
    let market = parser.value("--market") ?? "cn"
    let sessionProfileLabel = try sessionProfileLabel(parser)
    let sourceURL = try parser.requiredValue("--url")
    let sessionSeed =
      if sessionDomains.isEmpty {
        BrowserWorker.extractSessionSeed(
          capture: browserCapture,
          brand: brand,
          market: market,
          profile: sessionProfileLabel,
          sourceURL: sourceURL
        )
      } else {
        try BrowserWorker.extractScopedSessionSeed(
          capture: browserCapture,
          brand: brand,
          market: market,
          profile: sessionProfileLabel,
          sourceURL: sourceURL,
          allowedDomains: sessionDomains
        )
      }
    let store = workerResult.artifactStore
    let output = store.privateRoot.appending(path: "session-seed.json")
    try store.write(
      DeterministicJSON.encode(sessionSeed),
      named: "session-seed.json",
      maximumBytes: maximumPrivateSessionSeedBytes
    )
    return output
  }

  private static func decodePrivateCapture(
    from workerResult: BrowserWorkerData
  ) throws -> BrowserWorkerPrivateCapture {
    try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: workerResult.artifactStore.read(
        named: "capture.json",
        maximumBytes: maximumPrivateCaptureBytes
      )
    )
  }

  private static func sessionProfileLabel(
    _ parser: Arguments
  ) throws -> String {
    do {
      return try BrowserSessionProfileLabel.resolve(
        explicitLabel: parser.value("--session-profile-label"),
        browserProfile: parser.value("--profile")
      )
    } catch let error as BrowserSessionProfileLabelError {
      throw CLIError.invalidArguments(
        error.errorDescription
          ?? "--session-profile-label is invalid"
      )
    }
  }

  private static func authRestore(_ parser: Arguments) throws {
    let sessionSeedURL = try parser.requiredURL("--session-seed")
    let profileURL = try parser.requiredURL("--profile")
    try EvidencePathGuard.requirePrivateStateOutsideAPI(sessionSeedURL)
    try EvidencePathGuard.requirePrivateStateOutsideAPI(profileURL)
    let sessionDomains = parser.values("--session-domain")
    guard !sessionDomains.isEmpty else {
      throw CLIError.invalidArguments(
        "auth restore requires at least one --session-domain"
      )
    }
    let seed = try DeterministicJSON.decode(
      PrivateSessionSeed.self,
      from: Data(contentsOf: sessionSeedURL)
    )
    let validation = try BrowserSessionRestoreValidator.validate(
      seed: seed,
      allowedDomains: sessionDomains
    )
    let transaction = try BrowserProfileRestoreTransaction(
      profileDirectory: profileURL
    )
    var committed = false
    defer {
      if !committed {
        try? transaction.rollback()
      }
    }
    let workerResult = try runBrowserRestoreWorker(
      seed: validation.seed,
      profileDirectory: transaction.stagingDirectory,
      browser: parser.value("--browser") ?? "chromium"
    )
    try transaction.commit()
    committed = true
    try write(
      command: "auth.restore",
      data: BrowserRestoreResult(
        brand: validation.seed.brand,
        market: validation.seed.market,
        restoredCookieCount: workerResult.restoredCookieCount,
        restoredOriginCount: workerResult.restoredOriginCount,
        seedSHA256: validation.seedSHA256
      ),
      json: parser.flag("--json")
    ) {
      "Restored durable scoped session state after browser restart verification."
    }
  }

  private static func runBrowserRestoreWorker(
    seed: PrivateSessionSeed,
    profileDirectory: URL,
    browser: String
  ) throws -> BrowserRestoreWorkerData {
    guard let node = executable(named: "node") else {
      throw CLIError.missingDependency("node")
    }
    let worker = try BrowserWorker.resourceURL()
    let request = BrowserRestoreWorkerRequest(
      command: "auth.restore",
      browser: browser,
      profileDirectory: profileDirectory.path,
      restoreSeed: seed
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var input = try encoder.encode(request)
    input.append(0x0A)
    let process = Process()
    let stdin = Pipe()
    let stdout = Pipe()
    process.executableURL = URL(fileURLWithPath: node)
    process.arguments = [worker.path]
    process.environment = browserWorkerEnvironment(
      base: ProcessInfo.processInfo.environment
    )
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = FileHandle.standardError
    try process.run()
    try stdin.fileHandleForWriting.write(contentsOf: input)
    try stdin.fileHandleForWriting.close()
    let output = try readBoundedWorkerOutput(
      from: stdout.fileHandleForReading,
      process: process
    )
    let response = try DeterministicJSON.decode(
      BrowserRestoreWorkerResponse.self,
      from: output
    )
    guard process.terminationStatus == 0, response.ok,
      let data = response.data
    else {
      throw CLIError.browserWorkerFailed(
        code: response.error?.code ?? "worker.restore_failed",
        message:
          response.error?.message
          ?? "Browser restore worker failed.",
        checkpoint: nil
      )
    }
    return data
  }

  private static func importWorkerHAR(
    _ result: BrowserWorkerData,
    parser: Arguments,
    flow: String
  ) throws -> CaptureReceipt {
    let surfaceValue = try parser.requiredValue("--surface")
    guard let surface = SourceSurface(rawValue: surfaceValue) else {
      throw CLIError.invalidArguments(
        "Unsupported source surface: \(surfaceValue)"
      )
    }
    return try HARImporter.importHAR(
      data: result.artifactStore.read(
        named: "capture.har",
        maximumBytes: maximumPrivateHARBytes
      ),
      options: HARImportOptions(
        brand: try parser.requiredValue("--brand"),
        market: parser.value("--market") ?? "cn",
        surface: surface,
        sourceId: try parser.requiredValue("--source-id"),
        sourceVersion: try parser.requiredValue("--source-version"),
        flow: flow,
        captureContext: CaptureContext(
          browser: result.browser,
          browserVersion: result.browserVersion,
          headless: parser.flag("--headless")
        ),
        includeURLPatterns: parser.values("--include-url-regex"),
        routeDiscriminatorQueryNames:
          parser.values("--route-discriminator-query")
      )
    )
  }

  private static func runBrowserWorker(
    name: String,
    parser: Arguments,
    profileDirectoryOverride: String? = nil
  ) throws -> BrowserWorkerData {
    guard executable(named: "node") != nil else {
      throw CLIError.missingDependency("node")
    }
    let url = try parser.requiredValue("--url")
    let outputStore = try PrivateArtifactStore(
      privateRoot: parser.requiredURL("--private-output"),
      createPrivateRoot: true
    )
    let scratchRoot = try PrivateArtifactStore.makeTemporaryRoot(
      prefix: "web-api-reverse-browser"
    )
    let scratchStore = try PrivateArtifactStore(privateRoot: scratchRoot)
    defer { try? scratchStore.removeRoot() }
    let outputDirectory = scratchStore.privateRoot.path
    let worker = try BrowserWorker.resourceURL()
    let authCompletionURLRegex = parser.value(
      "--auth-completion-url-regex"
    )
    let authRequiredCookieNames = parser.values(
      "--auth-require-cookie"
    )
    let authRequiredLocalStorageKeys = parser.values(
      "--auth-require-local-storage"
    )
    let authRequiredSessionStorageKeys = parser.values(
      "--auth-require-session-storage"
    )
    let authRequiredResponseURLRegex = parser.value(
      "--auth-require-response-url-regex"
    )
    let authRequiredResponseBodyRegex = parser.value(
      "--auth-require-response-body-regex"
    )
    let authRevisitTriggerResponseURLRegex = parser.value(
      "--auth-revisit-trigger-response-url-regex"
    )
    let authRevisitTriggerResponseBodyRegex = parser.value(
      "--auth-revisit-trigger-response-body-regex"
    )
    let authHasResponseRequirement =
      authRequiredResponseURLRegex != nil
      || authRequiredResponseBodyRegex != nil
    let authHasRevisitTriggerResponse =
      authRevisitTriggerResponseURLRegex != nil
      || authRevisitTriggerResponseBodyRegex != nil
    let authHasSessionRequirements =
      !authRequiredCookieNames.isEmpty
      || !authRequiredLocalStorageKeys.isEmpty
      || !authRequiredSessionStorageKeys.isEmpty
    let autoCompleteOnAuthRequirements = parser.flag(
      "--auto-complete-on-auth-requirements"
    )
    let authRevisitEntryOnSessionChange = parser.flag(
      "--auth-revisit-entry-on-session-change"
    )
    let candidateOnly = parser.flag("--candidate-only")
    let rejectURLRegex = parser.value("--reject-url-regex")
    let captureResponseURLRegexes = parser.values(
      "--capture-response-url-regex"
    )
    let authTimeoutMs: Int?
    if let rawTimeout = parser.value("--auth-timeout-ms") {
      guard let value = Int(rawTimeout), value > 0 else {
        throw CLIError.invalidArguments(
          "--auth-timeout-ms must be a positive integer"
        )
      }
      authTimeoutMs = value
    } else {
      authTimeoutMs = nil
    }
    if name != "auth.bootstrap",
      authCompletionURLRegex != nil || authTimeoutMs != nil
    {
      throw CLIError.invalidArguments(
        "Auth completion options require auth bootstrap"
      )
    }
    if autoCompleteOnAuthRequirements,
      name != "auth.bootstrap" || !authHasSessionRequirements
    {
      throw CLIError.invalidArguments(
        "--auto-complete-on-auth-requirements requires auth bootstrap with at least one declared session requirement"
      )
    }
    if authRevisitEntryOnSessionChange,
      name != "auth.bootstrap" || !autoCompleteOnAuthRequirements
        || !authHasSessionRequirements || !authHasResponseRequirement
    {
      throw CLIError.invalidArguments(
        "--auth-revisit-entry-on-session-change requires automatic auth bootstrap with declared session and authenticated-response requirements"
      )
    }
    if authHasRevisitTriggerResponse,
      name != "auth.bootstrap" || !autoCompleteOnAuthRequirements
        || !authHasSessionRequirements || !authHasResponseRequirement
    {
      throw CLIError.invalidArguments(
        "Auth revisit trigger responses require automatic auth bootstrap with declared session and final authenticated-response requirements"
      )
    }
    if authHasRevisitTriggerResponse,
      authRevisitTriggerResponseURLRegex == nil
        || authRevisitTriggerResponseBodyRegex == nil
    {
      throw CLIError.invalidArguments(
        "Auth revisit trigger responses require both --auth-revisit-trigger-response-url-regex and --auth-revisit-trigger-response-body-regex"
      )
    }
    if authHasRevisitTriggerResponse, authRevisitEntryOnSessionChange {
      throw CLIError.invalidArguments(
        "Response-triggered and session-change-triggered auth revisits are mutually exclusive"
      )
    }
    if authHasResponseRequirement,
      authRequiredResponseURLRegex == nil
        || authRequiredResponseBodyRegex == nil
    {
      throw CLIError.invalidArguments(
        "Auth response completion requires both --auth-require-response-url-regex and --auth-require-response-body-regex"
      )
    }
    if name != "auth.bootstrap",
      name != "auth.inspect",
      authHasResponseRequirement
    {
      throw CLIError.invalidArguments(
        "Auth response completion requires auth bootstrap or auth inspect"
      )
    }
    if name != "auth.bootstrap",
      name != "auth.inspect",
      authHasSessionRequirements
    {
      throw CLIError.invalidArguments(
        "Auth session requirements require auth bootstrap or auth inspect"
      )
    }
    if candidateOnly {
      guard name == "auth.inspect" else {
        throw CLIError.invalidArguments(
          "--candidate-only is limited to auth inspect"
        )
      }
      guard authHasSessionRequirements else {
        throw CLIError.invalidArguments(
          "--candidate-only requires at least one declared session requirement"
        )
      }
      guard rejectURLRegex == nil, !authHasResponseRequirement,
        !authHasRevisitTriggerResponse
      else {
        throw CLIError.invalidArguments(
          "--candidate-only cannot use navigation or authenticated-response gates"
        )
      }
      guard !parser.flag("--headed") else {
        throw CLIError.invalidArguments(
          "--candidate-only is noninteractive and cannot use --headed"
        )
      }
    }
    let sessionDomains = parser.values("--session-domain")
    let replaySeed: PrivateSessionSeed?
    if let path = parser.value("--session-seed") {
      guard name == "capture" || name == "auth.bootstrap" else {
        throw CLIError.invalidArguments(
          "--session-seed is supported by capture and auth bootstrap only"
        )
      }
      if name == "capture" {
        guard parser.value("--profile") == nil,
          profileDirectoryOverride == nil
        else {
          throw CLIError.invalidArguments(
            "capture --session-seed cannot write a persistent --profile"
          )
        }
      }
      guard !sessionDomains.isEmpty else {
        throw CLIError.invalidArguments(
          "--session-seed requires at least one --session-domain"
        )
      }
      let seedURL = URL(fileURLWithPath: path)
      try EvidencePathGuard.requirePrivateStateOutsideAPI(seedURL)
      let decoded = try DeterministicJSON.decode(
        PrivateSessionSeed.self,
        from: Data(contentsOf: seedURL)
      )
      let validation = try BrowserSessionReplayValidator.validate(
        seed: decoded,
        allowedDomains: sessionDomains
      )
      let brand = try parser.requiredValue("--brand")
      let market = parser.value("--market") ?? "cn"
      guard validation.seed.brand == brand,
        validation.seed.market == market
      else {
        throw CLIError.invalidArguments(
          "The private session seed brand and market must match the capture"
        )
      }
      replaySeed = validation.seed
    } else {
      replaySeed = nil
    }
    if authHasSessionRequirements, sessionDomains.isEmpty {
      throw CLIError.invalidArguments(
        "Auth session requirements require at least one --session-domain"
      )
    }
    if name != "auth.inspect", rejectURLRegex != nil {
      throw CLIError.invalidArguments(
        "--reject-url-regex requires auth inspect"
      )
    }
    if name != "auth.inspect", parser.flag("--headed") {
      throw CLIError.invalidArguments(
        "--headed is limited to auth inspect"
      )
    }
    if name != "capture", !captureResponseURLRegexes.isEmpty {
      throw CLIError.invalidArguments(
        "--capture-response-url-regex is limited to capture"
      )
    }
    if parser.flag("--headed"), parser.flag("--headless") {
      throw CLIError.invalidArguments(
        "--headed and --headless are mutually exclusive"
      )
    }
    let headless =
      name == "auth.inspect"
      ? !parser.flag("--headed")
      : parser.flag("--headless")
    let settleMs: Int?
    if let rawSettle = parser.value("--settle-ms") {
      guard
        let value = Int(rawSettle),
        (0...30_000).contains(value)
      else {
        throw CLIError.invalidArguments(
          "--settle-ms must be between 0 and 30000"
        )
      }
      settleMs = value
    } else {
      settleMs = nil
    }
    if authTimeoutMs != nil,
      authCompletionURLRegex == nil && !authHasSessionRequirements
        && !authHasResponseRequirement
    {
      throw CLIError.invalidArguments(
        "--auth-timeout-ms requires an auth completion URL or session requirement"
      )
    }
    let request = BrowserRequest(
      command: name,
      url: url,
      outputDirectory: outputDirectory,
      browser: parser.value("--browser") ?? "chromium",
      profileDirectory:
        profileDirectoryOverride ?? parser.value("--profile"),
      headless: headless,
      waitForUser:
        name == "auth.bootstrap" && !autoCompleteOnAuthRequirements,
      autoCompleteOnAuthRequirements: autoCompleteOnAuthRequirements,
      authRevisitEntryOnSessionChange: authRevisitEntryOnSessionChange,
      device: parser.value("--device"),
      authCompletionURLRegex: authCompletionURLRegex,
      authTimeoutMs: authTimeoutMs,
      sessionDomains: sessionDomains,
      authRequiredCookieNames: authRequiredCookieNames,
      authRequiredLocalStorageKeys: authRequiredLocalStorageKeys,
      authRequiredSessionStorageKeys:
        authRequiredSessionStorageKeys,
      authRequiredResponseURLRegex: authRequiredResponseURLRegex,
      authRequiredResponseBodyRegex: authRequiredResponseBodyRegex,
      authRevisitTriggerResponseURLRegex:
        authRevisitTriggerResponseURLRegex,
      authRevisitTriggerResponseBodyRegex:
        authRevisitTriggerResponseBodyRegex,
      candidateOnly: candidateOnly,
      rejectURLRegex: rejectURLRegex,
      durationMs: settleMs,
      responseBodyURLRegexes: captureResponseURLRegexes,
      replaySeed: replaySeed
    )
    let inputEncoder = JSONEncoder()
    inputEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var input = try inputEncoder.encode(request)
    input.append(0x0A)
    let process = Process()
    let stdin = Pipe()
    let stdout = Pipe()
    process.executableURL = URL(fileURLWithPath: executable(named: "node")!)
    process.arguments = [worker.path]
    process.environment = browserWorkerEnvironment(
      base: ProcessInfo.processInfo.environment
    )
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = FileHandle.standardError
    try process.run()
    defer {
      try? stdin.fileHandleForWriting.close()
      if process.isRunning {
        process.terminate()
        process.waitUntilExit()
      }
    }
    try stdin.fileHandleForWriting.write(contentsOf: input)
    try provideTerminalConfirmationIfRequired(
      command: name,
      autoCompleteOnAuthRequirements: autoCompleteOnAuthRequirements,
      readTerminalLine: { readLine() },
      writeConfirmation: {
        try stdin.fileHandleForWriting.write(
          contentsOf: Data("\n".utf8)
        )
      }
    )
    try stdin.fileHandleForWriting.close()
    let output = try readBoundedWorkerOutput(
      from: stdout.fileHandleForReading,
      process: process
    )
    let response = try DeterministicJSON.decode(
      BrowserWorkerResponse.self,
      from: output
    )
    let promotedData = try response.data.map {
      try promoteBrowserWorkerArtifacts(
        $0,
        from: scratchStore,
        to: outputStore,
        requireHAR: process.terminationStatus == 0 && response.ok
      )
    }
    guard process.terminationStatus == 0 else {
      throw CLIError.browserWorkerFailed(
        code: response.error?.code ?? "worker.failed",
        message: response.error?.message
          ?? "Browser worker failed.",
        checkpoint: promotedData
      )
    }
    guard response.ok, let data = promotedData else {
      throw CLIError.browserWorkerFailed(
        code: response.error?.code ?? "worker.failed",
        message:
          response.error?.message
          ?? "Browser worker returned no data.",
        checkpoint: promotedData
      )
    }
    return data
  }

  private static func promoteBrowserWorkerArtifacts(
    _ data: BrowserWorkerWireData,
    from scratchStore: PrivateArtifactStore,
    to outputStore: PrivateArtifactStore,
    requireHAR: Bool
  ) throws -> BrowserWorkerData {
    let expectedCapture = scratchStore.privateRoot.appending(
      path: "capture.json"
    ).path
    let expectedHAR = scratchStore.privateRoot.appending(
      path: "capture.har"
    ).path
    guard browserWorkerArtifactPathMatches(
      data.rawCapturePath,
      expected: expectedCapture
    ) else {
      throw PrivateArtifactStoreError.unsafeFile(
        "browser-worker-capture-path"
      )
    }
    guard browserWorkerArtifactPathMatches(
      data.rawHARPath,
      expected: expectedHAR
    ) else {
      throw PrivateArtifactStoreError.unsafeFile("browser-worker-har-path")
    }
    try outputStore.copyFile(
      named: "capture.json",
      from: scratchStore,
      maximumBytes: maximumPrivateCaptureBytes
    )
    if try scratchStore.contains("capture.har") {
      try outputStore.copyFile(
        named: "capture.har",
        from: scratchStore,
        maximumBytes: maximumPrivateHARBytes
      )
    } else if requireHAR {
      throw PrivateArtifactStoreError.missingFile("capture.har")
    }
    return BrowserWorkerData(
      wireData: data,
      artifactStore: outputStore
    )
  }

  static func browserWorkerArtifactPathMatches(
    _ reportedPath: String,
    expected expectedPath: String
  ) -> Bool {
    let reported = URL(fileURLWithPath: reportedPath).standardizedFileURL
    let expected = URL(fileURLWithPath: expectedPath).standardizedFileURL
    guard reported.lastPathComponent == expected.lastPathComponent else {
      return false
    }
    return reported.deletingLastPathComponent().resolvingSymlinksInPath().path
      == expected.deletingLastPathComponent().resolvingSymlinksInPath().path
  }

  static func requiresTerminalConfirmation(
    command: String,
    autoCompleteOnAuthRequirements: Bool
  ) -> Bool {
    command == "auth.bootstrap" && !autoCompleteOnAuthRequirements
  }

  static func provideTerminalConfirmationIfRequired(
    command: String,
    autoCompleteOnAuthRequirements: Bool,
    readTerminalLine: () -> String?,
    writeConfirmation: () throws -> Void
  ) throws {
    guard
      requiresTerminalConfirmation(
        command: command,
        autoCompleteOnAuthRequirements: autoCompleteOnAuthRequirements
      )
    else {
      return
    }
    guard readTerminalLine() != nil else {
      throw BrowserTerminalConfirmationError.inputUnavailable
    }
    try writeConfirmation()
  }

  private static func runBrowserProfileSessionWorker(
    profileDirectory: URL,
    profileLabel: String,
    urls: [String],
    browser: String
  ) throws -> BrowserProfileSessionResult {
    guard let node = executable(named: "node") else {
      throw CLIError.missingDependency("node")
    }
    let worker = try BrowserWorker.resourceURL()
    let request = BrowserProfileSessionWorkerRequest(
      command: "auth.profile-session",
      browser: browser,
      profileDirectory: profileDirectory.path,
      urls: urls
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var input = try encoder.encode(request)
    input.append(0x0A)

    let process = Process()
    let stdin = Pipe()
    let stdout = Pipe()
    process.executableURL = URL(fileURLWithPath: node)
    process.arguments = [worker.path]
    process.environment = browserWorkerEnvironment(
      base: ProcessInfo.processInfo.environment
    )
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = FileHandle.standardError
    try process.run()
    try stdin.fileHandleForWriting.write(contentsOf: input)
    try stdin.fileHandleForWriting.close()
    let output = try readBoundedWorkerOutput(
      from: stdout.fileHandleForReading,
      process: process
    )
    let response = try DeterministicJSON.decode(
      BrowserProfileSessionWorkerResponse.self,
      from: output
    )
    guard process.terminationStatus == 0, response.ok,
      let data = response.data
    else {
      throw CLIError.browserWorkerFailed(
        code: response.error?.code ?? "worker.profile_session_failed",
        message:
          response.error?.message
          ?? "Browser profile session failed.",
        checkpoint: nil
      )
    }
    return BrowserProfileSessionResult(
      profileLabel: profileLabel,
      browser: data.browser,
      browserVersion: data.browserVersion,
      openedURLCount: data.openedURLCount,
      preCloseCookieCount: data.preCloseCookieCount,
      preCloseOriginCount: data.preCloseOriginCount,
      sessionScopedCookieCount: data.sessionScopedCookieCount,
      sessionStorageOriginCount: data.sessionStorageOriginCount,
      persistedCookieCount: data.persistedCookieCount,
      persistedOriginCount: data.persistedOriginCount,
      lostCookieCount: data.lostCookieCount,
      providerSessionValidated: data.providerSessionValidated,
      requiresProviderHandoffBeforeClose:
        data.requiresProviderHandoffBeforeClose
    )
  }

  private static func codegenSwift(_ parser: Arguments) throws {
    let providerRoot = try parser.requiredURL("--provider-root")
    let packagePath = try parser.requiredURL("--package-path")
    let target = try parser.requiredValue("--target")
    guard let swift = executable(named: "swift") else {
      throw CLIError.missingDependency("swift")
    }
    let (validated, receipt) = try ContractValidator()
      .withValidatedPublishedAuthority(
        providerRoot: providerRoot
      ) { validated, lock in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: swift)
        process.arguments = [
          "build",
          "--package-path",
          packagePath.path,
          "--target",
          target,
        ]
        process.standardOutput = FileHandle.standardError
        process.standardError = FileHandle.standardError
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
          throw CLIError.codegenFailed(process.terminationStatus)
        }
        return (
          validated,
          SwiftCodegenReceipt(
            provider: lock.provider,
            market: lock.market,
            target: target,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            publishLockSHA256: validated.publishLockSHA256
          )
        )
      }
    if let output = parser.value("--receipt") {
      try DeterministicJSON.write(
        receipt,
        to: URL(fileURLWithPath: output)
      )
    }
    try write(
      command: "codegen.swift",
      data: receipt,
      json: parser.flag("--json")
    ) {
      "Built \(target) from validated Published contract at \(validated.publishedDirectory)"
    }
  }

  private static func existingJSONFiles(in directory: URL) throws -> [URL] {
    var isDirectory: ObjCBool = false
    guard
      FileManager.default.fileExists(
        atPath: directory.path,
        isDirectory: &isDirectory
      )
    else {
      return []
    }
    guard isDirectory.boolValue else {
      throw CLIError.invalidArguments(
        "Expected a directory at \(directory.path)"
      )
    }
    return try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ).filter { $0.pathExtension.lowercased() == "json" }
      .sorted { $0.path < $1.path }
  }

  private static func deduplicated<T: Codable & Equatable>(
    _ values: [T],
    id: KeyPath<T, String>
  ) throws -> [T] {
    var byID: [String: T] = [:]
    for value in values {
      let identifier = value[keyPath: id]
      if let existing = byID[identifier], existing != value {
        throw CLIError.conflictingEvidence(identifier)
      }
      byID[identifier] = value
    }
    return byID.keys.sorted().compactMap { byID[$0] }
  }

  private static func writePrivate<T: Encodable>(
    _ value: T,
    to url: URL
  ) throws {
    let store = try PrivateArtifactStore(
      privateRoot: url.deletingLastPathComponent(),
      createPrivateRoot: true
    )
    try store.write(
      DeterministicJSON.encode(value),
      named: url.lastPathComponent,
      maximumBytes: 64 * 1_024 * 1_024
    )
  }

  private static func write<T: Codable & Sendable>(
    command: String,
    data: T,
    json: Bool,
    human: () -> String
  ) throws {
    if json {
      let envelope = CommandEnvelope(ok: true, command: command, data: data)
      FileHandle.standardOutput.write(try DeterministicJSON.encode(envelope))
    } else {
      print(human())
    }
  }

  private static func writeFailure(_ error: Error) {
    let payload = CommandErrorPayload(
      code: errorCode(for: error),
      message: error.localizedDescription,
      privateCheckpointPath: privateCheckpointPath(for: error)
    )
    let envelope = CommandEnvelope<EmptyPayload>(
      ok: false,
      command: "web-api-reverse",
      error: payload
    )
    if let data = try? DeterministicJSON.encode(envelope) {
      FileHandle.standardOutput.write(data)
    }
  }

  static func errorCode(for error: Error) -> String {
    switch error {
    case CLIError.invalidArguments:
      "arguments.invalid"
    case CLIError.missingDependency:
      "dependency.missing"
    case CLIError.secretFindings:
      "artifacts.sensitive"
    case CLIError.codegenFailed:
      "codegen.failed"
    case CLIError.browserWorkerFailed(let code, _, _):
      code
    case CLIError.browserCheckpointPreserved(let code, _, _):
      code
    case CLIError.browserWorkerOutputTooLarge:
      "browser.output-too-large"
    case BrowserTerminalConfirmationError.inputUnavailable:
      "browser.confirmation-unavailable"
    case is BundleRouteInventoryError:
      "evidence.invalid"
    case is SourceCandidateInventoryError:
      "evidence.invalid"
    case is EvidencePathError,
      is PrivateArtifactStoreError:
      "path.invalid"
    case is TrustValidationError,
      is OpenAPIProjectionError,
      is TrustedContractBuildError:
      "trust.invalid"
    case is NativeVerificationError,
      is SessionMaterialError,
      is BrowserSessionScopeError,
      is BrowserSessionRestoreError,
      is ReversibleVerificationError,
      is ReversibleVerificationArtifactError,
      is SourceProductVerificationError,
      is CollectionVerificationError:
      "verification.invalid"
    case let error as BrowserProfileSnapshotError:
      error.diagnosticCode
    case CLIError.operationNotFound:
      "operation.not-found"
    case CLIError.conflictingEvidence:
      "evidence.conflict"
    case is ContractError:
      "contract.invalid"
    default:
      "internal.error"
    }
  }

  static func exitCode(for error: Error) -> Int32 {
    switch error {
    case CLIError.invalidArguments:
      2
    case CLIError.missingDependency:
      69
    case CLIError.secretFindings,
      CLIError.codegenFailed,
      CLIError.browserWorkerFailed,
      CLIError.browserCheckpointPreserved,
      CLIError.browserWorkerOutputTooLarge,
      is BundleRouteInventoryError,
      is SourceCandidateInventoryError,
      is EvidencePathError,
      is PrivateArtifactStoreError,
      is TrustValidationError,
      is OpenAPIProjectionError,
      is TrustedContractBuildError,
      is NativeVerificationError,
      is SessionMaterialError,
      is BrowserSessionScopeError,
      is BrowserSessionRestoreError,
      is ReversibleVerificationError,
      is ReversibleVerificationArtifactError,
      is SourceProductVerificationError,
      is CollectionVerificationError,
      is BrowserTerminalConfirmationError,
      is ContractError:
      65
    case BrowserProfileSnapshotError.sourceInUse:
      75
    case is BrowserProfileSnapshotError:
      66
    case CLIError.operationNotFound:
      66
    case CLIError.conflictingEvidence:
      65
    default:
      70
    }
  }

  private static func privateCheckpointPath(for error: Error) -> String? {
    guard
      case CLIError.browserCheckpointPreserved(_, _, let path) = error
    else { return nil }
    return path
  }

  private static func executable(named name: String) -> String? {
    let environmentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
    for directory in environmentPath.split(separator: ":") {
      let candidate = URL(fileURLWithPath: String(directory))
        .appending(path: name)
        .path
      if FileManager.default.isExecutableFile(atPath: candidate) {
        return candidate
      }
    }
    return nil
  }

  static func browserWorkerEnvironment(
    base: [String: String],
    parentProcessID: pid_t = getppid()
  ) -> [String: String] {
    if let existing = base["WEB_API_REVERSE_OWNER_PID"],
      let processID = Int32(existing),
      processID > 0
    {
      return base
    }
    var environment = base
    environment["WEB_API_REVERSE_OWNER_PID"] = String(parentProcessID)
    return environment
  }

  static func readBoundedWorkerOutput(
    from handle: FileHandle,
    process: Process,
    maximumBytes: Int = maximumBrowserWorkerResponseBytes
  ) throws -> Data {
    precondition(maximumBytes > 0)
    var output = Data()
    while true {
      let remaining = maximumBytes - output.count
      let readSize =
        remaining >= 64 * 1_024 ? 64 * 1_024 : remaining + 1
      let chunk = try handle.read(upToCount: readSize) ?? Data()
      guard !chunk.isEmpty else {
        process.waitUntilExit()
        return output
      }
      guard chunk.count <= remaining else {
        try? handle.close()
        if process.isRunning {
          process.terminate()
        }
        process.waitUntilExit()
        throw CLIError.browserWorkerOutputTooLarge(
          maximumBytes: maximumBytes
        )
      }
      output.append(chunk)
    }
  }

  private static func workerIsReady(node: String, worker: URL) -> Bool {
    let process = Process()
    let stdin = Pipe()
    process.executableURL = URL(fileURLWithPath: node)
    process.arguments = [worker.path]
    process.environment = browserWorkerEnvironment(
      base: ProcessInfo.processInfo.environment
    )
    process.standardInput = stdin
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      try stdin.fileHandleForWriting.write(
        contentsOf: Data("{\"command\":\"doctor\"}\n".utf8)
      )
      try stdin.fileHandleForWriting.close()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }

  private static let help = """
    web-api-reverse 0.1.0

    Usage:
      web-api-reverse doctor [--json]
      web-api-reverse scaffold --provider-root <path> --provider <id> [--market <id>] [--json]
      web-api-reverse capture --url <url> --private-output <path> --receipt-output <json> --brand <id> --surface <surface> --source-id <id> --source-version <revision> [--market <id>] [--browser <name>] [--device <playwright-device>] [--profile <private-profile-directory> | --session-seed <private.json> --session-domain <domain> ...] [--headless] [--settle-ms <0...30000>] [--capture-response-url-regex <regex> ...] [--include-url-regex <regex> ...] [--route-discriminator-query <name> ...] [--json]
      web-api-reverse capture-request --request <private.json> --surface <surface> --source-id <id> --source-version <revision> --output <API/Observed/capture.json> [--session-seed <private.json>] [--flow <id>] [--captured-at <iso8601>] [--allow-remote-write] [--route-discriminator-query <name> ...] [--private-response <private.json>] [--json]
      web-api-reverse import-har --har <private.har> --output <receipt.json> --brand <id> --surface <surface> --source-id <id> --source-version <revision> [--market <id>] [--flow <id>] [--include-url-regex <regex> ...] [--route-discriminator-query <name> ...] [--json]
      web-api-reverse inventory-bundles --har <private.har> --output <API/Observed/bundle-routes/source.json> --brand <id> --surface <surface> --source-id <id> --source-version <revision> [--market <id>] [--captured-at <iso8601>] [--max-bundle-bytes <bytes>] [--max-total-bytes <bytes>] [--json]
      web-api-reverse inventory-source-candidates --har <private.har> --policy <source-candidate-policy.json> --output <private.json> [--json]
      web-api-reverse inventory --observed-dir <path> [--receipt <capture.json> ...] [--verification <verification.json> ...] [--source-verification <source-product-verification.json> ...] [--annotations <json>] [--source-manifest <json>] [--json]
      web-api-reverse extract-request --har <private.har> --capture-receipt <API/Observed/capture.json> --catalog <API/Observed/catalog.json> --operation-id <id> --output <private.json> [--json]
      web-api-reverse verify --catalog <catalog.json> --operation-id <id> (--request <private.json> | --capture-receipt <capture.json>) --receipt-output <API/Observed/verifications/verification.json> --request-evidence-output <API/Observed/request-evidence.json> [--session-seed <private.json>] [--private-response <private.json>] [--verified-at <iso8601>] [--allow-remote-write] [--json]
      web-api-reverse verify-reversible --catalog <catalog.json> --plan <private.json> --private-transaction-dir <private-directory> --output-dir <API/Observed/verifications> --allow-remote-write [--session-seed <private.json>] [--verified-at <iso8601>] [--json]
      web-api-reverse verify-source-product --source-product <private-source-product-import-v1.json> --policy <API/Config/source-product-policy.json> --platform-provider-root <path> --output <API/Observed/source-verifications/receipt.json> [--json]
      web-api-reverse validate-source-product-policy --policy <API/Config/source-product-policy.json> [--json]
      web-api-reverse validate-source-product --receipt <API/Observed/source-verifications/receipt.json> --policy <API/Config/source-product-policy.json> --platform-provider-root <path> [--json]
      web-api-reverse verify-collection --provider-root <path> --provider <id> [--market <id>] --source-product-receipt <API/Observed/source-verifications/receipt.json> --platform-provider-root <path> --add-transcript <private.json> --delete-transcript <private.json> --output <API/Observed/collection-verifications/receipt.json> --allow-remote-write [--verified-at <iso8601>] [--json]
      web-api-reverse trust --observed-dir <path> --trusted-dir <path>/API/Trusted --manifest <json> --verification <json> [--verification <json> ...] [--json]
      web-api-reverse auth bootstrap --url <url> --private-output <path> --brand <id> [--market <id>] [--browser <name>] [--device <playwright-device>] [--profile <private-profile-directory>] [--session-profile-label <logical-profile>] [--session-seed <private.json> --session-domain <domain> ...] [--auth-completion-url-regex <regex>] [--auth-require-cookie <name> ...] [--auth-require-local-storage <key> ...] [--auth-require-session-storage <key> ...] [--auto-complete-on-auth-requirements] [--auth-revisit-entry-on-session-change | --auth-revisit-trigger-response-url-regex <regex> --auth-revisit-trigger-response-body-regex <regex>] [--auth-require-response-url-regex <regex> --auth-require-response-body-regex <regex>] [--auth-timeout-ms <milliseconds>] (--session-only | --receipt-output <API/Observed/receipt.json> --surface <surface> --source-id <id> --source-version <revision>) [--include-url-regex <regex> ...] [--route-discriminator-query <name> ...] [--json]
      web-api-reverse auth inspect --url <authenticated-url> --profile <existing-profile-directory> [--session-profile-label <logical-profile>] --private-output <path> --brand <id> --session-domain <domain> [--session-domain <domain> ...] [--market <id>] [--device <playwright-device>] [--auth-require-cookie <name> ...] [--auth-require-local-storage <key> ...] [--auth-require-session-storage <key> ...] [--candidate-only | --auth-require-response-url-regex <regex> --auth-require-response-body-regex <regex>] [--headed] [--reject-url-regex <regex>] [--settle-ms <0...30000>] [--json]
      web-api-reverse auth restore --session-seed <private.json> --profile <persistent-profile> --session-domain <domain> [--session-domain <domain> ...] [--browser <name>] [--json]
      web-api-reverse auth profile-session --profile <persistent-profile> --profile-label <label> --url <account-url> [--url <url> ...] [--browser <name>] [--json]
      web-api-reverse codegen swift --provider-root <path> --package-path <path> --target <name> [--receipt <json>] [--json]
      web-api-reverse publish --provider-root <path> --provider <id> [--market <id>] [--published-at <iso8601>] [--json]
      web-api-reverse approve --provider-root <path> --provider <id> --reviewer <id> --zero-unknown [--market <id>] [--approved-at <iso8601>] [--json]
      web-api-reverse validate --provider-root <path> [--json]
      web-api-reverse coverage --catalog <json> --source-lock <json> [--strict] [--output <json>] [--json]
      web-api-reverse diff --from <catalog.json> --to <catalog.json> [--json]
      web-api-reverse scan-artifacts --root <path> [--json]
      web-api-reverse sanitize-artifacts --root <path> [--json]

    Browser and session output must use a private directory outside API/.
    """
}

enum BrowserTerminalConfirmationError: Error, Equatable, LocalizedError {
  case inputUnavailable

  var errorDescription: String? {
    switch self {
    case .inputUnavailable:
      "Manual authentication confirmation requires interactive terminal input."
    }
  }
}

private struct SourceProductPolicyValidationPayload: Codable, Sendable {
  let provider: String
  let market: String
  let sourceId: String
  let platformProvider: String
  let sourceProjection: SourceProductProjection
  let acceptedShopIDCount: Int
}

private struct BrowserRequest: Codable, Sendable {
  let command: String
  let url: String
  let outputDirectory: String
  let browser: String
  let profileDirectory: String?
  let headless: Bool
  let waitForUser: Bool
  let autoCompleteOnAuthRequirements: Bool
  let authRevisitEntryOnSessionChange: Bool
  let device: String?
  let authCompletionURLRegex: String?
  let authTimeoutMs: Int?
  let sessionDomains: [String]
  let authRequiredCookieNames: [String]
  let authRequiredLocalStorageKeys: [String]
  let authRequiredSessionStorageKeys: [String]
  let authRequiredResponseURLRegex: String?
  let authRequiredResponseBodyRegex: String?
  let authRevisitTriggerResponseURLRegex: String?
  let authRevisitTriggerResponseBodyRegex: String?
  let candidateOnly: Bool
  let rejectURLRegex: String?
  let durationMs: Int?
  let responseBodyURLRegexes: [String]
  let replaySeed: PrivateSessionSeed?
}

private let maximumPrivateCaptureBytes = 64 * 1024 * 1024
private let maximumPrivateHARBytes = 512 * 1024 * 1024
private let maximumPrivateSessionSeedBytes = 4 * 1024 * 1024
private let maximumBrowserWorkerResponseBytes = 1 * 1024 * 1024

private struct BrowserWorkerResponse: Codable, Sendable {
  let ok: Bool
  let data: BrowserWorkerWireData?
  let error: BrowserWorkerErrorPayload?
}

private struct BrowserWorkerWireData: Codable, Sendable {
  let rawCapturePath: String
  let rawHARPath: String
  let exchangeCount: Int
  let cookieCount: Int
  let browser: String
  let browserVersion: String
  let device: String?
  let storageOriginCount: Int?
}

private struct BrowserWorkerData: Sendable {
  let rawCapturePath: String
  let rawHARPath: String
  let exchangeCount: Int
  let cookieCount: Int
  let browser: String
  let browserVersion: String
  let device: String?
  let storageOriginCount: Int?
  let artifactStore: PrivateArtifactStore

  init(
    wireData: BrowserWorkerWireData,
    artifactStore: PrivateArtifactStore
  ) {
    rawCapturePath = artifactStore.privateRoot.appending(
      path: "capture.json"
    ).path
    rawHARPath = artifactStore.privateRoot.appending(
      path: "capture.har"
    ).path
    exchangeCount = wireData.exchangeCount
    cookieCount = wireData.cookieCount
    browser = wireData.browser
    browserVersion = wireData.browserVersion
    device = wireData.device
    storageOriginCount = wireData.storageOriginCount
    self.artifactStore = artifactStore
  }
}

private struct BrowserWorkerErrorPayload: Codable, Sendable {
  let code: String
  let message: String
}

private struct BrowserRestoreWorkerRequest: Codable, Sendable {
  let command: String
  let browser: String
  let profileDirectory: String
  let restoreSeed: PrivateSessionSeed
}

private struct BrowserProfileSessionWorkerRequest: Codable, Sendable {
  let command: String
  let browser: String
  let profileDirectory: String
  let urls: [String]
}

private struct BrowserProfileSessionWorkerResponse: Codable, Sendable {
  let ok: Bool
  let data: BrowserProfileSessionWorkerData?
  let error: BrowserWorkerErrorPayload?
}

private struct BrowserProfileSessionWorkerData: Codable, Sendable {
  let browser: String
  let browserVersion: String
  let openedURLCount: Int
  let preCloseCookieCount: Int
  let preCloseOriginCount: Int
  let sessionScopedCookieCount: Int
  let sessionStorageOriginCount: Int
  let persistedCookieCount: Int
  let persistedOriginCount: Int
  let lostCookieCount: Int
  let providerSessionValidated: Bool
  let requiresProviderHandoffBeforeClose: Bool
}

private struct BrowserProfileSessionResult: Codable, Sendable {
  let profileLabel: String
  let browser: String
  let browserVersion: String
  let openedURLCount: Int
  let preCloseCookieCount: Int
  let preCloseOriginCount: Int
  let sessionScopedCookieCount: Int
  let sessionStorageOriginCount: Int
  let persistedCookieCount: Int
  let persistedOriginCount: Int
  let lostCookieCount: Int
  let providerSessionValidated: Bool
  let requiresProviderHandoffBeforeClose: Bool
}

private struct BrowserRestoreWorkerResponse: Codable, Sendable {
  let ok: Bool
  let data: BrowserRestoreWorkerData?
  let error: BrowserWorkerErrorPayload?
}

private struct BrowserRestoreWorkerData: Codable, Sendable {
  let restoredCookieCount: Int
  let restoredOriginCount: Int
  let browser: String
}

private struct BrowserRestoreResult: Codable, Sendable {
  let brand: String
  let market: String
  let restoredCookieCount: Int
  let restoredOriginCount: Int
  let seedSHA256: String
}

private struct BrowserCaptureResult: Codable, Sendable {
  let privateCapturePath: String
  let privateHARPath: String
  let receiptPath: String?
  let captureId: String?
  let exchangeCount: Int
  let privateSessionSeedPath: String?

  init(
    privateCapturePath: String,
    privateHARPath: String,
    receiptPath: String?,
    captureId: String?,
    exchangeCount: Int,
    privateSessionSeedPath: String? = nil
  ) {
    self.privateCapturePath = privateCapturePath
    self.privateHARPath = privateHARPath
    self.receiptPath = receiptPath
    self.captureId = captureId
    self.exchangeCount = exchangeCount
    self.privateSessionSeedPath = privateSessionSeedPath
  }
}

private struct ScanResult: Codable, Sendable {
  let root: String
  let findings: [ArtifactFinding]
}

private struct ImportHARResult: Codable, Sendable {
  let receiptPath: String
  let captureId: String
  let exchangeCount: Int
}

private struct BundleInventoryCommandResult: Codable, Sendable {
  let receiptPath: String
  let receiptId: String
  let bundleCount: Int
  let candidateCount: Int
}

private struct SourceCandidateInventoryCommandResult: Codable, Sendable {
  let outputPath: String
  let provider: String
  let platformProvider: String
  let scannedExchangeCount: Int
  let candidateCount: Int
  let harSHA256: String
}

private struct NativeCaptureCommandResult: Codable, Sendable {
  let captureId: String
  let receiptPath: String
  let privateResponsePath: String?
}

private struct ExtractRequestCommandResult: Codable, Sendable {
  let operationId: String
  let matchedExchangeCount: Int
  let privateRequestPath: String
}

private struct InventoryCommandResult: Codable, Sendable {
  let observedDirectory: String
  let captureCount: Int
  let verificationCount: Int
  let sourceProductVerificationCount: Int
  let operationCount: Int
  let zeroUnknown: Bool
  let requiredCoverageAreaCount: Int
  let missingCoverageAreaCount: Int
  let unverifiedSafeCount: Int
}

private struct VerifyCommandResult: Codable, Sendable {
  let operationId: String
  let verificationId: String
  let outcome: ResponseOutcome
  let receiptPath: String
  let requestEvidencePath: String
  let privateResponsePath: String?
}

private struct ReversibleVerifyCommandResult: Codable, Sendable {
  let sequenceId: String
  let restorationProven: Bool
  let artifacts: ReversibleVerificationArtifactPaths
}

private enum CLIError: Error, LocalizedError {
  case invalidArguments(String)
  case missingDependency(String)
  case secretFindings([ArtifactFinding])
  case codegenFailed(Int32)
  case browserWorkerFailed(
    code: String,
    message: String,
    checkpoint: BrowserWorkerData?
  )
  case browserCheckpointPreserved(
    code: String,
    message: String,
    path: String
  )
  case browserWorkerOutputTooLarge(maximumBytes: Int)
  case operationNotFound(String)
  case conflictingEvidence(String)

  var errorDescription: String? {
    switch self {
    case .invalidArguments(let message):
      message
    case .missingDependency(let name):
      "Required dependency is not available on PATH: \(name)"
    case .secretFindings(let findings):
      """
      Sensitive material found in \(findings.count) artifact finding(s): \
      \(Set(findings.map(\.path)).sorted().joined(separator: ", "))
      """
    case .codegenFailed(let status):
      "Swift code generation build failed with status \(status)."
    case .browserWorkerFailed(_, let message, _):
      message
    case .browserCheckpointPreserved(_, let message, _):
      message
    case .browserWorkerOutputTooLarge(let maximumBytes):
      "Browser worker output exceeded the \(maximumBytes)-byte limit."
    case .operationNotFound(let operationID):
      "Observed operation was not found: \(operationID)"
    case .conflictingEvidence(let identifier):
      "Conflicting evidence uses the same identifier: \(identifier)"
    }
  }
}

private struct Arguments {
  let values: [String]

  init(_ values: [String]) {
    self.values = values
  }

  var positional: [String] {
    values.filter { !$0.hasPrefix("--") }
  }

  func droppingFirstPositional() -> Arguments {
    guard let first = values.firstIndex(where: { !$0.hasPrefix("--") }) else {
      return self
    }
    var copy = values
    copy.remove(at: first)
    return Arguments(copy)
  }

  func flag(_ name: String) -> Bool {
    values.contains(name)
  }

  func value(_ name: String) -> String? {
    guard let index = values.firstIndex(of: name), values.indices.contains(index + 1) else {
      return nil
    }
    return values[index + 1]
  }

  func values(_ name: String) -> [String] {
    values.indices.compactMap { index in
      guard values[index] == name,
        values.indices.contains(index + 1)
      else {
        return nil
      }
      return values[index + 1]
    }
  }

  func requiredValue(_ name: String) throws -> String {
    guard let value = value(name), !value.isEmpty else {
      throw CLIError.invalidArguments("Missing required option \(name)")
    }
    return value
  }

  func requiredURL(_ name: String) throws -> URL {
    URL(fileURLWithPath: try requiredValue(name))
  }
}
