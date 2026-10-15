#!/usr/bin/swift sh
import CryptoKit
import Foundation
import Security

// `sign` writes the output and sibling staging/backups; fixture self-tests write
// only their fixture directory. Keychain items, profiles and certificates are
// never modified. Results may include certificate metadata, never device IDs or keys.

// MARK: - Model

struct Certificate: Equatable {
  var sha1: String
  var name: String
  var notAfter: Date?
  var notBefore: Date = .distantPast

  func isCurrent(at now: Date) -> Bool {
    notBefore <= now && (notAfter.map { $0 > now } ?? false)
  }
}

struct Profile {
  var uuid = "", name = "", path = ""
  var platforms: [String] = []
  var team = "", prefix = "", appID = ""
  var groups: [String] = []
  var expires = Date.distantPast
  var development = false
  var deviceCount = 0
  var coversThisMac = false
  var certificates: [Certificate] = []
  var digest = ""
  var isMac: Bool { platforms.contains("OSX") }
  var isWildcard: Bool { appID.hasSuffix(".*") }

  func applicationIdentifier(for bundleID: String) -> String { prefix + "." + bundleID }
}

struct SignedBundle {
  var path = "", identifier = "", infoIdentifier = ""
  var signer: Certificate?
  var appID = "", teamEntitlement = ""
  var signatureTeam = ""
  var groups: [String] = []
  var embedded: Profile?
  var validSignature = false
}

struct Check {
  var name: String
  var ok: Bool
  var detail: String
}

// MARK: - Rules

func day(_ date: Date?) -> String {
  guard let date else { return "?" }
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withFullDate]
  return formatter.string(from: date)
}

/// Certificates that can sign with `profile` on this Mac: the profile is current and covers this
/// Mac, and the certificate is unexpired and backed by a local code-signing identity.
func signingCertificates(_ profile: Profile, identities: [Certificate], now: Date) -> [Certificate]
{
  guard profile.isMac, profile.development, profile.expires > now, profile.coversThisMac else {
    return []
  }
  let local = Set(identities.map(\.sha1))
  return profile.certificates.filter { local.contains($0.sha1) && $0.isCurrent(at: now) }
}

/// Profile wildcards match a suffix; signed entitlement values must be concrete.
func matches(_ pattern: String, _ value: String) -> Bool {
  guard !value.isEmpty, !value.contains("*") else { return false }
  if pattern.hasSuffix(".*"), !pattern.dropLast().contains("*") {
    let start = String(pattern.dropLast())
    return value.hasPrefix(start) && value.count > start.count
  }
  return !pattern.contains("*") && pattern == value
}

func allowsGroup(_ profile: Profile, _ group: String) -> Bool {
  profile.groups.contains { matches($0, group) }
}

func covers(_ profile: Profile, bundleID: String) -> Bool {
  !profile.prefix.isEmpty && !profile.team.isEmpty
    && matches(profile.appID, profile.applicationIdentifier(for: bundleID))
}

enum Selection {
  case selected(Profile, Certificate)
  case none
  /// More than one profile or certificate qualifies; the owner decides which one to use.
  case ambiguous([String])
}

/// Prefer eligible explicit App IDs, otherwise consider matching wildcards. Development/device
/// scope and the concrete own group must match. Ambiguity requires an explicit owner selector.
func selectProfile(bundleID: String, profiles: [Profile], identities: [Certificate], now: Date)
  -> Selection
{
  let qualifying = profiles.filter {
    covers($0, bundleID: bundleID) && allowsGroup($0, $0.applicationIdentifier(for: bundleID))
      && !signingCertificates($0, identities: identities, now: now).isEmpty
  }
  let explicit = qualifying.filter { !$0.isWildcard }
  let level = explicit.isEmpty ? qualifying : explicit
  guard let profile = level.first else { return .none }
  if level.count > 1 {
    return .ambiguous(level.map { "profile \($0.name) [\($0.uuid)]" }.sorted())
  }
  let certificates = signingCertificates(profile, identities: identities, now: now)
  if certificates.count > 1 {
    return .ambiguous(certificates.map { "certificate \($0.name) \($0.sha1)" }.sorted())
  }
  return .selected(profile, certificates[0])
}

func verifyChecks(_ bundle: SignedBundle, now: Date) -> [Check] {
  var checks = [
    Check(
      name: "signature", ok: bundle.validSignature,
      detail: bundle.validSignature ? "valid" : "invalid"),
    Check(
      name: "identifier",
      ok: bundle.identifier == bundle.infoIdentifier && !bundle.identifier.isEmpty,
      detail: "code \(bundle.identifier), Info.plist \(bundle.infoIdentifier)"),
  ]
  guard let embedded = bundle.embedded else {
    checks.append(
      Check(
        name: "embedded-profile", ok: false, detail: "missing, malformed or unsupported CMS/plist"))
    return checks
  }
  let team = embedded.team
  let appID = embedded.applicationIdentifier(for: bundle.identifier)
  checks += [
    Check(
      name: "profile-scope",
      ok: embedded.isMac && embedded.development && embedded.coversThisMac
        && embedded.expires > now && covers(embedded, bundleID: bundle.identifier),
      detail: "macOS development, device coverage, App ID and expiry \(day(embedded.expires))"),
    Check(
      name: "application-identifier", ok: bundle.appID == appID,
      detail: bundle.appID),
    Check(
      name: "team-identifier",
      ok: !team.isEmpty && bundle.teamEntitlement == team && bundle.signatureTeam == team,
      detail: "entitlement \(bundle.teamEntitlement), signature \(bundle.signatureTeam)"),
    Check(
      name: "own-access-group", ok: bundle.groups.first == appID,
      detail: bundle.groups.joined(separator: ",")),
    Check(
      name: "groups-authorized",
      ok: !bundle.groups.isEmpty && bundle.groups.allSatisfy { allowsGroup(embedded, $0) },
      detail: "by \(embedded.name)"),
  ]
  checks.append(
    Check(
      name: "signer-current",
      ok: bundle.signer.map { signer in
        signer.isCurrent(at: now) && embedded.certificates.contains { $0.sha1 == signer.sha1 }
      } ?? false,
      detail: bundle.signer.map { "\($0.name) \($0.sha1.prefix(8)) expires \(day($0.notAfter))" }
        ?? "none"))
  return checks
}

