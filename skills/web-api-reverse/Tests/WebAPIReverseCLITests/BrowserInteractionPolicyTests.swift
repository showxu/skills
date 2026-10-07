import Testing

@testable import WebAPIReverseCLI

@Suite("Browser CLI interaction policy")
struct BrowserInteractionPolicyTests {
  @Test("Browser workers inherit the owning caller process")
  func browserWorkerEnvironmentUsesCallerUnlessExplicitlyOwned() {
    let inherited = WebAPIReverseCLI.browserWorkerEnvironment(
      base: ["FIXTURE": "preserved"],
      parentProcessID: 42
    )
    let explicit = WebAPIReverseCLI.browserWorkerEnvironment(
      base: ["WEB_API_REVERSE_OWNER_PID": "84"],
      parentProcessID: 42
    )

    #expect(inherited["FIXTURE"] == "preserved")
    #expect(inherited["WEB_API_REVERSE_OWNER_PID"] == "42")
    #expect(explicit["WEB_API_REVERSE_OWNER_PID"] == "84")
  }

  @Test("Automatic auth completion never waits for terminal input")
  func automaticCompletionDoesNotWaitForTerminalInput() throws {
    var reads = 0
    var writes = 0

    try WebAPIReverseCLI.provideTerminalConfirmationIfRequired(
      command: "auth.bootstrap",
      autoCompleteOnAuthRequirements: true,
      readTerminalLine: {
        reads += 1
        return "unexpected"
      },
      writeConfirmation: { writes += 1 }
    )

    #expect(reads == 0)
    #expect(writes == 0)
  }

  @Test("Manual auth bootstrap still waits for explicit confirmation")
  func manualBootstrapWaitsForTerminalInput() throws {
    var reads = 0
    var writes = 0

    try WebAPIReverseCLI.provideTerminalConfirmationIfRequired(
      command: "auth.bootstrap",
      autoCompleteOnAuthRequirements: false,
      readTerminalLine: {
        reads += 1
        return ""
      },
      writeConfirmation: { writes += 1 }
    )

    #expect(reads == 1)
    #expect(writes == 1)
  }

  @Test("Non-auth browser commands never consume terminal confirmation")
  func nonAuthCommandsDoNotWaitForTerminalInput() throws {
    var reads = 0
    var writes = 0

    try WebAPIReverseCLI.provideTerminalConfirmationIfRequired(
      command: "capture",
      autoCompleteOnAuthRequirements: false,
      readTerminalLine: {
        reads += 1
        return "unexpected"
      },
      writeConfirmation: { writes += 1 }
    )

    #expect(reads == 0)
    #expect(writes == 0)
  }

  @Test("Manual auth bootstrap rejects terminal EOF")
  func manualBootstrapRejectsTerminalEOF() {
    var reads = 0
    var writes = 0

    #expect(throws: BrowserTerminalConfirmationError.inputUnavailable) {
      try WebAPIReverseCLI.provideTerminalConfirmationIfRequired(
        command: "auth.bootstrap",
        autoCompleteOnAuthRequirements: false,
        readTerminalLine: {
          reads += 1
          return nil
        },
        writeConfirmation: { writes += 1 }
      )
    }

    #expect(reads == 1)
    #expect(writes == 0)
  }
}
