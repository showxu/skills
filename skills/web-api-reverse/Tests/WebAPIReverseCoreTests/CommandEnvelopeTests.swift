import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite
struct CommandEnvelopeTests {
  @Test
  func errorPayloadCarriesStructuredPrivateCheckpointPath() throws {
    let payload = CommandErrorPayload(
      code: "worker.auth_response_timeout",
      message: "Authentication response timed out.",
      privateCheckpointPath: "/private/provider/session-seed.json"
    )

    let data = try DeterministicJSON.encode(payload)
    let decoded = try DeterministicJSON.decode(
      CommandErrorPayload.self,
      from: data
    )

    #expect(decoded == payload)
    #expect(
      decoded.privateCheckpointPath
        == "/private/provider/session-seed.json"
    )
  }

  @Test
  func legacyErrorPayloadWithoutCheckpointStillDecodes() throws {
    let decoded = try JSONDecoder().decode(
      CommandErrorPayload.self,
      from: Data(#"{"code":"worker.failure","message":"failed"}"#.utf8)
    )

    #expect(decoded.privateCheckpointPath == nil)
  }
}
