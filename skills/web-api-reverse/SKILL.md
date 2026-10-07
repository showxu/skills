---
name: web-api-reverse
description: Discover, capture, sanitize, classify, verify, promote, publish, diff, validate, and code-generate reverse-engineered Web APIs with Playwright-backed evidence and Swift-owned contracts. Use when building or reviewing an Observed/Trusted/Published API pipeline, authenticated browser capture, reversible mutation evidence, provider middleware, or a generated Swift API client from undocumented or drift-prone Web behavior.
compatibility: Requires macOS 14+, Swift 6, Node.js 22+, and Playwright for browser capture. Read-only contract operations do not require Node.js.
---

# Web API Reverse

## Purpose

Use this skill to turn undocumented or drift-prone Web behavior into an
auditable API contract and generated Swift client without placing browser
automation in normal product runtime.

The workflow owns evidence governance and tooling. The provider package owns
its route, authentication, signing, refresh, cookie, retry, and business
middleware.

## Required Artifact Shape

Each provider owns:

```text
API/Config/
API/Observed/
API/Trusted/
API/Published/
```

`Published` is the only code-generation input and contains exactly these
contract files:

```text
openapi.yaml
operation-policies.json
capability-claim.json
approval-receipt.json
publish-lock.json
```

Every consuming provider owns its own runtime projection tool and SwiftPM
build plugin. The projection must require this exact five-file Published set,
then re-hash every `approval-receipt.json.inputHashes` entry against the current
provider project. The required approval inputs are exactly the source manifest,
trust manifest, Observed catalog, Observed source lock, Trusted OpenAPI, and
Trusted operation policies; the only permitted additions are canonical single-file
`API/Observed/source-verifications/*.json` and
`API/Observed/collection-verifications/*.json` receipts. Missing, stale,
unsafe, symlinked, or unrecognized inputs fail closed. The plugin declares the
Published five, those six fixed approval inputs, and only safely parsed dynamic
source- and collection-verification inputs. Do not introduce a shared runtime
package or a governance plugin dependency.

Raw browser traffic, browser profiles, credentials, cookies, and session seeds
are private runtime state. Never store them in these directories or commit
them. Browser capture writes first to a tool-owned `0700` temporary root, then
the Swift CLI copies bounded canonical outputs through a descriptor-anchored
private store. `--private-output` must be an absolute, owner-only directory
outside every source and `API/` tree; symbolic-link components and root
identity replacement fail closed.

## Workflow

1. Read the provider's source manifest and formal API documentation.
   Declare the provider's required semantic coverage areas and assign them to
   required sources before capture. Do not use a small operation count as a
   substitute for desktop, H5, account, collection, config, or current-fact
   source coverage.
2. Run `web-api-reverse doctor`.
   If Playwright is missing, run `scripts/install-playwright`. The default
   installation is discovered automatically; set the printed
   `WEB_API_REVERSE_PLAYWRIGHT_ROOT` only for a custom installation.
3. Capture required desktop, H5, authenticated Web, or marketplace surfaces.
   Keep raw output in an explicit private directory.
   When no reviewed marketplace Product reference exists, run
   `inventory-source-candidates` against the private HAR with a Provider-owned
   allowed-host/exact-field policy. Its output is private discovery assistance;
   every candidate must still pass the owning platform's generated Product
   read and `verify-source-product`.
   When a brand provider consumes a separately Published Taobao/JD client,
   export one `SourceProductImportV1` and verify it against a provider-owned
   source policy. Use the default `platformRaw` projection only when the
   platform export carries an explicit garment brand. When the platform omits
   that field, use `sourceProjection: providerMapped` and export through the
   brand Provider after it has failed closed on the exact seller and
   storefront. Never infer garment brand from a shop title in the platform
   package. An identity-only policy may prove
   seller, storefront, Product/SKU identity, and complete-SKU-set semantics,
   but it cannot close `selected-platform-current-facts`. That area requires
   nonempty Product and SKU current-fact requirements which the receipt
   actually satisfies. Do not duplicate the platform operations in the brand
   Provider's OpenAPI.
4. Optionally inventory static route candidates from captured JavaScript
   bundles when a source surface did not exercise every relevant flow.
5. Import sanitized network receipts into `Observed`.
6. Inventory and classify every captured operation at the locked source
   revision.
7. For an authenticated operation, extract its exact private browser request
   from the matching private HAR and sanitized capture receipt. The extractor
   binds the HAR digest, capture source, operation fingerprint, method, and URL
   template before writing a mode-`0600` private replay request outside
   `API/`.
8. Verify safe reads through native replay. Session-lifecycle and
   authenticated-business receipts must retain native request evidence; a
   browser response fixture alone is not promotable. Every non-generated
   replay header must be owned by the reviewed operation policy as either a
   static header or a runtime-managed header, and every declared header must
   appear in the successful replay. A test-only request variant cannot grant
   authority to a narrower Published policy.
