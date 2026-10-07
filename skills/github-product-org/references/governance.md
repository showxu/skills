# Governance

## Identity and Signing

- Every commit and tag from the owner uses one name and one noreply email and is
  SSH-signed. Tool identities and attribution trailers never appear.
- `scripts/configure-clone.sh` sets identity, SSH signing, allowed signers,
  `gh` as the HTTPS credential helper, and installs `scripts/prepush-check.sh`
  as the pre-push hook. Run it on every fresh clone before the first commit.
  A task worktree gets the same values through `git config --worktree`
  (`references/operations.md`), so the owner's shared config stays unchanged.
- The gate checks only commits not yet on a remote. Commits GitHub creates
  (squash merges, API commits from Apps) are signed by GitHub and show as
  Verified.
- GitHub shows the account linked to a commit email, not the commit's author
  name. Variant author names under the same email are cosmetic; fix the local
  display with a mailmap, never by rewriting history.

## Default Branch

- Rename with `gh api -X POST repos/<org>/<repo>/branches/<old>/rename -f
  new_name=<new>`; GitHub retargets pull requests and branch protections.
- Each local clone then needs `git branch -m <old> <new>`, `git fetch origin`,
  `git branch -u origin/<new> <new>`, `git remote set-head origin -a`. Ask
  before touching the owner's checkouts.
- Forks keep upstream names; a fork's default branch is its maintained release
  branch.

## Rulesets

One repository ruleset named `default branch` per public repository:

- target `~DEFAULT_BRANCH`, enforcement active, no bypass actors;
- rules: `deletion`, `non_fast_forward`, `required_signatures`,
  `pull_request` with `allowed_merge_methods: [squash]` and zero required
  approvals for a single-owner organization, `required_status_checks` listing
  the stable policy and validation results plus the applicable brand check.

Pitfalls:

- Required check names must match job names exactly; a reusable workflow job
  appears as `<caller job> / <called job>`, for example `brand / brand`.
- Organization rulesets and rulesets on private repositories need a paid plan.
- Rename a required job and every pull request blocks until the ruleset
  follows; change both in one sitting.

## Repository and Actions Settings

- `allow_squash_merge` true, merge commits and rebase off,
  `delete_branch_on_merge` true; `allow_auto_merge` where automation proposes
  changes.
- Workflow token default `read`, `can_approve_pull_request_reviews` false, at
  repository and organization level. The organization value is what new
  repositories inherit.
- Each workflow declares `permissions:`; actions are pinned to full commit
  SHAs with the version in a comment; Dependabot updates them weekly.

## GitHub Apps

Use an App, not the workflow token or a personal token, when a workflow must
write or trigger another workflow:

- A pull request opened with the workflow token does not trigger checks without
  manual approval, and `git commit` in a workflow is unsigned. An App token
  opens pull requests whose checks run, and commits created through the API
  with it are signed by GitHub.
- One App per capability. Typical pair: a Release Notifier with
  `actions: write` installed only on the website, used by plugins to dispatch
  the website's deploy workflow; an Updater with `contents: write` and
  `pull_requests: write` installed only on the repositories it updates.
- No webhook events, no user authorization flow.
- Each token step requests explicit `permission-*` inputs and, across
  repositories, explicit `owner` and `repositories`, so a later permission
  increase on the App does not widen what workflows receive.
- Store `<PREFIX>_APP_CLIENT_ID` as a variable and `<PREFIX>_APP_PRIVATE_KEY`
  as a secret only in repositories that use them. No organization-level
  secrets unless every repository needs them.
- Permission increases and installation changes require the organization
  owner's approval; App and installation settings pages require sudo or a
  passkey, so the owner completes them in their own browser.
- Blast radius of a leaked key equals the App's installation permissions;
  rulesets still block merging anything that fails checks.

## Drift Declaration and Check

- `MAINTENANCE.md` has a "GitHub settings" section: prose for merge and
  workflow-token settings and the ruleset requirement, and an App table with
  columns App, Permissions, Installed on, Credentials, Stored in.
