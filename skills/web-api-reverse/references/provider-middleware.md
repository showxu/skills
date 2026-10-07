# Provider Middleware

Provider middleware belongs to the provider package because protocol behavior
is provider evidence, not a universal runtime.

## Required Separation

```text
Generated API
  owns DTOs, request/response serialization, operation identifiers

Provider Storefront runtime
  owns route resolution, auth injection, signing, cookies, refresh, retry

Feature or CLI
  owns user intent and presentation
```

Do not put provider session policy in generated source. Do not make features
read tokens or assemble URLs.

## Published Runtime Projection

Keep the projection tool and build plugin in the provider package. They are a
mechanical runtime-authority boundary, not shared middleware and not a trust
decision. A projection should implement the equivalent of:

```swift
let requiredApprovalInputs: Set<String> = [
  "API/Config/source-manifest.json",
  "API/Config/trust-manifest.json",
  "API/Observed/catalog.json",
  "API/Observed/source-lock.json",
  "API/Trusted/openapi.yaml",
  "API/Trusted/operation-policies.json",
]

guard publishedDirectoryContainsExactlyFive,
  requiredApprovalInputs.isSubset(of: approvalInputHashes.keys),
  approvalInputHashes.keys.allSatisfy(isCanonicalApprovalInput),
  approvalInputHashes.allSatisfy(currentProjectHashMatches)
else {
  return failClosedRuntimePolicy
}
```

`isCanonicalApprovalInput` accepts the six exact paths above or one regular,
non-symlink JSON file directly under
`API/Observed/source-verifications/` or
`API/Observed/collection-verifications/`. A source receipt must decode as
`web-api-reverse.source-product-verification` for the same provider and market;
runtime source-authority projection accepts receipt schema v1 through v3 during
migration. A collection receipt must decode as the canonical collection
verification kind and revalidate against its current source receipt and
platform Published lock. Exact-SKU collection authority requires a v2-or-v3
source receipt. Reject absolute paths, `..`, nested paths, missing files, and every
other input family.

The provider build plugin declares all five Published files and all six fixed
approval inputs unconditionally. It reads the approval receipt only to add
paths that pass the same strict dynamic-path syntax check:

```swift
let inputs = publishedFive
  + requiredApprovalInputs
  + safelyParsedSourceVerificationInputs
  + safelyParsedCollectionVerificationInputs
```

The runtime tool must still repeat path, file-kind, scope, and hash validation;
the plugin list is a rebuild dependency, not authority. Test drift with Swift
Testing by changing a fixed input, deleting one, adding an unsafe approval key,
and changing an approved source-verification receipt after publication.

## Implementation Checklist

- Resolve hosts and paths from Published operation policy.
- Treat generated `path` as the stable client path and Published `wirePath` as
  the upstream path. A gateway operation may intentionally use different
  values.
- Inject only headers, cookies, query values, and body fields proven by
  evidence.
- Apply `encodedQueryBodyNames` and `encodedBodyFieldNames` only when declared
  by the operation policy. Move the generated logical JSON body through that
  exact wire name and remove superseded entity headers when the final request
  has no entity body.
- Normalize a wire response media type only through
  `responseContentTypeAliases`. For example, `text/json` may be decoded by a
  generated `application/json` response only when that exact alias is
  Published.
- Normalize JSONP only when the reviewed operation publishes an explicit
  `responseExtraction` with `kind: jsonP` and either an exact `callback` or the
  owned request `callbackQueryName`. The latter models callbacks whose sequence
  suffix varies per request; middleware must validate the response against the
  callback on the actual prepared request. The evidence receipt retains the raw
  wire string; Trusted fixtures and generated response DTOs describe the
  extracted JSON payload. JSONP normalization is not business-success
  classification: non-success `ret` values and `bxpunish` challenge headers
  must fail verification before codegen.
- Extract an inline JavaScript JSON assignment only when the reviewed operation
  publishes `responseExtraction.kind: javascriptAssignmentJSON` with one exact
  variable path. The extractor ignores quoted/commented lookalikes, requires a
  unique balanced object or array, and rejects payloads that are not strict
  JSON. Provider middleware implements the same Published policy; it must not
  hand-write a provider-specific regex.
- Treat protocol signing-token bootstrap, account session acquisition,
  account refresh, authenticated business, and logout as distinct lifecycle
  actions. A short protocol token may be issued anonymously and still leave
  the account operation challenged.
- Publish a token-bootstrap operation only when evidence proves both the
  expected response Cookie names and a correctly re-signed successful retry.
  Keep subsequent account validation as a separate required gate.
- Retry an authenticated request at most once after a successful refresh.
- Fail closed when a required environment, seller identity, SKU identity, or
  session value is absent.
- Preserve a generated-client transport boundary so fixtures can test request
  construction without live network access.
- Keep mutation identity at the remote platform's real granularity.
- Keep selected-platform source authority separate from remote collection
  authority. Product/SKU/current-fact reads may use source authority; remote
  list/add/delete require both source authority and a current reversible
  collection receipt. Shared platform account status/login/logout remains
  independent of both gates.
- Add decode fixtures and request-shape tests for every Published operation.
- Keep Published freshness validation in the provider-owned projection and
  declare every safe approval input in its provider-owned build plugin.

## Anti-Patterns

- A generic middleware that guesses provider headers.
- A feature target constructing an endpoint URL.
- Reusing the generated client path as a gateway wire path without consulting
  `wirePath`.
- Hard-coding `data`, `body`, JSONP, or media-type exceptions because another
  operation from the provider used them.
- Treating every 401 as a refresh-token operation.
- Treating a renewed protocol signing token as proof of account login.
- Filling a Wishlist mutation with product-level data when the remote API is
  SKU-level.
- Falling back to another seller or provider when identity validation fails.
- Hiding an unsupported capability behind an empty successful response.
- Treating a valid Published lock as sufficient after an approval input has
  changed, or moving freshness checks into a shared runtime/plugin package.