9. Verify a write only with an explicit reversible plan and prove restoration.
   For a brand delegating collection writes to a platform Provider, consume
   one private bounded add/delete transcript pair with
   `verify-collection`. Declare the real target grain: product-grain carries no
   SKU and may use a current valid v1, v2, or v3 source-product receipt;
   SKU-grain must resolve to the v2-or-v3 source-product receipt's SKU graph.
10. Review the proposed Trusted projection. Scripts do not make semantic trust
   decisions.
11. Publish only reviewed OpenAPI, policies, capability claim, and approval
   receipt.
12. Run `web-api-reverse validate` before code generation.
    The JSON result includes the canonical `publishLockSHA256`; orchestration
    that invokes a separately built Provider executable must compare that
    value with the executable's compiled Published-lock fingerprint before
    the first network request.
13. Generate Swift only from `API/Published/openapi.yaml`.
14. Implement provider middleware inside the provider package using the
    published operation policies.
15. Add provider-owned runtime-projection tests that mutate each approval input
    class and prove that stale authority exposes no runtime operation policy.

For a platform-backed Provider, use `validate-source-product` whenever an
existing receipt is considered for reuse. This command applies the same
canonical JSON and typed-policy digest semantics as `verify-source-product`,
validates the current platform Published contract, and returns the exact
receipt-byte hash needed by collection evidence. Do not replace this semantic
validation with a raw-file hash in shell code.

Before login or Product access, validate every source policy offline:

```bash
web-api-reverse validate-source-product-policy \
  --policy API/Config/jd-source-product-policy.json \
  --json
```

This calls the same typed `SourceProductVerifier` used by verification, so
invalid projection, identity, fact, SKU, or optional shop constraints fail
before a platform session is inspected.

Read [evidence-workflow.md](references/evidence-workflow.md) for the evidence
states and approval rules. Read
[provider-middleware.md](references/provider-middleware.md) before adding
route/auth/session behavior. Read
[private-state.md](references/private-state.md) before authenticated capture
or native replay. Read
[architecture.md](references/architecture.md) when changing this Skill or CLI.

## Command Sequence

Install the Swift CLI and its resource bundle locally. The default invocation
also installs the pinned private Playwright runtime:

```bash
scripts/install-local
web-api-reverse doctor --json
```

The installer activates one immutable release atomically and then retains the
active release plus two rollback releases by default. Read
[installation.md](references/installation.md) for install layout, retention
configuration, resource safety, rollback behavior, and Playwright ownership.

Create the evidence roots and review inputs:

```bash
web-api-reverse scaffold \
  --provider-root . \
  --provider example-provider \
  --market cn
```

Capture a public Web surface. The private directory must be outside `API/`:

```bash
web-api-reverse capture \
  --url https://example.invalid \
  --private-output /private/example-provider/capture \
  --receipt-output API/Observed/captures/web.json \
  --brand example-provider \
  --market cn \
  --surface web \
  --source-id example-provider-cn-web \
  --source-version replace-with-locked-revision
```

Normal capture records bounded textual response bodies when Playwright can
read them from the response event. Some storefronts make a target body
unavailable through that path even though the request appears in the HAR. For
one exact, side-effect-free GET or HEAD operation, capture may instead forward
the matching request through a Playwright route and embed the returned body in
the private HAR:

```bash
web-api-reverse capture \
  --url https://example.invalid/product/123 \
  --capture-response-url-regex '^https://api\.example\.invalid/product\?id=123$' \
  --private-output /private/example-provider/product \
  --receipt-output API/Observed/captures/product.json \
  --brand example-provider \
  --market cn \
  --surface web \
  --source-id example-provider-cn-web-product \
  --source-version replace-with-locked-revision
```

Use the narrowest reviewed URL regex. This option is limited to `capture`,
intercepts only GET/HEAD, enforces bounded textual bodies, fulfills the
original browser request, and never promotes evidence by itself. It is not an
authentication mechanism, mutation probe, normal transport, or browser
fallback. If no response body can be proven, the importer records the outcome
as unknown rather than treating HTTP 200 as business success.

For a discovery-only replay that must preserve a session cookie or
`sessionStorage` value in the same browser lifecycle, pass a private scoped
seed to `capture`. This mode uses an ephemeral browser context, forbids
`--profile`, and never writes the user's persistent browser profile:

```bash
web-api-reverse capture \
  --url https://example.invalid/account \
  --session-seed /private/example-provider/session-seed.json \
  --session-domain example.invalid \
  --private-output /private/example-provider/replay \
  --receipt-output API/Observed/captures/account-replay.json \
  --brand example-provider \
  --market cn \
  --surface web \
  --source-id example-provider-cn-account \
  --source-version replace-with-locked-revision
```

