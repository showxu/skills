# Evidence Workflow

## Config

Config declares expected sources and human decisions:

- source manifest and locked revisions
- operation annotations
- capability claim proposal
- approval identity and review metadata

Config must not contain credentials or one-run browser state.

The source manifest must declare `requiredCoverageAreas` and assign
`coverageAreas` to every required source. Coverage areas are project-owned
semantic surfaces such as `official-desktop`, `official-h5`,
`authenticated-account`, `remote-collection`, `remote-config`, or
`current-facts`; they are not inferred from operation counts. Use the names
that match the provider's actual source and capability boundaries.

Every required coverage area must be assigned to at least one required source.
Every required source must declare at least one area. Area identifiers use
lowercase kebab-case. A source filtered down to one endpoint may cover that
endpoint family, but it must not claim the whole page or account surface when
the selection omitted other applicable business requests.

A required source with neither an observed operation fingerprint nor a
validated external-source evidence fingerprint is incomplete, even when a
browser capture file exists. A login redirect, risk page, empty shell, failed
navigation, or hand-written platform assertion is not API coverage. If a
surface has no applicable API, exclude that source with a reviewed rationale;
do not use an empty capture to satisfy a required area.

## Observed

Observed contains mechanically derived, sanitized facts:

- capture receipts
- bounded static bundle-route candidate receipts under `bundle-routes/`
- operation catalog
- source lock
- verification receipts
- request-shape evidence from native replay under `request-evidence/`
- reversible verification sequences and their five phase receipts under
  `verifications/<sequence-id>/`
- brand-to-platform collection qualification receipts under
  `collection-verifications/`
- coverage report

Operation verification receipts use the canonical plural
`Observed/verifications/`. Inventory and strict coverage derive current
verification status from that tree, and canonical provider-root validation
requires every Published operation approval to resolve to its current proven
receipt. The legacy singular `Observed/verification/` is not read: move its
receipts to the plural directory, remove the singular directory, and rerun
inventory.

Failed probes remain diagnostic evidence. They do not define successful
response schemas.

Trusted OpenAPI preserves the reviewed evidence shape. Publication is a
deterministic, hash-locked projection: an evidence-only empty schema becomes
an unconstrained object for code generation, while an observed-null-only
schema uses the OpenAPI 3.1 `type` union with `null`. This projection adds no
endpoint, field, or business claim; it only makes the approved evidence
representable by the generated Swift client. `Published/openapi.yaml`, not
Trusted, is therefore the sole codegen input.

An authenticated capture keeps its raw HAR private. After the sanitized
capture receipt is inventoried, `extract-request` may recover one exact
browser request for immediate native replay. Extraction is accepted only when
the private HAR digest equals the capture source digest and the selected
operation cites that exact capture/source/version reference. The resulting
request specification remains private and is never an Observed or Trusted
artifact. Extraction removes transport-managed compression headers. For a
safe read it also removes browser cache validators and byte-range headers,
because native replay has no matching browser cache body and must obtain one
complete response. Reversible writes retain their concurrency preconditions.

Bundle-route candidate receipts are deliberately outside operation inventory.
They may retain only sanitized absolute or root-relative route literals,
query names, template placeholders, source bundle hashes, and source revision
metadata. They do not establish method, auth, payload, response, safety,
business outcome, or codegen eligibility. They cannot satisfy a required
source or semantic coverage area and cannot be referenced directly by a
Trusted projection. A candidate becomes operation evidence only after the
route is exercised in a network capture and independently verified under the
normal workflow.

### Platform-backed source evidence

A brand Provider may consume a separately Published Taobao or JD library.
That relationship does not make platform operations part of the brand
Provider's OpenAPI. A private `SourceProductImportV1` comes either directly
from the platform CLI (`platformRaw`) or from a brand Provider that has
validated the exact seller/store pair (`providerMapped`);
`verify-source-product` validates it against:

- the exact five-file platform Published contract and its lock;
- the Provider's declared source revision;
- garment-brand, seller, storefront, optional exact shop, market, and platform
  allowlists;
- required product and SKU current-fact fields;
- minimum SKU count and the reviewed complete/incomplete SKU-set policy.

