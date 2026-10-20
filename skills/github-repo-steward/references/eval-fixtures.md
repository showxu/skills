# Eval fixtures

Durable inputs for qualitative review or isolated paired evals. Results stay in
the producer-owned ignored eval workspace, outside this package.

## default-versioning-first-release

Target behavior: Establish the default policy for an unpublished first release.

Input prompt: "Prepare root versioning policy and a local release PR candidate for my personal repository parcel. I want its first public release to be 0.1.0. It has no versioning standard. Its VERSION file says 0.8.4, which was never tagged or published. There are no mirrors; MAINTENANCE.md#publication owns its release checks and mechanics. Do not publish."

Context and files:

- A personal repository with no shared standard; the version source, absence
  of mirrors, release owner and unpublished state are supplied in the prompt.

Expected output:

- Render root `VERSIONING.md` from the shared template with the supplied
  repository values. Prepare `0.1.0` in the version source and changelog,
  leaving an empty `## Unreleased` above `## 0.1.0`.

Forbidden behavior:

- Treat the never-tagged, never-published number as a release floor, invent
  mirrors or ecosystem commands, narrate old manifest numbers in the changelog,
  or publish tags/assets during local preparation.

Acceptance checks:

- The common policy equals the template after filling its six placeholders;
  the version source and changelog agree on `0.1.0`.
- A new repository defaults to tag name `vX.Y.Z`; the tag message uses the
  supplied repository name and version.
- The policy covers signed annotated immutable tags, the repository-specific
  tag message, squash merge, remote peeled-commit verification and tag/source/
  changelog agreement. All mutations stay local.

Baseline expectation:

- A version-number-only workflow may reject `0.1.0` or invent release policy
  instead of resolving published identity and the template owner.

Evidence sources:

- Rendered policy, version source, changelog, executor report and command trace.

Owner notes:

- Repository name, paths and version numbers are synthetic fixture inputs.

## default-version-increments

Target behavior: Apply the default version increments before and after 1.0.

Input prompt: "Our two repositories use the steward's default version policy. One is at 0.4.2 and the other at 1.4.2. For each, determine the next version for three independent candidates: a breaking change, a new feature, and a fix. The 0.x breaking candidate removes a documented flag immediately, without prior deprecation or a planned release cadence. The 1.x breaking candidate belongs to the owner's planned yearly major. Prepare the release plan only."

Context and files:

- Both current versions are tagged and published. The candidates are
  independent alternatives, not a sequence of releases.

Expected output:

- For `0.4.2`, propose `0.5.0` for the breaking change and `0.4.3` for each
  new feature or fix. No deprecation window or release cadence is required
  during initial development; minor-bounded dependencies exclude the break.
- For `1.4.2`, propose `2.0.0` for the planned major, `1.5.0` for the new
  feature and `1.4.3` for the fix. Announce the major's removals in the
  changelog beforehand and include upgrade instructions.

Forbidden behavior:

- Require deprecation or planned-major cadence during 0.x, apply the 1.0+
  feature increment during 0.x, bump PATCH for a breaking 0.x change, reuse a
  tagged version, omit the planned major's advance notice or upgrade guidance,
  or execute publication.

Acceptance checks:

- All six choices follow the phase-specific rules and reset less significant
  components correctly. The plan binds source, mirrors, changelog and tag to
  the chosen version without changing remote state.

Baseline expectation:

- A generic SemVer summary may leave 0.x unspecified or impose the 1.0+
  minor increment for a compatible addition.

Evidence sources:

- Release plans, proposed changelog entries and executor report.

Owner notes:

- Versions and candidate changes are case-local inputs.

## stable-interface-release

Target behavior: Start the compatibility promise by the owner's decision.

Input prompt: "Two libraries use the steward's default version policy and are at 0.8.4. For one, the owner confirms that its interface is stable and promises compatibility. The other adds a compatible feature, with no stability decision from its owner. Determine the next version for each and prepare the release plan only."

Context and files:

- Both current versions are published. Only the first owner has made the
  stability and compatibility commitment.

Expected output:

- Plan `1.0.0` for the library with the owner's stability decision and
  `0.8.5` for the initial-development feature release.
