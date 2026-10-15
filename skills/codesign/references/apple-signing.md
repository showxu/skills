# Apple tooling and limits

Use current Apple documentation and the installed SDK/tool manuals when
maintaining this helper. Profile locations and plist fields are development
tool details that can change. The helper is a local development preflight,
not an implementation of the platform's authorization policy.

## Sources and decisions

- [TN3125: Provisioning Profiles](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles):
  profiles carry CMS data; the plist is a diagnostic view, and the DER profile
  is authoritative on modern systems. Certificates, App ID, devices, expiry
  and restricted entitlement claims must align. A standalone executable needs
  an app-like wrapper to embed its profile at
  `Contents/embedded.provisionprofile`.
- [TN2415: Entitlements Troubleshooting](https://developer.apple.com/library/archive/technotes/tn2415/):
  App ID prefixes can differ from Team IDs. Expand profile wildcards into
  concrete signed values. Keep application and team identifiers separate.
- [Sharing access to Keychain items](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps):
  access groups govern Data Protection Keychain items on macOS when queries
  select that implementation or synchronization. Group ordering affects the
  default group; keep this helper's own group first.
- [TN3137: Mac Keychain APIs and implementations](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains):
  file-based Keychain ACLs and Data Protection Keychain access groups differ.
  The latter requires a user login context and is governed by the host main
  executable's entitlements. `security` primarily operates on file-based
  keychains; listing signing identities does not test Data Protection Keychain
  access.
- [QA1726: Potential loss of Keychain access](https://developer.apple.com/library/archive/qa/qa1726/_index.html):
  changing the App ID prefix can remove access to existing items. Preserve
  concrete group identity when rebuilding or renewing signing assets.
- [Signing a daemon with a restricted entitlement](https://developer.apple.com/documentation/xcode/signing-a-daemon-with-a-restricted-entitlement):
  an app-like layout supplies the profile location for a main executable built
  by another build system. This packaging does not make the Data Protection
  Keychain available to a system daemon.

App groups have their own evolving macOS rules. Do not infer Keychain access
from a macOS app-group name alone; inspect profile authorization and current
[Apple guidance on macOS and iOS app groups](https://developer.apple.com/forums/thread/721701).
Shared app-group migration is outside the helper's single-access-group contract.

## Command review

Read `man codesign`, `man security`, `security help find-identity` and
`security help cms` on the host. These help commands do not enumerate keys.

| Operation | Reviewed command or API | Meaning and limit |
| --- | --- | --- |
| Identity discovery | `security find-identity -v -p codesigning` | Valid identities in the default search list; names are labels; never scrape/export private keys |
| Diagnostic profile dump | `security cms -D -i "$PROFILE" -o "$OUTPUT_PLIST"` | Write only to an ignored output; the dump can contain device/account metadata; decoding is not authorization |
| Sign local development code | `codesign --force --sign "$IDENTITY_SHA1" --entitlements "$PLIST" --timestamp=none "$APP"` | Sign all Mach-O slices; disabling timestamp service avoids that network request |
| Signature integrity | `codesign --verify --strict --all-architectures "$APP"` | Does not establish launch, revocation or restricted-entitlement authorization |
| Inspect claimed entitlements | `codesign --display --entitlements - --xml "$APP"` | Force XML output; inspect claims rather than copying the profile allowlist wholesale |

Current `codesign` generates DER entitlements by default. Do not add `--deep`
to signing: it applies one signing configuration recursively and is deprecated
for signing. Projects with nested code own its inside-out signing order.

The CLI uses supported Security APIs for certificate metadata and code
inspection. `SecStaticCodeCheckValidity` receives strict, all-architecture and
nested-code flags; it does not opt into network access. `CMSDecoder` validates
CMS signature integrity without evaluating the CMS signer's trust. Thus a
self-signed CMS fixture can decode successfully. It is not an Apple-authorized
profile, and the fixture runner never launches it with restricted entitlements.

Extra entitlements need their own policy review. Some macOS entitlements are
unrestricted; others require a profile or additional account approval. A
generic equality check against every plist entry cannot replace those rules.

## Validation boundary

The fixture runner denies network, owner/system Keychain directories and the
profile discovery directories. It generates certificates as files, imports
none, and signs only ad-hoc test code. Pure model tests cover selection,
certificate dates, prefix/team separation, group matching and renewal rules.
CMS and signed-bundle fixtures exercise actual Security APIs; filesystem
fixtures exercise installation and rollback. None establishes successful
Apple development signing or Data Protection Keychain access on an enrolled
Mac. Those require the project's authorized runtime test.