/// Audit choices are grouped by App ID; independent teams and scopes can coexist.
func decisions(identities: [Certificate], profiles: [Profile], now: Date) -> [String] {
  let usable = profiles.filter {
    !signingCertificates($0, identities: identities, now: now).isEmpty
  }
  var result: [String] = []
  for (_, group) in Dictionary(grouping: usable, by: { $0.team + ":" + $0.appID })
  where group.count > 1 {
    result.append(
      "choose a profile for \(group[0].appID) among: "
        + group.map(\.name).sorted().joined(separator: ", "))
  }
  for profile in usable {
    let certificates = signingCertificates(profile, identities: identities, now: now)
    if certificates.count > 1 {
      result.append(
        "choose a signing certificate for \(profile.name) among: "
          + certificates.map { "\($0.name) \($0.sha1.prefix(8))" }.sorted().joined(separator: ", "))
    }
  }
  return result.sorted()
}

func findings(
  identities: [Certificate], profiles: [Profile], bundles: [SignedBundle], now: Date,
  window: TimeInterval
) -> [String] {
  let soon = now.addingTimeInterval(window)
  var result: [String] = []
  for identity in identities {
    if let end = identity.notAfter, end <= soon {
      result.append(
        "identity \(identity.name) \(identity.sha1.prefix(8)) "
          + (end <= now ? "expired" : "expires")
          + " \(day(end))")
    }
  }
  let mac = profiles.filter { $0.isMac && $0.development }
  for profile in mac {
    if profile.expires <= now {
      result.append(
        "profile \(profile.name) expired \(day(profile.expires)); remove it once no bundle embeds it"
      )
    } else if signingCertificates(profile, identities: identities, now: now).isEmpty {
      result.append(
        "profile \(profile.name) cannot sign on this Mac: no current local identity among its certificates"
      )
    } else if profile.expires <= soon {
      result.append(
        "profile \(profile.name) expires \(day(profile.expires)); renew it and re-sign its bundles")
    }
  }
  for bundle in bundles {
    for check in verifyChecks(bundle, now: now) where !check.ok {
      result.append("bundle \(bundle.identifier) \(check.name): \(check.detail)")
    }
    if let end = bundle.embedded?.expires, end > now && end <= soon {
      result.append(
        "bundle \(bundle.identifier) embedded profile expires \(day(end)); renew and rebuild")
    }
    if let end = bundle.signer?.notAfter, end > now && end <= soon {
      result.append("bundle \(bundle.identifier) signer expires \(day(end)); renew and rebuild")
    }
  }
  return result
}

// MARK: - Bundle contents

struct InputError: Error {
  let message: String
  var status: Int32 = 1
}

let managedInfoKeys: Set = [
  "CFBundleIdentifier", "CFBundleExecutable", "CFBundlePackageType", "CFBundleName", "LSUIElement",
]
let managedEntitlementKeys: Set = [
  "com.apple.application-identifier", "application-identifier",
  "com.apple.developer.team-identifier",
  "keychain-access-groups",
]

/// Info.plist for a background tool bundle. `extra` adds string keys; the bundle's identity keys stay managed.
func bundleInfo(
  bundleID: String, executable: String, name: String, accessGroup: String, accessGroupKey: String?,
  extra: [String: String]
) throws -> [String: Any] {
  if let key = extra.keys.first(where: managedInfoKeys.contains) {
    throw InputError(message: "--info cannot set \(key)", status: 64)
  }
  if let key = accessGroupKey,
    key.isEmpty || key.hasPrefix("CFBundle") || key == "LSUIElement" || extra[key] != nil
  {
    throw InputError(
      message: "--access-group-key must be a distinct custom Info.plist key", status: 64)
  }
  var info: [String: Any] = [
    "CFBundleName": name, "CFBundleVersion": "1", "LSUIElement": true,
  ]
  for (key, value) in extra { info[key] = value }
  info["CFBundleIdentifier"] = bundleID
  info["CFBundleExecutable"] = executable
  info["CFBundlePackageType"] = "APPL"
  if let accessGroupKey { info[accessGroupKey] = accessGroup }
  return info
}

/// Signing entitlements: the bundle's application identifier, team and own access group, plus
/// any additional entitlements the project needs. The managed keys cannot be overridden.
func bundleEntitlements(team: String, prefix: String, bundleID: String, extra: [String: Any]) throws
  -> [String: Any]
{
  if let key = extra.keys.first(where: managedEntitlementKeys.contains) {
    throw InputError(message: "--entitlements cannot set \(key)", status: 64)
  }
  var entitlements = extra
  entitlements["com.apple.application-identifier"] = prefix + "." + bundleID
  entitlements["com.apple.developer.team-identifier"] = team
  entitlements["keychain-access-groups"] = [prefix + "." + bundleID]
  return entitlements
}

// MARK: - Local state

func run(_ arguments: [String]) -> (status: Int32, output: Data) {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: arguments[0])
  task.arguments = Array(arguments.dropFirst())
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = FileHandle.nullDevice
  do { try task.run() } catch { return (127, Data()) }
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  task.waitUntilExit()
  return (task.terminationStatus, data)
}

func runCapturingErrors(_ arguments: [String]) -> (status: Int32, error: String) {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: arguments[0])
  task.arguments = Array(arguments.dropFirst())
  let pipe = Pipe()
  task.standardOutput = FileHandle.nullDevice
  task.standardError = pipe
  do { try task.run() } catch { return (127, "cannot run \(arguments[0])") }
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  task.waitUntilExit()
  return (task.terminationStatus, String(decoding: data, as: UTF8.self))
}

func certificate(_ reference: SecCertificate) -> Certificate {
  let data = SecCertificateCopyData(reference) as Data
  let sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02X", $0) }.joined()
  let name = SecCertificateCopySubjectSummary(reference) as String? ?? "?"
  let keys = [kSecOIDX509V1ValidityNotBefore as String, kSecOIDX509V1ValidityNotAfter as String]
  let values = SecCertificateCopyValues(reference, keys as CFArray, nil) as? [String: Any] ?? [:]
  func date(_ key: String) -> Date? {
    guard let entry = values[key] as? [String: Any],
      let seconds = entry[kSecPropertyKeyValue as String] as? NSNumber
    else { return nil }
    return Date(timeIntervalSinceReferenceDate: seconds.doubleValue)
  }
  return Certificate(
    sha1: sha1, name: name, notAfter: date(keys[1]), notBefore: date(keys[0]) ?? .distantFuture)
}

