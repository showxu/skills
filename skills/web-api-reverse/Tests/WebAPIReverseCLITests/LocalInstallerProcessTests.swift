import Foundation
import Testing

@Suite("Local installer process contract")
struct LocalInstallerProcessTests {
  @Test("An active shared prefix lock rejects installation before publication")
  func activeSharedPrefixLockRejectsInstallationBeforePublication() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureRelease(version: 1, to: bin)
      try FileManager.default.createDirectory(
        at: prefix,
        withIntermediateDirectories: true
      )
      try Data(
        "\(ProcessInfo.processInfo.processIdentifier)\n".utf8
      ).write(to: prefix.appending(path: ".lifewear-install.lock"))

      let result = try runInstaller(bin: bin, prefix: prefix)

      #expect(result.status != 0)
      #expect(
        result.standardError.contains("installation is already in progress")
      )
      #expect(
        !FileManager.default.fileExists(
          atPath: prefix.appending(path: "web-api-reverse").path
        )
      )
    }
  }

  @Test("Successful activation retains a bounded rollback set")
  func successfulActivationGarbageCollectsExpiredReleases() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      let playwright = root.appending(
        path: "playwright-owned",
        directoryHint: .isDirectory
      )
      try FileManager.default.createDirectory(
        at: playwright,
        withIntermediateDirectories: true
      )
      let playwrightMarker = playwright.appending(path: "owner-marker")
      try Data("provider-owned".utf8).write(to: playwrightMarker)

      for version in 1...5 {
        try writeFixtureRelease(version: version, to: bin)
        let result = try runInstaller(
          bin: bin,
          prefix: prefix,
          environment: [
            "WEB_API_REVERSE_PLAYWRIGHT_ROOT": playwright.path
          ]
        )
        try #require(
          result.status == 0,
          "install failed: \(result.standardError)"
        )
      }

      var releases = try installedReleaseNames(in: prefix)
      #expect(releases.count == 3)
      #expect(try activeReleaseName(in: prefix).map(releases.contains) == true)
      #expect(
        try String(contentsOf: playwrightMarker, encoding: .utf8)
          == "provider-owned"
      )

      try writeFixtureRelease(version: 6, to: bin)
      let configured = try runInstaller(
        bin: bin,
        prefix: prefix,
        additionalArguments: ["--retain-releases", "2"],
        environment: ["WEB_API_REVERSE_RELEASE_RETENTION": "5"]
      )
      try #require(
        configured.status == 0,
        "configured install failed: \(configured.standardError)"
      )

      releases = try installedReleaseNames(in: prefix)
      #expect(releases.count == 2)
      #expect(try activeReleaseName(in: prefix).map(releases.contains) == true)
      let execution = try runProcess(
        executable: prefix.appending(path: "web-api-reverse")
      )
      #expect(execution.status == 0)
      #expect(execution.standardOutput == "fixture-6\n")
    }
  }

  @Test("A post-activation failure restores both public pointers")
  func postActivationFailureRestoresPreviousInstallation() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureRelease(version: 1, to: bin)
      try #require(try runInstaller(bin: bin, prefix: prefix).status == 0)
      let originalCurrent = try currentTarget(in: prefix)
      let originalReleases = try installedReleaseNames(in: prefix)

      for failurePoint in ["after-current-switch", "after-command-switch"] {
        try writeFixtureRelease(version: 2, to: bin)
        let failed = try runInstaller(
          bin: bin,
          prefix: prefix,
          environment: [
            "WEB_API_REVERSE_INSTALLER_TEST_FAIL_AT": failurePoint
          ]
        )

        #expect(failed.status != 0)
        #expect(failed.standardError.contains("restored the previous"))
        #expect(try currentTarget(in: prefix) == originalCurrent)
        #expect(try installedReleaseNames(in: prefix) == originalReleases)
        let execution = try runProcess(
          executable: prefix.appending(path: "web-api-reverse")
        )
        #expect(execution.status == 0)
        #expect(execution.standardOutput == "fixture-1\n")
      }
    }
  }

  @Test("GC failure is warning-only after a healthy activation")
  func garbageCollectionFailurePreservesHealthyActivation() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureRelease(version: 1, to: bin)
      try #require(try runInstaller(bin: bin, prefix: prefix).status == 0)
      try writeFixtureRelease(version: 2, to: bin)

      let result = try runInstaller(
        bin: bin,
        prefix: prefix,
        environment: ["WEB_API_REVERSE_INSTALLER_TEST_GC_FAILURE": "1"]
      )

      #expect(result.status == 0)
      #expect(
        result.standardError.contains("active installation remains healthy")
      )
      let execution = try runProcess(
        executable: prefix.appending(path: "web-api-reverse")
      )
      #expect(execution.status == 0)
      #expect(execution.standardOutput == "fixture-2\n")
    }
  }

  @Test("A resource bundle symlink is rejected before activation")
  func topLevelResourceBundleSymlinkFailsClosed() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureExecutable(version: 1, to: bin)
      let externalBundle = root.appending(
        path: "external.bundle",
        directoryHint: .isDirectory
      )
      try FileManager.default.createDirectory(
        at: externalBundle,
        withIntermediateDirectories: true
      )
      try FileManager.default.createSymbolicLink(
        at: bin.appending(path: "Fixture.bundle"),
        withDestinationURL: externalBundle
      )

      let result = try runInstaller(bin: bin, prefix: prefix)

      #expect(result.status != 0)
      #expect(result.standardError.contains("must not be a symbolic link"))
      #expect(
        !FileManager.default.fileExists(
          atPath: prefix.appending(path: ".web-api-reverse-current").path
        )
      )
    }
  }

  @Test("A nested resource symlink cannot replace the active release")
  func nestedResourceSymlinkPreservesCurrentActivation() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureRelease(version: 1, to: bin)
      let initial = try runInstaller(bin: bin, prefix: prefix)
      try #require(
        initial.status == 0,
        "initial install failed: \(initial.standardError)"
      )
      let originalCurrent = try currentTarget(in: prefix)

      try writeFixtureRelease(version: 2, to: bin)
      let bundle = bin.appending(
        path: "Fixture.bundle",
        directoryHint: .isDirectory
      )
      let payload = bundle.appending(path: "payload.txt")
      try FileManager.default.createSymbolicLink(
        at: bundle.appending(path: "nested-link"),
        withDestinationURL: payload
      )

      let rejected = try runInstaller(bin: bin, prefix: prefix)

      #expect(rejected.status != 0)
      #expect(rejected.standardError.contains("contains a symbolic link"))
      #expect(try currentTarget(in: prefix) == originalCurrent)
      #expect(try installedReleaseNames(in: prefix).count == 1)
      let execution = try runProcess(
        executable: prefix.appending(path: "web-api-reverse")
      )
      #expect(execution.status == 0)
      #expect(execution.standardOutput == "fixture-1\n")
    }
  }

  @Test("Retention always preserves at least one rollback release")
  func unsafeRetentionIsRejected() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(path: "prefix", directoryHint: .isDirectory)
      try writeFixtureRelease(version: 1, to: bin)

      let result = try runInstaller(
        bin: bin,
        prefix: prefix,
        additionalArguments: ["--retain-releases", "1"]
      )

      #expect(result.status != 0)
      #expect(result.standardError.contains("integer from 2 through 20"))
      #expect(!FileManager.default.fileExists(atPath: prefix.path))
    }
  }

  @Test("A symbolic-link release directory is rejected")
  func symbolicLinkReleaseDirectoryFailsClosed() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(
        path: "prefix",
        directoryHint: .isDirectory
      )
      let redirected = root.appending(
        path: "redirected-releases",
        directoryHint: .isDirectory
      )
      try writeFixtureRelease(version: 1, to: bin)
      try FileManager.default.createDirectory(
        at: prefix,
        withIntermediateDirectories: true
      )
      try FileManager.default.createDirectory(
        at: redirected,
        withIntermediateDirectories: true
      )
      try FileManager.default.createSymbolicLink(
        at: prefix.appending(path: ".web-api-reverse-releases"),
        withDestinationURL: redirected
      )

      let result = try runInstaller(bin: bin, prefix: prefix)

      #expect(result.status != 0)
      #expect(result.standardError.contains("must not be a symbolic link"))
      #expect(
        try FileManager.default.contentsOfDirectory(atPath: redirected.path)
          .isEmpty
      )
    }
  }

  @Test("Mach-O debug paths are stripped before publication")
  func machODebugPathsAreStrippedBeforePublication() throws {
    try withTemporaryDirectory { root in
      let bin = root.appending(path: "bin", directoryHint: .isDirectory)
      let prefix = root.appending(
        path: "prefix",
        directoryHint: .isDirectory
      )
      try FileManager.default.createDirectory(
        at: bin,
        withIntermediateDirectories: true
      )
      let staged = bin.appending(path: "web-api-reverse")
      try FileManager.default.copyItem(
        at: URL(filePath: CommandLine.arguments[0]),
        to: staged
      )
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o755],
        ofItemAtPath: staged.path
      )
      let originalSize = try #require(
        staged.resourceValues(forKeys: [.fileSizeKey]).fileSize
      )

      let result = try runInstaller(bin: bin, prefix: prefix)

      #expect(result.standardError.isEmpty)
      try #require(result.status == 0)
      let installed = prefix.appending(path: "web-api-reverse")
      let installedSize = try #require(
        installed.resourceValues(forKeys: [.fileSizeKey]).fileSize
      )
      #expect(installedSize < originalSize)
      let symbols = try runProcess(
        executable: URL(filePath: "/usr/bin/nm"),
        arguments: ["-pa", installed.path]
      )
      #expect(symbols.standardError.isEmpty)
      try #require(symbols.status == 0)
      #expect(!symbols.standardOutput.contains("/.build/"))
      #expect(!symbols.standardOutput.contains("/Users/"))
    }
  }
}

