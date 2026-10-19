# Eval fixtures

Durable inputs for qualitative review or isolated paired evals. Results stay in
the producer-owned ignored eval workspace, outside this package.

## personal-repository

Target behavior: personal repository.

Input prompt: "Set up the GitHub side of my personal repository, example-owner/parcel. It has no organization and no standard yet."

Context and files:

- `evals/files/personal.json`; no organization .github exists; empty fixture repository.

Expected output:

- A personal repository uses explicit overridable defaults, records whether issues are accepted and community files are inherited or local, and routes local community-file text to the documentation owner.

Forbidden behavior:

- Invent organization policy or copy another project’s branch, paths, license or colors.

Acceptance checks:

- The authority record says personal defaults; settings, community, CI and presentation are covered; any missing legal choice is owned by the user.
- Issue forms render on the new-issue page and use `.github/ISSUE_TEMPLATE/config.yml`. Their fields collect the issue workflow's required content; filing and working issues route to that workflow.

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

## ecosystem-readme-boundary

Target behavior: ecosystem README boundary.

Input prompt: "Redo the README first screen of example-team/swift-parcel, a Swift package, with badges and a Quick look."

Context and files:

- No checked-in package; a qualitative routing case. The organization's
  DESIGN defines the header, badge style and section order. Compiling the
  Quick look against a published tag is the ecosystem skill's own check.

Expected output:

- Route Swift facts to swiftpm-readme with the repository, accepted
  revision and the section skeleton of the README layout; use its reported
  badge values, Install line and snippet check result; hand the information
  set and the applicable DESIGN to github-readme-design for the header, badge
  styling, navigation, layout and images; keep settings and uploads here.

Forbidden behavior:

- Type badge values or a version by hand, present an unchecked Swift snippet
  as working, or hand the first-screen layout, cards or demos to the
  ecosystem skill.

Acceptance checks:

- The response names swiftpm-readme as the source of badge values, the
  Install requirement and the snippet check, and github-readme-design with
  DESIGN as the owner of layout and styling.

Baseline expectation:

- A presentation skill may derive Swift facts from memory, or an ecosystem
  skill may impose its own header and section order.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## installed-product-readme

Target behavior: installed product README facts.

Input prompt: "Redo the README of example-team/parcel-cli, a Swift command-line tool with an MCP server, distributed through our Homebrew tap and release archives."

Context and files:

- No checked-in product; a qualitative routing case. The organization's
  DESIGN defines the first screen, and the tool has a recorded session.

Expected output:

- Take the Homebrew line from homebrew, release download and checksum steps
  from the release skill, the commands shown from cli-creator checked against
  the released --help, MCP client configuration from mcp-server-patterns, and
  build-from-source and Swift badge values from swiftpm-readme; hand
  the information set and DESIGN to github-readme-design for layout and the
  light/dark terminal demo; show only channels that exist.

Forbidden behavior:

- Type install lines, asset names or command options from memory, or route
  every product fact to the language skill.

Acceptance checks:

- The response names an owner for each install channel, the command
  reference and the MCP configuration, and github-readme-design with DESIGN
  for layout and styling.

Baseline expectation:

- A presentation skill may copy install commands from another project, or a
  language skill may assert distribution channels it does not own.

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

## accepted-history-audit

Target behavior: accepted history audit.

Input prompt: "Audit example-owner/parcel. Its head is verified, but an ancestor is unsigned with subject “Initial import”. The release set has a lightweight tag, an unsigned annotated tag and an SSH tag whose verification service is unavailable."

Context and files:

- Captured accepted ancestry and tag objects; published identities are immutable.

Expected output:

- Report each commit signature and Conventional subject result, both tag-type/signature mismatches and the unsupported verification as unknown. Bind tag targets and coverage to exact SHAs; seek legacy dispositions without rewriting history.

Forbidden behavior:

- Declare conformance from the verified head, skip tag checks without a signer file, or rewrite legacy commits/tags.

Acceptance checks:

- Every accepted commit and advertised tag has evidence; unknown verification remains unknown and published objects stay unchanged.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## reusable-pin-audit

Target behavior: reusable pin audit.

Input prompt: "Audit reusable-workflow pins. A flow-style job calls a full older SHA, another uses a floating branch, the shared default is stable/next, and one shared repository lookup fails."

Context and files:

- Accepted workflow YAML includes a shell decoy uses line and a local workflow call.

Expected output:

- Parse job-level callers, resolve the actual shared default branch, report path/job/observed/expected/source for each external caller, floating-ref drift and lookup unknowns. Local calls bind to the accepted source; disposition pin lag by the applicable standard.

Forbidden behavior:

- Match shell text as a caller, assume main/master, silently repin, or treat lookup failure as clean.

Acceptance checks:

- All real callers appear with explicit drift/unknown evidence and no remote mutation.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## release-workflow-invariants

Target behavior: release workflow invariants.

Input prompt: "Audit our release caller and reusable jobs. A setup action enables a dependency cache and concurrency uses cancel-in-progress: false in a shared group with a single pending slot."

Context and files:

- Release validation, packaging and publication are in scope, including transitive calls.

Expected output:

- Report both release cache use and pending-run replacement; prepare cache-free fresh build paths and capacity-safe queuing or dispatch with no cancelling group.

Forbidden behavior:

- Accept release caching because PR caching is measured, or infer no cancellation from cancel-in-progress: false alone.

Acceptance checks:

- The complete release call graph has no restore/save operations or automatic running/pending cancellation.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## private-member-profile-scope

Target behavior: Apply the correct standard subset to a private member-profile repository.

Input prompt: "Bring our private .github-private repository into conformance with the organization standard."

Context and files:

- Shared standard available; generated dashboard inputs, CI and private-plan enforcement evidence supplied.

Expected output:

- Apply settings, rulesets, signing and CI, including the profile byte check. Review the member dashboard through its renderer, with policy linked to .github.

Forbidden behavior:

- Require a product README first screen, social card or inherited community files for this repository role; duplicate policy in the dashboard.

Acceptance checks:

- Conformance report marks those presentation/community rows inapplicable and verifies the applicable controls with evidence.

Baseline expectation:

- A product-repository audit can add irrelevant public presentation or copied community defaults.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.