This is browser-assisted evidence capture, not a runtime transport or a way to
declare a Provider connected. Native validation and the normal Trusted/
Published gates remain mandatory.

When the private HAR embeds JavaScript response bodies, inventory bounded
static route candidates before deciding which flows require another capture:

```bash
web-api-reverse inventory-bundles \
  --har /private/example-provider/capture/capture.har \
  --output API/Observed/bundle-routes/web.json \
  --brand example-provider \
  --market cn \
  --surface web \
  --source-id example-provider-cn-web \
  --source-version replace-with-locked-revision
```

This receipt is discovery assistance only. It preserves bundle hashes,
sanitized route literals, query names, and template placeholders. It does not
claim an HTTP method, authentication policy, request or response schema,
operation identity, safety, business success, source coverage, or trust.
Exercise candidates through browser capture and native verification before
adding them to the operation catalog or any Trusted/Published contract.

When a platform-store capture is expected to contain Product identifiers,
inventory only reviewed structured fields:

```bash
web-api-reverse inventory-source-candidates \
  --har /private/example-provider/store/capture.har \
  --policy API/Config/source-candidate-inventory-policy.json \
  --output /private/example-provider/store/candidates.json \
  --json
```

The command scans exact query, form, JSON, and JSONP keys on allowed hosts. It
does not regex arbitrary text, make a request, validate seller identity, or
promote evidence. The deterministic output is mode `0600` and must stay outside
`API/`. Zero candidates is a valid result. A candidate ID is only an input to
the owning platform Product client.

For a login flow, use `auth bootstrap` with a user-controlled persistent
profile. In manual mode, press Return only after the browser has reached the
authenticated state; noninteractive EOF fails closed. The command reports a private `session-seed.json` path without printing
its values. Use a Playwright device name when the H5 flow depends on browser
emulation. An optional completion URL regex is checked after explicit
confirmation in manual mode; it does not replace that confirmation:

When a Provider already owns a private session seed, pass it back through
`--session-seed` with the same provider domains. Bootstrap injects the seed
into that one browser lifecycle before navigation, then captures the refreshed
state. This is the reliable path for session Cookies: it does not assume that
Chromium will persist a Cookie whose expiry is session-scoped after the browser
closes. The seed remains private, the persistent profile is not replaced, and
the generated native account operation remains the login authority.

Do not ask the user to log in through a browser connector, a generic browser
control task, or a separately opened Chrome for Testing window. Those sessions
may use a temporary or unrelated `user-data-dir`, and closing the task can
discard the only authenticated state. Operational login must be started by the
owning Provider's explicit login command, which supplies its resolved
persistent `--profile`, consumes the resulting private checkpoint immediately,
validates it with the generated native account client, and commits it before
the command exits. `auth inspect` and `auth profile-session` are read-only
audits and must not be repurposed as login windows.

```bash
web-api-reverse auth bootstrap \
  --url https://example.invalid/login \
  --device "iPhone 15 Pro Max" \
  --profile /private/example-provider/browser-profile \
  --session-profile-label default \
  --private-output /private/example-provider/auth \
  --session-domain example.invalid \
  --receipt-output API/Observed/captures/auth.json \
  --brand example-provider \
  --market cn \
  --surface web \
  --source-id example-provider-cn-auth \
  --source-version replace-with-locked-revision \
  --auth-completion-url-regex '/account|/member' \
  --auth-require-cookie session \
  --auto-complete-on-auth-requirements \
  --auth-revisit-entry-on-session-change \
  --auth-require-response-url-regex '/api/account' \
  --auth-require-response-body-regex '"authenticated":true' \
  --settle-ms 3000 \
  --auth-timeout-ms 120000
```

`auth profile-session` audits one exact, existing physical browser profile
across several surfaces. It copies the durable profile into a machine-private
disposable snapshot, opens each supplied URL headlessly once, and compares that
snapshot before and after restart. It never creates a replacement profile,
opens, closes, or mutates the source profile, prompts for login, or acts as an
account bootstrap. Session cookies and
`sessionStorage` may already be absent from the durable snapshot. A general
Chrome for Testing window is also not authoritative because its live state may
be ephemeral, unflushed, or belong to another profile. A missing or mistyped
profile path fails closed instead of silently creating an empty browser
identity.
The source profile must also be quiescent. A Chromium `SingletonLock` whose
recorded process is still alive fails as `sourceInUse`; it is not interpreted
as missing authentication and must never trigger another login window. A stale
singleton symlink left by a process that no longer exists is ignored, and
transient lock entries are removed only from the disposable snapshot.

```bash
web-api-reverse auth profile-session \
  --profile /private/lifewear/browser-profiles/official-cn \
  --profile-label official-cn \
  --url https://example-one.invalid/account \
  --url https://example-two.invalid/login \
  --json
```

