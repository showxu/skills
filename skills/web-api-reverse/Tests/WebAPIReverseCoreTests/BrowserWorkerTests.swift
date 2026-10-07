import Foundation
import Testing

@testable import WebAPIReverseCore

@Suite("Playwright browser worker")
struct BrowserWorkerTests {
  @Test("Closes the browser context when the owning command exits")
  func closesBrowserWhenOwnerExits() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let owner = Process()
    owner.executableURL = URL(fileURLWithPath: "/bin/sleep")
    owner.arguments = ["1"]
    try owner.run()
    defer {
      if owner.isRunning {
        owner.terminate()
        owner.waitUntilExit()
      }
    }
    let output = fixture.root.appending(path: "owner-exit-output")
    let profile = fixture.root.appending(path: "owner-exit-profile")
    let closeMarker = fixture.root.appending(path: "context-closed")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "autoCompleteOnAuthRequirements": true,
        "authTimeoutMs": 10_000,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["never-present"],
      ],
      ownerProcessID: owner.processIdentifier,
      contextCloseMarker: closeMarker
    )

    #expect(result.status == 130)
    #expect(try result.errorCode() == "worker.owner_terminated")
    #expect(FileManager.default.fileExists(atPath: closeMarker.path))
  }

  @Test("Merges every captured storage origin into one private session seed")
  func extractsAllWorkerStorageOrigins() throws {
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(
        """
        {
          "capturedAt": "2026-07-29T10:00:00Z",
          "sessionSeed": {
            "storageState": {
              "cookies": [],
              "origins": [{
                "origin": "https://example.test",
                "localStorage": [
                  {"name": "persisted", "value": "one"}
                ]
              }]
            },
            "webStorages": [{
              "origin": "https://example.test",
              "localStorage": {"live": "two"},
              "sessionStorage": {"main": "three"}
            }, {
              "origin": "https://frame.test",
              "localStorage": {},
              "sessionStorage": {"frame": "four"}
            }]
          }
        }
        """.utf8
      )
    )

    let seed = BrowserWorker.extractSessionSeed(
      capture: capture,
      brand: "fixture",
      market: "cn",
      profile: "persistent",
      sourceURL: "https://example.test/login"
    )

    #expect(
      seed.origins.map(\.origin) == [
        "https://example.test",
        "https://frame.test",
      ])
    #expect(
      seed.origins[0].localStorage == [
        "live": "two",
        "persisted": "one",
      ])
    #expect(seed.origins[0].sessionStorage == ["main": "three"])
    #expect(seed.origins[1].sessionStorage == ["frame": "four"])
  }

  @Test("Scopes a shared browser profile to one provider domain")
  func scopesSharedProfileSessionState() throws {
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(
        """
        {
          "capturedAt": "2026-07-30T10:00:00Z",
          "sessionSeed": {
            "storageState": {
              "cookies": [{
                "name": "uniqlo-session",
                "value": "private-uniqlo-cookie",
                "domain": ".uniqlo.cn",
                "path": "/",
                "expires": -1,
                "httpOnly": true,
                "secure": true,
                "sameSite": "Lax"
              }, {
                "name": "hm-session",
                "value": "private-hm-cookie",
                "domain": ".hm.com.cn",
                "path": "/",
                "expires": -1,
                "httpOnly": true,
                "secure": true,
                "sameSite": "Lax"
              }],
              "origins": [{
                "origin": "https://www.uniqlo.cn",
                "localStorage": [{"name": "uniqlo", "value": "one"}]
              }, {
                "origin": "https://www.hm.com.cn",
                "localStorage": [{"name": "hm", "value": "two"}]
              }]
            },
            "webStorages": []
          }
        }
        """.utf8
      )
    )

    let seed = try BrowserWorker.extractScopedSessionSeed(
      capture: capture,
      brand: "uniqlo",
      market: "cn",
      profile: "shared-official",
      sourceURL: "https://www.uniqlo.cn/account",
      allowedDomains: ["uniqlo.cn"]
    )

    #expect(seed.cookies.map(\.name) == ["uniqlo-session"])
    #expect(seed.origins.map(\.origin) == ["https://www.uniqlo.cn"])
  }

  @Test("Rejects session scopes that do not own the source URL")
  func rejectsCrossProviderSessionScope() throws {
    let capture = BrowserWorkerPrivateCapture(
      capturedAt: "2026-07-30T10:00:00Z",
      sessionSeed: BrowserWorkerSessionSnapshot(
        storageState: PrivateBrowserStorageState(
          cookies: [],
          origins: []
        ),
        webStorages: []
      )
    )

    #expect(throws: BrowserSessionScopeError.self) {
      try BrowserWorker.extractScopedSessionSeed(
        capture: capture,
        brand: "uniqlo",
        market: "cn",
        profile: "shared-official",
        sourceURL: "https://www.hm.com.cn/account",
        allowedDomains: ["uniqlo.cn"]
      )
    }
  }

  @Test("Rejects unknown devices and invalid auth regex before launch")
  func rejectsInvalidBrowserConfiguration() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }

    let unknownOutput = fixture.root.appending(path: "unknown-output")
    let unknown = try fixture.run([
      "command": "capture",
      "url": "https://example.test/",
      "outputDirectory": unknownOutput.path,
      "browser": "chromium",
      "device": "Missing Device",
    ])
    #expect(unknown.status == 1)
    #expect(try unknown.errorCode() == "worker.invalid_device")
    #expect(!FileManager.default.fileExists(atPath: unknownOutput.path))

    let regexOutput = fixture.root.appending(path: "regex-output")
    let invalidRegex = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/login",
      "outputDirectory": regexOutput.path,
      "browser": "chromium",
      "authCompletionURLRegex": "[",
    ])
    #expect(invalidRegex.status == 1)
    #expect(
      try invalidRegex.errorCode()
        == "worker.invalid_auth_completion_regex"
    )
    #expect(!FileManager.default.fileExists(atPath: regexOutput.path))

    let automaticOutput = fixture.root.appending(path: "automatic-output")
    let invalidAutomatic = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/login",
      "outputDirectory": automaticOutput.path,
      "browser": "chromium",
      "autoCompleteOnAuthRequirements": true,
    ])
    #expect(invalidAutomatic.status == 1)
    #expect(
      try invalidAutomatic.errorCode()
        == "worker.invalid_auth_auto_completion"
    )
    #expect(!FileManager.default.fileExists(atPath: automaticOutput.path))

    let revisitOutput = fixture.root.appending(path: "revisit-output")
    let invalidRevisit = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/login",
      "outputDirectory": revisitOutput.path,
      "browser": "chromium",
      "autoCompleteOnAuthRequirements": true,
      "authRevisitEntryOnSessionChange": true,
      "sessionDomains": ["example.test"],
      "authRequiredCookieNames": ["session"],
    ])
    #expect(invalidRevisit.status == 1)
    #expect(
      try invalidRevisit.errorCode()
        == "worker.invalid_auth_session_change_revisit"
    )
    #expect(!FileManager.default.fileExists(atPath: revisitOutput.path))

    let responseRevisitOutput = fixture.root.appending(
      path: "response-revisit-output"
    )
    let invalidResponseRevisit = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/login",
      "outputDirectory": responseRevisitOutput.path,
      "browser": "chromium",
      "autoCompleteOnAuthRequirements": true,
      "sessionDomains": ["example.test"],
      "authRequiredCookieNames": ["session"],
      "authRequiredResponseURLRegex":
        #"^https://api\.example\.test/account$"#,
      "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
      "authRevisitTriggerResponseURLRegex":
        #"^https://login\.example\.test/silent$"#,
    ])
    #expect(invalidResponseRevisit.status == 1)
    #expect(
      try invalidResponseRevisit.errorCode()
        == "worker.invalid_auth_response_revisit"
    )
    #expect(
      !FileManager.default.fileExists(atPath: responseRevisitOutput.path)
    )

    let responseRegexOutput = fixture.root.appending(
      path: "response-regex-output"
    )
    let invalidResponseRegex = try fixture.run([
      "command": "capture",
      "url": "https://example.test/",
      "outputDirectory": responseRegexOutput.path,
      "browser": "chromium",
      "responseBodyURLRegexes": ["["],
    ])
    #expect(invalidResponseRegex.status == 1)
    #expect(
      try invalidResponseRegex.errorCode()
        == "worker.invalid_response_body_url_regex"
    )
    #expect(
      !FileManager.default.fileExists(atPath: responseRegexOutput.path)
    )

    let authResponseCaptureOutput = fixture.root.appending(
      path: "auth-response-capture-output"
    )
    let invalidAuthResponseCapture = try fixture.run([
      "command": "auth.inspect",
      "url": "https://example.test/account",
      "outputDirectory": authResponseCaptureOutput.path,
      "browser": "chromium",
      "responseBodyURLRegexes": [#"^https://example\.test/"#],
    ])
    #expect(invalidAuthResponseCapture.status == 1)
    #expect(
      try invalidAuthResponseCapture.errorCode()
        == "worker.invalid_response_body_url_regex"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: authResponseCaptureOutput.path
      )
    )
  }

  @Test("Profile session audits one exact browser profile without input")
  func profileSessionAuditsExactProfileWithoutInput() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "persistent-profile")

    let result = try fixture.run(
      [
        "command": "auth.profile-session",
        "browser": "chromium",
        "profileDirectory": profile.path,
        "urls": [
          "https://example.test/account",
          "https://second.example.test/login",
        ],
      ]
    )

    #expect(result.status == 0)
    #expect(try result.dataInt("openedURLCount") == 2)
    #expect(try result.dataInt("preCloseCookieCount") == 1)
    #expect(try result.dataInt("sessionScopedCookieCount") == 1)
    #expect(try result.dataInt("sessionStorageOriginCount") == 2)
    #expect(try result.dataInt("persistedCookieCount") == 1)
    #expect(try result.dataInt("persistedOriginCount") == 1)
    #expect(try result.dataInt("lostCookieCount") == 0)
    #expect(try result.dataBool("providerSessionValidated") == false)
    #expect(
      try result.dataBool("requiresProviderHandoffBeforeClose")
        == true
    )
    #expect(FileManager.default.fileExists(atPath: profile.path))
  }

  @Test("Profile session reports session-cookie loss across restart")
  func profileSessionReportsSessionCookieLoss() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "persistent-profile")

    let result = try fixture.run(
      [
        "command": "auth.profile-session",
        "browser": "chromium",
        "profileDirectory": profile.path,
        "urls": ["https://example.test/account"],
      ],
      dropSessionCookiesOnClose: true
    )

    #expect(result.status == 0)
    #expect(try result.dataInt("preCloseCookieCount") == 1)
    #expect(try result.dataInt("persistedCookieCount") == 0)
    #expect(try result.dataInt("lostCookieCount") == 1)
    #expect(
      try result.dataBool("requiresProviderHandoffBeforeClose")
        == true
    )
  }

  @Test("Auth timeout preserves the persistent profile and hardens HAR")
  func timesOutWithoutReplacingProfile() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "timeout-output")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "device": "Fixture Phone",
        "authCompletionURLRegex": "/complete$",
        "authTimeoutMs": 20,
      ],
      confirm: true
    )

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.auth_timeout")
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
    #expect(try permissions(output) == 0o700)
    #expect(try permissions(output.appending(path: "capture.har")) == 0o600)
  }

  @Test("Closing automatic auth exits immediately and preserves checkpoint")
  func closedAutomaticAuthFlowFailsFast() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "closed-auth-flow")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "autoCompleteOnAuthRequirements": true,
        "authRevisitEntryOnSessionChange": true,
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 5_000,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      closeFlowPagesAfterNavigationMilliseconds: 10
    )

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.auth_flow_closed")
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
    #expect(try permissions(output.appending(path: "capture.json")) == 0o600)
  }

  @Test("Auth completion requires confirmation and a matching URL")
  func requiresExplicitAuthConfirmation() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let missingConfirmationOutput = fixture.root.appending(
      path: "missing-confirmation"
    )
    let missingConfirmation = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/login",
      "outputDirectory": missingConfirmationOutput.path,
      "browser": "chromium",
      "authCompletionURLRegex": "/login$",
      "authTimeoutMs": 100,
    ])
    #expect(missingConfirmation.status == 1)
    #expect(
      try missingConfirmation.errorCode()
        == "worker.user_confirmation_required"
    )

    let completedOutput = fixture.root.appending(path: "completed-auth")
    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": completedOutput.path,
        "browser": "chromium",
        "device": "Fixture Phone",
        "authCompletionURLRegex": "/login$",
        "authTimeoutMs": 1_000,
      ],
      confirm: true
    )
    #expect(completed.status == 0)
    #expect(try completed.dataString("device") == "Fixture Phone")
    #expect(
      try permissions(completedOutput.appending(path: "capture.json"))
        == 0o600
    )
  }

  @Test("Auth bootstrap waits for scoped usable session material")
  func waitsForScopedAuthSessionMaterial() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "auth-material")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "authCompletionURLRegex": "/login$",
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "authRequiredLocalStorageKeys": ["live"],
        "authRequiredSessionStorageKeys": ["main"],
      ],
      confirm: true,
      failStorageState: true,
      expectScopedRecordHAR: true
    )

    #expect(result.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    let storage = try #require(capture.sessionSeed.webStorages.first)
    #expect(storage.localStorage == ["live": "main"])
    #expect(storage.sessionStorage == ["main": "one"])
  }

  @Test("Auth bootstrap persists the exact qualifying session snapshot")
  func persistsExactQualifyingAuthSnapshot() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "qualifying-auth-snapshot")

    let result = try fixture.run(
      [
        "command": "auth.inspect",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      dropSessionAfterCookieReads: 3
    )

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name) == ["session"]
    )
  }

  @Test("Auth bootstrap retains session material captured before confirmation")
  func retainsQualifyingSnapshotBeforeConfirmation() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "eager-qualifying-auth")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      confirm: true,
      confirmationDelayMilliseconds: 1_000,
      dropSessionAfterCookieReads: 1
    )

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name) == ["session"]
    )
  }

  @Test("Auth bootstrap can complete from declared session material")
  func autoCompletesFromAuthRequirements() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "automatic-auth")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "waitForUser": false,
        "autoCompleteOnAuthRequirements": true,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ]
    )

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name) == ["session"]
    )
    #expect(
      String(decoding: result.errorOutput, as: UTF8.self).contains(
        "continue automatically"
      )
    )
  }

  @Test("Cookie-only auth does not read web storage")
  func cookieOnlyAuthSkipsWebStorage() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "cookie-only-auth")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "waitForUser": false,
        "autoCompleteOnAuthRequirements": true,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      inaccessibleStorageHost: "example.test"
    )

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(capture.sessionSeed.webStorages.isEmpty)
  }

  @Test("Scoped auth ignores inaccessible storage outside its domains")
  func scopedAuthSkipsUnrelatedInaccessibleStorage() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "scoped-storage")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "waitForUser": false,
        "autoCompleteOnAuthRequirements": true,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "authRequiredLocalStorageKeys": ["live"],
      ],
      inaccessibleStorageHost: "frame.test"
    )

    #expect(result.status == 0)
  }

  @Test("Scoped auth rejects inaccessible required storage")
  func scopedAuthRejectsInaccessibleRequiredStorage() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "inaccessible-required-storage")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "waitForUser": false,
        "autoCompleteOnAuthRequirements": true,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "authRequiredLocalStorageKeys": ["live"],
      ],
      inaccessibleStorageHost: "example.test"
    )

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.storage_capture_failed")
  }

  @Test("Auth bootstrap requires a matching successful business response")
  func waitsForAuthenticatedBusinessResponse() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "auth-response")

    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 1_000,
      ],
      confirm: true,
      authenticatedResponse: .success
    )
    #expect(completed.status == 0)

    let missingOutput = fixture.root.appending(
      path: "auth-response-missing"
    )
    let missing = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": missingOutput.path,
        "browser": "chromium",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 20,
      ],
      confirm: true,
      authenticatedResponse: .failure
    )
    #expect(missing.status == 1)
    #expect(
      try missing.errorCode()
        == "worker.auth_response_requirement_timeout"
    )
    #expect(
      try missing.dataString("rawCapturePath")
        == missingOutput.appending(path: "capture.json").path
    )
    #expect(
      FileManager.default.fileExists(
        atPath: missingOutput.appending(path: "capture.json").path
      )
    )
    #expect(
      try permissions(missingOutput.appending(path: "capture.json"))
        == 0o600
    )
  }

  @Test("Auth bootstrap settles before its final session snapshot")
  func settlesBeforeFinalAuthSnapshot() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "auth-settle")

    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "autoCompleteOnAuthRequirements": true,
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 100,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "durationMs": 40,
      ],
      authenticatedResponse: .success,
      addCookieAfterNavigationMilliseconds: 10
    )

    #expect(completed.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name)
        .contains("stabilized-session")
    )
  }

  @Test("Auth bootstrap revisits the entry after user confirmation")
  func revisitsEntryForAuthenticatedBusinessResponse() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "auth-response-after-revisit")

    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 100,
      ],
      confirm: true,
      authenticatedResponse: .successAfterConfirmationRevisit
    )

    #expect(completed.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Automatic auth bootstrap revisits after required session change")
  func revisitsEntryAfterRequiredSessionChange() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(
      path: "auth-response-after-session-change"
    )

    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "autoCompleteOnAuthRequirements": true,
        "authRevisitEntryOnSessionChange": true,
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 1_000,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["stabilized-session"],
      ],
      authenticatedResponse: .successAfterConfirmationRevisit,
      addCookieAfterNavigationMilliseconds: 100
    )

    #expect(completed.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Automatic auth bootstrap revisits after an intermediate response")
  func revisitsEntryAfterIntermediateResponse() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(
      path: "auth-response-triggered-revisit"
    )

    let completed = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "autoCompleteOnAuthRequirements": true,
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authRevisitTriggerResponseURLRegex":
          #"^https://login\.example\.test/silent$"#,
        "authRevisitTriggerResponseBodyRegex":
          #""resultCode"\s*:\s*100"#,
        "authTimeoutMs": 1_000,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      authenticatedResponse: .intermediateThenSuccessAfterRevisit
    )

    #expect(completed.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Automatic auth bootstrap does not revisit for unchanged session")
  func doesNotRevisitEntryForUnchangedSession() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "unchanged-auth-session")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "autoCompleteOnAuthRequirements": true,
        "authRevisitEntryOnSessionChange": true,
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 20,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      authenticatedResponse: .successAfterConfirmationRevisit
    )

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.auth_session_change_timeout")
  }

  @Test("Automatic auth bootstrap accepts an already successful entry response")
  func acceptsSuccessfulEntryResponseWithoutSessionChange() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "existing-auth-session")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "autoCompleteOnAuthRequirements": true,
        "authRevisitEntryOnSessionChange": true,
        "authCompletionURLRegex": "/account$",
        "authRequiredResponseURLRegex":
          #"^https://api\.example\.test/account$"#,
        "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
        "authTimeoutMs": 1_000,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "replaySeed": [
          "cookies": [
            [
              "name": "session",
              "value": "private-existing-session",
              "domain": ".example.test",
              "path": "/",
              "expires": -1,
              "httpOnly": true,
              "secure": true,
              "sameSite": "Lax",
            ]
          ],
          "origins": [],
        ],
      ],
      authenticatedResponse: .success
    )

    #expect(result.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Auth bootstrap rejects incomplete session material")
  func rejectsIncompleteAuthSessionMaterial() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "missing-auth-material")

    let result = try fixture.run(
      [
        "command": "auth.bootstrap",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "authCompletionURLRegex": "/login$",
        "authTimeoutMs": 20,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["missing-session"],
      ],
      confirm: true
    )

    #expect(result.status == 1)
    #expect(
      try result.errorCode()
        == "worker.auth_session_requirements_timeout"
    )
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
    #expect(
      try result.dataString("rawCapturePath")
        == output.appending(path: "capture.json").path
    )
  }

  @Test("Captures device-emulated multi-page storage with private permissions")
  func capturesMultiPageStorage() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "capture-output")

    let result = try fixture.run(
      [
        "command": "capture",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "device": "Fixture Phone",
        "durationMs": 0,
      ],
      expectedNavigationWaitUntil: "commit",
      captureResponseBody: true
    )

    #expect(result.status == 0)
    #expect(try result.dataString("device") == "Fixture Phone")
    #expect(try result.dataInt("storageOriginCount") == 2)
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
    #expect(try permissions(output) == 0o700)
    #expect(try permissions(output.appending(path: "capture.json")) == 0o600)
    #expect(try permissions(output.appending(path: "capture.har")) == 0o600)

    let har =
      try JSONSerialization.jsonObject(
        with: Data(contentsOf: output.appending(path: "capture.har"))
      ) as? [String: Any]
    let log = try #require(har?["log"] as? [String: Any])
    let entries = try #require(log["entries"] as? [[String: Any]])
    let entry = try #require(entries.first)
    let response = try #require(entry["response"] as? [String: Any])
    let content = try #require(response["content"] as? [String: Any])
    #expect(content["encoding"] as? String == "base64")
    let encodedBody = try #require(content["text"] as? String)
    #expect(
      Data(base64Encoded: encodedBody).map {
        String(decoding: $0, as: UTF8.self)
      } == #"{"currentPrice":"99.00"}"#
    )

    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(
        contentsOf: output.appending(path: "capture.json")
      )
    )
    let seed = BrowserWorker.extractSessionSeed(
      capture: capture,
      brand: "fixture",
      market: "cn",
      profile: profile.path,
      sourceURL: "https://example.test/login"
    )
    #expect(
      seed.origins.map(\.origin) == [
        "https://example.test",
        "https://frame.test",
      ])
    let main = try #require(seed.origins.first)
    #expect(main.localStorage["persisted"] == "one")
    #expect(main.localStorage["live"] == "main")
    #expect(main.sessionStorage["main"] == "one")
    #expect(main.sessionStorage["shared"] == "popup")
    #expect(seed.origins[1].sessionStorage["frame"] == "two")
  }

  @Test("Explicit safe-read route capture backfills an unavailable response body")
  func capturesExplicitSafeReadResponseBody() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "route-capture-output")

    let result = try fixture.run(
      [
        "command": "capture",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "durationMs": 0,
        "responseBodyURLRegexes": [
          #"^https://example\.test/login$"#
        ],
      ],
      captureRouteResponseBody: true
    )

    #expect(result.status == 0)
    let har =
      try JSONSerialization.jsonObject(
        with: Data(contentsOf: output.appending(path: "capture.har"))
      ) as? [String: Any]
    let log = try #require(har?["log"] as? [String: Any])
    let entries = try #require(log["entries"] as? [[String: Any]])
    let entry = try #require(entries.first)
    let response = try #require(entry["response"] as? [String: Any])
    let content = try #require(response["content"] as? [String: Any])
    #expect(content["encoding"] as? String == "base64")
    let encodedBody = try #require(content["text"] as? String)
    #expect(
      Data(base64Encoded: encodedBody).map {
        String(decoding: $0, as: UTF8.self)
      } == #"{"code":"605"}"#
    )
  }

  @Test("Explicit route fulfills the fetched response when its body is unavailable")
  func fulfillsFetchedResponseAfterBodyFailure() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "route-body-failure-output")

    let result = try fixture.run(
      [
        "command": "capture",
        "url": "https://example.test/login",
        "outputDirectory": output.path,
        "browser": "chromium",
        "durationMs": 0,
        "responseBodyURLRegexes": [
          #"^https://example\.test/login$"#
        ],
      ],
      captureRouteResponseBody: true,
      routeResponseBodyFails: true
    )

    #expect(result.status == 0)
    let har =
      try JSONSerialization.jsonObject(
        with: Data(
          contentsOf: output.appending(path: "capture.har")
        )
      ) as? [String: Any]
    let log = try #require(har?["log"] as? [String: Any])
    let entries = try #require(log["entries"] as? [[String: Any]])
    let entry = try #require(entries.first)
    let response = try #require(entry["response"] as? [String: Any])
    let content = try #require(response["content"] as? [String: Any])
    #expect(content["text"] == nil)
  }

  @Test("Session inspection is noninteractive and preserves the profile")
  func inspectsPersistedSessionWithoutConfirmation() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "inspect-output")

    let result = try fixture.run(
      [
        "command": "auth.inspect",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "durationMs": 0,
        "rejectURLRegex": #"/login(?:[/?#]|$)"#,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
        "authRequiredLocalStorageKeys": ["live"],
        "authRequiredSessionStorageKeys": ["main"],
      ],
      expectedHeadless: true,
      expectSessionRestore: true,
      expectedNavigationWaitUntil: "domcontentloaded"
    )

    #expect(result.status == 0)
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
    #expect(try permissions(output.appending(path: "capture.json")) == 0o600)
  }

  @Test("Session inspection rejects missing required material immediately")
  func rejectsIncompletePersistedSessionMaterial() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "inspect-missing-output")

    let result = try fixture.run([
      "command": "auth.inspect",
      "url": "https://example.test/account",
      "outputDirectory": output.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "durationMs": 0,
      "sessionDomains": ["example.test"],
      "authRequiredCookieNames": ["missing-session"],
    ])

    #expect(result.status == 1)
    #expect(
      try result.errorCode()
        == "worker.auth_session_requirements_missing"
    )
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Failed inspection preserves eager refresh material privately")
  func preservesEagerMaterialAfterNavigationDeletion() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "inspect-eager-output")

    let result = try fixture.run(
      [
        "command": "auth.inspect",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "durationMs": 0,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      expectSessionRestore: true,
      deleteSessionOnNavigation: true
    )

    #expect(result.status == 1)
    let data = try Data(
      contentsOf: output.appending(path: "capture.json")
    )
    let document = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let seed = try #require(document["sessionSeed"] as? [String: Any])
    let storage = try #require(seed["storageState"] as? [String: Any])
    let cookies = try #require(storage["cookies"] as? [[String: Any]])
    #expect(cookies.compactMap { $0["name"] as? String } == ["session"])
  }

  @Test("Session inspection rejects a login redirect without replacing profile")
  func rejectsPersistedSessionLoginRedirect() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "inspect-login-output")

    let result = try fixture.run([
      "command": "auth.inspect",
      "url": "https://example.test/login",
      "outputDirectory": output.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "durationMs": 0,
      "rejectURLRegex": #"/login(?:[/?#]|$)"#,
    ])

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.session_requires_login")
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
  }

  @Test("Candidate inspection extracts the startup snapshot without navigation")
  func extractsCandidateWithoutNavigation() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "inspect-candidate-output")

    let result = try fixture.run(
      [
        "command": "auth.inspect",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "candidateOnly": true,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      expectSessionRestore: true,
      rejectNavigation: true
    )

    #expect(result.status == 0)
    #expect(try result.dataInt("exchangeCount") == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name) == ["session"]
    )
  }

  @Test("Session inspection rejects a login frame below the account page")
  func rejectsPersistedSessionLoginFrame() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let sentinel = profile.appending(path: "keep.txt")
    try Data("keep".utf8).write(to: sentinel)
    let output = fixture.root.appending(path: "inspect-login-frame-output")

    let result = try fixture.run([
      "command": "auth.inspect",
      "url": "https://example.test/account",
      "outputDirectory": output.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "durationMs": 0,
      "rejectURLRegex": #"frame\.test"#,
    ])

    #expect(result.status == 1)
    #expect(try result.errorCode() == "worker.session_requires_login")
    #expect(FileManager.default.fileExists(atPath: sentinel.path))
  }

  @Test("Session inspection requires an authenticated business response")
  func requiresAuthenticatedResponseDuringInspection() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let successfulOutput = fixture.root.appending(
      path: "inspect-auth-response-success"
    )
    let requirement: [String: Any] = [
      "command": "auth.inspect",
      "url": "https://example.test/account",
      "outputDirectory": successfulOutput.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "durationMs": 0,
      "authTimeoutMs": 1_000,
      "authRequiredResponseURLRegex":
        #"^https://api\.example\.test/account$"#,
      "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
    ]

    let successful = try fixture.run(
      requirement,
      authenticatedResponse: .success
    )
    #expect(successful.status == 0)

    var failedRequirement = requirement
    failedRequirement["outputDirectory"] =
      fixture.root.appending(
        path: "inspect-auth-response-failed"
      ).path
    let failed = try fixture.run(
      failedRequirement,
      authenticatedResponse: .failure
    )
    #expect(failed.status == 1)
    #expect(try failed.errorCode() == "worker.session_requires_login")
  }

  @Test("Session inspection checks required material before response evidence")
  func checksSessionMaterialBeforeAuthenticatedResponse() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(
      path: "inspect-material-before-response"
    )

    let result = try fixture.run([
      "command": "auth.inspect",
      "url": "https://example.test/account",
      "outputDirectory": output.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "durationMs": 0,
      "sessionDomains": ["example.test"],
      "authRequiredCookieNames": ["missing-session"],
      "authRequiredResponseURLRegex":
        #"^https://api\.example\.test/account$"#,
      "authRequiredResponseBodyRegex": #""connected"\s*:\s*true"#,
    ])

    #expect(result.status == 1)
    #expect(
      try result.errorCode()
        == "worker.auth_session_requirements_missing"
    )
  }

  @Test("Session inspection ignores an unrelated persisted login tab")
  func ignoresPersistedLoginTabOutsideCurrentInspection() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )
    let output = fixture.root.appending(path: "inspect-stale-login-output")

    let result = try fixture.run(
      [
        "command": "auth.inspect",
        "url": "https://example.test/account",
        "outputDirectory": output.path,
        "browser": "chromium",
        "profileDirectory": profile.path,
        "durationMs": 0,
        "rejectURLRegex": #"/login(?:[/?#]|$)"#,
        "sessionDomains": ["example.test"],
        "authRequiredCookieNames": ["session"],
      ],
      includePersistedLoginPage: true
    )

    #expect(result.status == 0)
    #expect(
      FileManager.default.fileExists(
        atPath: output.appending(path: "capture.json").path
      )
    )
  }

  @Test("Session restore verifies cookies and local storage after restart")
  func restoresDurableSessionState() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "profile")
    try FileManager.default.createDirectory(
      at: profile,
      withIntermediateDirectories: true
    )

    let result = try fixture.run(
      [
        "command": "auth.restore",
        "browser": "chromium",
        "profileDirectory": profile.path,
        "restoreSeed": [
          "cookies": [
            [
              "name": "restored-session",
              "value": "private-restored-cookie",
              "domain": ".example.test",
              "path": "/",
              "expires": 2_000_000_000,
              "httpOnly": true,
              "secure": true,
              "sameSite": "Lax",
            ]
          ],
          "origins": [
            [
              "origin": "https://example.test",
              "localStorage": ["restored-token": "private-restored-token"],
              "sessionStorage": [:],
            ]
          ],
        ],
      ],
      expectedHeadless: true
    )

    #expect(result.status == 0)
    #expect(try result.dataInt("restoredCookieCount") == 1)
    #expect(try result.dataInt("restoredOriginCount") == 1)
  }

  @Test("Capture replays private session state in one ephemeral context")
  func capturesWithEphemeralSessionReplay() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let output = fixture.root.appending(path: "session-replay-output")

    let result = try fixture.run([
      "command": "capture",
      "url": "https://example.test/account",
      "outputDirectory": output.path,
      "browser": "chromium",
      "headless": true,
      "durationMs": 0,
      "replaySeed": [
        "cookies": [
          [
            "name": "replayed-session",
            "value": "private-replayed-cookie",
            "domain": ".example.test",
            "path": "/",
            "expires": -1,
            "httpOnly": true,
            "secure": true,
            "sameSite": "Lax",
          ]
        ],
        "origins": [
          [
            "origin": "https://example.test",
            "localStorage": ["replayed": "local"],
            "sessionStorage": ["replayed": "session"],
          ]
        ],
      ],
    ])

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name)
        .contains("replayed-session")
    )
  }

  @Test("Auth bootstrap injects a private seed into one persistent-profile lifecycle")
  func authBootstrapReplaysSessionWithoutBrowserPersistence() throws {
    let fixture = try WorkerProcessFixture()
    defer { fixture.remove() }
    let profile = fixture.root.appending(path: "persistent-profile")
    let output = fixture.root.appending(path: "auth-replay-output")

    let result = try fixture.run([
      "command": "auth.bootstrap",
      "url": "https://example.test/account",
      "outputDirectory": output.path,
      "browser": "chromium",
      "profileDirectory": profile.path,
      "autoCompleteOnAuthRequirements": true,
      "authTimeoutMs": 100,
      "sessionDomains": ["example.test"],
      "authRequiredCookieNames": ["replayed-session"],
      "replaySeed": [
        "cookies": [
          [
            "name": "replayed-session",
            "value": "private-replayed-cookie",
            "domain": ".example.test",
            "path": "/",
            "expires": -1,
            "httpOnly": true,
            "secure": true,
            "sameSite": "Lax",
          ]
        ],
        "origins": [
          [
            "origin": "https://example.test",
            "localStorage": ["replayed-local": "local"],
            "sessionStorage": ["replayed-session": "session"],
          ]
        ],
      ],
    ])

    #expect(result.status == 0)
    let capture = try DeterministicJSON.decode(
      BrowserWorkerPrivateCapture.self,
      from: Data(contentsOf: output.appending(path: "capture.json"))
    )
    #expect(
      capture.sessionSeed.storageState.cookies.map(\.name)
        .contains("replayed-session")
    )
  }
}

