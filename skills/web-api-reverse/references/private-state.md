# Private Browser And Session State

## Boundary

Browser profiles, raw HAR files, raw captures, cookies, tokens, storage values,
private request specifications, raw responses, and session seeds are runtime
inputs. They must stay outside every provider's `API/` tree and outside source
control.

Browser capture never gives Playwright the caller's output path. The worker
writes into a fresh tool-owned `0700` scratch root; Swift copies bounded
canonical files to the explicit private root using descriptor-relative
`O_NOFOLLOW` reads and atomic replacement. The final root is owner-only and
bound by device/inode. Symbolic-link parents or leaves, source/API ancestry,
and a root path replaced during the transaction fail closed without writing to
the replacement target.

Sanitized capture receipts, verification receipts, and request-shape evidence
belong under `API/Observed`. They may contain names, schemas, URL templates,
status codes, business outcomes, and redacted fixtures, but never credential
values or personal identifiers.

`inventory-bundles` may read embedded JavaScript bodies from a private HAR and
write only a bounded, sanitized candidate receipt under
`API/Observed/bundle-routes/`. The raw bundle body remains private. Candidate
receipts contain route leads and bundle hashes only; they are not capture
receipts and cannot prove operations, authentication, coverage, or trust.

## Login Bootstrap

`auth bootstrap` opens the provider login page using a user-controlled
persistent profile when `--profile` is supplied. The tool:

1. never logs out or deletes the profile;
2. uses the operating system Keychain for persistent-profile Cookie
   encryption and explicitly rejects Playwright's process-local mock Keychain;
3. waits for explicit user confirmation unless automatic completion is
   enabled;
4. optionally verifies a completion URL before either completion mode exits;
5. optionally waits for provider-declared Cookie/localStorage/sessionStorage
   names to contain usable values under explicit provider domains;
6. optionally waits for one bounded 2xx business response whose URL and body
   match provider-declared regular expressions;
7. eagerly checkpoints raw storage privately with mode `0600` while the
   authentication gate remains open;
8. preserves a scoped `session-seed.json` checkpoint even when the later
   completion, field-presence, or business-response gate fails;
9. for authenticated commands, captures cookies only under declared session
   domains and reads only explicitly required local/session storage keys from
   matching origins; public capture may still inventory every open HTTP(S)
   page and frame;
10. filters authenticated HAR and in-memory exchange capture to those same
    declared domains, so unrelated tabs in a shared profile never enter the
    Provider checkpoint;
11. converts Playwright cookies and storage into
   `web-api-reverse.private-session-seed`;
12. writes only a sanitized capture receipt to Observed in evidence mode.

The worker treats browser lifetime as part of the private-state transaction.
The Swift CLI passes its parent command as the default owner and preserves a
Provider adapter's explicit owner when one is supplied. Node monitors that
owner plus its direct Swift parent. An interrupt or lost owner closes the
active Playwright context before the worker exits, preserving the persistent
profile while releasing its process lock. Interruption never commits a
candidate, deletes a profile, or implies that the upstream account logged out.

Bootstrap may also receive a previously captured private `--session-seed`.
The seed is validated against the requested provider, market, and domain scope,
then injected into the newly opened browser context before navigation. This is
single-lifecycle replay, not durable browser storage: session Cookies may be
discarded by Chromium after a normal close even when their encrypted rows were
readable during the run. The newly captured seed remains the private handoff to
provider-owned native session storage and validation.

`--profile` is the physical persistent-browser directory. When a caller maps
a provider-owned logical account profile such as `default` onto a shared
physical directory, it must also pass `--session-profile-label default`.
The seed stores that explicit logical label while Playwright continues to use
the physical directory. Provider decoders may then validate account-profile
identity without depending on a machine-local path. Direct callers that omit
the label retain the legacy behavior of storing the `--profile` value.

Persistent-profile launches must ignore Playwright's default
`--use-mock-keychain` argument. A mock Keychain can encrypt Cookie rows with
process-local material that a later browser process cannot decrypt; the next
launch may then load an empty Cookie store or delete those rows. A profile
created under a different encryption policy is not migrated or guessed from.
It requires one explicit login bootstrap under the current policy before
noninteractive inspection is allowed.

Persistent Chromium profiles must also launch with Playwright's full Chrome
for Testing executable, not its headless shell. The two processes do not share
the same macOS Cookie-decryption identity even when they come from one
Playwright installation. `auth inspect` additionally restores the last
session only inside its disposable snapshot so session Cookies survive the
inspection launch. Neither rule changes the writable user profile.

`--session-only` is the operational login mode. It writes no Observed receipt
and requires no source revision. It requires at least one `--session-domain`
so a shared profile cannot leak another provider's state; raw capture, HAR,
and the scoped generic session seed remain private. The provider adapter must
validate/normalize the seed and may derive provider-specific private runtime
values from the private HAR before secure import. This does not make browser
automation a normal business transport.

