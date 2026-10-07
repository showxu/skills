import Foundation

public struct CommandErrorPayload: Codable, Equatable, Sendable {
  public let code: String
  public let message: String
  public let privateCheckpointPath: String?

  public init(
    code: String,
    message: String,
    privateCheckpointPath: String? = nil
  ) {
    self.code = code
    self.message = message
    self.privateCheckpointPath = privateCheckpointPath
  }
}

public struct CommandEnvelope<DataPayload: Codable & Sendable>: Codable, Sendable {
  public let schemaVersion: Int
  public let ok: Bool
  public let command: String
  public let data: DataPayload?
  public let error: CommandErrorPayload?

  public init(
    ok: Bool,
    command: String,
    data: DataPayload? = nil,
    error: CommandErrorPayload? = nil
  ) {
    self.schemaVersion = 1
    self.ok = ok
    self.command = command
    self.data = data
    self.error = error
  }
}

public struct EmptyPayload: Codable, Equatable, Sendable {
  public init() {}
}

public struct DoctorResult: Codable, Equatable, Sendable {
  public let swiftAvailable: Bool
  public let nodeAvailable: Bool
  public let playwrightWorkerAvailable: Bool

  public init(
    swiftAvailable: Bool,
    nodeAvailable: Bool,
    playwrightWorkerAvailable: Bool
  ) {
    self.swiftAvailable = swiftAvailable
    self.nodeAvailable = nodeAvailable
    self.playwrightWorkerAvailable = playwrightWorkerAvailable
  }
}