- Apply the compatibility promise and roughly yearly planned-major policy
  from `1.0` onward; the other library remains under the 0.x rules.

Forbidden behavior:

- Infer a compatibility promise from feature size or a version number, impose
  the 1.0+ cadence on the second library, or publish.

Acceptance checks:

- The version choices depend on the owner's explicit stability decision;
  `1.0.0` resets the lower components and the 0.x feature increments PATCH.

Baseline expectation:

- A generic feature-based bump may omit the owner's transition decision or
  apply stable-interface obligations before the promise begins.

Evidence sources:

- Version choices, release plans and executor report.

Owner notes:

- Versions and the two owners' decisions belong to this case.

## interface-change-in-place

Target behavior: Evolve a documented interface through addition and deprecation.

Input prompt: "Our CLI is at 1.4.2 and uses the steward's default version policy. Published tags use X.Y.Z. In the next release, replace the documented --config flag with --settings and remove --config immediately. We have not announced a deprecation, and this release is outside our planned yearly major. Prepare the release plan only."

Context and files:

- The current flag is a documented interface. This is a single requested
  change outside the planned major; release planning is authorized.

Expected output:

- Keep `--config` working, add `--settings` compatibly and plan `1.5.0` for
  the addition and deprecation. Record the deprecation in the changelog.
- Preserve the published `X.Y.Z` tag format. Put eventual removals in a
  planned major on the roughly yearly cadence, with advance changelog notice
  and upgrade instructions.

Forbidden behavior:

- Remove or change the old flag in this release, trigger an immediate major
  for the single request, switch tags to `vX.Y.Z`, or publish.

Acceptance checks:

- The next-release plan supports both flags and uses the compatible-feature
  increment; its changelog records the deprecation.
- Removal belongs only to a planned major whose removals are announced
  beforehand, with the published tag format retained.

Baseline expectation:

- A version-bump-only workflow may call the requested removal breaking and
  schedule `2.0.0` without first preserving existing usage.

Evidence sources:

- Release plan, compatibility and deprecation steps, and executor report.

Owner notes:

- Flag names, current version and published tag format belong to this case.

## planned-major-feature-release

Target behavior: Allow a significant feature release at a planned major.

Input prompt: "Our library is at 1.4.2 and uses the steward's default version policy. The owner has scheduled its roughly yearly major, covering a significant suite of features with no interface removals. May the planned release use 2.0.0? Prepare the release plan only."

Context and files:

- This is an owner-planned major containing a significant feature suite,
  rather than an immediate release triggered by one change.

Expected output:

- Permit `2.0.0` for the planned significant feature release and preserve
  interface compatibility. Keep single feature changes outside planned majors
  on the MINOR path.

Forbidden behavior:

- Require an interface break to justify every major, cut an immediate major
  because of one feature, or publish.

Acceptance checks:

- The plan permits a significant feature major on the declared cadence and
  resets both lower components, without inventing removals or deprecations.

Baseline expectation:

- A breaking-change-only interpretation may reject a planned significant
  feature major or manufacture a break to justify it.

Evidence sources:

- Release plan, proposed notes and executor report.

Owner notes:

- The current version and owner's scheduled feature suite are case inputs.

## regenerated-output-change

Target behavior: Classify a value change by whether consumers must change usage.

Input prompt: "Our two organization standards use the steward's default version policy and are at 0.4.2 and 1.4.2. An accepted DESIGN value update changes rendered colors. Members only regenerate their assets; token names, workflow inputs and outputs, and caller contexts stay the same. Determine each next version and prepare the release plan only."

Context and files:

- The accepted design values are inputs; this case asks for version selection,
  not a visual decision. The two candidates are independent.

Expected output:

- Treat the value/output change as compatible and propose `0.4.3` and `1.5.0`.
  Describe the regeneration in release notes without calling it a breaking
  interface removal.

Forbidden behavior:

- Bump to `0.5.0` or `2.0.0` solely because outputs change, require a
  deprecation for the value update, invent design values, or publish.

Acceptance checks:

- Both choices follow the phase-specific feature rules; the rationale
  identifies unchanged consumer usage rather than unchanged generated bytes.

Baseline expectation:

- An output-difference rule may label regeneration breaking or apply a
  separate organization version-level scheme.

