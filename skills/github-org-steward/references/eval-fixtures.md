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

Acceptance checks:

- The rollout records the standard revision, a consumer run, explicit adoption rows and current member acceptance.

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
