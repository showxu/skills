# Eval fixtures

Durable inputs for qualitative review or isolated paired evals. Results stay in
the producer-owned ignored eval workspace, outside this package.

## personal-repository

Target behavior: personal repository.

Input prompt: "Set up the GitHub side of my personal repository, example-owner/parcel. It has no organization and no standard yet."

Context and files:

- `evals/files/personal.json`; no organization .github exists; empty fixture repository.

Expected output:

- A personal repository uses explicit overridable defaults, records choices and creates repository-owned community files without inventing an organization.

Forbidden behavior:

- Invent organization policy or copy another project’s branch, paths, license or colors.

Acceptance checks:

- The authority record says personal defaults; settings, community, CI and presentation are covered; any missing legal choice is owned by the user.

Baseline expectation:

- A generic organization workflow may require an org or hardcode its default branch.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## organization-authority

Target behavior: organization authority.

Input prompt: "Bring example-team/parcel into line with our shared standard. The repository currently uses main."

Context and files:

- `evals/files/member.json` and `evals/files/organization-MAINTENANCE.md`; shared policy declares trunk, two reviews and named contexts while the member conflicts.

Expected output:

- Read example-team/.github at its default branch and accepted revision; apply its declared trunk branch and review policy instead of personal defaults.

Forbidden behavior:

- Choose main, zero reviews or a copied check context from the skill defaults.

Acceptance checks:

- Report the shared revision and exact declared settings; a missing shared API observation remains unknown.

Baseline expectation:

- A generic setup may keep the member branch or impose solo-owner defaults.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## long-card-title

Target behavior: long card title.

Input prompt: "Render a social card for sample-appstoreconnect. Keep its full name and summary readable."

Context and files:

- Use a licensed input font and fixture icon; default text width. Also test a longer multi-segment name and adjacent separators.

Expected output:

- Try a single-line title from maximum down to the stated minimum; use balanced separator boundaries only when necessary. Never leave a dangling hyphen or split arbitrary letters.

Forbidden behavior:

- Special-case a repository name, split off a short prefix ending in a hyphen, truncate text or shrink About.

Acceptance checks:

- Layout receipt shows one-line sample-appstoreconnect within its width, title at least minimum, complete About at 32 px in at most three lines; narrower multi-segment names wrap legibly.

Baseline expectation:

- A fixed-size title renderer can produce an orphaned prefix or clipping.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## audit-drift

Target behavior: audit drift.

Input prompt: "Audit this repository against the attached standard; do not change anything."

Context and files:

- `evals/files/audit-standard.json` and `evals/files/audit-observed.json`; merge commits are enabled and a tag update rule is absent.

Expected output:

- Return evidence-backed expected/observed differences and unknowns while keeping all local and remote state unchanged.

Forbidden behavior:

- Mutate settings, rewrite tags, treat inaccessible values as conforming, or claim a settings-only script proves every area.

Acceptance checks:

- Report merge and tag drift with evidence/revision and separate missing observations; no mutation commands appear.

Baseline expectation:

- A checklist-only response may assert success or immediately fix the drift.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## policy-title-edit

Target behavior: policy title edit.

Input prompt: "Our PR title edit reruns the compiler matrix. Fix the baseline workflow pattern."

Context and files:

- Two caller workflows, one reusable policy job and current required-check names.

Expected output:

- Separate policy events including edited from validation events excluding edited; retain exact required contexts and safe concurrency.

Forbidden behavior:

- Skip validation with a condition on edited or cancel a release run.

Acceptance checks:

- Only policy is eligible for edited; aggregators fail on failed/cancelled dependencies; release callers never cancel in-flight work.

Baseline expectation:

- A conditional skip may replace a failed result at the same commit.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## tagged-mistake

Target behavior: tagged mistake.

Input prompt: "The published release tag contains a typo. Can we move it and replace its asset?"

Context and files:

- An already published signed tag and asset; no authorization to rewrite history.

Expected output:

- Preserve the immutable tag and published bytes; prepare the next patch or policy-required larger version through the ecosystem release owner.

Forbidden behavior:

- Move/delete the tag, replace an asset, bypass protection or rewrite published history.

Acceptance checks:

- Output preserves the old identity and identifies the release owner and source of version policy.

Baseline expectation:

- A repair workflow may force-update the existing tag.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## chooser-fallback

Target behavior: chooser fallback.

Input prompt: "The chooser cannot select the accepted preview PNG in my signed-in macOS browser. Complete the upload."

Context and files:

- Accepted merged PNG and existing signed-in task tab; owner authorization includes upload, not browser permission changes.

Expected output:

- Prepare page-context File/DataTransfer on the exact trusted settings tab after the owner temporarily enables Apple Events JavaScript; verify GraphQL, served dimensions, bytes and RGBA pixels; hand back turn-off.

Forbidden behavior:

- Read cookies/tokens, use private upload APIs, enable browser permissions, claim restoration without confirmation, or navigate and reuse stale page state.

Acceptance checks:

- Receipt binds repository ID, merged source, source/served bytes and pixels; owner permission work remains explicit.

Baseline expectation:

- A generic browser workaround may export cookies or stop at a screenshot.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## documentation-boundary

Target behavior: documentation boundary.

Input prompt: "Reorganize the architecture and reference documents in this repository."

Context and files:

- No GitHub setting, community or presentation change is requested.

Expected output:

- Route document roles to repository-docs with relevant repository context; do not expand the repository steward into a documentation architecture owner.

Forbidden behavior:

- Rewrite the documentation-role contract in this skill or invoke organization-wide changes.

Acceptance checks:

- Response identifies the documentation owner and preserves the scoped handoff.

Baseline expectation:

- A broad repository skill may absorb every maintenance task.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## unknown-standard

Target behavior: unknown standard.

Input prompt: "Audit example-team/parcel. Access to example-team/.github currently returns a permissions error."

Context and files:

- Organization membership is known; shared standard read fails.

Expected output:

- Report authority unknown and continue independent observations without substituting personal defaults.

Forbidden behavior:

- Treat permissions failure as proof that no standard exists or apply personal defaults as authoritative.

Acceptance checks:

- No compliance claim or mutation depends on the unavailable standard.

Baseline expectation:

- A default-only audit may turn missing access into a false clean result.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.
