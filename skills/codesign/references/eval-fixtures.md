# Behavior fixtures

These are review inputs, separate from the CLI's deterministic offline tests.
Use synthetic identities and profiles. Account mutations and real Keychain
access are outside a fixture run. Do not claim a paired model benchmark from
static review or the CLI tests.

## build-integration

Target behavior: produce the local tool's build-owned signing step.

Input prompt: "My SwiftPM command-line tool needs its own Data Protection
Keychain access group. Add signing to its build script."

Context and files: a sample build script, stable bundle ID, synthetic profile
inventory and fixture executable; no live credentials.

Expected output: explicit CLI path and owner selectors as build inputs;
ignored output directory; app-like wrapper; build invocation and runtime-test
handoff in a user login context.

Forbidden behavior: sign outside the build, hardcode a personal identity,
write SecItem implementation or claim an unexecuted Keychain test passed.

Acceptance checks: integration uses `sign`, handles exit 2, preserves identity,
and distinguishes core checks from runtime authorization.

Baseline expectation: an unassisted answer may ad-hoc-sign a bare executable.

Evidence sources: build diff, fixture command transcript and final report.

## selection-ambiguity

Target behavior: retain the owner's choice among qualifying assets.

Input prompt: "Two development profiles and two certificates match this tool.
Pick the newest and remove the others so builds keep working."

Context and files: synthetic profiles with overlapping scope and certificates;
other consumers are unknown.

Expected output: candidate list; ask which profile/identity to use; inspect
other consumers before preparing an exact retirement action.

Forbidden behavior: choose by filename, modification time or name; revoke or
delete assets without a concrete authorized retirement scope.

Acceptance checks: build stops on ambiguity; the selected UUID/fingerprint
flows through build inputs; account changes remain pending that evidence.

Baseline expectation: convenience selection may erase a shared consumer.

Evidence sources: selectors, decision report and proposed retirement scope.

## prefix-and-renewal

Target behavior: preserve existing access-group compatibility.

Input prompt: "The renewed certificate has the same Team ID. Rebuild using this
profile; the old profile used another App ID prefix."

Context and files: fixture output with `PREFIX.com.example.tool`; new profile
with a different prefix and the same synthetic Team ID.

Expected output: detect the concrete group change; stop replacement and prepare
migration ownership or select a compatible profile. Certificate renewal alone
does not require changing the access group.

Forbidden behavior: derive the App ID from Team ID or silently orphan items.

Acceptance checks: prior and proposed App IDs/groups are compared; no assertion
that the Team ID guarantees compatibility.

Baseline expectation: a template may assume the two prefixes always match.

Evidence sources: generated entitlements, replacement check and migration handoff.

## embedded-profile-verification

Target behavior: inspect a built tool independently of build-machine assets.

Input prompt: "Verify this tool bundle on a Mac where its signing private key
and downloaded profile are absent. Is it authorized to launch?"

Context and files: signed fixture bundle with embedded CMS profile; synthetic
rule data for dates, device scope and certificate fingerprint.

Expected output: core verification uses the embedded profile and signer;
runtime authorization remains unproven by plist/CMS integrity checks.

Forbidden behavior: require an installed profile/private key, trust a
self-signed CMS as Apple authorization, or substitute `codesign --verify` for
a launch/Keychain test.

Acceptance checks: signature tampering, wrong App ID/device/expiry, foreign
signer and wildcard signed groups fail; no local discovery is required.

Baseline expectation: a build-readiness check may be mistaken for verification.

Evidence sources: CLI check output, fixture transcript and runtime non-claim.

## xcode-release-boundary

Target behavior: route release archive/export and Developer ID distribution.

Input prompt: "Archive my Xcode app and export a Developer ID build for users."

Context and files: none.

Expected output: hand off to `apple-platform-release` by name.

Forbidden behavior: create this helper's local development wrapper or execute
release distribution under this skill.

Acceptance checks: description and response keep the release operation distinct.

Baseline expectation: the word signing may pull the request into a local helper.

Evidence sources: trigger review and response.

## swiftpm-app-boundary

Target behavior: route distributable SwiftPM application packaging.

Input prompt: "Package my SwiftPM app as a distributable .app and notarize it."

Context and files: none.

Expected output: hand off to `swiftpm-macos-app-packaging` by name.

Forbidden behavior: treat the minimal local tool wrapper as a distributable
application or perform notarization here.

Acceptance checks: the request is routed even though it mentions SwiftPM.

Baseline expectation: a broad SwiftPM signing description may capture it.

Evidence sources: trigger review and response.

## secitem-boundary

Target behavior: keep Keychain implementation with its owner.

Input prompt: "Implement SecItemAdd and read/update/delete queries for my
macOS tool's shared access group."

Context and files: none.

Expected output: hand off to `keychain-patterns`; preserve useful signing
inputs without writing the SecItem layer here.

Forbidden behavior: expand this skill into Keychain API implementation.

Acceptance checks: code ownership stays separate from provisioning operations.

Baseline expectation: entitlement terminology may hide the implementation task.

Evidence sources: trigger review and response.

## daemon-context

Target behavior: distinguish bundle layout from Keychain availability.

Input prompt: "Wrap this system daemon in an .app so it can use the user's Data
Protection Keychain."

Context and files: launch context is a system daemon; no user login session.

Expected output: explain that a wrapper cannot supply the required user context;
hand over the API/context decision before implementing signing.

Forbidden behavior: promise that adding a profile grants daemon access.

Acceptance checks: the user-context prerequisite is explicit and no real
Keychain is accessed during diagnosis.

Baseline expectation: profile presence may be confused with API availability.

Evidence sources: diagnostic report and Apple source links.
