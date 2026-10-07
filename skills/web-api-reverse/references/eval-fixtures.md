# Evaluation Fixtures

## Trigger Fixtures

1. "Inspect this logged-in storefront and produce an auditable OpenAPI
   contract." Expected: use this skill; separate private capture, Observed,
   Trusted, and Published.
2. "Review whether our reverse-engineered Wishlist mutation is safe to
   codegen." Expected: use this skill; require SKU/request evidence and a
   reversible restoration receipt.
3. "Implement auth headers for this provider from its published operation
   policies." Expected: use this skill for evidence interpretation, then keep
   middleware in the provider package.

## Boundary Fixtures

1. "Write a normal client for a documented public API." Expected: do not force
   browser discovery or the evidence pipeline.
2. "Make Playwright the production transport." Expected: reject the design;
   Playwright is capture/login guidance, not normal runtime.
3. "Automatically trust every successful captured request." Expected: reject;
   trust is explicit semantic review.
4. "Put the user's Chrome cookies into API/Observed." Expected: reject and
   keep credentials in private runtime state.

## Validation Fixtures

1. Published is missing `approval-receipt.json`. Expected: validation fails.
2. A Published file hash differs from `publish-lock.json`. Expected:
   validation fails.
3. A Published JSON file contains a bearer token or phone number. Expected:
   scan and publish fail.
4. A reversible mutation receipt has different before/restored hashes.
   Expected: the operation is ineligible for publication.
5. Required source has unknown operations. Expected: zero-unknown claim fails
   without deleting or deferring the source.
6. Published claims `selected-platform-current-facts` but
   `Observed/source-verifications/` is empty or the receipt fingerprint is not
   in the approval-bound source lock. Expected: canonical validation fails.
7. Approval claims `selected-platform-current-facts` or
   `selected-platform-identity` without hashing every required canonical
   source-verification receipt. Expected: approval/publication fails.
8. A required source-verification receipt is removed or byte-tampered after
   publication, or its hash is removed from the Published approval and the
   publish lock is recomputed. Expected: canonical validation fails.
9. Published cites an operation verification that exists only as an ID in
   `catalog.json` or under legacy `Observed/verification/`. Expected: strict
   coverage and canonical validation fail with plural-directory guidance.
10. A provider changes `Trusted/openapi.yaml` after publication without a new
    approval. Expected: provider-owned runtime projection exposes no operation
    policy even when the Published lock still matches Published bytes.
11. Approval omits one canonical input hash or names `../outside.json`, an
    absolute path, or `Observed/verifications/*.json`. Expected: provider-owned
    projection fails closed.
12. Approval names a canonical source-verification receipt that is missing,
    byte-drifted, symlinked, or scoped to another provider/market. Expected:
    provider-owned projection fails closed.
13. A provider build plugin omits a canonical approval input or an approved
    safe source-verification receipt from `inputFiles`. Expected: integration
    review fails because incremental builds can retain stale projection output.

## Good Output Shape

The agent reports:

- source revisions and coverage boundary
- operation classification and evidence ids
- Trusted versus unsupported capabilities
- exact Published artifacts
- provider middleware owner
- validation and reversible-write status

It never reports raw credentials or claims completeness beyond the locked
sources.
