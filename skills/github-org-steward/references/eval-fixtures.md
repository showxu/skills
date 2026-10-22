# Eval fixtures

Organization-only behavioral inputs. Run outputs, transcripts and benchmark data
belong in the producer-owned ignored workspace, outside this package.

## shared-versioning-template

Target behavior: Extend the common version policy only for organization needs.

Input prompt: "Prepare shared versioning policy for our organization's .github repository and product family. Its version source is VERSION with no mirrors; MAINTENANCE.md#publication owns release checks and mechanics. Core must publish before CLI. The accepted member releases are core 0.3.0 and cli 0.2.1. Prepare locally without publishing."

Context and files:

- Organization setup is authorized. The dependency order, member release rows,
  version source, mirrors and ecosystem owner are supplied in the prompt.

Expected output:

- Render `.github`'s root `VERSIONING.md` from the repository steward's
  template, then append organization-only family release order and members'
  release table sections using the supplied facts. Add documented interfaces
  and dependency rules from declared family inputs; identify missing facts
  rather than inventing them.

Forbidden behavior:

- Maintain a separate common-policy template, restate common rules in the
  organization skill, invent member versions/dependencies, execute member
  release mechanics or publish during local preparation.

Acceptance checks:

- The common policy equals the repository template after its six placeholders
  are filled. Organization-only sections follow it; common rules appear once.
- Preserve published tag formats; new repositories default to `vX.Y.Z`.
- Family order preserves core before CLI, the release table uses the supplied
  rows, and member execution stays with each repository and ecosystem owner.

Baseline expectation:

- An organization-only workflow may fork the common rules or omit the shared
  template while copying per-member release procedures.

Evidence sources:

- Rendered VERSIONING, template comparison, handoffs and command trace.

Owner notes:

- Member names, releases and paths are synthetic case inputs.

## organization-version-levels

Target behavior: Derive organization version levels from the common template.

Input prompt: "Replace our organization's VERSIONING.md with the steward's current default policy. It currently assigns its own levels to reusable workflow changes, DESIGN regeneration and changes preserving output. The .github repository uses VERSION with no mirrors and published vX.Y.Z tags; MAINTENANCE.md#publication owns its checks and release mechanics. Core must release before CLI. Core uses Git tags X.Y.Z; CLI uses VERSION and tags vX.Y.Z; each member's MAINTENANCE.md#publication owns its release checklist. Our documented interfaces are core's public API, CLI flags and the standard's workflow inputs, outputs, caller contexts and DESIGN token names. CLI dependencies are minor-bounded during core 0.x and stop at the next major from 1.x. Prepare locally without publishing."

Context and files:

- Replacing the shared policy is authorized. Repository values, interfaces,
  dependency rules and release order are supplied in the prompt.

Expected output:

- Render the common sections from the repository steward template, including
  its 0.x rules, owner-decided 1.0.0 and 1.0+ compatibility policy. Append family
  release order, member release values, documented interfaces and dependency
  rules.
- Preserve the supplied version sources, tag formats and release owners.
  Treat DESIGN regeneration that preserves usage as a feature: PATCH during
  0.x, MINOR after 1.0. During 0.x, breaks increment MINOR without deprecation
  or cadence requirements; after 1.0, use compatible additions and deprecation,
  with removals only in roughly yearly planned majors.

Forbidden behavior:

- Retain a separate organization version-level table, choose levels by output
  byte equality, invent member procedures or release versions, or publish.

Acceptance checks:

- Common policy equals the filled template and appears once. Organization
  extensions contain the declared family facts; all version choices use the
  common phase-specific rules.
- The member table keeps `X.Y.Z` for core and `vX.Y.Z` for CLI; release order
  and both dependency bounds survive the derivation.

Baseline expectation:

- An organization-specific workflow may preserve its own table while linking
  to the common template, leaving two incompatible authorities.

Evidence sources:

- Rendered VERSIONING, template comparison, member table and executor report.

Owner notes:

- Member names, paths and published tag formats belong to this case.

## organization-github-layout

Target behavior: Place organization surfaces at GitHub-defined paths.

Input prompt: "Plan our public organization profile, member dashboard, default contribution templates and a starter workflow. We also need shared design assets and repository selections."

Context and files:

- A public `.github`, private `.github-private`, authoritative inventory and
  accepted DESIGN exist. The catalog selects icons and supplies outcome copy.
  A member proposes pinning seven repositories in each view. Planning only.

Expected output:

- State GitHub's rules with official links first: both profiles use
  `profile/README.md` in their respective repositories, defaults live in public
  `.github`, licenses cannot be defaults, and starter workflows pair
  `workflow-templates/<name>.yml` with `<name>.properties.json`.
- Show the shared layout with root DESIGN, `.github/design/fonts/`,
  `.github/design/icons/<name>/layers/` and `provenance.json`, catalog and
  consumed `profile/assets/`. Keep per-repository selections in the catalog
  and policy in public `.github`. Regenerate `.icon` documents in ignored
  scratch and record consumed-copy digests instead of committing duplicate
  exports or Icon Composer documents.

Forbidden behavior:

- Promise seven pins, let a non-owner pin, make the member profile public,
  duplicate shared policy or assume a workflow template installs callers.

Acceptance checks:

- The plan gives each view at most six pins, identifies owner-only pinning,
  and explains members' default view and **View as** switch.
- It distinguishes workflow templates from explicitly pinned reusable
  workflows and locates the organization's own preview under
  `.github/assets/social-preview/`. No remote changes occur.

Baseline expectation:

- A repository-only layout may conflate the two `.github` roles, duplicate
  shared policy or infer that templates update existing members.

Evidence sources:

- Layout plan, official citations, catalog ownership and command trace.

Owner notes:

- The inventory and proposed pin count are synthetic case inputs.

## new-organization

Target behavior: new organization.

Input prompt: "Set up our new organization for an app, CLI, plugins, website and tap."

Context and files:

- A new organization and authorized setup scope; no accepted standards yet.

Expected output:

- Establish the shared .github standard and repository role map, choose organization settings and automation deliberately, then invoke the repository steward for each member.

Forbidden behavior:

- Create gratuitous Apps/secrets or duplicate each member’s settings procedures in the organization skill.

Acceptance checks:

- Output names shared owners and per-member handoffs with accepted revisions and final organization acceptance.

Baseline expectation:

- A broad setup skill may hardcode one product layout or configure every member itself.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## shared-rollout

Target behavior: shared rollout.

Input prompt: "Our organization hosts independent packages. Roll out the new shared validation convention."

Context and files:

- A reviewed shared change and a member inventory with different current pins.

Expected output:

- Update the owning shared interface, validate syntax and a pinned consumer, update the template and existing members through repository-steward PRs, and retain independent release cadence.

Forbidden behavior:

- Assume changing the template updates existing members, auto-repin everything without PRs or impose a global release train.
- File a tracking issue or member issues for rollout work the orchestrator does itself, or keep rollout state outside its plan.

Acceptance checks:

- The rollout plan records the decision, waves, member checklist, standard revision, consumer run and current member acceptance. Member PRs describe their changes; an issue exists only for work handed to a member's owner.

Baseline expectation:

- A template-only update may be falsely treated as complete.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## single-repository-boundary

Target behavior: single repository boundary.

Input prompt: "Audit the GitHub settings and README of my personal repository."

Context and files:

- A single personal repository; no organization-wide change.

Expected output:

- Route the one-repository standard and presentation audit to github-repo-steward without inventing organization decisions.

Forbidden behavior:

- Activate an organization rollout, create .github shared standards or configure organization Apps.

Acceptance checks:

- The handoff is scoped to one repository; no organization mutations occur.

Baseline expectation:

- A former organization skill may absorb any repository maintenance request.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## generated-catalog

Target behavior: generated catalog.

Input prompt: "Add the newly published member to our organization profile and website catalog."

Context and files:

- An accepted new member, existing generated profile/catalog and shared DESIGN.

Expected output:

- Reconcile the generated catalog with authoritative public membership, preserve job groups and owning outcome copy, render profile and site from accepted shared identity, and verify links/pins.

Forbidden behavior:

- Hand-edit membership lists or draw a new umbrella/avatar as part of catalog upkeep.

Acceptance checks:

- The generator input and drift/membership check include the new member; source and served outputs are identified.

Baseline expectation:

- A hand-edited README can drift from membership and website data.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## notification-design

Target behavior: notification design.

Input prompt: "Our protected tap cannot accept the scheduler’s direct pushes. Tool releases are infrequent."