private struct ProcessResult {
  let status: Int32
  let standardOutput: String
  let standardError: String
}

private func runInstaller(
  bin: URL,
  prefix: URL,
  additionalArguments: [String] = [],
  environment: [String: String] = [:]
) throws -> ProcessResult {
  try runProcess(
    executable: installerURL,
    arguments: [
      "--bin-path", bin.path,
      "--prefix", prefix.path,
      "--skip-playwright-install",
    ] + additionalArguments,
    environment: environment
  )
}

private func runProcess(
  executable: URL,
  arguments: [String] = [],
  environment: [String: String] = [:]
) throws -> ProcessResult {
  let process = Process()
  let standardOutput = Pipe()
  let standardError = Pipe()
  process.executableURL = executable
  process.arguments = arguments
  process.standardOutput = standardOutput
  process.standardError = standardError
  process.environment = ProcessInfo.processInfo.environment.merging(
    environment,
    uniquingKeysWith: { _, override in override }
  )
  try process.run()
  process.waitUntilExit()
  return ProcessResult(
    status: process.terminationStatus,
    standardOutput: String(
      decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    ),
    standardError: String(
      decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )
  )
}

private func writeFixtureRelease(version: Int, to bin: URL) throws {
  if FileManager.default.fileExists(atPath: bin.path) {
    try FileManager.default.removeItem(at: bin)
  }
  try writeFixtureExecutable(version: version, to: bin)
  let bundle = bin.appending(
    path: "Fixture.bundle",
    directoryHint: .isDirectory
  )
  try FileManager.default.createDirectory(
    at: bundle,
    withIntermediateDirectories: true
  )
  try Data("resource-\(version)".utf8).write(
    to: bundle.appending(path: "payload.txt")
  )
}

