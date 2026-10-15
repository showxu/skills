# CLI contract

`codesign.swift` is a dependency-free swift-sh script for local development
signing. Projects call it from their build entrypoint. It invokes Apple's
`/usr/bin/codesign`; it does not replace that tool or perform account operations.
The repository's root license governs this original helper and guidance.

## Requirements and commands

macOS with the Xcode command line tools and `swift-sh` on `PATH`. The executable
shebang uses `/usr/bin/swift sh`; `swift-sh codesign.swift ...` is also supported.
The runner compiles the script and caches that build. There are no package
imports to resolve over the network.

```sh
codesign.swift select-profile --bundle-id ID [--profile UUID] [--identity SHA1] [--json]
codesign.swift sign --bundle-id ID --binary PATH --output PATH.app [--name NAME] \
  [--info KEY=VALUE]... [--access-group-key KEY] [--entitlements PLIST] \
  [--profile UUID] [--identity SHA1] [--json]
codesign.swift verify --bundle PATH [--json]
codesign.swift audit [--bundle PATH]... [--within-days N] [--json]
codesign.swift self-test [--fixtures PATH]
```

Use a reverse DNS bundle identifier. UUID/fingerprint selectors accept an
unambiguous prefix of at least eight characters. Empty selectors, unknown
options and repeated singleton options are usage errors.

| Exit | Meaning |
| --- | --- |
| 0 | Command completed; `verify` core checks passed; `audit` may still report warnings/decisions |
| 1 | No candidate, unusable input, signing or verification failure |
| 2 | Several profiles/certificates qualify; choose and retry |
| 64 | Usage error |

Requested results go to stdout; errors go to stderr. `--json` returns JSON for
successful commands and ambiguous selection. Input/tool failures use stderr.

## Calling from a project

Run the project's compilation first, then call this as its signing step. Put
the output inside the project's ignored build-output directory:

```sh
: "${CODESIGN_CLI:?set CODESIGN_CLI to the installed codesign.swift path}"
set -- sign \
  --bundle-id "$BUNDLE_ID" \
  --binary ".build/release/$EXECUTABLE" \
  --output "$OUTPUT_DIR/$APP_NAME.app" \
  --access-group-key "$ACCESS_GROUP_INFO_KEY"
if [ -n "${CODESIGN_PROFILE:-}" ]; then
  set -- "$@" --profile "$CODESIGN_PROFILE"
fi
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  set -- "$@" --identity "$CODESIGN_IDENTITY"
fi
"$CODESIGN_CLI" "$@"
```

- Exit 2 stops the build; supply the owner's choice through the build inputs.
- `--access-group-key` writes the concrete access group to a distinct custom
  Info.plist key, for the main executable to read from `Bundle.main`.
- `--info` adds string Info.plist values. It cannot overwrite managed identity
  keys. The access-group key cannot collide with a supplied key or `CFBundle*`.
- `--entitlements` adds claims beyond the managed application identifier, Team
  ID and one access group. It cannot override those keys. The caller must review
  extra claims against current Apple policy and profile authorization; core
  `verify` does not validate them. Use the project's own signing step for
  complex entitlement requirements, shared groups, resources or nested code.
- If vendoring this helper, preserve the root license notice with the copy.

## Selection, reads and writes

Selection reads valid code-signing identities from the default keychain search
list using `security find-identity -v -p codesigning` and Security APIs. It reads
this Mac's provisioning UDID from `system_profiler SPHardwareDataType -json`.
It inspects regular `.provisionprofile` and `.mobileprovision` files, one level
under these discovery directories relative to the current user's home:

- `Library/Developer/Xcode/UserData/Provisioning Profiles`
- `Library/MobileDevice/Provisioning Profiles`

These are tooling locations, not a stable Apple API. Unsupported or malformed
profiles are skipped. Matching requires macOS development/device scope,
current dates, a matching App ID and group, and a certificate backed by a valid
local identity. Explicit App IDs take precedence over matching wildcard App
IDs. Separate matching scopes remain ambiguous; file order never chooses.
Byte-identical CMS files are deduplicated across discovery directories.

`sign` accepts a regular native Mach-O executable, assembles a minimal wrapper,
copies the selected profile, and signs with `--timestamp=none`. It creates
sibling staging and backup directories beside the requested output. Signing
may prompt for permission to use the private key; the helper does not change
key ACLs, partition lists, identities, profile files or Keychain items.

Assembly/signing/check failures clean staging and leave an existing output
untouched. An existing output must be a signed bundle with the same application
identifier and single access group. Installation uses two renames with rollback;
it is not an atomic exchange. Stop concurrent builds/launches during replacement.
On rollback failure the diagnostic identifies the retained backup; on backup
cleanup failure it identifies the previous bundle to remove.

## What verification establishes

`verify` reads only the requested bundle plus the Mac's provisioning UDID. It
requires neither an installed profile copy nor the signing private key. It uses
Security APIs to check strict signature integrity for all architectures and
nested code. Core entitlement inspection uses the native architecture's signing
information. The embedded profile's decoded plist must cover macOS development,
the current Mac, dates, App ID, signing certificate, Team ID and concrete groups.
The managed own group must be first, so default Keychain writes remain stable.

CMS integrity is checked without evaluating signer trust. A decoded profile is
not proof of Apple provenance. The plist is a diagnostic view; modern systems
use the DER profile as their authority. These checks do not establish arbitrary
entitlement authorization, revocation status, Gatekeeper acceptance or successful
launch. Run the tool in its intended context and exercise a disposable Keychain
item before relying on the result. See [Apple tooling and limits](../references/apple-signing.md).

## Offline validation

`self-test` uses synthetic in-memory data without querying identities, installed
profiles or the Keychain. `--fixtures PATH` additionally reads the generated
CMS/ad-hoc fixtures and tests replacement/rollback within that directory.

From the collection root, run:

```sh
python3 -B skills/codesign/cli/test_codesign.py
```

The runner compiles with the local SDK, generates temporary OpenSSL certificates
and CMS messages, signs only ad-hoc fixture code, and exercises the production
inspection and replacement functions. Its sandbox denies network and reads or
writes to the user's/system's Keychain and provisioning-profile directories.
No certificate is imported and no Keychain search list is changed. All outputs
reuse `.build/codesign-tests/`; remove that producer directory after recording
the result. The swift-sh cache is not used by this validation route.