The result reports only aggregate counts, whether session-scoped material was
detected, and whether cookies were lost at restart. It always reports
`providerSessionValidated: false`. When
`requiresProviderHandoffBeforeClose` is true, do not treat the result as a
retained login and do not turn this audit into a batch login flow. Use the Provider's explicit
atomic login transaction so capture, generated native account validation, and
secure native-session commit complete before the browser closes.

`auth bootstrap` retains the latest exact scoped snapshot that satisfies its
declared authentication requirements throughout the interactive flow. That
qualifying snapshot must flow to Provider-native validation; a later weaker
checkpoint or browser read must not replace it because session-scoped material
can change or disappear before browser close.

When a storefront commits or rotates Cookie/storage state after its first
successful account response, pass a reviewed `--settle-ms` interval. For auth
bootstrap this interval runs after all completion gates pass, inside the same
browser lifecycle, and the worker takes a fresh qualifying snapshot before it
closes. It is a persistence-stability guard, not a replacement for the
authenticated-response gate or generated native validation.

Provider login commands with sufficient declared Cookie/Web Storage
requirements should add `--auto-complete-on-auth-requirements`. The user then
only completes the website login; the Swift CLI does not wait for terminal
input, and capture closes automatically as soon as every declared session,
URL, and authenticated-response requirement is satisfied. The flag is invalid
without at least one scoped session requirement. Generated native account
validation and atomic secure-session commit are still mandatory after capture.

Some providers leave the user on a generic landing page after login and do not
exercise the authenticated business operation until the account entry is
opened again. In that reviewed case, the Provider may also add
`--auth-revisit-entry-on-session-change`. The worker fingerprints only the
declared, scoped Cookie/Web Storage requirements, waits for them to become
complete and differ from their post-entry baseline, and then revisits the entry
URL exactly once in the same browser context. Pre-existing complete material,
analytics Cookie churn, and URL matching alone cannot trigger the revisit. The
flag requires automatic completion and an authenticated-response requirement;
the response gate and generated native account validation remain the success
authority. Do not use this as a navigation loop or a browser business fallback.

If the required session fingerprint may remain unchanged, use the paired
`--auth-revisit-trigger-response-url-regex` and
`--auth-revisit-trigger-response-body-regex` options instead. Their reviewed
intermediate 2xx response triggers one entry revisit but never satisfies the
separate final `--auth-require-response-*` gate. The two revisit strategies are
mutually exclusive.

For normal CLI/App login bootstrap, use `--session-only`. This operational mode
keeps the raw capture, HAR, and provider-neutral seed under the private output
root and deliberately does not write an Observed receipt:

```bash
web-api-reverse auth bootstrap \
  --url https://example.invalid/account \
  --profile /private/example-provider/browser-profile \
  --session-profile-label default \
  --private-output /private/example-provider/auth \
  --brand example-provider \
  --market cn \
  --session-domain example.invalid \
  --auth-completion-url-regex '/account|/member' \
  --auth-require-cookie session \
  --session-only \
  --json
```

Completion URL matching is only a navigation check. When the provider knows
the browser material that proves login, pass repeatable
`--auth-require-cookie`, `--auth-require-local-storage`, or
`--auth-require-session-storage` names. The worker waits for nonempty,
non-placeholder values under the declared session domains before capturing
and closing the browser. The provider package owns these names and must still
perform a generated native account read before importing or reporting the
session as connected.

When the authenticated page has a stable business read, pair
`--auth-require-response-url-regex` with
`--auth-require-response-body-regex`. The worker observes only a bounded,
successful response body matching both patterns and keeps the bootstrap open
when the page shell or Cookie names appear before the account operation
succeeds. After explicit user confirmation, the worker revisits the requested
entry URL once in the same persistent browser context when no matching response
has been observed yet. This makes the newly issued session perform the
authoritative read without restarting login or replacing the profile. These
patterns are provider-owned runtime facts and still do not replace generated
native validation.

Bootstrap checkpoints private Cookie and Web Storage state atomically while
these gates remain open. If a completion rule, required field, or business
response later times out, the command still writes a provider-domain-scoped
private `session-seed.json` and reports its path in the failure. Reuse that
checkpoint for diagnosis or secure provider import; do not ask the user to
repeat login merely because a response regex or API assumption was wrong. The
failed gate remains failed and produces no Trusted or Published claim.

After importing the checkpoint HAR and inventorying its operation, derive the
one-shot native replay request from the exact matching private HAR. This is not
code generation and does not expose credentials:

```bash
web-api-reverse extract-request \
  --har /private/example-provider/auth/capture.har \
  --capture-receipt API/Observed/captures/auth.json \
  --catalog API/Observed/catalog.json \
  --operation-id getAuthenticatedAccount \
  --output /private/example-provider/auth/account-request.json \
  --json
```

