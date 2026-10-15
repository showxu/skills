---
name: codesign
description: 'Prepare, integrate, review and audit local development signing for native macOS tools, helpers and SwiftPM executables outside Xcode that need profile-authorized entitlements such as Data Protection Keychain access groups. Select provisioning profiles and identities by criteria, sign a single-executable tool bundle through its build, verify its signing inputs and plan renewals. Does not own Xcode archive/export or Developer ID distribution (apple-platform-release), SwiftPM .app packaging and notarization (swiftpm-macos-app-packaging), or SecItem implementation (keychain-patterns).'
---

# codesign

Own the local tool's signing integration, profile/identity selection, bundle
checks and renewal audit. Use the bundled [CLI contract](cli/README.md) from
the project's build entrypoint. Run the project's build to produce its signed
artifact; keep the CLI path and owner choices explicit build inputs.

## Scope

Use for local development tools with restricted entitlements, signing-step
reviews, launch or entitlement failures, and certificate/profile renewals.
The helper assembles a minimal app-like wrapper for one native Mach-O main
executable. This wrapper provides a place to embed the provisioning profile.

This skill does not own release archives, distribution or submission:

- Xcode archive/export and Developer ID distribution: `apple-platform-release`.
- SwiftPM application packaging, notarization, stapling and Sparkle:
  `swiftpm-macos-app-packaging`.
- SecItem queries, access control and data models: `keychain-patterns`.

These skills can live in another installed collection; refer to them by name.
Tools without restricted entitlements may use ad-hoc signing, but an ad-hoc
signature cannot authorize a restricted entitlement.

## Signing model

- A signing identity is a certificate plus its private key in an accessible
  keychain. Do not assume a particular keychain or certificate display name.
- A profile authorizes certificates, App IDs, devices, dates and restricted
  entitlements. Use a macOS development profile covering the current Mac and
  an appropriate Apple development identity for this workflow.
- An App ID is `APP_ID_PREFIX.BUNDLE_ID`. Read the prefix and Team ID from the
  profile separately; they can differ. The managed Keychain access group is
  the concrete App ID. Never embed a wildcard in the signed entitlements.
- The main executable's signed entitlements govern its Data Protection
  Keychain access. A library's signature cannot supply its host's access group.
  This Keychain is available in a user login context, not a system daemon.
  File-based Keychain ACLs are a different access model.

Read [Apple tooling and limits](references/apple-signing.md) when diagnosing a
profile, validating extra entitlements or reviewing platform assumptions.

## Selection and compatibility

Select by platform, development scope, expiry, device coverage, App ID,
authorized access group and a current local identity listed in the profile.
The CLI prefers a qualifying explicit App ID profile; otherwise it considers
matching wildcard profiles, including scoped wildcards. Identical profile
files count once. Multiple profiles or identities remain an owner choice:
return candidates, then pass `--profile` or `--identity` through the build.
Never revoke or delete another candidate to resolve ambiguity automatically.

A shared wildcard development profile may serve compatible local tools. Use
an explicit App ID when a capability requires one. Independent teams, App ID
prefixes and scopes can coexist; a shared profile is not an Apple requirement.
Names are labels, not authorization. A regenerated profile may have a new
UUID, so refresh a pinned choice after inspecting the downloaded profile.

Keep the existing application identifier and access group stable across
rebuilds and certificate renewal. Changing the App ID prefix or group can
remove access to existing Keychain items. The CLI stops when replacing an
output with a different application identity or group. Plan a secret migration
before that change, with SecItem implementation owned by `keychain-patterns`.

## Workflow

1. **Inspect inputs.** Determine the executable, stable bundle identifier,
   producer-owned output path, user/daemon launch context and existing signed
   identity/group. Review any extra entitlements against current Apple docs
   and the selected profile. The helper checks only its managed identity and
   Keychain group contract; it is not a general entitlement-policy validator.
2. **Integrate.** Add `sign` to the project's build using [the CLI example](cli/README.md).
   Pass the CLI path explicitly. If needed, choose a custom Info.plist key
   from which the tool reads its access group with `Bundle.main`.