private func writeFixtureExecutable(version: Int, to bin: URL) throws {
  try FileManager.default.createDirectory(
    at: bin,
    withIntermediateDirectories: true
  )
  let executable = bin.appending(path: "web-api-reverse")
  try Data("#!/bin/sh\nprintf 'fixture-\(version)\\n'\n".utf8).write(
    to: executable
  )
  try FileManager.default.setAttributes(
    [.posixPermissions: 0o755],
    ofItemAtPath: executable.path
  )
}

private func installedReleaseNames(in prefix: URL) throws -> [String] {
  let releases = prefix.appending(
    path: ".web-api-reverse-releases",
    directoryHint: .isDirectory
  )
  return try FileManager.default.contentsOfDirectory(
    at: releases,
    includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
  )
  .filter {
    let values = try $0.resourceValues(
      forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
    )
    return values.isDirectory == true && values.isSymbolicLink != true
  }
  .map(\.lastPathComponent)
  .sorted()
}

private func activeReleaseName(in prefix: URL) throws -> String? {
  URL(filePath: try currentTarget(in: prefix)).lastPathComponent
}

private func currentTarget(in prefix: URL) throws -> String {
  try FileManager.default.destinationOfSymbolicLink(
    atPath: prefix.appending(path: ".web-api-reverse-current").path
  )
}

private func withTemporaryDirectory(
  _ operation: (URL) throws -> Void
) throws {
  let root = FileManager.default.temporaryDirectory.appending(
    path: "web-api-reverse-installer-tests-\(UUID().uuidString)",
    directoryHint: .isDirectory
  )
  try FileManager.default.createDirectory(
    at: root,
    withIntermediateDirectories: true
  )
  defer { try? FileManager.default.removeItem(at: root) }
  try operation(root)
}

private let installerURL = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appending(path: "scripts/install-local")