private struct WorkerProcessResult {
  let status: Int32
  let output: Data
  let errorOutput: Data

  func errorCode() throws -> String {
    let root = try object()
    let error = try dictionary(root["error"], name: "error")
    return try string(error["code"], name: "error.code")
  }

  func dataString(_ key: String) throws -> String {
    let root = try object()
    let data = try dictionary(root["data"], name: "data")
    return try string(data[key], name: "data.\(key)")
  }

  func dataInt(_ key: String) throws -> Int {
    let root = try object()
    let data = try dictionary(root["data"], name: "data")
    guard let number = data[key] as? NSNumber else {
      throw WorkerTestError.invalidOutput("data.\(key)")
    }
    return number.intValue
  }

  func dataBool(_ key: String) throws -> Bool {
    let root = try object()
    let data = try dictionary(root["data"], name: "data")
    guard let number = data[key] as? NSNumber else {
      throw WorkerTestError.invalidOutput("data.\(key)")
    }
    return number.boolValue
  }

  private func object() throws -> [String: Any] {
    guard
      let value = try JSONSerialization.jsonObject(
        with: output
      ) as? [String: Any]
    else {
      throw WorkerTestError.invalidOutput(
        String(decoding: output, as: UTF8.self)
      )
    }
    return value
  }

  private func dictionary(
    _ value: Any?,
    name: String
  ) throws -> [String: Any] {
    guard let value = value as? [String: Any] else {
      throw WorkerTestError.invalidOutput(name)
    }
    return value
  }