3. **Build.** Run that build. Exit 2 lists candidates for an owner choice;
   rebuild with the choice. Exit 1 reports an input or signing/check failure.
   The helper stages, signs and checks the new bundle before installation.
4. **Exercise.** Run the main executable from `Tool.app/Contents/MacOS/` in its
   intended user login context. Validate launch and the tool's Keychain access
   with a disposable test item. Get authorization before testing against live
   secrets. Static verification cannot establish runtime authorization.
5. **Report.** Name the build entrypoint, profile and identity used, checks,
   runtime evidence, warnings and pending owner decisions. Do not publish
   private paths, team/certificate identifiers, device IDs or secret values.

### Projects with their own signing step

Keep nested code, multiple executables, existing application packaging and
custom entitlement policy in the project's own build. Sign nested code inside
out; do not use `--deep` to repair signing. Use this skill's inspection rules
and `verify` for the supported core checks.

```text
Tool.app/Contents/
├── Info.plist                 CFBundleIdentifier, CFBundleExecutable,
│                              CFBundlePackageType=APPL, LSUIElement=true,
│                              optional custom access-group key
├── MacOS/<executable>
└── embedded.provisionprofile
```

```xml
<key>com.apple.application-identifier</key><string>APP_ID_PREFIX.BUNDLE_ID</string>
<key>com.apple.developer.team-identifier</key><string>TEAM_ID</string>
<key>keychain-access-groups</key><array><string>APP_ID_PREFIX.BUNDLE_ID</string></array>
```

```sh
codesign --force --sign "$SIGNING_IDENTITY_SHA1" \
  --entitlements entitlements.plist --timestamp=none Tool.app
codesign --verify --strict --all-architectures Tool.app
codesign --display --entitlements - --xml Tool.app
```

Disabling timestamp service is appropriate for this local development flow.
Distribution signing follows its own owner and timestamp requirements.

## Renewal and retirement

1. Audit named tools with `cli/codesign.swift audit --bundle A.app --bundle B.app`.
   Audit inventories valid local identities and decoded macOS profiles; it
   cannot discover every installed consumer.
2. With existing authorization, renew certificates or regenerate profiles in
   Xcode or the Developer account. Inspect and install the new profile, then
   pass its selection through each tool's build. Preserve the App ID prefix,
   bundle identifier and access group.
3. Rebuild, inspect, launch and exercise every affected tool. The installed
   profile file and private key are build inputs; the embedded profile and
   signer certificate are what the built tool carries. Removing an installed
   profile does not itself invalidate its embedded copy. Revocation, expiry
   and platform policy can still prevent launch.
4. Retire a superseded profile or certificate only after identifying its other
   consumers and obtaining authorization. Retain needed recovery material.

Creating App IDs, portal edits, certificate revocation, profile removal and
secret migration are account/data operations. Carry existing authorization
forward; otherwise prepare the exact action and request it before mutation.
Audit and selection read local state. `sign` writes the requested output and
sibling staging/backup directories, and can prompt to use the selected key.

## CLI and validation

| Command | Result |
| --- | --- |
| `select-profile --bundle-id ID [--profile UUID] [--identity SHA1] [--json]` | Candidate or owner decision; no account changes |
| `sign --bundle-id ID --binary PATH --output PATH.app [...]` | Single-executable wrapper, signing and core checks |
| `verify --bundle PATH [--json]` | Signature integrity and embedded-profile/core entitlement checks |
| `audit [--bundle PATH]... [--within-days N] [--json]` | Inventory, renewal warnings and selection decisions; default 90 days |
| `self-test` | Synthetic in-memory rule tests; no Keychain/profile discovery |

After editing, run `python3 -B skills/codesign/cli/test_codesign.py` from the
collection root and the skill package/repository validators. The fixture
runner compiles the CLI, exercises CMS and ad-hoc bundles, usage and rollback,
and blocks network and real Keychain/profile directories. Its outputs belong
in `.build/codesign-tests/`. Read [behavior fixtures](references/eval-fixtures.md)
for trigger, routing, compatibility and authorization review.