The command rejects a different HAR, an unrelated capture receipt, or an
operation not sourced by that receipt. When the browser issued the same
operation more than once, the latest matching request is selected so rotating
session material is not replaced by an earlier request. The private request is
for immediate native replay and provider-owned session derivation only; it
must never enter Config, Observed, Trusted, Published, fixtures, or logs.

When the user has already logged in, inspect the existing persistent profile
without reopening the login flow. `auth inspect` is noninteractive, never
clears or replaces the profile, and never navigates the writable profile
directly. It creates a disposable private snapshot, lets browser responses
mutate only that snapshot, and removes the snapshot on success or failure.
The inspector uses the full Playwright Chrome for Testing binary rather than
the headless shell and restores session Cookies only in that disposable
snapshot. This preserves profiles whose authenticated material is not a
persistent Cookie while keeping the original profile untouched.
If the snapshot contains provider-scoped Cookie or Web Storage state but the
declared business-response gate does not fire, inspection still writes the
private seed/HAR/capture checkpoint before returning the failed gate. The
provider may decode and validate that checkpoint natively; the failure does
not authorize a Trusted claim or a connected account.
This matters because even a GET can receive a `Set-Cookie` deletion and is not
read-only when executed in a persistent browser context. Inspection writes no
Observed receipt and requires explicit provider domains so a shared browser
profile cannot leak another provider's cookies or Web storage into the
exported seed. Inspection is headless by default so an expired provider
session cannot surface an unexpected login window. Use `--headed` only during
an explicit, user-authorized diagnostic; automated account audits must not use
it. When an account page can render a logged-in shell from stale cookies,
inspection must use the same paired
`--auth-require-response-url-regex` and
`--auth-require-response-body-regex` facts as bootstrap. It then fails closed
unless the snapshot produces that provider-owned authenticated business
response:

```bash
web-api-reverse auth inspect \
  --url https://example.invalid/account \
  --profile /private/shared-browser-profile \
  --session-profile-label default \
  --private-output /private/example-provider/auth \
  --brand example-provider \
  --market cn \
  --session-domain example.invalid \
  --auth-require-cookie session \
  --auth-require-response-url-regex '/api/account' \
  --auth-require-response-body-regex '"authenticated":true' \
  --reject-url-regex '/login(?:[/?#]|$)' \
  --json
```

When the provider knows its required browser session fields, inspection must
declare the same `--auth-require-*` names as bootstrap. Inspection checks them
once after the requested settle period and fails without opening a login flow
when any usable value is absent.

When headless navigation can itself trigger risk routing, use
`auth inspect --candidate-only`. This mode launches only a disposable profile
snapshot, captures its first provider-scoped Cookie/Web Storage snapshot, and
does not create or navigate a new page. It requires at least one exact
`--auth-require-*` field and is incompatible with URL rejection, authenticated
response, and headed gates. Success means only that a structurally usable
candidate seed exists. The provider must immediately validate that candidate
through its Published generated account operation and commit it atomically;
candidate extraction never establishes login by itself:

```bash
web-api-reverse auth inspect \
  --url https://example.invalid/account \
  --profile /private/shared-browser-profile \
  --session-profile-label default \
  --private-output /private/example-provider/auth \
  --brand example-provider \
  --market cn \
  --session-domain example.invalid \
  --auth-require-cookie session \
  --candidate-only \
  --json
```

After inspection, the provider adapter must still validate the seed with a
generated native account read. A failed native read does not clear the browser
profile or existing secure session. Only an explicit server authentication
failure may transition the provider to `requiresLogin`.

Use `auth restore` only to recover a previously exported private seed into a
closed persistent profile. The command requires explicit provider domains,
rejects any seed state outside that scope, rejects tab-scoped sessionStorage,
and never writes Observed evidence. It copies the profile to sibling staging,
injects Cookie and localStorage state there, closes and reopens the browser
with the operating-system Keychain policy, verifies the restored values, and
atomically swaps the staging profile into place. Failure leaves the original
profile untouched. Output contains only counts and a deterministic seed digest:

```bash
web-api-reverse auth restore \
  --session-seed /private/example-provider/session-seed.json \
  --profile /private/shared-browser-profile \
  --session-domain example.invalid \
  --json
```

The profile must not be open in any browser. Restore is recovery tooling, not
a login bypass, refresh mechanism, or normal business transport. The provider
must still execute its generated native account validation after restoration.

`--reject-url-regex` applies to the inspection page, popups opened by the
current flow, and every frame in those pages. Tabs that already existed when
the persistent context opened are excluded so an unrelated stale login tab
cannot invalidate the requested account surface. A storefront that keeps its
account URL while embedding a login frame is treated as requiring login and
cannot emit a successful session seed.

