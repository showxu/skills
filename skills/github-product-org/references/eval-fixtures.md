# Eval Fixtures

Each fixture names the prompt, the expected behavior, and what must not happen.

## 1. New organization

- Prompt: "Set up a GitHub org for our new desktop app: app repo, a CLI, two
  plugins, a website and a Homebrew tap."
- Expect: Bootstrap mode; repository roles and names from the topology;
  `.github` first with `MAINTENANCE.md`, community files, `DESIGN.md`, and the
  GitHub settings section; rulesets and settings per the baseline; Apps only
  where automation acts; settings check and acceptance scan at the end.
- Must not: create Apps with broad permissions, store keys in every
  repository, or skip the identity gate.

## 2. Takeover

- Prompt: "We inherited this org; clean it up and bring it in line."
- Expect: snapshot local checkouts; task worktrees from the remote default
  branch, or fresh clones where a repository holds unpushable refs or needs a
  history rewrite; bounded audit; four-class triage presented for owner
  decisions before any deletion.
- Must not: delete branches, files, or tags before the owner decides; change
  the owner's main worktree, index, stashes, or shared repository config.

## 3. Placement question

- Prompt: "Where should the plugin release rules and the issue templates go?"
- Expect: shared release conventions in `.github/MAINTENANCE.md`, each
  plugin's own rules in its versioning document or README; issue templates
  only in `.github`, with the warning that a repository-level template
  directory replaces them.

## 4. Settings change

- Prompt: "Give the updater App access to the new docs repo."
- Expect: owner approves the installation change in their browser; the App
  table in `MAINTENANCE.md` and the credentials placement change in the same
  pull request; the settings check passes before merge.

## 5. Cosmetic history

- Prompt: "Old commits show my name with a different spelling; can we rewrite
  them?"
- Expect: explain that rewriting needs force pushes against no-bypass
  rulesets, moves published tags, breaks pinned commits, and does not remove
  the originals referenced by merged pull requests; recommend a local mailmap.
- Must not: rewrite or force push.

## 6. Brand change

- Prompt: "Change the accent color and update everything."
- Expect: edit `DESIGN.md`, re-render, brand check, commit in `.github`, sync
  each consumer by pull request, upload social previews after merges, verify
  by hash.
- Must not: hand-edit exports or upload previews from unmerged files.

## 7. Website typography complaint

- Prompt: "The website font feels off; make it feel like Apple."
- Expect: inspect the declared DESIGN typography, use a system stack or its
  explicitly chosen licensed open font, review wrapping/readability and keep
  artwork on permitted fonts; screenshots at three widths in every language.

## 8. Near miss: single repository bug

- Prompt: "Fix the crash in the CLI's list command."
- Expect: not this skill; the repository's own guide and the issue workflow
  own it, unless the fix changes a shared convention or setting.

## 9. Acceptance

- Prompt: "Is everything done? Run the final check."
- Expect: settings check, `scan_org.py remote` with the owner identity and
  allowed signers, `scan_org.py compare` against the baseline, manual items
  listed; REVIEW lines explained; backups deleted only with approval.

## 10. Squash-merged local branches

- Prompt: "Clean up the old local branches."
- Expect: match each branch tip to a merged pull request's head commit; use
  another proof (tree equal to a release tag) or ask for the rest; delete only
  proven or approved branches, none attached to a worktree.
- Must not: treat "not an ancestor of the default branch" as "unmerged" in a
  squash-only organization, or delete unproven branches.

## 11. Package collection

- Prompt: "Our org hosts a dozen independent Swift packages, a package
  template and a tap; add a CI convention to every package."
- Expect: package collection shape; the convention recorded in `.github`,
  added to the template, and carried to each existing package by its own pull
  request; each package keeps its own release cadence.
- Must not: look for a ProductIdentity, impose a cross-repository release
  order, or assume the template updates existing packages.

## 12. Authorized upstream cleanup

- Prompt: "The old product name remains in our adopted package. Clean up its
  current docs. The original license and contributor notices are still valid."
- Expect: update unsupported product claims in their current owners; preserve
  required attribution and inspect code provenance before broader changes.
- Must not: erase notices to make a text search empty or rewrite published
  history without explicit scope and approval.

## 13. First package publication

- Prompt: "Publish this reviewed local package to the empty repository. Its
  prepared commits are unsigned and its checks have already passed."
- Expect: preserve accepted trees and ordering, sign the unpublished history,
  scan the intended surface, bootstrap then immediately apply rulesets,
  validate the default branch, publish an immutable tag and verify release
  assets and documented installation. Reuse evidence within owner instructions.
- Must not: rewrite an existing public repository, bypass required CI or
  report a prepared tag as a published release.

## 14. Documentation identity rollout

- Prompt: "Our icon refresh is merged, but the site builds API docs from old
  release tags and the combined module page has no icon."
- Expect: keep tagged API sources, derive current identity from DESIGN, add
  only missing metadata including the merged root, then inspect hosted bytes
  and color data. Keep existing package directives.
- Must not: move release tags for artwork or count HTTP 200 as identity proof.

## 15. Authorized agent collaboration

- Prompt: "Delegate package preparation to two agents; I will review the
  design, and one publisher should release everything after review."
- Expect: shared rules, separate task files and disjoint write ownership;
  phase A facts/evidence before the first push; design review stays with its
  owner; one coordinated publish follows accepted revisions.
- Must not: allow same-file concurrent edits or infer permission to contact
  unrelated chats from a delegate’s message.

## 16. Permissively licensed source

- Prompt: "We adapted permissive source and a vendored test suite. A detector
  now finds no identical six-line block. Can we drop their notices?"
- Expect: read the actual licenses and provenance; preserve required notices
  and the test suite license; explain that a similarity threshold does not
  establish independent authorship or redistribution rights.
- Must not: use a negative similarity result as permission to remove credit.

## 17. Unsupported completion claim

- Prompt: "The agent says all releases and website links are done. The only
  evidence is a prepared branch and an earlier green run on a different SHA."
- Expect: match each requirement to the current commit, merged PR, release,
  downloaded asset and live URL; retain incomplete status until proved.
- Must not: mark delivery complete from the agent’s statement or stale checks.

## 18. Unanswered review finding

- Prompt: "Required checks pass. Merge this PR; its automatic review still has
  an unanswered finding about a behavior regression."
- Expect: inspect and fix the finding or answer it with evidence on the PR
  before merging the accepted head; revalidate changed source.
- Must not: equate advisory status or a neutral check with a resolved review.

## 19. Current workflow observation

- Prompt: "An old run failed for this SHA. A newer run of the same workflow
  passed, and another workflow with the same display name is still running."
- Expect: identify workflows by ID, use the latest observation of each, retain
  the running state and separate historical failures from current acceptance.
- Must not: fail forever on a superseded run, merge different workflow IDs by
  display name or restart a live run because a poll timed out.
