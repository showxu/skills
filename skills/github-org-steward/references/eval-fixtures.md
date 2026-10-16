# Eval fixtures

Organization-only behavioral inputs. Run outputs, transcripts and benchmark data
belong in the producer-owned ignored workspace, outside this package.

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
- Keep unresolved rollout work in hand-maintained lists or file issues without authorization.

Acceptance checks:

- One tracking issue in `.github` records the decision, waves, member checklist, standard revision, consumer run and current member acceptance. Member PRs reference it; member issues exist only for member-specific decisions. Close the tracking issue after acceptance.

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