The provider's browser-session adapter validates and normalizes that generic
seed, derives any provider-specific private runtime values from the private
HAR, imports the result into provider-owned secure storage, and validates it
with a generated native business read. It must not promote the operational
login capture into reusable evidence.

Build the source-locked inventory after reviewing Config:

```bash
web-api-reverse inventory \
  --observed-dir API/Observed \
  --receipt API/Observed/captures/web.json \
  --annotations API/Config/operation-annotations.json \
  --source-manifest API/Config/source-manifest.json
```

For a platform-backed brand source, keep the source export outside `API/`,
validate the platform's exact Published contract plus the provider's
brand/seller/storefront allowlists, and write only the sanitized verification
receipt to Observed. A `platformRaw` policy consumes the platform CLI export:

```bash
jd product export 10000000000000 \
  --output /private/example-provider/jd-source-product.json

web-api-reverse verify-source-product \
  --source-product /private/example-provider/jd-source-product.json \
  --policy API/Config/jd-source-product-policy.json \
  --platform-provider-root /workspace/jd-cli \
  --output API/Observed/source-verifications/jd-product.json

web-api-reverse inventory \
  --observed-dir API/Observed \
  --annotations API/Config/operation-annotations.json \
  --source-manifest API/Config/source-manifest.json
```

The policy must identify the Provider source revision, platform provider,
commerce platform, optional `sourceProjection`, accepted garment-brand aliases,
seller IDs, storefronts, and optional exact shop IDs,
required product/SKU current facts, minimum SKU count, and whether the source
must claim a complete SKU set. The v2 receipt binds the source product digest,
complete SKU identity graph, policy digest, and platform `publish-lock.json`
digest. When `acceptedShopIDs` is present and nonempty, the Product export must
contain exactly one `shopId` Product alias in that allowlist and verification
emits a v3 receipt that binds the exact shop ID into its evidence fingerprint.
Omitting `acceptedShopIDs` preserves the v2 contract. Enabling or changing the
allowlist changes the policy digest and therefore requires fresh verification,
review, approval, and publication; do not relabel an existing receipt. A wrong identity,
missing fact, incomplete required SKU set, or platform Published drift fails
closed. The source lock records an external evidence fingerprint rather than
pretending the brand Provider observed or owns the platform API operation.

Use `sourceProjection: providerMapped` only when the brand package owns the
export and has already validated the exact seller and storefront through the
separately Published platform client. The exported `sourceTool` must equal the
brand Provider slug. `providerID.brand` remains the nonblank domain BrandID and
may differ from that command/package slug; its market and optional storefront
must still be internally consistent. `commercePlatform` and
`platformProvider` continue to identify the platform contract. Omitting
`sourceProjection` preserves the legacy `platformRaw` behavior, where
`sourceTool` and `providerID.brand` remain equal. Both modes bind the same
platform Published lock; neither permits a shop-name brand guess.

For a platform-backed remote collection, run the brand CLI add and delete once,
redirect each deterministic JSON envelope to a private file outside `API/`,
then create one sanitized qualification receipt:

```bash
web-api-reverse verify-collection \
  --provider-root . \
  --provider example-provider \
  --market cn \
  --source-product-receipt API/Observed/source-verifications/jd-product.json \
  --platform-provider-root /workspace/jd-cli \
  --add-transcript /private/example-provider/favorite-add.json \
  --delete-transcript /private/example-provider/favorite-delete.json \
  --output API/Observed/collection-verifications/jd-favorite.json \
  --verified-at 2026-08-06T00:00:00Z \
  --allow-remote-write
```

The transcript contract identifies provider, market, platform Provider,
product, explicit `targetGrain`, optional SKU, action,
`platform-confirmed-change`, and resulting remote state. Use
`targetGrain: product` with no `skuExternalID` for product-level collections
such as Taobao/Tmall Favorite. Use `targetGrain: sku` only when the platform
operation truly targets a SKU, and require that SKU in the v2-or-v3 source
receipt.
Product-grain qualification accepts a current valid v1 receipt because it
needs only the receipt-bound product, identity/current-fact proof, complete-SKU
claim/count, and platform lock; it does not need individual SKU IDs.
Add and delete must use the same grain and exact target. An already-present
add, failed/no-change delete, or final state other than absent is not
qualification evidence. JSON whitespace and key order may differ across
Provider CLIs: verification accepts only the exact semantic field set, then
canonicalizes the decoded envelopes before hashing them. The command namespace
must be exactly `<provider>.wishlist.add` and `<provider>.wishlist.delete`.

Replay one safe Observed operation. Use either a private request specification
or a reconstructable unauthenticated capture receipt:

```bash
web-api-reverse verify \
  --catalog API/Observed/catalog.json \
  --operation-id product.currentFacts \
  --capture-receipt API/Observed/captures/web.json \
  --receipt-output API/Observed/verifications/product-current-facts.json \
  --request-evidence-output API/Observed/request-evidence/product-current-facts.json
```

