# Architecture

## Ownership

`WebAPIReverseCore` owns deterministic evidence models, redaction, artifact
validation, coverage, promotion inputs, Published projection, and lock
verification.

The Published OpenAPI projection may normalize evidence-only empty or
null-only schemas into deterministic OpenAPI 3.1 codegen shapes. Trusted keeps
the reviewed response evidence unchanged; the projected bytes are included in
the Published lock and remain the sole codegen authority.

It also owns deterministic private source-candidate inventory. The inventory
accepts one private HAR plus a Provider-owned allowed-host/exact-field policy,
records only public Product identifiers and structural provenance, and writes
mode-`0600` output outside `API/`. It is candidate discovery, not Observed,
Trusted, Published, seller identity, Product facts, or a normal transport.

`WebAPIReverseCLI` owns the command and JSON/error contract. It is a thin
adapter over core operations.

The skill-local installer owns immutable CLI releases, atomic `current` and
command symlink replacement, resource-bundle validation, and bounded release
retention. It rejects symbolic-link resource inputs before publication and
restores both public pointers if either activation replacement fails. It
collects expired releases only after activation succeeds, and collection
failure is warning-only. The active release and configured rollback set are
always retained. Playwright remains a separate private runtime owned by
`install-playwright`; CLI release collection never reads, moves, or removes
that runtime.

The Playwright worker owns browser interaction only. It writes raw capture to
a tool-created owner-only scratch directory and returns structured results to
Swift. Swift then copies only the bounded canonical `capture.json` and
`capture.har` files into the explicit private output root through
descriptor-relative reads and atomic writes. The private root is bound by
device and inode, every open rejects symbolic links, and source/API ancestry
or root replacement fails closed. The worker never receives the caller's
private-output pathname. Swift continuously drains the worker's bounded JSON
control response before waiting for process exit. Oversized control output
terminates the worker and fails closed; probes that do not consume output send
it to the null device. Large capture and HAR bytes remain file-backed under the
descriptor-anchored private store and never traverse the process control pipe.
`WebAPIReverseCore` converts that raw browser state into the private session
schema; Node does not own a durable evidence or session contract.
The worker also owns its browser-process lifetime. The Swift CLI passes its
own parent command as the default owner while preserving an explicit caller-
supplied owner, and the Node worker monitors both that owner and its direct
Swift parent. It closes the active Playwright context before exiting when
either disappears. This
prevents an interrupted Provider login command from leaving a browser process
holding the persistent profile lock; it never deletes or resets that profile.

Device emulation, login-completion matching, provider domain scope, and
provider-declared session-material presence checks are browser inputs, not API
facts. Manual mode requires explicit user confirmation; a Provider may instead
select automatic completion only when it has declared sufficient scoped
session, URL, and authenticated-response gates. Persistent profiles are
opened in place only for explicit login bootstrap. Every persistent context
uses the operating system Keychain and ignores Playwright's
`--use-mock-keychain` default; cross-process Cookie restoration is a profile
invariant, not a provider heuristic. Noninteractive inspection opens a
disposable private snapshot and removes it afterward, so response Cookie writes
never reach the persistent profile. Provider-owned decoding and native account
validation remain authoritative after capture.

`auth profile-session` is a durable-profile audit, not an account handoff. It
requires one existing declared persistent profile and copies it into a
machine-private disposable snapshot, visits each supplied URL headlessly once,
compares aggregate state before and after restarting that snapshot, and reports
session-scoped material
and cookie loss without exposing values. It never opens, closes, or mutates the
source profile, prompts for login, or validates accounts. The source must be
quiescent; an active browser lock is an inspection error, not evidence of a
missing login and not permission to open another login window. A Provider whose
login uses session cookies or
`sessionStorage` must capture, validate through a generated native business
read, and commit native session storage before the browser closes.

The auth worker retains the latest exact snapshot that satisfied the declared
Cookie and Web Storage requirements throughout bootstrap, then persists that
snapshot after the URL and authenticated-response gates pass. A later weaker
checkpoint or browser-state read between qualification and Provider-native
validation is forbidden because it can replace valid session material with an
incomplete snapshot.

A bootstrap may inject a provider-scoped private seed into the opened context
before navigation. This supports repeatable browser-assisted work when the
authoritative Cookie is session-scoped and therefore cannot be expected to
survive browser shutdown. The private seed is durable provider state; the
browser context is disposable execution state. Injection never substitutes for
the generated native account validation that commits or rejects the session.

