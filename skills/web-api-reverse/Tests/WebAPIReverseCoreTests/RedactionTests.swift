import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Structural evidence redaction")
struct RedactionTests {
  @Test(
    "API credential names are sensitive",
    arguments: ["api-key", "app_key", "clientId"]
  )
  func apiCredentialNamesAreSensitive(name: String) {
    #expect(EvidenceRedactor.isSensitiveName(name))
    #expect(EvidenceRedactor.isSensitiveHeaderName(name))
    #expect(
      EvidenceRedactor.redact(
        .object([name: .string("credential-value")])
      ) == .object([name: .string(EvidenceRedactor.placeholder)])
    )
  }

  @Test("API credentials embedded in text are redacted")
  func embeddedAPICredentialsAreRedacted() {
    for input in [
      #"window.config={apiKey:'credential-value'}"#,
      #"{\"responseFixture\":\"{\\\"storefront_API_KEY\\\":\\\"credential-value\\\"}\"}"#,
    ] {
      let redacted = EvidenceRedactor.redact(input)
      #expect(redacted.contains(EvidenceRedactor.placeholder))
      #expect(!redacted.contains("credential-value"))
      #expect(!EvidenceRedactor.containsRawSecrets(in: redacted))
    }
  }

  @Test("Phone redaction does not mistake digest substrings for PII")
  func digestPhoneSubstringIsNotPII() {
    let digest = "a11380000000b" + String(repeating: "c", count: 51)
    #expect(EvidenceRedactor.redact(digest) == digest)
    #expect(!EvidenceRedactor.containsRawSecrets(in: digest))
    #expect(
      EvidenceRedactor.redact("contact: 13800000000")
        == "contact: [REDACTED]"
    )
    #expect(
      EvidenceRedactor.containsRawSecrets(in: "contact: 13800000000")
    )
  }

  @Test("Sensitive values lose content while retaining JSON structure")
  func sensitiveShapeIsPreserved() {
    let input: JSONValue = .object([
      "accessToken": .string("raw-access-token"),
      "enabled": .bool(true),
      "productCode": .string("484203"),
      "name": .string("SUPIMA COTTON T"),
      "profile": .object([
        "name": .string("Private User"),
        "phone": .number(13_800_138_000),
        "email": .string("person@example.com"),
      ]),
    ])

    let redacted = EvidenceRedactor.redact(input)

    guard case .object(let object) = redacted else {
      Issue.record("Expected a redacted object")
      return
    }
    #expect(object["accessToken"] == .string("[REDACTED]"))
    #expect(object["enabled"] == .bool(true))
    #expect(object["productCode"] == .string("484203"))
    #expect(object["name"] == .string("SUPIMA COTTON T"))
    guard case .object(let profile) = object["profile"] else {
      Issue.record("Expected profile shape")
      return
    }
    #expect(profile["name"] == .string("[REDACTED]"))
    #expect(profile["phone"] == .number(0))
    #expect(profile["email"] == .string("[REDACTED]"))
  }

  @Test("URL sanitization keeps names but removes values and credentials")
  func urlSanitizationIsDeterministic() throws {
    let first = try EvidenceRedactor.sanitizeURL(
      "https://user:pass@example.test/p/484203?color=09&access_token=secret#account"
    )
    let second = try EvidenceRedactor.sanitizeURL(
      "https://example.test/p/484203?access_token=other&color=10"
    )

    #expect(first == second)
    #expect(!first.contains("secret"))
    #expect(!first.contains("user"))
    #expect(!first.contains("pass"))
    #expect(!first.contains("09"))
    #expect(first.contains("access_token"))
    #expect(first.contains("%5BREDACTED%5D"))
    #expect(first.contains("color=%7Bvalue%7D"))
  }

  @Test("Account identity aliases are redacted without changing product facts")
  func accountAliasesAreRedacted() {
    let redacted = EvidenceRedactor.redact(
      JSONValue.object([
        "data": .object([
          "displayNick": .string("private-display"),
          "nick": .string("private-nick"),
          "userNumId": .string("123456"),
        ]),
        "product": .object([
          "name": .string("SUPIMA COTTON T"),
          "productCode": .string("484203"),
        ]),
      ])
    )

    guard case .object(let root) = redacted,
      case .object(let data) = root["data"],
      case .object(let product) = root["product"]
    else {
      Issue.record("Expected object fixtures")
      return
    }
    #expect(data["displayNick"] == .string("[REDACTED]"))
    #expect(data["nick"] == .string("[REDACTED]"))
    #expect(data["userNumId"] == .string("[REDACTED]"))
    #expect(product["name"] == .string("SUPIMA COTTON T"))
    #expect(product["productCode"] == .string("484203"))
  }

  @Test("Header and cookie evidence contains names only")
  func headerAndCookieEvidenceIsStructural() {
    let headers = [
      "Authorization": "Bearer raw-secret-value-that-must-not-survive",
      "Cookie": "session_id=private; region=cn",
      "Accept": "application/json",
      "Sec-CH-UA-Mobile": "?0",
      "X-User-Mobile": "13800000000",
    ]

    let presence = EvidenceRedactor.headerPresence(headers)
    #expect(
      presence.map(\.name)
        == [
          "accept", "authorization", "cookie", "sec-ch-ua-mobile",
          "x-user-mobile",
        ]
    )
    #expect(presence.first { $0.name == "authorization" }?.sensitive == true)
    #expect(presence.first { $0.name == "sec-ch-ua-mobile" }?.sensitive == false)
    #expect(presence.first { $0.name == "x-user-mobile" }?.sensitive == true)
    #expect(EvidenceRedactor.cookieNames(headers) == ["region", "session_id"])
  }
}