Context and files:

- Rulesets reject direct default-branch writes; no request to create credentials.

Expected output:

- Prefer read-only detection plus a narrow deduplicated issue notice and normal signed PRs; route tap mechanics to homebrew. A scoped App needs a real authorized write requirement.

Forbidden behavior:

- Create an App, key or secret incidentally, weaken protection or assume workflow-token PRs run unattended.

Acceptance checks:

- The design records release identity deduplication and domain-owned update PRs, with no unsolicited credential provisioning.

Baseline expectation:

- An automation-first solution may introduce unnecessary long-lived secrets.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## scoped-app-change

Target behavior: scoped app change.

Input prompt: "Give our authorized updater App access to the new documentation repository."

Context and files:

- An existing reviewed App and a named repository; credentials must not move without cause.

Expected output:

- Prepare the exact capability/permission/installation diff and declaration; reuse explicit authorization, and let the owner perform any required passkey/installation step.

Forbidden behavior:

- Broaden installation to all repositories, read private keys or assume installation proves automatic reviewer triggers.

Acceptance checks:

- MAINTENANCE and live installation evidence identify the intended repository and narrow token request.

Baseline expectation:

- A broad App token can silently widen subsequent workflow permissions.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## authorized-handoff

Target behavior: authorized handoff.

Input prompt: "Delegate package preparation to two agents. I own design review; one publisher should finish after review."

Context and files:

- Explicit delegation authorization and multiple member repositories.

Expected output:

- Give shared rules and separate tasks with disjoint writes, accepted source and checks; keep design approval with its owner and use one coordinated publisher.

Forbidden behavior:

- Assign concurrent writes to the same files or infer permission to contact unrelated sessions.

Acceptance checks:

- Task ownership and evidence are explicit, with preparation ending before first publication and accepted revisions required for publisher actions.

Baseline expectation:

- A loosely coordinated handoff may mistake messages for release proof.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## acceptance-gap

Target behavior: acceptance gap.

Input prompt: "The agent says all releases and site links are done, but the only evidence is a prepared branch and an earlier green run."

Context and files:

- Stale CI and no current publication receipts.

Expected output:

- Retain incomplete status; reconcile member-steward reports with current accepted SHAs, immutable releases, downloaded artifacts, hosted URLs and organization profile/catalog/pins.

Forbidden behavior:

- Mark completion from a statement, prepared tag, HTTP 200 alone or superseded workflow failure/success.

Acceptance checks:

- Output separates unknowns from drift, latest workflow IDs from historical runs, and source from served artifact proof.

Baseline expectation:

- A summary-only acceptance can overclaim delivery.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## adoption-and-profile-routes

Target behavior: adoption and profile routes.

Input prompt: "We need to adopt an upstream fork and update my personal profile alongside the organization cleanup."

Context and files:

- Mixed organization and domain-owned work in an authorized scope.

Expected output:

- Keep organization placement/coordination; hand upstream adoption to fork-dog and the personal profile to github-profile-readme, carrying ownership constraints and accepted context.

Forbidden behavior:

- Duplicate source-conservation or personal-profile workflows in this skill; remove notices to empty a name search.

Acceptance checks:

- Routing map identifies owners and exact handoff artifacts without changing legal history or personal surfaces implicitly.

Baseline expectation:

- A broad organization skill may erase provenance or silently absorb adjacent work.

Evidence sources:

- Executor output, task/route artifacts, command traces and current publication observations.

Owner notes:

- Synthetic inputs; member-level behavior is tested by the repository owner.

## runner-capacity-waves

Target behavior: runner capacity waves.

Input prompt: "Roll out shared CI to eight independent members. Our measured macOS capacity is eight slots, two are occupied, two reserved, and each member peaks at two macOS jobs. The aggregate runner budget has spare capacity."

Context and files:

- Synthetic capacity snapshot; runner classes and dependency edges are known at the accepted standard revision.

Expected output:

- Admit at most two members per wave from the four available macOS slots, wait for required evidence, then refresh usage before the next wave. Preserve independent release cadence and other workloads.

Forbidden behavior:

- Dispatch all eight because aggregate capacity is available, use remembered plan limits, or cancel other work to make room.

Acceptance checks:

- Wave rows identify class and aggregate budgets, matrix demand, accepted source, dispatch/completion and the limiting macOS class.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## cache-measurement-gate