An optional nonempty `acceptedShopIDs` list upgrades a successful source
verification from receipt schema v2 to v3. The source Product must expose
exactly one Product alias named `shopId`, and its value must be allowlisted.
The v3 evidence fingerprint binds that exact shop ID in addition to the v2
Product/SKU graph. Omitting the field preserves v2 compatibility. Adding or
changing it invalidates the old policy digest and requires a fresh generated
Product export, verification, review, approval, and publication.

Run `validate-source-product-policy --policy <path> --json` as an offline
preflight for every configured policy. It uses the owning typed verifier rather
than a shell approximation and must pass before account validation or Product
access.

Omitted `sourceProjection` means `platformRaw` for compatibility. In that
mode, `sourceTool` and `providerID.brand` must equal `platformProvider`. With
`providerMapped`, `sourceTool` must equal the brand `provider`, while the
nonblank `providerID.brand` remains the domain BrandID and may use a different
canonical spelling. Its market and optional storefront must remain consistent;
`commercePlatform` and the independently validated Published lock still belong
to `platformProvider`. A provider-mapped export is appropriate only after the
brand package rejects non-allowlisted seller/store identity. It must not turn a
shop title into an inferred garment brand.

Only the resulting sanitized receipt belongs under
`Observed/source-verifications/`. It contains hashes and bounded identity/fact
metadata, not the raw product export, session material, or user state.
Inventory binds its evidence fingerprint to the declared source lock. It does
not add an operation to the Provider catalog.

Before a caller reuses that receipt for source freshness or collection
qualification, it must call the owning semantic validator:

```sh
web-api-reverse validate-source-product \
  --receipt API/Observed/source-verifications/<receipt>.json \
  --policy API/Config/<platform>-source-product-policy.json \
  --platform-provider-root <platform-provider-root> \
  --json
```

The validator decodes the typed policy, validates the platform's current
Published contract and scope, and recomputes the verifier's canonical JSON
digests. A raw hash of `publish-lock.json` or the policy file is not equivalent:
formatting and JSON encoder escaping are not authority. The command also returns
the exact source-receipt byte hash that collection evidence binds.
An invalid or stale receipt is a deterministic `verification.invalid` failure
with exit code 65; orchestration must treat it as evidence requiring
requalification, not as an internal tool crash.

If there is no current Product reference, use
`inventory-source-candidates` on a project-owned private HAR before editing a
qualification config. Its Provider-owned policy limits extraction to reviewed
hosts and exact query/form/JSON/JSONP field names. The private result contains
only public Product IDs and structural provenance, never Cookie, token, header,
or response-body values.

Candidate inventory is deliberately outside the evidence ladder. Selecting a
candidate still requires a generated platform Product export, seller/brand
checks, complete SKU semantics, current-fact checks, and
`verify-source-product`. A store title, Product-like number in arbitrary text,
or candidate occurrence cannot close `selected-platform-identity` or
`selected-platform-current-facts`.

When Published approval claims `selected-platform-current-facts` or
`selected-platform-identity`, approval requires the current
`Observed/source-lock.json` and every required canonical receipt under
`Observed/source-verifications/`. At least one required source covering each
such area must bind a current sanitized source-verification fingerprint. The
matching receipt must prove the exact source revision, source-product digest,
current policy digest and allowlists, required current-fact summary, and
platform Published-lock digest.

`approve` records the raw SHA-256 of each required receipt under its canonical
`API/Observed/source-verifications/<file>.json` path in `inputHashes`.
Publication reopens the current source lock, policies, and receipt directory
and requires the exact receipt path/hash set before copying Trusted authority.
Canonical provider-root validation repeats that check, so receipt removal,
byte tampering, or omission from approval invalidates Published. Providers
whose semantic coverage contains neither area do not require source-product
receipts.

### Platform-backed collection evidence

A brand Provider may qualify a remote collection implemented by a separately
Published platform Provider without copying platform operations into the
brand OpenAPI. `verify-collection` consumes one current valid
`SourceProductVerificationReceipt`, the platform Provider's valid Published
contract and lock, and private exact-shape JSON envelopes from one brand CLI
add followed by delete. Product-grain accepts receipt v1, v2, or v3;
SKU-grain requires v2 or v3.

Transcript `command` must be exactly `<provider>.wishlist.add` or
`<provider>.wishlist.delete`. The semantic shape includes provider, market,
platform Provider, product, explicit target grain, optional SKU, action,
`platform-confirmed-change`, and resulting remote state. Input whitespace and
key order are not authority: the verifier decodes only that bounded shape,
re-encodes it canonically, and hashes the canonical bytes.