Evidence sources:

- Version choices, proposed notes and executor report.

Owner notes:

- Versions and the accepted color update are case-local inputs.

## existing-version-policy

Target behavior: Preserve a repository's declared 0.x version interpretation.

Input prompt: "Plan the next release of my personal repository at 0.4.2. Its existing VERSIONING.md requires a MINOR increment for a compatible addition during 0.x. This candidate adds a compatible feature."

Context and files:

- No organization standard applies. The repository's current policy is
  explicit and the task does not authorize changing it.

Expected output:

- Use the declared policy to propose `0.5.0`; keep the repository's policy
  authoritative and identify its version source and release owner before
  preparing release artifacts.
- Still apply the steward's baseline release hygiene the policy does not
  state: one version source, a CHANGELOG with Unreleased, a signed annotated
  immutable tag and remote peeled-commit verification.

Forbidden behavior:

- Replace the existing policy with the template, impose its default 0.x
  PATCH increment on this repository, or drop baseline release hygiene because
  the declared policy omits it.

Acceptance checks:

- The plan cites the existing policy for the increment and preserves it;
  missing source/owner facts remain identified rather than invented.
- The plan keeps one version source, an Unreleased changelog section, a signed
  annotated tag and remote peeled-commit verification.

Baseline expectation:

- A newly introduced default may accidentally override existing 0.x policy.

Evidence sources:

- Policy comparison, release plan and executor report.

Owner notes:

- This policy is a fixture-owned override, not a reusable default.

## github-defined-paths

Target behavior: Preserve GitHub's recognized paths and presentation behavior.

Input prompt: "Review our proposed .github directory and explain which paths GitHub recognizes before we apply it."

Context and files:

- A proposed directory inventory has `issue-template/config.yaml`, root-level
  `FUNDING.yml`, a `.github/README.md` intended only as an asset index, and
  a committed social-preview PNG that has not been uploaded. A reusable
  workflow has both local and remote callers. The repository root README is
  the intended landing page; review-only scope.

Expected output:

- Cite GitHub's rules before local conventions; identify the exact issue
  template/config and funding paths, README precedence, the Settings upload
  requirement and which workflow references Dependabot can update.

Forbidden behavior:

- Treat locally chosen names as GitHub-recognized, claim the PNG is served
  because it is committed, or change the repository during a review.

Acceptance checks:

- The report names `.github/ISSUE_TEMPLATE/config.yml` and
  `.github/FUNDING.yml`, explains that `.github/README.md` takes precedence,
  and distinguishes local workflow references from remote `uses:` pins.
- Official links support the findings and no upload or mutation is claimed.

Baseline expectation:

- A generic file tidy-up may normalize away GitHub's exact names or miss
  that committing a preview does not upload it.

Evidence sources:

- Executor report, cited sources and command trace.

Owner notes:

- The proposed paths are case-local mistakes; GitHub defines the corrections.

## presentation-asset-layout

Target behavior: Apply the same asset placement across languages and owners.

Input prompt: "Plan presentation asset placement for my standalone Swift CLI and our organization's Python library. Their accepted design inputs are attached."

Context and files:

- The CLI has repository-owned DESIGN and metadata; the library consumes the
  organization's DESIGN and catalog. Both have accepted icons and README
  information; the CLI has a session to demonstrate. Planning is authorized.

Expected output:

- Use `.github/assets/` in both repositories, with kind directories and
  appearance filenames from the asset contract. Keep the standalone DESIGN
  and `design/` at root, and the member's shared design authority in its
  organization. Hand asset production to the README-design owner.

Forbidden behavior:

- Choose language-specific presentation paths, copy organization DESIGN into
  the member, invent design values, or give the library a terminal demo.

Acceptance checks:

- Both plans place logos and social previews in their kind directories; only
  the CLI has `terminal/script.yml`, `recording.json` and terminal SVGs.
- The report explains the GitHub-facing, language-neutral placement and links
  to the product-kind and production contract rather than duplicating it.

Baseline expectation:

- An ecosystem-specific setup may impose its documentation directory or
  create a second member design authority.

Evidence sources:

- Placement plans, handoff and executor report.

Owner notes:

- Languages and ownership models are fixture inputs; placement is shared.

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