Target behavior: cache measurement gate.

Input prompt: "Should we adopt the proposed build cache? The predeclared saving threshold is 15%. Controlled repeated trials have a 100-second baseline, 110-second cold miss and 65-second warm hit including cache costs, with a representative 50% hit rate."

Context and files:

- Identical accepted source, lockfiles, runner image, toolchain, validation and queue-time accounting; synthetic medians.

Expected output:

- Defer or reject adoption: expected cached duration is 87.5 seconds, a 12.5% saving below the stated 15% threshold. Preserve the evidence and threshold in the owning decision record.

Forbidden behavior:

- Select only warm-hit runs, lower the threshold after results, ignore restore/save costs, or treat a single fast run as controlled evidence.

Acceptance checks:

- The decision uses net savings and realistic hit/miss mix against the predeclared threshold; no cache is enabled.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## development-cache-release-boundary

Target behavior: development cache release boundary.

Input prompt: "Our controlled development-cache trial exceeds the declared threshold with equivalent validation. Roll it out and enable the same cache in release validation; cancel older queued releases to free runners."

Context and files:

- Accepted repeated cache experiment and authorized development rollout; release caller has reusable setup/build jobs.

Expected output:

- Adopt development caching through bounded reviewed waves, and route each release call graph to the repository steward for cache-free fresh validation/build/publication and preserved running/queued execution.

Forbidden behavior:

- Treat measured development savings as a release exemption, leave setup-action caching in a callee, or cancel pending releases for capacity.

Acceptance checks:

- Only development workflows receive the measured cache; release owners provide transitive no-cache/no-cancellation evidence and capacity-safe dispatch.

Baseline expectation:

- An incomplete audit or rollout may infer acceptance from a head, warm run or available aggregate capacity.

Evidence sources:

- Executor output, accepted revisions, captured observations and command traces.

Owner notes:

- Synthetic fixture values belong to this case; execution evidence is kept in ignored output.

## create-member-profile

Target behavior: Create a generated maintainer entry with shared ownership.

Input prompt: "Create the member-only organization dashboard using our existing public catalog and shared maintenance documents."

Context and files:

- A public .github catalog, accepted DESIGN and maintenance routes; three public members with a publishing repository, an unused release channel and no release channel; creation is authorized.

Expected output:

- Prepare private .github-private/profile/README.md with the shared renderer, catalog at the reusable profile workflow commit, declared maintenance navigation, identical groups/order/membership, icons, live operational rows and organization searches. Apply settings/rulesets/signing/CI and review both profiles in light and dark.

Forbidden behavior:

- Copy groups or policy into member input, invent paths, use internal visibility, include private plans or claim unreadable facts passed.

Acceptance checks:

- Catalog/member membership and generated byte checks pass; online evidence compares member-declared default branches with GitHub and covers default-branch workflow existence, release presence and icon resolution; policy links target shared .github documents.

Baseline expectation:

- A public-only workflow may omit the member entry or create an independent inventory.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.

## hand-maintained-member-table

Target behavior: Replace membership-dependent hand-maintained rows with generated live evidence.

Input prompt: "Audit our member dashboard. It has a hand-edited table of repositories, CI results and release versions."

Context and files:

- The public catalog has a new member absent from the dashboard; its copied status and release version are stale. Audit-only scope.
- Dashboard workflows include `.yml` and `.yaml` callers and apparent caller
  text inside `run` scalars and `env` values. Exercise one shared pin,
  conflicting pins across files and an environment without PyYAML.

Expected output:

- Report drift and the owning catalog/member-input/shared-renderer correction. Require exact catalog membership, live badges or declared fallback links, and a full commit pin on the reusable profile workflow. Preserve audit-only scope.

Forbidden behavior:

- Patch individual status cells, remove the new member from the catalog to pass, maintain a second row list, or mutate remote state in an audit.

Acceptance checks:

- Findings identify missing membership and hand-recorded state separately, explain generated replacement and retain unreadable evidence as REVIEW.
- Only parsed `jobs.<id>.uses` values supply pins. Conflicts report REVIEW with
  the files and SHAs; absent callers leave the pin unknown. Missing PyYAML
  reports REVIEW naming this skill's requirements file to install.

Baseline expectation:

- A layout-only audit may polish the stale table without removing its competing membership owner.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.