Collection grain follows the platform operation. Product-grain binds the
exact `productExternalID` and forbids `skuExternalID`; Taobao/Tmall Favorite
for H&M is one such product-grain surface. SKU-grain requires an exact
`skuExternalID` present in the v2-or-v3 source receipt. Product-grain may use a valid
v1 receipt because its bound product, seller/storefront, complete-SKU-set
flag/count, current facts, and platform lock are sufficient without SKU IDs.
Product-grain evidence must not invent a SKU target. Add and delete must use
the same grain and exact target and prove absent -> present -> absent.

Only the sanitized receipt is written to
`Observed/collection-verifications/`. It stores provider/market, platform
Provider, platform publish-lock hash, current source-receipt hash, exact
product and grain, optional exact SKU, canonical transcript hashes,
verification time, and restoration proof. It stores no response body,
account, Cookie, token, session, or private path.

`approve` may add a supported zero-operation `remote-collection` capability
only when exactly one current canonical collection receipt resolves to an
approval-bound source-product receipt and the same platform lock digest. The
receipt's exact path and raw hash become approval inputs. Publication and
canonical validation reopen both Observed receipt families and reject missing,
duplicate, symlinked, stale, cross-scope, cross-product, cross-SKU, or
cross-platform evidence. No other supported capability may be operationless;
the OpenAPI, policy, approval, and capability operation-ID sets remain equal.

When a wire query or form field contains a JSON object, Observed keeps the wire
field name while Trusted/OpenAPI projects the decoded object as the logical
generated request body. Published operation policy carries the exact
`encodedQueryBodyNames` or `encodedBodyFieldNames` transform needed to restore
the wire request.

A verification receipt must bind one Observed operation fingerprint, its
complete source-reference set, the independently observed response shape, and
the assessed business outcome. HTTP `2xx` alone does not prove success.
Syntactically valid JSONP is unwrapped only for outcome assessment. A payload
whose `ret` array contains no `SUCCESS::` entry, or a response carrying a
nonempty/nonzero `bxpunish` header, is `business-error` evidence even when the
HTTP status is `200` and the browser executed the callback. Browser success is
also not native-runtime proof; publication still requires the declared direct
or lifecycle replay class to succeed.

Repository-wide sensitive-artifact scanning may resolve a symbolic link only
when it targets a regular file inside the scanned root; the target is scanned
as content. Links outside the root and links to directories fail closed.
Trusted, Published, receipt, and private-state writers continue to reject
symbolic links entirely.

The accepted receipt set also owns the sanitized request evidence used for
policy approval: final normalized URL template, header names, Cookie names,
request-body schema, and any reviewed request-variant digest. Every cited
session-lifecycle or authenticated-business receipt must carry this native
request evidence. Provider route policy may declare exact static query/header
facts; native verification checks the resolved request before replay and binds
those facts into the digest, so two requests sharing an API path cannot be
silently collapsed into one runtime variant. Trust also compares the replayed
header-name set with the final policy. Apart from generated `Accept`,
`Content-Type`, transport framing, and auth-policy-owned Cookie/Authorization
material, every replayed header must be declared by `staticHeaders` or
`runtimeManagedHeaderNames`; every declared header must appear in replay.
Test-only policy enrichment therefore cannot approve a narrower runtime
contract. When an operation is approved with `authPolicy:
none`, at least one cited receipt must prove a successful exact replay with no
Cookie or authentication header. Another cited receipt may retain a separately
reviewed structured response fixture; every receipt still must match the same
operation, fingerprint, complete source-reference set, required evidence
class, and successful response contract. A successful response first observed
in an authenticated browser is not anonymous evidence. `trust`, `approve`,
`publish`, and canonical `validate` all enforce the same set-level rule, so an
older Published projection cannot bypass it.

Sanitized response evidence retains response header names and Set-Cookie names
when the capture path observed them. It never retains header or Cookie values.
This distinction is required for session-lifecycle review: an HTTP success or
token-shaped response body cannot prove that a browser protocol actually
issued the Cookie material consumed by the next request. Legacy receipts that
predate these fields remain decodable, but absence of the fields is absence of
that lifecycle proof, not evidence that no Cookie was written.