`--auto-complete-on-auth-requirements` removes the separate terminal-confirm
step for Provider flows whose scoped session requirements are sufficient. The
CLI waits for all declared session, completion-URL, and authenticated-response
gates without reading terminal input. It does not weaken the Provider-native
validation gate: the browser only captures the seed, while the generated client
proves the business session before any native store is committed.
When a reviewed Provider flow returns from login to a generic landing page,
`--auth-revisit-entry-on-session-change` may trigger one same-context revisit
of the declared entry URL. The trigger is a complete, changed fingerprint of
only the required scoped Cookie/Web Storage values; pre-existing material and
unrelated state cannot trigger it. This capability requires automatic
completion plus an authenticated-response gate. It does not loop, infer login,
or replace the generated native account read.
When the required session material can remain byte-for-byte unchanged across
login, the Provider may instead declare paired
`--auth-revisit-trigger-response-*` regexes. A matching bounded 2xx
intermediate response triggers exactly one same-context entry revisit; it does
not satisfy the separate final authenticated-response gate. The two revisit
strategies are mutually exclusive, and a final response observed before the
intermediate trigger completes without an unnecessary revisit.
When the Provider passes `--settle-ms`, auth bootstrap waits that bounded
interval after the gates pass and takes a new scoped checkpoint before closing.
This handles storefronts that commit the final replayable session material just
after their first successful account response.
Manual mode fails closed when interactive terminal input is unavailable; EOF is
never converted into a synthetic confirmation.

Authentication snapshots never enumerate the complete shared profile. They
filter Cookie state by provider-declared domains and read only declared Web
Storage keys from matching origins, allowing several providers to share one
physical profile without coupling their capture size or private state. The
same domain scope filters authenticated HAR and exchange capture; undeclared
tabs and hosts are not merely redacted later, they are never admitted to the
Provider checkpoint.

Provider packages own generated API targets and provider-specific runtime
middleware. They do not import this Swift package or inherit a governance
plugin. A macOS browser-session adapter may invoke the installed
`web-api-reverse` executable for user-controlled login bootstrap; normal
business requests never do.

Provider packages also own their Published runtime projection executable and
build plugin. `web-api-reverse` defines the invariant but is not linked into
runtime and does not supply a shared plugin. The provider projection must:

1. require exactly the five canonical files in `API/Published`;
2. verify the lock over the other four Published files;
3. require the six canonical approval inputs and compare every recorded hash
   with the current provider-root file;
4. admit additional approval inputs only as canonical, single-file
   `API/Observed/source-verifications/*.json` or
   `API/Observed/collection-verifications/*.json` receipts with matching
   provider and market scope; and
5. project no usable operation policy when any file is missing, stale,
   symlinked, unsafe, noncanonical, or unrecognized.

The provider build plugin always declares the Published five and canonical
approval six. It may parse the approval receipt only to add safe dynamic
source- and collection-verification paths. It must never declare an absolute
path, traversal, nested receipt path, or another approval-input family. Plugin
input discovery only controls incremental rebuilds; the projection
independently repeats all authority checks.

## Data Flow

```text
browser or HAR
  -> private raw capture
  -> optional sanitized static bundle-route candidates
  -> sanitized capture receipt
  -> Observed catalog and semantic source lock
  -> operation coverage + required source-area coverage
  -> reviewed Trusted OpenAPI and operation policies
  -> approved Published five-file projection
  -> generated Swift API
  -> provider-owned runtime middleware
```

The optional bundle branch is discovery-only. It reads successful embedded
JavaScript bodies from the private HAR, emits a distinct candidate receipt,
and never feeds operation inventory, source coverage, trust, publication, or
codegen directly. Its purpose is to make unexercised route families visible
so a maintainer can capture and verify them deliberately.

A brand Provider that delegates product facts to a platform client uses a
parallel evidence adapter:

```text
Taobao/JD generated client
  -> platform-raw export, or exact seller/store validation in brand Provider
  -> private SourceProductImportV1 export
  -> provider identity/current-fact policy
  + exact platform Published lock
  -> sanitized source-product verification receipt
  -> brand Provider semantic source lock
```

The adapter governs source coverage only. It does not copy platform
operations into the brand Provider's Observed, Trusted, Published, generated
client, or middleware.

The source policy makes the projection explicit. `platformRaw` requires the
platform package to own `sourceTool` and to expose the garment brand directly.
`providerMapped` requires the brand package to own `sourceTool` after exact
seller/store validation; the policy still binds the independent platform
Provider and its Published lock. This prevents platform runtimes from guessing
a garment brand from a shop title while allowing brand-owned identity
projection when the Product API omits a brand field.