For authenticated or non-reconstructable operations, keep the concrete
request specification and session seed outside `API/`. If the operation was
not present in a browser HAR, first use `capture-request` to create sanitized
Observed source evidence, then rebuild inventory and verify the resulting
Observed operation.

Verify a remote mutation only through one explicit five-step restoration
plan. The plan is private because it contains executable request material:

```bash
web-api-reverse verify-reversible \
  --catalog API/Observed/catalog.json \
  --plan /private/example-provider/wishlist-verification-plan.json \
  --session-seed /private/example-provider/session-seed.json \
  --output-dir API/Observed/verifications \
  --allow-remote-write
```

After explicit semantic review, project and publish:

```bash
web-api-reverse trust \
  --observed-dir API/Observed \
  --trusted-dir API/Trusted \
  --manifest API/Config/trust-manifest.json \
  --verification API/Observed/verifications/product-current-facts.json \
  --verification API/Observed/verifications/rev_<sequence>/add.json \
  --verification API/Observed/verifications/rev_<sequence>/remove.json

web-api-reverse approve \
  --provider-root . \
  --provider example-provider \
  --market cn \
  --reviewer local-review \
  --zero-unknown

web-api-reverse publish \
  --provider-root . \
  --provider example-provider \
  --market cn

web-api-reverse validate --provider-root .
```

## Hard Gates

- Discovery may update Observed only.
- Trusted requires reviewed evidence and explicit operation policy.
- Published requires all five files, deterministic hashes, no raw secrets, and
  an approval receipt covering the exact Trusted inputs.
- A mutation cannot be published unless restoration is proven.
- Reciprocal restoration receipts normally belong to distinct add and remove
  operations. Inventory validates each receipt against its own operation and
  resolves its reciprocal proof from the complete current receipt set.
- A session lifecycle operation cannot inherit an authenticated-business auth
  policy by convention; its request and refresh semantics require direct
  evidence.
- Every session-lifecycle and authenticated-business receipt cited by Trusted
  must include native request evidence. When provider policy declares static
  query or header facts, verification checks the actual request and binds a
  deterministic request-variant digest. A browser-only receipt or another
  appKey/callback/header variant cannot authorize the reviewed operation.
- Authenticated response values may inform schema projection in memory, but
  must never be written as Trusted fixtures or OpenAPI examples. Exercise the
  generated DTO shape with synthetic test values instead of copied account
  data. For authenticated-business and session-lifecycle safe reads, Trust
  accepts a reviewed response schema without a fixture only when the receipt
  includes native request evidence and a nonempty fixture-omission reason;
  anonymous operations retain the normal fixture requirement.
- HTTP success is not business success. A JSON risk-disposal envelope with a
  non-success `code` plus `disposal` or `echo` is imported as
  `business-error`, even when it has no message and the HTTP status is 2xx.
  Syntactically valid JSONP is unwrapped for the same assessment; a non-success
  `ret` array or nonempty/nonzero `bxpunish` response header is also a
  `business-error`. Such a receipt cannot satisfy Trusted verification or
  Published approval. A successful browser request still requires the
  declared native replay class before it can authorize generated runtime use.
- A Published `authPolicy: none` operation requires its accepted current
  receipt set to contain embedded request evidence proving the exact operation
  URL was called without Cookie or authentication headers. A separate receipt
  may own the reviewed response fixture; a successful anonymous request-proof
  receipt may omit its duplicate fixture only with a nonempty omission reason.
  Every cited receipt remains bound to the exact operation and successful
  evidence contract. A Cookie-bearing
  browser capture cannot be relabeled anonymous; it needs a separate
  successful no-Cookie replay or an authenticated policy.
- Unknown operations block a zero-unknown coverage claim.
- Missing, unassigned, or uncaptured required coverage areas block inventory,
  approval, and Published validation. A legacy source lock without explicit
  semantic areas fails closed.
- A captured exchange with an exact reviewed operation annotation enters
  Observed even when the default API-shape heuristic would exclude it, such as
  a redirected HTML product document. The source lock derives its operation
  fingerprints from the resulting catalog references, not from a second
  candidate heuristic.
- A required source with zero observed operation fingerprints is incomplete.
  Browser capture existence alone does not turn a login redirect, risk page,
  or empty shell into API evidence.
- Published operations must still resolve to successful current receipts under
  `Observed/verifications/`; approval metadata and verification IDs already
  embedded in `catalog.json` are not standalone proof. The legacy singular
  `Observed/verification/` directory is rejected with migration guidance.
- Verification receipt IDs are globally unique within the canonical Observed
  receipt tree. Duplicate IDs fail contract validation instead of being
  selected by file order.