One verification ID identifies one receipt in the canonical tree. Duplicate
IDs are invalid even when files have different friendly names; reversible
verification should use its exact sequence-owned receipts rather than copying
the same receipt into adjacent aliases.

A successful top-level JSON `null` response is a concrete fixture, not a
missing response body. Because Codable optional storage cannot preserve the
difference between an encoded JSON null and an absent optional after reload,
the evidence model reconstructs `.null` only when `bodySchema` is exactly
`{type: null}` and no fixture-omission reason exists. Empty responses and
explicitly omitted fixtures remain fixtureless and fail the normal trust gate.

Default operation-shape detection is discovery assistance, not authority over
an explicit review decision. If Config contains an exact operation annotation
for a captured exchange fingerprint, inventory retains that exchange even when
the default heuristic would omit it, such as a redirected HTML product
document. The source lock derives operation fingerprints from the resulting
catalog's exact capture/source/version references so catalog and lock cannot
apply different inclusion rules.

## Trusted

Trusted contains the reviewed projection:

- OpenAPI 3.1 contract
- operation policies
- fixtures referenced by policy
- evidence references

Trust is a semantic decision. The CLI validates that referenced facts exist,
but it cannot decide that two business responses mean the same thing.

The OpenAPI projection may use reviewed names for path parameters. Parameter
count and static route shape must still match the Observed operation after a
reviewed fixed base path is removed. A review cannot silently rewrite an
endpoint while retaining its evidence fingerprint.

Set `useNamedComponents: true` on a reviewed trust-manifest operation when a
public generated client needs stable request or response component names even
for a currently small schema. This is a code-generation stability policy, not
permission to rename wire fields or invent a schema; the named component is
still projected entirely from the accepted Observed and verification facts.

OpenAPI `path` may be a stable collision-free client path for several
operations sharing one gateway. In that case operation policy must retain the
Observed upstream `wirePath`. Nonstandard JSON-compatible response media types
are projected as generated `application/json` only when policy records the
wire-to-generated mapping in `responseContentTypeAliases`.

Successful fixtures are retained when they carry a generated response shape.
Textual or authenticated response bodies may be omitted only with an explicit
reviewed extraction policy and omission reason; a null-only scalar does not
become a required generated field. A response-array property whose observed
elements are only `null` is likewise omitted from the generated response
schema while its exact path remains in
`x-web-api-reverse-observed-null-paths`; this avoids inventing an element type
or emitting an unsupported OpenAPI `null` schema. When the entire successful
response is observed only as `null`, the media type retains its reviewed null
example and exact null path but omits `schema`; a vendor-extension-only schema
is not a generated data contract.

Account response fixtures are structurally redacted. Numeric account IDs and
nickname aliases are personal material even when they do not match a phone,
email, or token pattern. `scan-artifacts` rejects those values across JSON-form
Observed, Trusted, and Published files. `sanitize-artifacts` exists only to
migrate historical JSON and must be followed by diff review and a fresh scan.

## Published

Published is codegen input. It is built atomically from:

- Trusted `openapi.yaml`
- Trusted `operation-policies.json`
- Config `capability-claim.json`
- Trusted `approval-receipt.json`

The publisher copies those four files and writes `publish-lock.json` with
their SHA-256 hashes. Validation recomputes every hash and scans every file for
raw secret material. Required source-product and collection-verification
receipts remain in Observed rather than becoming a sixth Published file: their
hashes are durable inputs of `approval-receipt.json`, whose own hash is covered
by `publish-lock.json`.

Validation does not trust those copied bytes merely because their lock hashes
match. It reconstructs the deterministic OpenAPI publication projection from
Trusted and loads the other three authoritative Trusted/Config payloads, then
requires byte-for-byte equality with all four Published files. Only after that
comparison does it validate `publish-lock.json`. Editing Published and
recomputing its lock cannot promote new runtime authority.

Publication is byte-deterministic for identical approved inputs. By default,
`publish-lock.json.publishedAt` is copied from the approved authority's
`approval-receipt.json.approvedAt`; it never uses the publisher's wall clock.
`approve --approved-at` and `publish --published-at` accept explicit ISO 8601
audit timestamps for deterministic recovery of an already reviewed historical
contract, and an explicit publish timestamp is preserved exactly. These inputs
do not change evidence, reviewer, operation, capability, coverage, input hash,
secret-scan, or exact-five validation rules. A discovery-only capture must not
be Published merely to retain it; if it does not change runtime authority,
keep it Observed until a deliberate contract revision is reviewed.