Cookie and storage names are provider-owned runtime facts. A provider may pass
them through `--auth-require-cookie`, `--auth-require-local-storage`, and
`--auth-require-session-storage`. The worker rejects empty and placeholder
values such as `null` or `undefined` and keeps waiting until the auth timeout.
These presence checks prevent premature browser closure; they do not replace
provider-owned decoding or a generated native account validation.
Other scoped Chromium Cookies may legitimately carry an empty value. Private
seed replay preserves them; only provider-declared authentication requirements
must be nonempty.
Authenticated checkpoints deliberately omit undeclared Web Storage keys and
all state outside `--session-domain`, even when several providers share one
persistent profile. A provider that needs a Web Storage value must declare its
exact key; discovery must not compensate by exporting another site's complete
storage state. The same declared domains filter private HAR and exchange
capture. If an authenticated flow requires another first-party API or identity
host, the Provider must declare that domain explicitly rather than relying on
another open tab.

When Cookie/storage presence is not strong enough, the provider may also pass
paired authenticated response URL/body regexes. The worker accepts only a 2xx
response body of at most 1 MiB and keeps waiting when the page shell loads
without the declared business success. It never persists the regex match as API
evidence and the generated native account read remains authoritative.

With `--auto-complete-on-auth-requirements`, the Swift CLI closes worker input
and waits for every declared session, completion-URL, and authenticated-response
gate. It does not read terminal input in this mode. The browser gate still only
produces a candidate seed; generated native validation remains mandatory.
Closing every page/window created by the interactive auth flow cancels that
transaction immediately with `worker.auth_flow_closed`; the worker does not
wait for the remaining auth timeout and does not reopen a page. The final
private checkpoint is still hardened and the persistent profile is preserved.

If an authenticated redirect leaves the browser away from the Provider's
business entry, the Provider may explicitly add
`--auth-revisit-entry-on-session-change`. The worker records the required
session-material fingerprint after initial entry navigation, waits for that
exact scoped material to become complete and change, then revisits the entry
once. It does not react to undeclared Cookies, reuse an already-complete stale
fingerprint, or repeat navigation. The option requires an authenticated-
response gate, which remains subordinate to generated native validation.

Some login systems confirm browser authentication without changing the
Provider's required Cookie value. For those flows, paired
`--auth-revisit-trigger-response-url-regex` and
`--auth-revisit-trigger-response-body-regex` options may replace the
session-change trigger. The bounded 2xx intermediate response causes exactly
one same-context revisit of the declared entry URL. It cannot complete auth:
the separate `--auth-require-response-*` gate must still succeed after the
revisit, and Provider-native generated validation remains final authority.
Response-triggered and session-change-triggered revisits cannot be combined.

`--settle-ms` applies after those bootstrap gates have passed. The worker keeps
the same context alive for that bounded interval and then refreshes the scoped
session checkpoint. Providers should use it when the authenticated response can
arrive before Chromium has finished committing the Cookie or Web Storage state
needed by native replay. A settle interval cannot turn an unverified page shell
or stale Cookie into authenticated evidence.

The private storage checkpoint is independent of the business-response gate.
The worker rewrites `capture.json` atomically while bootstrap is open and takes
one final snapshot before reporting a failure. The Swift CLI derives a
provider-domain-scoped `session-seed.json` from that checkpoint and includes
its private path in the failure message. A wrong response regex, API drift, or
decode failure must not discard a login the user already completed. The
checkpoint is recovery input only: it does not make the failed API claim
Trusted and it does not turn a page shell into authentication proof.

`auth inspect` is the preferred route when a persistent profile is already
logged in. It copies the profile into a disposable private snapshot, opens the
authenticated account surface against that snapshot, exports only cookies and
Web storage matching explicit `--session-domain` suffixes, and removes the
snapshot on success or failure. The writable persistent profile is never
navigated during inspection. This is required because an HTTP response may
delete or rotate cookies even when the command is conceptually a read.
Inspection checkpoints the scoped seed, HAR, and capture before propagating a
missing authenticated-response gate. This is a recoverable private checkpoint,
not proof of login: provider-owned decoding and a generated native account
read remain mandatory. A redirect to the provider login surface or missing
declared Cookie/Storage material remains conclusively unavailable.

`auth inspect --candidate-only` is the no-navigation handoff variant. It
launches the disposable snapshot with the same Cookie-decryption policy,
captures the first scoped startup snapshot, enforces exact declared
Cookie/Storage names, and does not create or navigate a new page. It cannot be
combined with reject-URL, authenticated-response, or headed gates because it
makes no browser authentication claim. The resulting private seed is only a
candidate for immediate provider-native validation. A provider must validate
with a Published generated account operation and atomically commit only on
success; failure preserves both the persistent browser profile and any prior
native session.