- `Scripts/check-settings.py` in `.github` parses that section and compares it
  with the live organization through the owner's `gh` login: organization and
  repository workflow-token settings, Actions secrets and variables at both
  levels, merge settings, every public repository's ruleset, App installations
  (permissions, events, selection). Copy it from the reference organization and
  change its organization constant.
- A change to a setting, App, or credential updates the section in the same
  pull request, and the check runs before merge.
- GitHub lists an installation's repositories only to a personal access token,
  not to the `gh` OAuth login; the check reports that it skipped them, and the
  owner compares them on the installation page.

## Token Scopes

The `gh` login needs `repo`, `workflow` (to push workflow files), and
`admin:org` (organization settings and installations). Reading Actions secret
names needs repository admin. If a push touching `.github/workflows/` is
rejected for missing `workflow` scope, the owner refreshes the login; pushing
over SSH with the owner's key also works.

## Release Tags and Bootstrap

Protect the declared release tag pattern, normally `v*`, against update and
deletion. Sign new annotated tags and verify the remote peeled commit. Keep
published legacy lightweight tags unchanged outside an authorized rewrite.

A new repository starts with reviewed source and a signed unpublished history.
Push the accepted initial history to the empty repository, immediately install
branch and tag rulesets, then require PRs for subsequent changes. Validate the
default branch before the first release. Preserve original trees, ordering and
ownership when re-signing unpublished history.

## Required Policy and Early Feedback

The organization’s reusable policy job checks commit identity and signatures,
attribution trailers, publication content and version consistency. Scan paths
and bytes safely, including non-ASCII filenames. Keep legitimate product names,
source notices and scanner fixtures distinct from leaked agent working state.
Required checks are stable aggregators that fail when a dependency fails or is
cancelled; use `always()` and explicit result checks where needed. Activate a
new required name only after the consuming workflow emits it successfully.

The pre-push hook reuses repository-owned commands rather than maintaining a
second content policy. Configure `CONTENT_CHECK` and `FAST_CHECK` with
`configure-clone.sh`; they become local `org.contentCheck` and `org.fastCheck`
Git settings. The content command receives each new commit as shell positional
argument `$1`; it must inspect that commit for workstation paths, internal
working folders and prohibited attribution, including the repository’s declared
exceptions for legitimate source material. The fast command runs once against
the clean checked-out candidate. Both must succeed; missing configuration fails
with an actionable setup error. These local checks do not replace required CI.

## Automatic Review

Connect each public repository to the reviewer and enable automatic review on
every PR. For Codex, open its Code review settings and enable Automatic review
for the repository; select All PRs and the intended update trigger. Following
personal preferences only works when those preferences actually enable review.
Verify a real latest PR, not just the installation switch.

Rules live in `AGENTS.md`. Their format is owned by
[repository-docs](../../repository-docs/rules/code-review-rules.md); language
adapters and the package template derive that source and sync repositories by
PR. This skill configures the reviewer; it does not duplicate the rule format.
Use `templates/MAINTENANCE.md.tpl` to declare reviewer, scope and trigger.
Fix or answer findings on the PR before merging. Record an explicit owner
deferral as a deviation, without weakening required checks.

For a blocking variant, an organization may adopt
[openai/codex-action](https://github.com/openai/codex-action) as a required job.
It needs an API key and a defined severity policy; false positives can block
merges. Enable it as a deliberate owner decision.

Other supported choices include Claude Code Review, the lighter
[anthropics/claude-code-action](https://github.com/anthropics/claude-code-action),
Cursor Bugbot and GitHub Copilot. Claude’s hosted review is available to Team
and Enterprise and is billed separately by token usage; its neutral conclusion does not block
a merge. A custom severity gate must inspect the review output and distinguish
a completed review from a failed or timed-out one. Tool-specific instruction
files import or derive the canonical rules under the documentation owner’s
contract. Recheck provider eligibility and billing before enabling a service.

Manual checks: inspect `gh api orgs/<org>/installations`, confirm repository
selection and inspect actual review evidence on each latest applicable PR.
GitHub installation metadata does not expose the reviewer’s automatic-trigger
preferences or prove a review completed.

Sources: [Codex GitHub review](https://learn.chatgpt.com/docs/third-party/github),
[Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md),
[Claude Code Review](https://code.claude.com/docs/en/code-review).