  private func string(
    _ value: Any?,
    name: String
  ) throws -> String {
    guard let value = value as? String else {
      throw WorkerTestError.invalidOutput(name)
    }
    return value
  }
}

private final class WorkerProcessFixture {
  enum AuthenticatedResponse {
    case none
    case success
    case failure
    case successAfterConfirmationRevisit
    case intermediateThenSuccessAfterRevisit
  }

  let root: URL
  private let node: URL
  private let worker: URL
  private let dependencyRoot: URL

  init() throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "web-api-reverse-worker-\(UUID().uuidString)"
    )
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    node = try nodeExecutable()
    worker = try BrowserWorker.resourceURL()
    dependencyRoot = root.appending(path: "playwright-root")
    let moduleDirectory = dependencyRoot.appending(
      path: "node_modules/playwright"
    )
    try FileManager.default.createDirectory(
      at: moduleDirectory,
      withIntermediateDirectories: true
    )
    try Data(fakePlaywright.utf8).write(
      to: moduleDirectory.appending(path: "index.js")
    )
  }

  func run(
    _ input: [String: Any],
    confirm: Bool = false,
    confirmationDelayMilliseconds: UInt64 = 0,
    expectedHeadless: Bool? = nil,
    includePersistedLoginPage: Bool = false,
    authenticatedResponse: AuthenticatedResponse = .none,
    failStorageState: Bool = false,
    expectScopedRecordHAR: Bool = false,
    expectSessionRestore: Bool = false,
    rejectNavigation: Bool = false,
    deleteSessionOnNavigation: Bool = false,
    dropSessionCookiesOnClose: Bool = false,
    dropSessionAfterCookieReads: Int? = nil,
    expectedNavigationWaitUntil: String? = nil,
    captureResponseBody: Bool = false,
    captureRouteResponseBody: Bool = false,
    routeResponseBodyFails: Bool = false,
    addCookieAfterNavigationMilliseconds: Int? = nil,
    closeFlowPagesAfterNavigationMilliseconds: Int? = nil,
    inaccessibleStorageHost: String? = nil,
    ownerProcessID: Int32? = nil,
    contextCloseMarker: URL? = nil
  ) throws -> WorkerProcessResult {
    var request = try JSONSerialization.data(
      withJSONObject: input,
      options: [.sortedKeys]
    )
    request.append(0x0A)
    let process = Process()
    let stdin = Pipe()
    let stdout = Pipe()
    let stderr = Pipe()
    process.executableURL = node
    process.arguments = [worker.path]
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr
    var environment = ProcessInfo.processInfo.environment
    environment["WEB_API_REVERSE_PLAYWRIGHT_ROOT"] = dependencyRoot.path
    if let ownerProcessID {
      environment["WEB_API_REVERSE_OWNER_PID"] = String(ownerProcessID)
    }
    if let contextCloseMarker {
      environment["WEB_API_REVERSE_CONTEXT_CLOSE_MARKER"] =
        contextCloseMarker.path
    }
    if let expectedHeadless {
      environment["WEB_API_REVERSE_EXPECT_HEADLESS"] =
        expectedHeadless ? "true" : "false"
    }
    if includePersistedLoginPage {
      environment["WEB_API_REVERSE_INCLUDE_PERSISTED_LOGIN_PAGE"] = "1"
    }
    if failStorageState {
      environment["WEB_API_REVERSE_FAIL_STORAGE_STATE"] = "1"
    }
    if expectScopedRecordHAR {
      environment["WEB_API_REVERSE_EXPECT_SCOPED_RECORD_HAR"] = "1"
    }
    if expectSessionRestore {
      environment["WEB_API_REVERSE_EXPECT_SESSION_RESTORE"] = "1"
    }
    if rejectNavigation {
      environment["WEB_API_REVERSE_REJECT_NAVIGATION"] = "1"
    }
    if let expectedNavigationWaitUntil {
      environment["WEB_API_REVERSE_EXPECT_NAVIGATION_WAIT_UNTIL"] =
        expectedNavigationWaitUntil
    }
    if captureResponseBody {
      environment["WEB_API_REVERSE_CAPTURE_RESPONSE_BODY"] = "1"
    }
    if captureRouteResponseBody {
      environment["WEB_API_REVERSE_CAPTURE_ROUTE_RESPONSE_BODY"] = "1"
    }
    if routeResponseBodyFails {
      environment["WEB_API_REVERSE_ROUTE_RESPONSE_BODY_FAILURE"] = "1"
    }
    if deleteSessionOnNavigation {
      environment["WEB_API_REVERSE_DELETE_SESSION_ON_NAVIGATION"] = "1"
    }
    if dropSessionCookiesOnClose {
      environment["WEB_API_REVERSE_DROP_SESSION_COOKIES_ON_CLOSE"] = "1"
    }
    if let dropSessionAfterCookieReads {
      environment["WEB_API_REVERSE_DROP_SESSION_AFTER_COOKIE_READS"] =
        String(dropSessionAfterCookieReads)
    }
    if let addCookieAfterNavigationMilliseconds {
      environment["WEB_API_REVERSE_ADD_COOKIE_AFTER_NAVIGATION_MS"] =
        String(addCookieAfterNavigationMilliseconds)
    }
    if let closeFlowPagesAfterNavigationMilliseconds {
      environment["WEB_API_REVERSE_CLOSE_FLOW_PAGES_AFTER_NAVIGATION_MS"] =
        String(closeFlowPagesAfterNavigationMilliseconds)
    }
    if let inaccessibleStorageHost {
      environment["WEB_API_REVERSE_INACCESSIBLE_STORAGE_HOST"] =
        inaccessibleStorageHost
    }
    switch authenticatedResponse {
    case .none:
      break
    case .success:
      environment["WEB_API_REVERSE_AUTH_RESPONSE"] = "success"
    case .failure:
      environment["WEB_API_REVERSE_AUTH_RESPONSE"] = "failure"
    case .successAfterConfirmationRevisit:
      environment["WEB_API_REVERSE_AUTH_RESPONSE"] = "success-after-revisit"
    case .intermediateThenSuccessAfterRevisit:
      environment["WEB_API_REVERSE_AUTH_RESPONSE"] =
        "intermediate-then-success-after-revisit"
    }
    process.environment = environment
    try process.run()
    try stdin.fileHandleForWriting.write(contentsOf: request)
    if confirm {
      if confirmationDelayMilliseconds > 0 {
        Thread.sleep(
          forTimeInterval: Double(confirmationDelayMilliseconds) / 1_000
        )
      }
      try stdin.fileHandleForWriting.write(contentsOf: Data([0x0A]))
    }
    try stdin.fileHandleForWriting.close()
    process.waitUntilExit()
    return WorkerProcessResult(
      status: process.terminationStatus,
      output: stdout.fileHandleForReading.readDataToEndOfFile(),
      errorOutput: stderr.fileHandleForReading.readDataToEndOfFile()
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private enum WorkerTestError: Error {
  case missingNode
  case invalidOutput(String)
}

private func nodeExecutable() throws -> URL {
  let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
  for directory in path.split(separator: ":") {
    let candidate = URL(fileURLWithPath: String(directory))
      .appending(path: "node")
    if FileManager.default.isExecutableFile(atPath: candidate.path) {
      return candidate
    }
  }
  throw WorkerTestError.missingNode
}

private func permissions(_ url: URL) throws -> Int {
  let attributes = try FileManager.default.attributesOfItem(
    atPath: url.path
  )
  return (attributes[.posixPermissions] as? NSNumber)?.intValue ?? -1
}

private let fakePlaywright = #"""
  const fs = require("node:fs");
  let persistedCookies = [{
    name: "session",
    value: "private-cookie",
    domain: ".example.test",
    path: "/",
    expires: -1,
    httpOnly: true,
    secure: true,
    sameSite: "Lax",
  }];
  const persistedLocalStorage = { live: "main" };
  let cookieReadCount = 0;

  function frame(url, storage) {
    return {
      url: () => url,
      evaluate: async () => {
        const inaccessibleHost =
          process.env.WEB_API_REVERSE_INACCESSIBLE_STORAGE_HOST;
        if (inaccessibleHost && new URL(url).hostname === inaccessibleHost) {
          throw new Error("fixture storage is inaccessible");
        }
        return storage;
      },
    };
  }

  function page(
    initialURL,
    storage,
    extraFrames = [],
    onNavigate = async () => {}
  ) {
    let currentURL = initialURL;
    let navigationCount = 0;
    let closed = false;
    const mainFrame = frame(initialURL, storage);
    let responseHandler = async () => {};
    return {
      on: (event, handler) => {
        if (event === "response") responseHandler = handler;
      },
      goto: async (url, options) => {
        if (process.env.WEB_API_REVERSE_REJECT_NAVIGATION === "1") {
          throw new Error("candidate-only inspection must not navigate");
        }
        const expectedWaitUntil =
          process.env.WEB_API_REVERSE_EXPECT_NAVIGATION_WAIT_UNTIL;
        if (expectedWaitUntil && options?.waitUntil !== expectedWaitUntil) {
          throw new Error(
            `expected waitUntil=${expectedWaitUntil}, got ${options?.waitUntil}`
          );
        }
        currentURL = url;
        navigationCount += 1;
        await onNavigate(url);
        if (process.env.WEB_API_REVERSE_CAPTURE_RESPONSE_BODY === "1") {
          await responseHandler({
            request: () => ({
              method: () => "GET",
              allHeaders: async () => ({}),
              postData: () => null,
            }),
            url: () => url,
            status: () => 200,
            allHeaders: async () => ({
              "content-type": "application/json",
            }),
            body: async () => Buffer.from('{"currentPrice":"99.00"}'),
          });
        }
        if (
          process.env.WEB_API_REVERSE_DELETE_SESSION_ON_NAVIGATION === "1"
        ) {
          persistedCookies = [];
        }
        const authResponse = process.env.WEB_API_REVERSE_AUTH_RESPONSE;
        const shouldRespond = authResponse
          && (
            authResponse !== "success-after-revisit"
            || navigationCount > 1
          );
        if (shouldRespond) {
          const isIntermediate =
            authResponse === "intermediate-then-success-after-revisit"
            && navigationCount === 1;
          const isSuccess = authResponse === "success"
            || authResponse === "success-after-revisit"
            || (
              authResponse === "intermediate-then-success-after-revisit"
              && navigationCount > 1
            );
          const body = isIntermediate
            ? '{"resultCode":100}'
            : isSuccess
              ? '{"connected":true}'
              : '{"connected":false}';
          await responseHandler({
            request: () => ({
              method: () => "GET",
              allHeaders: async () => ({}),
              postData: () => null,
            }),
            url: () => isIntermediate
              ? "https://login.example.test/silent"
              : "https://api.example.test/account",
            status: () => 200,
            allHeaders: async () => ({}),
            text: async () => body,
          });
        }
        const addCookieDelay = Number.parseInt(
          process.env.WEB_API_REVERSE_ADD_COOKIE_AFTER_NAVIGATION_MS ?? "",
          10
        );
        if (Number.isFinite(addCookieDelay)) {
          setTimeout(() => {
            if (!persistedCookies.some(
              (cookie) => cookie.name === "stabilized-session"
            )) {
              persistedCookies.push({
                name: "stabilized-session",
                value: "stable-private-cookie",
                domain: ".example.test",
                path: "/",
                expires: -1,
                httpOnly: true,
                secure: true,
                sameSite: "Lax",
              });
            }
          }, addCookieDelay);
        }
      },
      waitForTimeout: async () => {},
      evaluate: async (_function, argument) => {
        if (Array.isArray(argument)) {
          return Object.fromEntries(
            argument.map((key) => [
              key,
              persistedLocalStorage[key] ?? null,
            ])
          );
        }
        Object.assign(persistedLocalStorage, argument ?? {});
      },
      close: async () => { closed = true; },
      isClosed: () => closed,
      url: () => currentURL,
      frames: () => [mainFrame, ...extraFrames],
    };
  }

  function context(options) {
    let routeHandler = null;
    if (options.storageState) {
      persistedCookies = options.storageState.cookies ?? [];
      for (const origin of options.storageState.origins ?? []) {
        for (const item of origin.localStorage ?? []) {
          persistedLocalStorage[item.name] = item.value;
        }
      }
    }
    if (process.env.WEB_API_REVERSE_EXPECT_SCOPED_RECORD_HAR === "1") {
      const filter = options.recordHar?.urlFilter;
      if (
        !(filter instanceof RegExp)
        || !filter.test("https://api.example.test/account")
        || filter.test("https://www.unrelated.test/account")
      ) {
        throw new Error("auth HAR must be scoped to the provider domain");
      }
    }
    const invokeRoute = async (url) => {
      if (
        process.env.WEB_API_REVERSE_CAPTURE_ROUTE_RESPONSE_BODY !== "1"
        || routeHandler === null
      ) {
        return;
      }
      const response = {
        status: () => 200,
        headers: () => ({ "content-type": "application/json" }),
        body: async () => {
          if (process.env.WEB_API_REVERSE_ROUTE_RESPONSE_BODY_FAILURE === "1") {
            throw new Error("fixture response body unavailable");
          }
          return Buffer.from('{"code":"605"}');
        },
      };
      let fetched = false;
      await routeHandler({
        request: () => ({
          method: () => "GET",
          url: () => url,
        }),
        fetch: async () => {
          fetched = true;
          return response;
        },
        fulfill: async () => {},
        continue: async () => {
          if (fetched) {
            throw new Error("a fetched response must be fulfilled");
          }
        },
      });
    };
    const pages = process.env.WEB_API_REVERSE_INCLUDE_PERSISTED_LOGIN_PAGE === "1"
      ? [page("https://example.test/login", {
          origin: "https://example.test",
          localStorage: {},
          sessionStorage: {},
        })]
      : [];
    let pageHandler = () => {};
    return {
      on: (event, handler) => {
        if (event === "page") pageHandler = handler;
      },
      addInitScript: async () => {},
      pages: () => pages.filter((candidate) => !candidate.isClosed()),
      newPage: async () => {
        const main = page(
          "about:blank",
          {
            origin: "https://example.test",
            localStorage: persistedLocalStorage,
            sessionStorage: { main: "one", shared: "main" },
          },
          [
            frame("https://frame.test/embed", {
              origin: "https://frame.test",
              localStorage: {},
              sessionStorage: { frame: "two" },
            }),
          ],
          invokeRoute
        );
        const popup = page("https://example.test/popup", {
          origin: "https://example.test",
          localStorage: { popup: "yes" },
          sessionStorage: { shared: "popup" },
        });
        pages.push(main, popup);
        pageHandler(main);
        pageHandler(popup);
        const closeFlowDelay = Number.parseInt(
          process.env.WEB_API_REVERSE_CLOSE_FLOW_PAGES_AFTER_NAVIGATION_MS ?? "",
          10
        );
        if (Number.isFinite(closeFlowDelay)) {
          setTimeout(() => {
            void main.close();
            void popup.close();
          }, closeFlowDelay);
        }
        return main;
      },
      addCookies: async (cookies) => {
        for (const cookie of cookies) {
          const index = persistedCookies.findIndex((candidate) =>
            candidate.name === cookie.name
            && candidate.domain === cookie.domain
            && candidate.path === cookie.path
          );
          if (index >= 0) persistedCookies[index] = cookie;
          else persistedCookies.push(cookie);
        }
      },
      cookies: async () => {
        cookieReadCount += 1;
        const dropAfter = Number.parseInt(
          process.env.WEB_API_REVERSE_DROP_SESSION_AFTER_COOKIE_READS ?? "",
          10
        );
        if (Number.isFinite(dropAfter) && cookieReadCount > dropAfter) {
          return [];
        }
        return persistedCookies;
      },
      storageState: async () => {
        if (process.env.WEB_API_REVERSE_FAIL_STORAGE_STATE === "1") {
          throw new Error("full profile storage must not be read");
        }
        return {
          cookies: persistedCookies,
          origins: [{
            origin: "https://example.test",
            localStorage: [{ name: "persisted", value: "one" }],
          }],
        };
      },
      browser: () => ({ version: () => "fixture-browser" }),
      route: async (_pattern, handler) => {
        routeHandler = handler;
      },
      close: async () => {
        const closeMarker = process.env.WEB_API_REVERSE_CONTEXT_CLOSE_MARKER;
        if (closeMarker) fs.writeFileSync(closeMarker, "closed");
        if (
          process.env.WEB_API_REVERSE_DROP_SESSION_COOKIES_ON_CLOSE === "1"
        ) {
          persistedCookies = persistedCookies.filter(
            (cookie) => Number.isFinite(cookie.expires) && cookie.expires > 0
          );
        }
        if (options.recordHar?.path) {
          const entries =
            process.env.WEB_API_REVERSE_CAPTURE_RESPONSE_BODY === "1"
              || process.env.WEB_API_REVERSE_CAPTURE_ROUTE_RESPONSE_BODY === "1"
              ? [{
                  request: {
                    method: "GET",
                    url: "https://example.test/login",
                  },
                  response: {
                    status: 200,
                    content: { mimeType: "application/json" },
                  },
                }]
              : [];
          fs.writeFileSync(
            options.recordHar.path,
            JSON.stringify({ log: { version: "1.2", entries } })
          );
        }
      },
    };
  }

  const chromium = {
    executablePath: () => "/fixture/full-chrome-for-testing",
    launch: async (options) => {
      assertHeadless(options);
      return {
        newContext: async (contextOptions) => context(contextOptions),
        close: async () => {},
      };
    },
    launchPersistentContext: async (_profile, options) => {
      assertHeadless(options);
      assertDurablePersistentProfile(options);
      return context(options);
    },
  };

  function assertHeadless(options) {
    const expected = process.env.WEB_API_REVERSE_EXPECT_HEADLESS;
    if (expected !== undefined && String(options.headless) !== expected) {
      throw new Error(
        `expected headless=${expected}, got ${String(options.headless)}`
      );
    }
  }

  function assertDurablePersistentProfile(options) {
    if (
      !Array.isArray(options.ignoreDefaultArgs)
      || !options.ignoreDefaultArgs.includes("--use-mock-keychain")
    ) {
      throw new Error(
        "persistent profiles must use the macOS Keychain instead of Playwright's mock keychain"
      );
    }
    if (options.executablePath !== chromium.executablePath()) {
      throw new Error(
        "persistent profiles must use the full Playwright browser instead of the headless shell"
      );
    }
    const expectsRestore =
      process.env.WEB_API_REVERSE_EXPECT_SESSION_RESTORE === "1";
    if (
      expectsRestore
      && (
        !Array.isArray(options.args)
        || !options.args.includes("--restore-last-session")
        || !options.args.includes("--disable-session-crashed-bubble")
      )
    ) {
      throw new Error(
        "auth inspection must restore session cookies in its disposable profile snapshot"
      );
    }
  }

  module.exports = {
    chromium,
    devices: {
      "Fixture Phone": {
        defaultBrowserType: "chromium",
        userAgent: "Fixture Mobile",
        viewport: { width: 390, height: 844 },
        screen: { width: 390, height: 844 },
        deviceScaleFactor: 3,
        isMobile: true,
        hasTouch: true,
      },
    },
  };
  """#