- Published `selected-platform-current-facts` or
  `selected-platform-identity` coverage requires a sanitized source-product
  receipt under `Observed/source-verifications/`, its evidence fingerprint in
  the current approval-bound source lock, and an exact match to the current
  source-product policy and receipt-bound platform Published lock. `approve`
  hashes every required canonical receipt path into `approval-receipt.json`;
  publication and canonical validation require the exact path/hash set. The
  existing `publish-lock.json` covers that durable authority by hashing the
  approval receipt; no sixth Published file is added.
- A platform-backed supported zero-operation `remote-collection` capability
  requires exactly one canonical receipt under
  `Observed/collection-verifications/`. It binds the current source-product
  receipt hash, its platform Published-lock digest, exact product and target
  grain, optional exact SKU, private add/delete transcript hashes, and
  absent-to-present-to-absent restoration. Product-grain receipts must not
  carry a SKU and may bind a current valid v1, v2, or v3 source-product
  receipt; SKU-grain receipts must match the v2-or-v3 source SKU graph. No other supported
  capability may have an empty operation set, and all operation-ID equality
  gates remain active.
- `approve --zero-unknown` is an explicit reviewer assertion, not authority by
  itself. Approval recomputes operation and source-area coverage from
  Observed, requires each Trusted verification ID to remain proven by the
  matching current Observed operation, and embeds the complete area proof.
- Published output is byte-deterministic for identical approved inputs. When
  `--published-at` is absent, publication uses the approved authority's
  `approval-receipt.approvedAt`, never the wall clock. Explicit
  `approve --approved-at` and `publish --published-at` values are preserved as
  deterministic historical audit/recovery inputs. They do not bypass
  coverage, verification, approval-input hashing, or exact-five validation.
- Classified-only cart, order, payment, address, or similarly risky operations
  do not enter normal generated clients.
- Provider code must not hand-build URLs, auth headers, or mutation payloads
  outside its generated-client/runtime boundary.
- Generated OpenAPI `path` is the stable client path. Middleware must use the
  same operation's Published `wirePath` for the upstream path and must not
  infer one from the other.
- `encodedQueryBodyNames` and `encodedBodyFieldNames` are reviewed wire
  transforms. Middleware applies only the names present in Published policy;
  it never guesses conventional names such as `data` or `body`.
- `responseContentTypeAliases` is the only authority for accepting an
  upstream JSON-compatible media type under a generated JSON response.
- Reviewed OpenAPI path aliases may rename path parameters, but they must keep
  the exact Observed static route shape after removal of a reviewed fixed base
  path.

## Browser Boundary

Playwright performs browser capture, login guidance, and session-seed
extraction. The worker emits private raw browser state; Swift converts it into
the package-owned private session schema. Evidence capture emits only
sanitized Observed receipts; `--session-only` emits no durable receipt. Normal
reads and writes use the generated Swift client.

Persistent browser profiles are user-controlled. Do not log out, delete,
replace, or copy a profile without explicit user direction.

Stable snapshot capture refuses a profile owned by a live Chromium process with the
structured `browser.profile.in_use` code. Treat that result as a deferred
handoff: ask the user to close the browser normally, then retry the same
noninteractive capture. It is not evidence of logout and must never start a
new login flow. A dead process's stale singleton lock is not an active lock and
does not justify another login.

One logical session profile must resolve to one stable physical profile path.
Do not silently fall back to another Chrome profile or create a fresh path when
the declared profile is unavailable. Browser login state, a validated native
session, and native-session renewability are separate facts; API, signature,
risk, and handoff failures must not be reported as browser logout.

The worker captures cookies plus local/session storage from every open
HTTP(S) page and frame, merges the material deterministically by origin, and
writes it only to private files. Unknown devices, invalid completion regexes,
invalid timeouts, and inaccessible HTTP(S) frame storage fail closed.

Browser HARs may also contain `blob:`, `data:`, extension, and other
browser-internal resources. Evidence import excludes every non-HTTP(S) request
before include-pattern matching and URL normalization; those resources are
neither API operations nor source-entry candidates.

## Validation

From this skill directory:

```bash
swift test --enable-swift-testing
swift run web-api-reverse doctor --json
python3 ../skill-creator/scripts/validate_skill_package.py .
```

Before publishing a provider:

```bash
web-api-reverse scan-artifacts --root API --json
web-api-reverse validate --provider-root . --json
```

`sanitize-artifacts --root API` is an explicit migration tool for historical
JSON artifacts containing account identity values. Run it only when
`scan-artifacts` reports structured personal identity, then review the diff and
rerun the scanner. It does not remove credentials, repair invalid evidence, or
make a receipt Trusted.

The provider's own generated-client, fixture, middleware, and live reversible
tests remain mandatory. This Skill does not replace provider tests.
