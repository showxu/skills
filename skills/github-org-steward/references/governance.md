# Organization governance

## Shared standard

The organization's `.github` contains data and documents, including signing and
PR-title rules, exception lists and the settings declaration. It carries no
scripts and only thin workflow callers. Required member checks are `policy`
and `validate`.

The family `github-workflows` owns source-policy checkers, the organization
check, ecosystem validation/release workflows and their scripts. The organization
check runs through `.github` CI, compares membership and About completeness,
and checks declared settings against live state. It reads the declaration and
records the enforced `.github` revision. Parameters that differ per repository
come from those members. Never copy a reference checker and merely replace an organization constant.

The organization owner chooses shared default-branch policy, review policy,
release identity and supported enforcement. `github-repo-steward` applies and
audits those choices for each member; it owns local signing, branch/tag
rulesets, merge settings, CI baseline and community inheritance. Shared workflow
interfaces need syntax checks, fixture-package tests and one representative
member run at the exact candidate before rollout. Require real emitted check
contexts before making them mandatory; update the organization
declaration when caller configuration changes. The ecosystem release skill
owns the shared CI job catalog, member format and defaults; organizations and
repositories may extend them. Validation always runs format, tests and release
build; platforms, docs and demo are declared options. Render/check profiles and
images locally and commit outputs. CI checks only the demo recording through
the validation workflow's `demo` switch.

Organization Actions defaults use least privilege, normally a read token and
no workflow approval of PRs. Record any chosen exception in the shared
MAINTENANCE declaration and verify both organization state and affected member
reports. Never retrieve secret contents for an audit.

Reviewer configuration follows the owner's actual choice: installation scope,
provider trigger preferences and an applicable real PR are separate evidence.
Record explicit deferrals rather than claiming the App enabled review. Canonical
review-rule format belongs to `repository-docs`; templates derive it and members
adopt through their repository steward.

## Choose the smallest automation

Ask what event and write capability the workflow needs before provisioning
credentials. For infrequent releases, prefer read-only scheduled detection and
a narrowly scoped issue-notice job; normal signed PRs then perform updates.
Deduplicate notices by stable release identity, checking open and closed items.
Do not push directly to a protected default branch. Dependabot remains the
owner of dependency update proposals.

If unattended cross-repository writes are actually required and authorized,
use a narrowly scoped GitHub App. Do not create an App, private key or secret
as an incidental part of a notifier. GitHub token-trigger behavior changes;
check the current [workflow trigger contract](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)
and the organization's accepted settings. Never assume workflow-token PRs will
run unattended; current cases can require approval.

## Scoped GitHub Apps

For an authorized App:

- Name the capability, exact operations and permission set. Install only on
  repositories where it acts. Separate notification from content updates when
  their permission/installation scopes differ.
- Token requests state permissions and the owner/repository selection explicitly,
  so later App permission expansion does not silently expand a workflow token.
- No webhook subscriptions or user authorization flow unless the capability
  requires them. Store credential identifiers and locations in MAINTENANCE,
  never their values. Use organization secrets only for the scope that needs
  them, with an explicit repository selection.
- The owner performs passkeys, App setup, permission increases and installation
  changes in their own browser. Never extract credentials or write a private
  key into a transcript or disposable script.
- When App-authenticated API commits are intended to be GitHub-verified, inspect
  `verification.verified` and `reason` for the actual commit; do not assume an
  App token signs arbitrary local `git commit` output. GitHub’s
  [bot-signature contract](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#signature-verification-for-bots)
  requires App/bot authentication without custom author, committer or signature
  fields for that API verification path.

Keep an App table with capability/name, permissions, installation selection,
credential names and storage scope. Change it in the same reviewed operation as
live state. A skipped installation-repository lookup needs owner/browser
evidence, not a conformance claim. Never broaden a personal token to hide a
read-access gap.

## Drift and acceptance

The shared settings check reports enforced differences separately from
observations such as shared pin lag. Pin updates proceed through consumer PRs.
Unavailable metadata remains unknown. Aggregate each repository steward's
report with the organization declaration; partial scanner success cannot prove
complete organization conformance.