Receipt reuse is also owned by this evidence layer. Callers use
`validate-source-product` to re-open the typed Provider policy, current platform
Published contract, and sanitized receipt. The command returns canonical
platform-lock and policy digests plus the exact receipt-byte hash. Shell code
must not infer freshness from raw file hashes because those bytes do not define
the verifier's canonical semantic digest.

A successfully verified source-product receipt upgrades its exact declared
source revision from `missing` or `partial` to `captured` in the generated
source lock. The manifest status describes the state before verification; it
must not keep verified identity, SKU, and current-fact evidence incomplete.
Approval accepts the `partial` to `captured` transition only for a declared
selected-platform semantic source with a bound evidence fingerprint. It then
revalidates the current source-product policy and exact platform Published
lock and hashes the canonical receipt into the approval. A bare status edit or
an unbound fingerprint cannot authorize the transition.

When the manifest still says `missing`, the project-owned reviewed-publication
transaction must first promote that exact source to `partial`. The promotion,
capability claim, approval receipt, and exact-five Published replacement are
one rollback domain. Discovery and qualification continue to write Observed
only; they cannot make this reviewer-owned lifecycle decision.

The same source receipt can authorize one bounded platform collection
qualification without importing platform operations:

```text
brand CLI private add transcript + private delete transcript
  + current source-product receipt valid for the declared target grain
  + exact platform Published lock
  -> sanitized collection-verification receipt
  -> supported zero-operation remote-collection capability
```

The target grain is evidence, not a Provider convention. Product-grain binds
only `productExternalID`, forbids a SKU, and accepts a current valid v1, v2, or
v3 source receipt. SKU-grain additionally requires an exact `skuExternalID`
from the v2-or-v3 source receipt. Add and delete must use the same target and prove
absent-to-present-to-absent restoration. The receipt is governance input only
and creates no shared runtime or middleware dependency.

Source-product receipt v3 is the shop-bound form of v2. A policy with a
nonempty `acceptedShopIDs` allowlist requires the private Product export to
carry exactly one Product alias named `shopId`, validates that value against
the allowlist, and includes the exact shop ID in the evidence fingerprint.
Policies without the field remain v2 and continue to validate. Adding or
changing the shop allowlist changes policy authority, so existing receipts
must not be relabeled or reused; repeat verification, review, approval, and
publication with a fresh generated Product export.

Operational login uses a separate private-only path:

```text
web-api-reverse auth bootstrap --session-only
  -> atomic private Cookie/Web Storage checkpoints while gates remain open
  -> provider-neutral scoped private seed + private HAR
  -> preserve the private seed even when a later auth/business gate fails
  -> provider-owned validation/normalization and private derivation
  -> provider-owned secure session store
  -> generated native session validation
```

Checkpoint recovery preserves user-acquired state, not an API claim. A failed
business-response gate remains failed and cannot enter Observed trust,
Published contracts, or codegen.

An already authenticated profile uses the noninteractive variant:

```text
headless web-api-reverse auth inspect + explicit provider domain scope
  -> disposable private profile snapshot
  -> provider-isolated private seed
  -> generated native account validation
  -> secure session update only after validation succeeds
```

For providers whose account page is itself risk-sensitive, the same ownership
chain uses `auth inspect --candidate-only`: the disposable snapshot yields its
first scoped session candidate without new page navigation, then the provider's
Published generated account operation supplies the only login verdict. The
generic tool does not infer account validity from Cookie presence.

Headed inspection is an explicit user-authorized diagnostic, not an automatic
fallback for a rejected or expired session.

Private seed recovery is a third private-only path:

```text
web-api-reverse auth restore + explicit provider domain scope
  -> validate durable scoped Cookie/localStorage state
  -> copy the closed persistent profile to sibling staging
  -> inject and close/reopen staging with the OS Keychain policy
  -> verify every restored value
  -> atomically replace the original profile or roll back
  -> generated native account validation remains required
```

Core owns scope validation and the profile transaction. The Playwright worker
owns injection and browser-restart verification only. Restore refuses
sessionStorage, never writes Observed evidence, and never serves as a runtime
browser fallback.

Discovery may also replay a private scoped seed without a profile:

```text
web-api-reverse capture --session-seed + explicit provider domain scope
  -> validate provider, market, Cookie, and origin ownership
  -> inject Cookie/localStorage/sessionStorage into one ephemeral context
  -> capture browser requests before that context closes
  -> discard the context without writing any persistent profile
```