## Mutation Approval

A reversible write requires:

1. before-state hash
2. one probe-owned identity
3. changed-state hash
4. restored-state hash
5. proof that restored state equals before state

`verify-reversible` resolves every operation from the current Observed catalog;
the private execution plan carries operation IDs and concrete requests only.
It performs `read-before -> add -> read-mutated -> remove -> read-restored`.
The six durable files are swapped into one sequence directory atomically only
after exact restoration and artifact scanning succeed.

The default state projection reads a JSON collection through
`collectionPointer` and extracts each identity through `identityPointers`.
For first-party storefronts whose authenticated collection is
server-rendered HTML, the plan may additionally declare `textCollection` with
one bounded regular-expression pattern and explicit identity capture groups.
Set `fixtureOmissionReason` on private read requests when the authenticated
HTML must be parsed during verification but must not be retained in durable
receipts. The private body remains available in memory for exact collection
projection; only its response shape, digest-derived proof, and reviewed
omission reason cross the evidence boundary.
The verifier runs the same exact set comparison over those captured scalar
identities, records the pattern digest and capture-group indexes, and still
requires the restored collection to equal the complete preflight collection.
Do not use a membership-only scalar as a substitute for full collection
restoration when a collection surface is available.

The add and remove receipts usually belong to different operations. Inventory
checks each receipt against its own operation fingerprint and source-reference
set, then resolves the reciprocal receipt from the complete current receipt
tree. Pre-filtering reciprocal lookup to one operation would make every valid
add/delete pair appear unproven.

Never delete or modify a pre-existing remote item to prove a mutation. If a
safe probe identity cannot be found, leave the capability unsupported.

## Coverage

Zero-unknown requires both:

1. every operation from every required source at its locked revision is
   classified; and
2. every manifest-declared required coverage area is covered by at least one
   required source whose locked revision is fully captured.

The source lock carries the manifest's required areas and each source's
assigned areas. The coverage report records required, covered, and missing
areas. A legacy source lock without this semantic contract cannot pass strict
coverage or approval.

Deferred and excluded sources remain visible and must carry rationale.
Zero-unknown does not mean every operation is Trusted or Published. It also
does not mean an undeclared source surface was investigated; reviewers must
make the manifest's required areas match the provider's claimed product,
account, collection, config, and current-fact capabilities before approval.

`approve` recomputes coverage from the current Observed catalog and source
lock. It does not trust the `--zero-unknown` flag by itself. The resulting
approval receipt embeds the required and covered area sets, and Published
validation rejects receipts without a complete semantic coverage proof.
For selected-platform semantic areas it also embeds the exact required
source-verification receipt path/hash set.
The approval always hashes these six provider-root inputs:

```text
API/Config/source-manifest.json
API/Config/trust-manifest.json
API/Observed/catalog.json
API/Observed/source-lock.json
API/Trusted/openapi.yaml
API/Trusted/operation-policies.json
```

No fixed input may be omitted. Additional approval hashes are restricted to
canonical single-file receipts under
`API/Observed/source-verifications/` or
`API/Observed/collection-verifications/`; absolute paths, traversal, nested
paths, other Observed trees, and arbitrary project files are forbidden. A
collection receipt is admitted only for the supported zero-operation
`remote-collection` capability and must revalidate against its current source
receipt. Publication
does not freeze the provider tree: provider-owned runtime projection must
re-hash every approval input against current bytes and fail closed after any
drift, deletion, unsafe replacement, or receipt-scope mismatch. The source
manifest hash and semantic equality with `source-lock.json` bind source
replacement, exclusion, coverage policy, and declared status to approval. The owning
SwiftPM plugin declares the same fixed inputs and only safe dynamic receipt
paths so incremental builds rerun that check.
Every Trusted policy must also cite verification IDs that the current
Observed operation still accepts. A historical receipt whose source-reference
set, safety, evidence class, response outcome, fixture proof, or reciprocal
restoration no longer matches current inventory cannot be repackaged by
approval; it must be reproduced through the owning verification workflow.

Strict coverage also reloads the canonical receipt tree and recomputes accepted
verification IDs. It does not treat historical IDs already present in
`catalog.json` as current proof when their receipts are absent.
