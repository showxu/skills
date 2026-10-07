import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Private session material")
struct SessionMaterialTests {
  @Test("Decoding applies the documented empty derivation default")
  func decodesMissingSessionDerivations() throws {
    let data = Data(
      """
      {
        "schemaVersion": 1,
        "kind": "web-api-reverse.private-verification-request",
        "brand": "fixture",
        "market": "cn",
        "url": "https://example.test/session",
        "headers": {}
      }
      """.utf8
    )

    let request = try DeterministicJSON.decode(
      PrivateVerificationRequestSpec.self,
      from: data
    )

    #expect(request.sessionDerivations.isEmpty)
  }

  @Test("An explicit logical profile label is separate from its browser path")
  func resolvesLogicalProfileLabel() throws {
    #expect(
      try BrowserSessionProfileLabel.resolve(
        explicitLabel: "default",
        browserProfile: "/private/browser-profiles/official-cn"
      ) == "default"
    )
    #expect(
      try BrowserSessionProfileLabel.resolve(
        explicitLabel: nil,
        browserProfile: "/private/browser-profile"
      ) == "/private/browser-profile"
    )
    #expect(
      try BrowserSessionProfileLabel.resolve(
        explicitLabel: nil,
        browserProfile: nil
      ) == "ephemeral"
    )
  }

  @Test("Explicit logical profile labels fail closed")
  func rejectsInvalidLogicalProfileLabel() {
    for label in ["", ".", "..", "../shared", "account/profile", "账户"] {
      #expect(
        throws:
          BrowserSessionProfileLabelError.invalidExplicitLabel(label)
      ) {
        try BrowserSessionProfileLabel.resolve(
          explicitLabel: label,
          browserProfile: "/private/browser-profile"
        )
      }
    }
  }

  @Test("Aliases and derivations resolve recursively from preferred origin storage")
  func resolvesAliasesAndDerivations() throws {
    let spec = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      safety: .safeRead,
      url: "https://{{session.apiHost}}/p/session",
      method: "POST",
      headers: [
        "authorization": "Bearer {{session.accessToken}}"
      ],
      body: .object([
        "expiration": .string("{{session.expiration}}"),
        "refresh": .string("{{session.refreshToken}}"),
      ]),
      sessionAliases: [
        "accessToken": ["access_token"],
        "duration": ["expires_in"],
        "environment": ["env"],
        "fetchedAt": ["fetched_at"],
        "refreshToken": ["refresh_token"],
      ],
      sessionDerivations: [
        "apiHost": .lookup(
          sourceField: "environment",
          values: ["idc": "i.example.test"],
          missingValue: nil
        ),
        "expiration": .unixExpirationMilliseconds(
          fetchedAtField: "fetchedAt",
          durationSecondsField: "duration"
        ),
      ]
    )

    let resolved = try SessionMaterialResolver.resolve(
      spec,
      seed: sessionSeed()
    )

    #expect(resolved.url == "https://i.example.test/p/session")
    #expect(
      resolved.headers["authorization"]
        == "Bearer nested-access-token"
    )
    #expect(
      resolved.body
        == .object([
          "expiration": .string("1700003600000"),
          "refresh": .string("nested-refresh-token"),
        ])
    )
  }

  @Test("Templated requests require explicit seed, aliases, and material")
  func failsClosedForMissingSessionFacts() {
    let templated = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      url: "https://example.test/{{session.path}}"
    )
    #expect(throws: SessionMaterialError.sessionSeedRequired) {
      try SessionMaterialResolver.resolve(templated, seed: nil)
    }
    #expect(throws: SessionMaterialError.aliasMapRequired) {
      try SessionMaterialResolver.resolve(
        templated,
        seed: sessionSeed()
      )
    }

    let missing = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      url: "https://example.test/{{session.path}}",
      sessionAliases: ["path": ["not_present"]]
    )
    #expect(throws: SessionMaterialError.missingField("path")) {
      try SessionMaterialResolver.resolve(
        missing,
        seed: sessionSeed()
      )
    }
  }

  @Test("Unknown lookup values and nonnumeric expiration inputs fail")
  func rejectsUnapprovedDerivations() {
    let lookup = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      url: "https://{{session.host}}",
      sessionAliases: ["environment": ["env"]],
      sessionDerivations: [
        "host": .lookup(
          sourceField: "environment",
          values: ["cloud": "a.example.test"],
          missingValue: nil
        )
      ]
    )
    #expect(
      throws: SessionMaterialError.unmappedLookup(
        sourceField: "environment",
        targetField: "host"
      )
    ) {
      try SessionMaterialResolver.resolve(
        lookup,
        seed: sessionSeed()
      )
    }

    let expiration = PrivateVerificationRequestSpec(
      brand: "fixture",
      market: "cn",
      url: "https://example.test/{{session.expiration}}",
      sessionAliases: [
        "duration": ["access_token"],
        "fetchedAt": ["fetched_at"],
      ],
      sessionDerivations: [
        "expiration": .unixExpirationMilliseconds(
          fetchedAtField: "fetchedAt",
          durationSecondsField: "duration"
        )
      ]
    )
    #expect(throws: SessionMaterialError.nonNumericField("duration")) {
      try SessionMaterialResolver.resolve(
        expiration,
        seed: sessionSeed()
      )
    }
  }
}

private func sessionSeed() -> PrivateSessionSeed {
  PrivateSessionSeed(
    brand: "fixture",
    market: "cn",
    profile: "test",
    createdAt: "2026-07-29T00:00:00Z",
    sourceURL: "https://i.example.test/login",
    cookies: [
      PrivateSessionCookie(
        name: "session",
        value: "private-cookie",
        domain: ".example.test",
        path: "/",
        expires: -1,
        httpOnly: true,
        secure: true,
        sameSite: "Lax"
      )
    ],
    origins: [
      PrivateSessionOrigin(
        origin: "https://other.example.test",
        localStorage: [
          "access_token": "lower-priority-token"
        ],
        sessionStorage: [:]
      ),
      PrivateSessionOrigin(
        origin: "https://i.example.test",
        localStorage: [
          "account": """
          {
            "access_token":"nested-access-token",
            "refresh_token":"nested-refresh-token",
            "env":"idc",
            "fetched_at":1700000000,
            "expires_in":3600
          }
          """
        ],
        sessionStorage: [:]
      ),
    ]
  )
}