Bootstrap and inspection launch persistent contexts with the same OS-Keychain
policy, so encrypted Cookie rows remain readable after both process restart
and snapshot relocation.
When the provider knows required browser session fields, inspection must
receive the exact `--auth-require-*` names needed by the next generated native
account operation. Account-page inspection may additionally apply the paired
response URL/body proof. Candidate-only inspection deliberately cannot apply
that browser business-response gate: it extracts the minimum session candidate
without navigation and immediately delegates authority to the Published
generated account operation. Cookie names, an account URL, and a rendered
account shell never establish a connected native account by themselves.
Inspection is headless by default. A visible
inspection requires the explicit `--headed` option and user authorization; it
must not be used by an automated account audit. This is required when multiple
providers share one browser profile. A redirect rejection, missing required
material, or empty scoped seed fails without replacing a previously exported
seed. Provider-native account validation remains the authority for whether the
captured session is usable.
Redirect rejection checks the inspection page, pages opened by the current
flow, and their frames, not only the top-level URL, so an embedded login widget
cannot be mistaken for an authenticated account page. Unrelated tabs that
already existed when the persistent context opened are ignored; otherwise a
stale login tab would produce a false `requiresLogin` result for a valid
account surface.

`auth restore` is an explicit recovery path for durable state in a private seed that was
previously exported by this tool. It is not part of login, refresh, discovery,
or runtime API execution. Restore requires a closed persistent profile and
explicit provider domains. Core validation rejects an unsupported seed schema,
empty or malformed Cookie state, any Cookie/origin outside the requested
scope, session-scoped Cookies, and nonempty sessionStorage because neither
browser-lifetime nor tab-scoped state can be restored truthfully as durable
profile state.

Do not use `auth restore` as the retention mechanism for session Cookies.
Their browser lifetime ends when Chromium closes. Use provider-native private
session storage for normal requests and `auth bootstrap --session-seed` when a
later browser-assisted transaction must rehydrate that state.

Restore never edits the profile in place. It copies existing state to a
sibling staging directory, removes transient browser locks only from staging,
injects the scoped Cookie/localStorage state, closes and reopens the staging
profile with the operating-system Keychain policy, and verifies each restored
value. Only then does Swift atomically replace the original profile. Any
validation, browser, or verification failure removes staging and preserves the
original profile. The command emits only Cookie/origin counts and a SHA-256
digest of the scoped seed; it never emits values or creates Observed evidence.
Generated native account validation remains mandatory after restore.

`capture --session-seed` is a separate discovery-only replay path for facts
that must remain in one browser lifecycle. It validates exact provider/domain
scope, requires the capture brand and market to match the seed, and injects
Cookie, localStorage, and sessionStorage into a new ephemeral Playwright
context. It cannot be combined with `--profile`, never writes a persistent
browser profile, and never declares the Provider connected. Use it to compare
browser-generated requests with native replay without pretending that a
session Cookie or tab-scoped value is durable across restart.

Do not interpret a network error, decode error, or one failed business request
as proof that the user must log in again. Preserve the browser profile and
secure session; transition to `requiresLogin` only for an explicit server
authentication result.

`--device` accepts an exact Playwright device descriptor for H5 emulation.
Unknown devices and invalid completion regexes fail before browser state is
captured. Completion, field-presence, and business-response timeouts fail the
authentication claim but preserve any valid scoped private checkpoint acquired
before the timeout. Cookie-only authentication does not read Web Storage.
When storage keys are explicitly required, frames outside the declared session
domains are ignored and inaccessible in-scope HTTP(S) frame storage remains a
hard failure.

The session seed is an input to verification, not a generated API contract.
Provider runtime session acquisition and refresh remain provider-owned.

## Native Replay

A private HAR request must be extracted only after its sanitized capture
receipt has entered Observed and the selected operation exists in the current
catalog. `extract-request` recomputes the HAR SHA-256, requires the exact
capture source reference on the operation, and matches the captured exchange
ID, method, URL template, and fingerprint. It writes the complete request only
to a mode-`0600` path outside `API/`; command output reports counts and paths,
not request values. If the same operation appears more than once, the latest
matching browser request is used.

The extracted request is semantically equivalent, not a byte-for-byte browser
cache replay. Transport-managed compression is removed. Safe reads also drop
`If-Modified-Since`, `If-None-Match`, `If-Range`, and `Range` so the verifier
cannot accept a bodyless 304 or partial cached response. Write preconditions
remain provider evidence and are not removed by this safe-read rule.

This extraction is the bridge from an atomic login checkpoint to one-shot
native verification. It does not make browser traffic Trusted, define
provider middleware, or authorize copying raw request values into generated
code. Provider-owned session import must still normalize durable session
material, and a generated native account read remains the connected-state
authority.

A private request may refer to session values only through explicit
`{{session.field}}` templates, aliases, and derivations. Unknown aliases,
unknown environment mappings, missing values, and invalid expiration inputs
fail closed.

Native replay binds the resolved request to the exact Observed URL template
and request fingerprint. Durable output records only header/cookie names,
request schema, response schema, status, outcome, source references, and
redacted fixture data. Provider-declared static query/header facts are also
validated against the resolved request and represented only by a deterministic
request-variant digest. Optional raw response output remains private and is
written with mode `0600`.

High-risk writes are never replayed. A reversible write requires explicit
operator approval and a full restoration sequence; a single successful HTTP
response is not mutation proof. The private plan does not own endpoint facts:
it references operation IDs from the current Observed catalog. Only the
sanitized sequence receipt and five phase receipts enter
`API/Observed/verifications/<sequence-id>/`.
