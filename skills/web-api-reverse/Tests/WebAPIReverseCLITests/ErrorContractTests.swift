import Testing
import WebAPIReverseCore

@testable import WebAPIReverseCLI

@Suite("CLI error contract")
struct ErrorContractTests {
  @Test("Stale source-product evidence is a verification failure")
  func staleSourceProductEvidenceIsNotInternal() {
    let error = SourceProductVerificationError.invalidReceipt(
      "platform Published lock digest does not match the current contract"
    )

    #expect(WebAPIReverseCLI.errorCode(for: error) == "verification.invalid")
    #expect(WebAPIReverseCLI.exitCode(for: error) == 65)
  }
}