This path exists because session Cookies and sessionStorage can be valid within
one browser lifecycle while being intentionally non-durable. It is browser
evidence only; native verification and publication remain independent gates.

The flow is intentionally one-way. A generated client cannot alter its
evidence, and a capture cannot promote itself.

## Stable Boundaries

- Observed is complete discovery fact, not a client contract.
- Static bundle-route candidates are leads inside Observed, not operations or
  source-coverage proof.
- The source manifest defines the semantic coverage boundary; the source lock
  preserves it and coverage fails closed when an area or required revision is
  missing.
- Trusted is the reviewed subset with exact evidence references.
- A Trust decision may declare `opaqueResponsePointers` only for exact,
  semantically irrelevant success-response object or array subtrees. Pointers
  must be unique absolute JSON Pointers and resolve in every retained success
  schema; projection fails closed otherwise. Stable envelope and
  business-success fields stay typed, and error responses are never widened by
  this policy.
- Session-lifecycle and authenticated-business trust requires native request
  evidence on every cited receipt. Provider-declared static query/header facts
  are checked against the actual replay and bound by a request-variant digest;
  browser-only success and same-path protocol variants remain insufficient.
  Native replay headers must also have an owning final policy: ordinary
  generated wire headers and auth-policy-owned Cookie/Authorization material
  are recognized explicitly, while every other header must be present in
  `routePolicy.staticHeaders` or `runtimeManagedHeaderNames`. Declared headers
  absent from replay and replay headers absent from policy both fail Trust.
- Authenticated response values may be inspected transiently to derive and
  review a response schema, but they never become reusable Trusted fixtures or
  OpenAPI examples. Generated decode tests use synthetic values that conform to
  the reviewed schema.
- Published is an immutable codegen release projection.
- The Published approval receipt carries the complete required/covered
  coverage-area proof and hashes every required selected-platform source
  receipt under its canonical Observed path, so Published does not rely on
  `.agent` notes or a machine-local audit.
- Canonical provider-root validation reopens the approval-bound Observed
  catalog and source lock. Published operation approvals must resolve to
  current receipts in `Observed/verifications/`; selected-platform product
  semantic areas must resolve to policy-matching receipts in
  `Observed/source-verifications/` whose exact path/hash set is carried by the
  Published approval. A zero-operation `remote-collection` claim must also
  resolve to exactly one current receipt in
  `Observed/collection-verifications/`, which rebinds the current source
  receipt and its platform Published-lock digest.
- `Observed/verifications/` is the sole operation-receipt directory.
  Inventory, strict coverage, and provider-root validation reject the legacy
  singular `Observed/verification/` instead of selecting different evidence.
- An anonymous Published operation's accepted receipt set must contain exact
  sanitized replay evidence proving no Cookie or authentication header was
  sent. A separate receipt may retain the reviewed response fixture, but every
  cited receipt remains operation-, fingerprint-, source-, class-, and
  success-bound. Browser-observed account state cannot be converted into
  anonymous runtime policy by review alone.
- Verification IDs are unique across the complete canonical receipt tree;
  duplicate physical receipts are rejected before approval or validation.
- Sanitized import distinguishes HTTP transport success from business success.
  A non-success business `code` in a risk-disposal envelope (`disposal` or
  `echo`) produces a `business-error` outcome even without a message field;
  providers must not repair that outcome by annotation or review.
- `publish-lock.json` hashes the other four Published files, including the
  approval that carries source- and collection-verification receipt hashes;
  receipts do not become a sixth Published file.
- The approval's six fixed `inputHashes` keys are
  `API/Config/source-manifest.json`, `API/Config/trust-manifest.json`,
  `API/Observed/catalog.json`,
  `API/Observed/source-lock.json`, `API/Trusted/openapi.yaml`, and
  `API/Trusted/operation-policies.json`. Runtime projection compares every
  approval hash with current bytes; a valid Published lock does not make a
  stale approval current.
- Browser state and credentials never enter durable artifacts.
- Structured account identity is rejected by artifact scanning even when it is
  not a phone number, email, or credential. Historical JSON may be migrated
  with the explicit sanitizer, but sanitization never repairs trust authority.
- Product-specific capability semantics remain in the consuming project.

## Maintainer Route

1. Read `SKILL.md`.
2. Read this document.
3. Read `evidence-workflow.md` for state transitions.
4. Read `provider-middleware.md` for provider integration.
5. Run Swift Testing and the single-skill validator.

Do not weaken validation to accommodate an invalid provider artifact. Fix the
provider evidence or make the capability claim narrower.