func parseIdentities(_ output: String) -> [Certificate] {
  let pattern = try! NSRegularExpression(pattern: #"\)\s+([0-9A-F]{40})\s+"(.+)""#)
  return output.split(separator: "\n").compactMap { line in
    let text = String(line)
    guard let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let sha = Range(match.range(at: 1), in: text), let name = Range(match.range(at: 2), in: text)
    else { return nil }
    return Certificate(sha1: String(text[sha]), name: String(text[name]), notAfter: nil)
  }
}

func localIdentities() -> [Certificate] {
  let listed = parseIdentities(
    String(
      decoding: run(["/usr/bin/security", "find-identity", "-v", "-p", "codesigning"]).output,
      as: UTF8.self))
  var certificates: [String: Certificate] = [:]
  let query: [String: Any] = [
    kSecClass as String: kSecClassIdentity, kSecMatchLimit as String: kSecMatchLimitAll,
    kSecReturnRef as String: true,
  ]
  var items: CFTypeRef?
  if SecItemCopyMatching(query as CFDictionary, &items) == errSecSuccess,
    let found = items as? [SecIdentity]
  {
    for identity in found {
      var reference: SecCertificate?
      if SecIdentityCopyCertificate(identity, &reference) == errSecSuccess, let reference {
        let cert = certificate(reference)
        certificates[cert.sha1] = cert
      }
    }
  }
  return Set(listed.map(\.sha1)).sorted().compactMap { certificates[$0] }
}

func macProvisioningUDID() -> String {
  let output = run(["/usr/sbin/system_profiler", "SPHardwareDataType", "-json"]).output
  let object = (try? JSONSerialization.jsonObject(with: output)) as? [String: Any]
  let hardware = (object?["SPHardwareDataType"] as? [[String: Any]])?.first
  return hardware?["provisioning_UDID"] as? String ?? ""
}

/// The plist is a diagnostic view; macOS validates the authoritative DER profile at launch.
func profileFromPlist(_ plist: [String: Any], path: String, macUDID: String) -> Profile? {
  guard let uuid = plist["UUID"] as? String, !uuid.isEmpty,
    let team = (plist["TeamIdentifier"] as? [String])?.first, !team.isEmpty,
    let prefix = (plist["ApplicationIdentifierPrefix"] as? [String])?.first, !prefix.isEmpty,
    let entitlements = plist["Entitlements"] as? [String: Any],
    entitlements["com.apple.developer.team-identifier"] as? String == team,
    let appID = entitlements["com.apple.application-identifier"] as? String,
    appID.hasPrefix(prefix + "."),
    let expires = plist["ExpirationDate"] as? Date
  else { return nil }
  let devices = plist["ProvisionedDevices"] as? [String]
  let allDevices = plist["ProvisionsAllDevices"] as? Bool ?? false
  return Profile(
    uuid: uuid, name: plist["Name"] as? String ?? uuid, path: path,
    platforms: plist["Platform"] as? [String] ?? [], team: team, prefix: prefix, appID: appID,
    groups: entitlements["keychain-access-groups"] as? [String] ?? [],
    expires: expires, development: devices != nil && !allDevices,
    deviceCount: devices?.count ?? 0,
    coversThisMac: !macUDID.isEmpty && devices?.contains(macUDID) == true,
    certificates: (plist["DeveloperCertificates"] as? [Data] ?? []).compactMap {
      SecCertificateCreateWithData(nil, $0 as CFData).map(certificate)
    })
}

func decodeProfile(_ url: URL, macUDID: String) -> Profile? {
  guard let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
  var decoder: CMSDecoder?
  guard CMSDecoderCreate(&decoder) == errSecSuccess, let decoder else { return nil }
  let updated = data.withUnsafeBytes {
    CMSDecoderUpdateMessage(decoder, $0.baseAddress!, data.count)
  }
  var content: CFData?
  guard updated == errSecSuccess, CMSDecoderFinalizeMessage(decoder) == errSecSuccess,
    CMSDecoderCopyContent(decoder, &content) == errSecSuccess, let content,
    let plist = try? PropertyListSerialization.propertyList(from: content as Data, format: nil)
      as? [String: Any]
  else { return nil }
  var count = 0
  guard CMSDecoderGetNumSigners(decoder, &count) == errSecSuccess, count > 0 else { return nil }
  for index in 0..<count {
    var status = CMSSignerStatus.unsigned
    var trust: SecTrust?
    // Check CMS integrity only. Apple provenance and DER authorization remain platform decisions.
    guard
      CMSDecoderCopySignerStatus(
        decoder, index, SecPolicyCreateBasicX509(), false, &status, &trust, nil)
        == errSecSuccess, status == .valid
    else { return nil }
  }
  guard var profile = profileFromPlist(plist, path: url.path, macUDID: macUDID) else { return nil }
  profile.digest = SHA256.hash(data: data).map { String(format: "%02X", $0) }.joined()
  return profile
}

func installedProfiles(macUDID: String) -> [Profile] {
  let home = FileManager.default.homeDirectoryForCurrentUser
  var result: [Profile] = []
  for folder in [
    "Library/Developer/Xcode/UserData/Provisioning Profiles",
    "Library/MobileDevice/Provisioning Profiles",
  ] {
    let directory = home.appendingPathComponent(folder)
    let files =
      (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil))
      ?? []
    for file in files.sorted(by: { $0.path < $1.path })
    where ["provisionprofile", "mobileprovision"].contains(file.pathExtension.lowercased()) {
      guard
        (try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])).map({
          $0.isRegularFile == true && $0.isSymbolicLink != true
        }) == true
      else { continue }
      if let profile = decodeProfile(file, macUDID: macUDID) {
        result.append(profile)
      }
    }
  }
  return uniqueProfiles(result).sorted { ($0.name, $0.uuid) < ($1.name, $1.uuid) }
}

func uniqueProfiles(_ profiles: [Profile]) -> [Profile] {
  var seen: Set<String> = []
  return profiles.filter { $0.digest.isEmpty || seen.insert($0.digest).inserted }
}

func signedBundle(_ url: URL, macUDID: String) -> SignedBundle? {
  var bundle = SignedBundle(path: url.path)
  var code: SecStaticCode?
  guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else {
    return nil
  }
  var information: CFDictionary?
  guard
    SecCodeCopySigningInformation(
      code, SecCSFlags(rawValue: kSecCSSigningInformation), &information)
      == errSecSuccess, let info = information as? [String: Any]
  else { return nil }
  let entitlements = info[kSecCodeInfoEntitlementsDict as String] as? [String: Any] ?? [:]
  bundle.identifier = info[kSecCodeInfoIdentifier as String] as? String ?? ""
  bundle.infoIdentifier = Bundle(url: url)?.bundleIdentifier ?? ""
  bundle.signer = (info[kSecCodeInfoCertificates as String] as? [SecCertificate])?.first.map(
    certificate)
  bundle.appID =
    entitlements["com.apple.application-identifier"] as? String
    ?? entitlements["application-identifier"] as? String ?? ""
  bundle.teamEntitlement = entitlements["com.apple.developer.team-identifier"] as? String ?? ""
  bundle.signatureTeam = info[kSecCodeInfoTeamIdentifier as String] as? String ?? ""
  bundle.groups = entitlements["keychain-access-groups"] as? [String] ?? []
  bundle.embedded = decodeProfile(
    url.appendingPathComponent("Contents/embedded.provisionprofile"), macUDID: macUDID)
  bundle.validSignature =
    SecStaticCodeCheckValidity(
      code,
      SecCSFlags(
        rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures | kSecCSCheckNestedCode), nil)
    == errSecSuccess
  return bundle
}

