import Foundation

public struct SwiftCodegenReceipt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: String
  public let provider: String
  public let market: String
  public let target: String
  public let generatedAt: String
  public let publishLockSHA256: String

  public init(
    provider: String,
    market: String,
    target: String,
    generatedAt: String,
    publishLockSHA256: String
  ) {
    self.schemaVersion = 1
    self.kind = "web-api-reverse.swift-codegen-receipt"
    self.provider = provider
    self.market = market
    self.target = target
    self.generatedAt = generatedAt
    self.publishLockSHA256 = publishLockSHA256
  }
}