// MARK: - Output

func emit(_ object: Any) {
  let data = try! JSONSerialization.data(
    withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
  print(String(decoding: data, as: UTF8.self))
}

func record(_ c: Certificate?) -> [String: Any] {
  guard let c else { return [:] }
  return ["sha1": c.sha1, "name": c.name, "expires": day(c.notAfter)]
}

func record(_ p: Profile, identities: [Certificate], now: Date) -> [String: Any] {
  [
    "uuid": p.uuid, "name": p.name, "path": p.path, "team": p.team, "app_id_prefix": p.prefix,
    "app_id": p.appID,
    "keychain_access_groups": p.groups, "expires": day(p.expires), "development": p.development,
    "device_count": p.deviceCount, "covers_this_mac": p.coversThisMac,
    "certificates": p.certificates.map { record($0) },
    "signing_certificates": signingCertificates(p, identities: identities, now: now).map(\.sha1),
  ]
}

func usage() -> Never {
  FileHandle.standardError.write(
    Data(
      """
      usage: codesign.swift select-profile --bundle-id ID [--profile UUID] [--identity SHA1] [--json]
             codesign.swift sign --bundle-id ID --binary PATH --output PATH.app [--name NAME]
                                 [--info KEY=VALUE]... [--access-group-key KEY] [--entitlements PLIST]
                                 [--profile UUID] [--identity SHA1] [--json]
             codesign.swift verify --bundle PATH [--json]
             codesign.swift audit [--bundle PATH]... [--within-days N] [--json]
             codesign.swift self-test [--fixtures PATH]

      """.utf8))
  exit(64)
}

func options(_ arguments: ArraySlice<String>, command: String) -> (
  values: [String: [String]], json: Bool
) {
  let allowed: [String: Set<String>] = [
    "select-profile": ["--bundle-id", "--profile", "--identity", "--json"],
    "sign": [
      "--bundle-id", "--binary", "--output", "--name", "--info", "--access-group-key",
      "--entitlements", "--profile", "--identity", "--json",
    ],
    "verify": ["--bundle", "--json"],
    "audit": ["--bundle", "--within-days", "--json"],
    "self-test": ["--fixtures"],
  ]
  guard let allowed = allowed[command] else { usage() }
  var values: [String: [String]] = [:]
  var json = false
  var index = arguments.startIndex
  while index < arguments.endIndex {
    let key = arguments[index]
    guard allowed.contains(key) else { usage() }
    if key == "--json" {
      guard !json else { usage() }
      json = true
      index += 1
      continue
    }
    guard index + 1 < arguments.endIndex, !arguments[index + 1].isEmpty,
      !arguments[index + 1].hasPrefix("--"),
      values[key] == nil || key == "--info" || (command == "audit" && key == "--bundle")
    else { usage() }
    values[key, default: []].append(arguments[index + 1])
    index += 2
  }
  if let id = values["--bundle-id"]?.first, !validBundleIdentifier(id) { usage() }
  if let id = values["--identity"]?.first,
    id.range(of: #"^[0-9A-Fa-f]{8,40}$"#, options: .regularExpression) == nil
  {
    usage()
  }
  if let id = values["--profile"]?.first,
    id.range(of: #"^[0-9A-Fa-f][0-9A-Fa-f-]{7,35}$"#, options: .regularExpression) == nil
  {
    usage()
  }
  return (values, json)
}

func validBundleIdentifier(_ value: String) -> Bool {
  value.utf8.count <= 255
    && value.range(of: #"^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$"#, options: .regularExpression) != nil
}

func absolute(_ path: String) -> URL {
  URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
}

func fail(_ message: String, status: Int32 = 1) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(status)
}

/// The profile and identity for `bundleID`, honouring `--profile` / `--identity`. Several candidates
/// stop with exit 2 so the owner can choose; nothing qualifying stops with exit 1.
func resolve(bundleID: String, values: [String: [String]], json: Bool, now: Date) -> (
  Profile, Certificate
) {
  let chosenProfile = values["--profile"]?.last?.lowercased()
  let chosenIdentity = values["--identity"]?.last?.uppercased()
  let identities = localIdentities().filter {
    chosenIdentity == nil || $0.sha1.hasPrefix(chosenIdentity!)
  }
  let profiles = installedProfiles(macUDID: macProvisioningUDID())
    .filter { chosenProfile == nil || $0.uuid.lowercased().hasPrefix(chosenProfile!) }
  switch selectProfile(bundleID: bundleID, profiles: profiles, identities: identities, now: now) {
  case .selected(let profile, let identity):
    return (profile, identity)
  case .none:
    fail("no usable provisioning profile for \(bundleID)")
  case .ambiguous(let candidates):
    let next = "ask the owner which to use, then rerun with --profile UUID or --identity SHA1"
    if json {
      emit(["bundle_id": bundleID, "needs_decision": true, "candidates": candidates, "next": next])
    } else {
      print("needs_decision=true")
      for candidate in candidates { print("candidate=" + candidate) }
      print("next=" + next)
    }
    exit(2)
  }
}

// MARK: - Self-test

func selfTest(fixtures: URL? = nil) -> Int32 {
  var failures = 0
  var count = 0
  func expect(_ condition: Bool, _ label: String) {
    count += 1
    if !condition {
      failures += 1
      print("FAIL \(label)")
    }
  }
  let now = Date(timeIntervalSince1970: 1_791_000_000)
  let later = now.addingTimeInterval(400 * 86_400)
  let soon = now.addingTimeInterval(30 * 86_400)
  let past = now.addingTimeInterval(-14 * 86_400)
  let window: TimeInterval = 90 * 86_400
  func cert(_ c: Character, _ end: Date) -> Certificate {
    Certificate(
      sha1: String(repeating: String(c), count: 40), name: "Apple Development: \(c)", notAfter: end)
  }
  func profile(
    _ name: String, _ uuid: String, appID: String = "TEAM.*", expires: Date? = nil,
    certs: [Certificate],
    covers: Bool = true, platforms: [String] = ["OSX"], groups: [String] = ["TEAM.*"]
  ) -> Profile {
    Profile(
      uuid: uuid, name: name, path: "/p/\(uuid)", platforms: platforms, team: "TEAM",
      prefix: "TEAM", appID: appID,
      groups: groups, expires: expires ?? later, development: true, deviceCount: 1,
      coversThisMac: covers,
      certificates: certs)
  }
  func bundle(
    _ id: String, signer: Certificate?, embedded: Profile?, valid: Bool = true, group: String? = nil
  )
    -> SignedBundle
  {
    SignedBundle(
      path: "/b/\(id).app", identifier: id, infoIdentifier: id, signer: signer, appID: "TEAM.\(id)",
      teamEntitlement: "TEAM", signatureTeam: "TEAM", groups: [group ?? "TEAM.\(id)"],
      embedded: embedded, validSignature: valid)
  }

  let ids = parseIdentities(
    "  1) \(String(repeating: "A", count: 40)) \"Developer ID Application: X (TEAM)\"\n  2) \(String(repeating: "B", count: 40)) \"Apple Development: X (P)\"\n     2 valid identities found"
  )
  expect(
    ids.map(\.name) == ["Developer ID Application: X (TEAM)", "Apple Development: X (P)"],
    "parse identities")

  let current = cert("A", later)
  let expired = cert("B", past)
  let shared = profile("Shared", "s", certs: [current, expired])
  expect(
    signingCertificates(shared, identities: [current], now: now) == [current],
    "current identity signs")
  expect(
    signingCertificates(shared, identities: [expired], now: now).isEmpty,
    "expired identity cannot sign")
  expect(
    signingCertificates(
      profile("Elsewhere", "e", certs: [current], covers: false), identities: [current], now: now
    )
    .isEmpty, "profile must cover this Mac")

  func chosen(_ selection: Selection) -> String {
    switch selection {
    case .selected(let profile, _): return profile.uuid
    case .none: return "none"
    case .ambiguous: return "ambiguous"
    }
  }
  let explicit = profile(
    "Explicit", "x", appID: "TEAM.tool", expires: soon, certs: [current], groups: ["TEAM.tool"])
  expect(
    chosen(
      selectProfile(
        bundleID: "tool", profiles: [shared, explicit], identities: [current], now: now)) == "x",
    "explicit App ID profile is the bundle's profile")
  expect(
    chosen(
      selectProfile(
        bundleID: "other", profiles: [shared, explicit], identities: [current], now: now)) == "s",
    "shared wildcard covers other bundles")
  expect(
    chosen(
      selectProfile(
        bundleID: "tool", profiles: [profile("Stale", "t", certs: [expired])],
        identities: [expired], now: now))
      == "none", "no usable profile")
  expect(
    chosen(
      selectProfile(
        bundleID: "other", profiles: [shared, profile("Second", "u", certs: [current])],
        identities: [current], now: now))
      == "ambiguous", "two shared wildcard profiles are reported")
  expect(
    chosen(
      selectProfile(
        bundleID: "tool",
        profiles: [
          explicit,
          profile("Explicit 2", "y", appID: "TEAM.tool", certs: [current], groups: ["TEAM.tool"]),
        ], identities: [current], now: now))
      == "ambiguous", "two explicit profiles are reported")
  let renewed = cert("C", later)
  expect(
    chosen(
      selectProfile(
        bundleID: "other", profiles: [profile("Shared", "s", certs: [current, renewed])],
        identities: [current, renewed], now: now))
      == "ambiguous", "two usable certificates are reported")

  let healthy = bundle("tool", signer: current, embedded: shared)
  expect(verifyChecks(healthy, now: now).allSatisfy(\.ok), "healthy bundle verifies")
  expect(
    findings(
      identities: [current], profiles: [shared], bundles: [healthy], now: now, window: window
    ).isEmpty,
    "healthy setup has no findings")

  let stale = profile("Stale", "t", certs: [expired])
  let problems = findings(
    identities: [cert("A", soon)],
    profiles: [
      profile("Shared", "s", certs: [cert("A", soon)]),
      profile("Second", "u", certs: [cert("A", soon)]), stale,
      profile("Gone", "g", expires: past, certs: [current]),
      profile("iOS", "i", certs: [expired], platforms: ["iOS"]),
    ],
    bundles: [
      bundle("old", signer: expired, embedded: stale),
      bundle("renamed", signer: current, embedded: profile("Removed", "r", certs: [current])),
      bundle("broken", signer: current, embedded: shared, valid: false),
      bundle("foreign", signer: current, embedded: shared, group: "OTHER.group"),
    ], now: now, window: window)
  expect(
    problems.contains { $0.hasPrefix("identity Apple Development: A") && $0.contains("expires") },
    "identity expiry")
  expect(problems.contains { $0.hasPrefix("profile Stale cannot sign") }, "unusable profile")
  expect(problems.contains { $0.hasPrefix("profile Gone expired") }, "expired profile")
  expect(!problems.contains { $0.contains("Second") }, "duplicate wildcard is not a warning")
  expect(
    decisions(
      identities: [cert("A", soon)],
      profiles: [
        profile("Shared", "s", certs: [cert("A", soon)]),
        profile("Second", "u", certs: [cert("A", soon)]),
      ], now: now)
      == ["choose a profile for TEAM.* among: Second, Shared"],
    "duplicate wildcard needs a decision")
  expect(
    decisions(
      identities: [current, cert("C", later)],
      profiles: [profile("Shared", "s", certs: [current, cert("C", later)])], now: now
    ).count == 1,
    "two usable certificates need a decision")
  expect(
    decisions(identities: [current], profiles: [shared], now: now).isEmpty,
    "single shared profile needs no decision")
  expect(!problems.contains { $0.contains("iOS") }, "non-macOS ignored")
  expect(problems.contains { $0.hasPrefix("bundle old signer-current") }, "expired signer")
  expect(
    !problems.contains { $0.hasPrefix("bundle renamed") },
    "embedded profile suffices without installed copy or local key")
  expect(problems.contains("bundle broken signature: invalid"), "invalid signature")
  expect(problems.contains { $0.hasPrefix("bundle foreign own-access-group") }, "own access group")
  expect(
    problems.contains { $0.hasPrefix("bundle foreign groups-authorized") },
    "TEAM.* only allows the team's groups")
  expect(
    !problems.contains { $0.hasPrefix("bundle renamed signer-current") },
    "signer compared by fingerprint")
  expect(
    findings(identities: [], profiles: [], bundles: [], now: now, window: window).isEmpty,
    "a shared profile is optional")

  let info = try? bundleInfo(
    bundleID: "tool", executable: "tool", name: "Tool", accessGroup: "TEAM.tool",
    accessGroupKey: "ToolAccessGroup",
    extra: ["CFBundleShortVersionString": "1.2"])
  expect(
    info?["CFBundleIdentifier"] as? String == "tool"
      && info?["ToolAccessGroup"] as? String == "TEAM.tool"
      && info?["CFBundleShortVersionString"] as? String == "1.2",
    "Info.plist carries identity and extras")
  expect(
    (try? bundleInfo(
      bundleID: "tool", executable: "tool", name: "Tool", accessGroup: "TEAM.tool",
      accessGroupKey: nil,
      extra: ["CFBundleIdentifier": "other"])) == nil, "Info.plist identity cannot be overridden")
  let ent = try? bundleEntitlements(
    team: "TEAM", prefix: "TEAM", bundleID: "tool",
    extra: ["com.apple.security.network.client": true])
  expect(
    ent?["com.apple.application-identifier"] as? String == "TEAM.tool"
      && ent?["keychain-access-groups"] as? [String] == ["TEAM.tool"]
      && ent?["com.apple.security.network.client"] as? Bool == true,
    "entitlements carry identity and extras")
  expect(
    (try? bundleEntitlements(
      team: "TEAM", prefix: "TEAM", bundleID: "tool", extra: ["keychain-access-groups": ["TEAM.*"]]))
      == nil,
    "managed entitlements cannot be overridden")

  var legacy = shared
  legacy.prefix = "PREFIX"
  legacy.appID = "PREFIX.*"
  legacy.groups = ["PREFIX.*"]
  expect(
    chosen(selectProfile(bundleID: "tool", profiles: [legacy], identities: [current], now: now))
      == "s",
    "App ID prefix can differ from Team ID")
  let legacyEnt = try? bundleEntitlements(
    team: legacy.team, prefix: legacy.prefix, bundleID: "tool", extra: [:])
  expect(
    legacyEnt?["com.apple.application-identifier"] as? String == "PREFIX.tool"
      && legacyEnt?["com.apple.developer.team-identifier"] as? String == "TEAM",
    "application and team identifiers have separate sources")
  var scoped = shared
  scoped.appID = "TEAM.com.example.*"
  expect(
    covers(scoped, bundleID: "com.example.tool") && !covers(scoped, bundleID: "com.example2.tool"),
    "scoped wildcards respect dot boundary")
  expect(
    !allowsGroup(shared, "TEAM.*") && !allowsGroup(shared, "TEAM.")
      && !allowsGroup(shared, "OTHER.tool"),
    "signed groups must be concrete and authorized")
  var distribution = shared
  distribution.development = false
  expect(
    chosen(
      selectProfile(bundleID: "tool", profiles: [distribution], identities: [current], now: now))
      == "none",
    "distribution profiles are outside local development signing")
  var future = current
  future.notBefore = later
  var futureProfile = shared
  futureProfile.certificates = [future]
  expect(
    signingCertificates(futureProfile, identities: [future], now: now).isEmpty,
    "future certificate cannot sign")
  var duplicate = shared
  duplicate.digest = "fixture-digest"
  expect(
    uniqueProfiles([duplicate, duplicate]).count == 1, "identical profile files are one candidate")
  expect(
    findings(identities: [current], profiles: [explicit], bundles: [], now: now, window: 0).isEmpty,
    "explicit-only setup needs no shared wildcard")
  var otherScope = shared
  otherScope.appID = "TEAM.com.other.*"
  expect(
    decisions(identities: [current], profiles: [shared, otherScope], now: now).isEmpty,
    "independent scopes coexist")
  func fails(_ check: String, _ changed: SignedBundle) -> Bool {
    verifyChecks(changed, now: now).contains { $0.name == check && !$0.ok }
  }
  var changed = healthy
  changed.embedded = profile("Expired", "expired", expires: past, certs: [current])
  expect(fails("profile-scope", changed), "expired embedded profile fails")
  changed = healthy
  changed.embedded = explicit
  changed.identifier = "other"
  changed.infoIdentifier = "other"
  changed.appID = "TEAM.other"
  changed.groups = ["TEAM.other"]
  expect(fails("profile-scope", changed), "embedded App ID must cover bundle")
  changed = healthy
  changed.signatureTeam = "OTHER"
  expect(fails("team-identifier", changed), "signature Team ID must match entitlement")
  changed = healthy
  changed.groups = ["TEAM.shared", "TEAM.tool"]
  expect(fails("own-access-group", changed), "own group stays first to preserve default writes")
  changed = healthy
  changed.groups = ["TEAM.tool", "TEAM.*"]
  expect(fails("groups-authorized", changed), "signed wildcard is rejected")
  changed = healthy
  changed.embedded = profile("No device", "no-device", certs: [current], covers: false)
  expect(fails("profile-scope", changed), "embedded profile must cover this Mac")
  changed = healthy
  changed.embedded = nil
  expect(fails("embedded-profile", changed), "missing embedded profile fails")
  changed = healthy
  changed.signer = renewed
  expect(fails("signer-current", changed), "signer must appear in embedded profile")
  let embeddedSoon = bundle(
    "tool", signer: current, embedded: profile("Soon", "soon", expires: soon, certs: [current]))
  expect(
    findings(identities: [], profiles: [], bundles: [embeddedSoon], now: now, window: window)
      .contains { $0.contains("embedded profile expires") }, "embedded-only profile renewal warning"
  )
  expect(
    (try? preserveIdentity(healthy, bundleID: "tool", accessGroup: "TEAM.tool")) != nil,
    "stable access group survives certificate renewal")
  expect(
    (try? preserveIdentity(healthy, bundleID: "tool", accessGroup: "PREFIX.tool")) == nil,
    "prefix change cannot silently replace existing output")
  for key in ["CFBundleIdentifier", "CFBundleExecutable", "CFBundleVersion", "LSUIElement"] {
    expect(
      (try? bundleInfo(
        bundleID: "tool", executable: "tool", name: "Tool", accessGroup: "TEAM.tool",
        accessGroupKey: key, extra: [:])) == nil, "access group cannot overwrite \(key)")
  }
  expect(
    validBundleIdentifier("com.example.tool") && !validBundleIdentifier("com.example.*")
      && !validBundleIdentifier("../tool") && !validBundleIdentifier("com..tool"),
    "bundle identifier validation")

  if let fixtures {
    let decoded = decodeProfile(
      fixtures.appendingPathComponent("signed.provisionprofile"), macUDID: "fixture-device")
    expect(
      decoded?.prefix == "PREFIX" && decoded?.team == "TEAM" && decoded?.coversThisMac == true,
      "decode signed CMS fixture with distinct App ID prefix")
    let observed = Date()
    let fixtureCertificate = decoded?.certificates.first
    expect(
      decoded?.certificates.count == 1 && fixtureCertificate?.isCurrent(at: observed) == true
        && (fixtureCertificate?.notAfter ?? .distantPast) > observed.addingTimeInterval(86_400)
        && (fixtureCertificate?.notAfter ?? .distantFuture)
          < observed.addingTimeInterval(3 * 86_400),
      "decode real certificate validity dates with the correct epoch")
    for name in [
      "empty.provisionprofile", "unsigned.provisionprofile", "corrupt.provisionprofile",
      "profile.plist",
    ] {
      expect(
        decodeProfile(fixtures.appendingPathComponent(name), macUDID: "fixture-device") == nil,
        "reject malformed or unsigned profile \(name)")
    }
    let app = fixtures.appendingPathComponent("Fixture.app")
    expect(
      signedBundle(app, macUDID: "fixture-device")?.validSignature == true,
      "inspect genuine ad-hoc bundle without a Keychain identity")
    expect(
      signedBundle(fixtures.appendingPathComponent("Tampered.app"), macUDID: "fixture-device")?
        .validSignature == false,
      "detect tampered signed resources")
    let destination = fixtures.appendingPathComponent("Installed.app")
    let replacement = fixtures.appendingPathComponent("Replacement.app")
    do {
      try installBundle(replacement, at: destination)
      expect(
        try String(contentsOf: destination.appendingPathComponent("value"), encoding: .utf8)
          == "new",
        "install replaces existing fixture")
      do {
        try installBundle(fixtures.appendingPathComponent("Missing.app"), at: destination)
        expect(false, "missing replacement must fail")
      } catch {
        expect(
          try String(contentsOf: destination.appendingPathComponent("value"), encoding: .utf8)
            == "new",
          "failed replacement restores existing fixture")
      }
      let remnants = try FileManager.default.contentsOfDirectory(atPath: fixtures.path)
      expect(!remnants.contains { $0.contains(".previous-") }, "installation cleans its backup")
    } catch { expect(false, "fixture filesystem operation: \(error.localizedDescription)") }
  }

  print("self_test_checks=\(count)")
  print(failures == 0 ? "self_test=ok" : "self_test_failures=\(failures)")
  return failures == 0 ? 0 : 1
}

// MARK: - Signing

func sign(values: [String: [String]], json: Bool, now: Date) throws {
  guard let bundleID = values["--bundle-id"]?.last, let binaryPath = values["--binary"]?.last,
    let outputPath = values["--output"]?.last, outputPath.hasSuffix(".app"),
    values["--binary"]?.count == 1
  else { usage() }
  let files = FileManager.default
  let binary = absolute(binaryPath)
  let output = absolute(outputPath)
  let parent = output.deletingLastPathComponent()
  guard files.isExecutableFile(atPath: binary.path),
    (try? binary.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])).map({
      $0.isRegularFile == true && $0.isSymbolicLink != true
    }) == true
  else { throw InputError(message: "binary is not an executable file: \(binaryPath)") }
  let magic = try Data(contentsOf: binary, options: .mappedIfSafe).prefix(4)
  guard
    [
      "FEEDFACE", "CEFAEDFE", "FEEDFACF", "CFFAEDFE", "CAFEBABE", "BEBAFECA", "CAFEBABF",
      "BFBAFECA",
    ]
    .contains(magic.map { String(format: "%02X", $0) }.joined())
  else { throw InputError(message: "binary must be a Mach-O executable") }
  var parentIsDirectory: ObjCBool = false
  guard files.fileExists(atPath: parent.path, isDirectory: &parentIsDirectory),
    parentIsDirectory.boolValue
  else {
    throw InputError(message: "output directory is missing: \(parent.path)")
  }
  var extraInfo: [String: String] = [:]
  for pair in values["--info"] ?? [] {
    guard let separator = pair.firstIndex(of: "="), separator != pair.startIndex else { usage() }
    extraInfo[String(pair[..<separator])] = String(pair[pair.index(after: separator)...])
  }
  var extraEntitlements: [String: Any] = [:]
  if let path = values["--entitlements"]?.last {
    guard let data = try? Data(contentsOf: absolute(path)),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    else { throw InputError(message: "cannot read entitlements plist: \(path)") }
    extraEntitlements = plist
  }
  let (profile, identity) = resolve(bundleID: bundleID, values: values, json: json, now: now)
  let accessGroup = profile.applicationIdentifier(for: bundleID)
  let info = try bundleInfo(
    bundleID: bundleID, executable: binary.lastPathComponent,
    name: values["--name"]?.last ?? output.deletingPathExtension().lastPathComponent,
    accessGroup: accessGroup, accessGroupKey: values["--access-group-key"]?.last, extra: extraInfo)
  let entitlements = try bundleEntitlements(
    team: profile.team, prefix: profile.prefix, bundleID: bundleID, extra: extraEntitlements)
  if files.fileExists(atPath: output.path) {
    guard (try? output.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink != true,
      let previous = signedBundle(output, macUDID: "")
    else { throw InputError(message: "existing output must be a signed tool bundle") }
    try preserveIdentity(previous, bundleID: bundleID, accessGroup: accessGroup)
  }

  // Assemble and sign in a sibling staging directory; replace the output only after verification.
  let staging = parent.appendingPathComponent(
    ".\(output.lastPathComponent).staging-\(UUID().uuidString)")
  defer { try? files.removeItem(at: staging) }
  let app = staging.appendingPathComponent(output.lastPathComponent)
  let contents = app.appendingPathComponent("Contents")
  let entitlementsFile = staging.appendingPathComponent("entitlements.plist")
  do {
    try files.createDirectory(
      at: contents.appendingPathComponent("MacOS"), withIntermediateDirectories: true)
    try files.copyItem(
      at: binary, to: contents.appendingPathComponent("MacOS/" + binary.lastPathComponent))
    try files.copyItem(
      at: URL(fileURLWithPath: profile.path),
      to: contents.appendingPathComponent("embedded.provisionprofile"))
    try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
      .write(to: contents.appendingPathComponent("Info.plist"))
    try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
      .write(to: entitlementsFile)
  } catch {
    throw InputError(message: "cannot assemble bundle: \(error.localizedDescription)")
  }
  let signing = runCapturingErrors([
    "/usr/bin/codesign", "--force", "--sign", identity.sha1, "--entitlements",
    entitlementsFile.path,
    "--timestamp=none", app.path,
  ])
  guard signing.status == 0 else {
    throw InputError(
      message: "codesign failed: " + signing.error.trimmingCharacters(in: .whitespacesAndNewlines))
  }
  let udid = macProvisioningUDID()
  guard let signed = signedBundle(app, macUDID: udid) else {
    throw InputError(message: "signed bundle is unreadable")
  }
  let checks = verifyChecks(signed, now: now)
  guard checks.allSatisfy(\.ok) else {
    throw InputError(
      message: "verification failed: "
        + checks.filter { !$0.ok }.map { "\($0.name): \($0.detail)" }.joined(separator: "; "))
  }
  try installBundle(app, at: output)
  let result: [String: Any] = [
    "output": output.path, "bundle_id": bundleID, "access_group": accessGroup,
    "profile_name": profile.name,
    "profile_uuid": profile.uuid, "signing_identity": identity.sha1, "core_checks_passed": true,
  ]
  if json {
    emit(result)
  } else {
    for key in result.keys.sorted() { print("\(key)=\(result[key]!)") }
  }
}

func preserveIdentity(_ previous: SignedBundle, bundleID: String, accessGroup: String) throws {
  guard previous.identifier == bundleID, previous.infoIdentifier == bundleID,
    previous.groups == [accessGroup], previous.appID == accessGroup
  else {
    throw InputError(
      message:
        "existing output has a different application identity or access group; plan its secret migration before replacing it"
    )
  }
}

/// Keep the previous bundle available for rollback until the verified replacement is installed.
func installBundle(_ app: URL, at output: URL) throws {
  let files = FileManager.default
  let previous = output.deletingLastPathComponent()
    .appendingPathComponent(".\(output.lastPathComponent).previous-\(UUID().uuidString)")
  do {
    if files.fileExists(atPath: output.path) { try files.moveItem(at: output, to: previous) }
    try files.moveItem(at: app, to: output)
  } catch {
    if files.fileExists(atPath: previous.path), !files.fileExists(atPath: output.path) {
      do { try files.moveItem(at: previous, to: output) } catch {
        throw InputError(
          message:
            "installation and rollback failed; recover the previous bundle at \(previous.path)")
      }
    }
    throw InputError(message: "cannot install signed bundle: \(error.localizedDescription)")
  }
  if files.fileExists(atPath: previous.path) {
    do { try files.removeItem(at: previous) } catch {
      FileHandle.standardError.write(
        Data(
          "installed; remove previous bundle at \(previous.path): \(error.localizedDescription)\n"
            .utf8))
    }
  }
}

// MARK: - Main

let arguments = CommandLine.arguments.dropFirst()
guard let command = arguments.first else { usage() }
let parsed = options(arguments.dropFirst(), command: command)
let now = Date()

switch command {
case "self-test":
  exit(selfTest(fixtures: parsed.values["--fixtures"]?.first.map(absolute)))
case "select-profile":
  guard let bundleID = parsed.values["--bundle-id"]?.last else { usage() }
  let (profile, identity) = resolve(
    bundleID: bundleID, values: parsed.values, json: parsed.json, now: now)
  let team = profile.team
  let result: [String: Any] = [
    "bundle_id": bundleID, "team": team, "app_id_prefix": profile.prefix,
    "application_identifier": profile.applicationIdentifier(for: bundleID),
    "access_group": profile.applicationIdentifier(for: bundleID), "profile_path": profile.path,
    "profile_name": profile.name, "profile_uuid": profile.uuid,
    "profile_expires": day(profile.expires), "signing_identity": identity.sha1,
    "signing_identity_name": identity.name, "identity_expires": day(identity.notAfter),
  ]
  if parsed.json {
    emit(result)
  } else {
    for key in result.keys.sorted() { print("\(key)=\(result[key]!)") }
  }
case "verify":
  guard let path = parsed.values["--bundle"]?.last else { usage() }
  let udid = macProvisioningUDID()
  guard let bundle = signedBundle(absolute(path), macUDID: udid) else {
    FileHandle.standardError.write(Data("not a signed bundle: \(path)\n".utf8))
    exit(1)
  }
  let checks = verifyChecks(bundle, now: now)
  if parsed.json {
    emit([
      "bundle": bundle.path, "identifier": bundle.identifier, "ok": checks.allSatisfy(\.ok),
      "checks": checks.map { ["name": $0.name, "ok": $0.ok, "detail": $0.detail] },
    ])
  } else {
    for check in checks { print("\(check.ok ? "ok  " : "FAIL") \(check.name): \(check.detail)") }
  }
  exit(checks.allSatisfy(\.ok) ? 0 : 1)
case "audit":
  let days = Int(parsed.values["--within-days"]?.last ?? "90") ?? -1
  guard days >= 0 else { usage() }
  let udid = macProvisioningUDID()
  let identities = localIdentities()
  let profiles = installedProfiles(macUDID: udid)
  var bundles: [SignedBundle] = []
  for path in parsed.values["--bundle"] ?? [] {
    guard let bundle = signedBundle(absolute(path), macUDID: udid) else {
      FileHandle.standardError.write(Data("not a signed bundle: \(path)\n".utf8))
      exit(1)
    }
    bundles.append(bundle)
  }
  let mac = profiles.filter(\.isMac)
  let found = findings(
    identities: identities, profiles: profiles, bundles: bundles, now: now,
    window: TimeInterval(days) * 86_400)
  let open = decisions(identities: identities, profiles: profiles, now: now)
  if parsed.json {
    emit([
      "identities": identities.map { record($0) },
      "profiles": mac.map { record($0, identities: identities, now: now) },
      "other_platform_profiles": profiles.count - mac.count,
      "bundles": bundles.map { b in
        [
          "path": b.path, "identifier": b.identifier, "signer": record(b.signer), "app_id": b.appID,
          "keychain_access_groups": b.groups, "profile_uuid": b.embedded?.uuid ?? "",
          "profile_name": b.embedded?.name ?? "", "valid_signature": b.validSignature,
        ] as [String: Any]
      },
      "findings": found,
      "decisions": open,
    ])
  } else {
    for i in identities {
      print("identity \(i.sha1.prefix(8)) \(i.name) expires \(day(i.notAfter))")
    }
    for p in mac {
      let usable = signingCertificates(p, identities: identities, now: now).map {
        String($0.sha1.prefix(8))
      }
      print(
        "profile \(p.name) [\(p.uuid.prefix(8))] app-id \(p.appID) expires \(day(p.expires)) "
          + "signs-here \(usable.isEmpty ? "no" : usable.joined(separator: ","))")
    }
    for b in bundles {
      print(
        "bundle \(b.identifier) signer \(b.signer.map { String($0.sha1.prefix(8)) } ?? "none") "
          + "profile \(b.embedded?.name ?? "none") groups \(b.groups.joined(separator: ",")) "
          + "signature \(b.validSignature ? "valid" : "INVALID")")
    }
    for line in found { print("WARN " + line) }
    for line in open { print("DECIDE " + line) }
  }
case "sign":
  do { try sign(values: parsed.values, json: parsed.json, now: now) } catch let error as InputError
  { fail(error.message, status: error.status) } catch { fail(error.localizedDescription) }
default:
  usage()
}
