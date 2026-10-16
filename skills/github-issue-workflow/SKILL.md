---
name: github-issue-workflow
description: File a well-formed issue in its owning repository when work is discovered for later, or land any change through a merged, test-backed GitHub pull request, with or without an issue, then clean up and optionally tag a release. Use for fixing or implementing a GitHub issue, opening or merging a pull request, repository commit and signing conventions, branch naming including issue-linked branches, test-first fixes, pull request hygiene, diagnosing failing CI check runs, post-merge branch cleanup, and issue-driven release tags. Do not use for release readiness audits without a change to land, store or package-manager publishing, or repositories hosted outside GitHub.
---

# GitHub Issue Workflow

## Purpose

File one actionable problem in its owning repository, or land any change
through a minimal, test-backed GitHub pull request, with or without an issue:
sync, repository conventions, branch, failing test, fix, pull request, green
CI, merge, cleanup, and an optional release tag.

## When To Use

- Work is discovered for later and needs a well-formed issue in its owning
  repository.
- The user asks to fix, implement, or close a GitHub issue.
- Any change needs to land through a GitHub pull request, with or without an
  issue, including opening or merging a pull request.
- A pull request has failing CI checks that need diagnosis and a root-cause
  fix.
- A merged pull request needs local sync and branch cleanup.
- The user wants an issue fix released as a new tag.

## When Not To Use

- Release readiness audits or version/tag consistency checks without a change
  to land; use the ecosystem's release skill, such as `swiftpm-github-release`
  for Swift packages, when installed.
- App Store, TestFlight, notarization, codesigning, or package-manager
  publishing.
- Repositories hosted outside GitHub.

## Inputs To Inspect

- Change request, issue text when present, related pull requests, and the base
  branch.
- Git status, branch, and remotes.
- The build manifest, such as `Package.swift`, and the tests around the
  affected code.
- Repo-local CI workflows, Makefile tasks, and contribution docs for the
  validation commands the repository already uses.
- Current check runs on the pull request head.

## Filing an issue

1. Choose the repository whose code, documentation or settings would change.
   Organization-wide work goes to the tracker designated for shared standards.
   Work with no GitHub owner is not an issue; hand it to its named owner.
2. Search open and closed issues and pull requests first. Add evidence to an
   existing issue instead of duplicating it.
3. Keep one actionable problem per issue. The title states the problem or
   wanted outcome, using the repository's title convention when it has one.
4. Use the effective issue form or template, local or inherited from the
   owner's defaults. Include current behavior or state, expected outcome,
   reproducible evidence (commands, versions, links), the decision needed and
   who makes it, and how completion will be checked.
5. Public issues contain no machine-local paths, private identifiers,
   credentials, private conversations or unpublished plans. Report
   vulnerabilities through the repository's private vulnerability reporting,
   never as a public issue.
6. Use only labels, issue types and assignees the repository already uses.
   Link related issues and pull requests.
7. Read the issue back after filing and report its URL.

## Workflow

1. Sync and baseline:
   - `git fetch --prune origin`
   - `git switch <base-branch>`, then `git pull --ff-only`
   - collect the change request, issue text when present, PR state, changed
     files, and current CI checks.
   - before the first commit, read `CONTRIBUTING`, `MAINTENANCE`, or equivalent
     repository rules and follow their commit subject, pull-request title,
     signing, and merge method conventions.
   - when no commit or pull-request title convention is declared, use
     Conventional Commits. With squash merging, the pull-request title becomes
     the commit subject on the default branch and must carry that convention.
   - configure signing only in the repository (`git config --local`), never
     globally, and verify signatures as the repository requires.
   - land changes through pull requests; push directly to the default branch
     only when the repository's rules explicitly allow it.
2. Branch and scope:
   - use the repository's branch convention. Without one, use `<type>/<slug>`,
     or `<type>/issue-<id>-<slug>` when there is an issue.
   - branch names carry no tool, agent, or vendor names.
   - `<type>` is one of `fix`, `feat`, `docs`, `ci`, `refactor`, `chore`,
     `release`.
   - `<slug>` is lowercase kebab-case, usually 3 to 6 words.
   - Examples: `fix/issue-3-non-swift-output`,
     `docs/issue-12-readme-swift-version`, `ci/macos-latest-swift-testing`.
   - Keep one clear objective per PR unless the user asks for bundling.
3. Test first:
   - add or adjust a failing test, or a reproducible failing check, before the
     fix;
   - implement the minimal fix;
   - validate with the repository's CI or Makefile commands when present;
     otherwise use the ecosystem's test command, such as `swift test` plus
     `swift build` for SwiftPM, and script self-tests when the change needs
     them.
4. Pull request:
   - `git push -u origin <branch>`
   - open or update the PR with a clear summary, the validation commands and
     their outcomes. Add `Resolves #<id>` only when there is a linked issue.
5. CI stabilization:
   - inspect check runs with
     `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`;
   - read failures with `gh run view <run-id> --job <job-id> --log-failed`;
   - patch only the failing root cause, rerun local validation, and push fix
     commits;
   - when the user prefers an infrastructure fix over a code fallback, update
     the CI runner or toolchain explicitly and state the rationale in the PR.
6. Merge:
   - after all required checks pass and every review thread is resolved, merge
     using the repository's declared method, pinned to the reviewed head SHA
     (`--match-head-commit` with GitHub CLI).
   - if the head changes, check and review the new head before retrying.
   - for a squash merge, use the pull-request title as the subject and follow
     the repository's commit-body rule. For an empty-body rule:
     `gh pr merge <number> --squash --match-head-commit <sha> --subject '<PR title>' --body ''`.
7. Merge cleanup:
   - confirm the PR is merged;
   - fast-forward the local base branch to the remote head;
   - delete the working branch locally and on the remote.
8. Release tag, only when the user asks for a release:
   - run the ecosystem's release readiness check when one exists, such as
     `swiftpm-github-release` for Swift packages, when installed;
   - align release-facing metadata first, such as README version tables,
     dependency examples, and manifest version fields like the
     `Package.swift` tools-version;
   - after the user's confirmation, create and push the tag exactly as the
     repository's release procedure declares, including name, message and
     signing. Only when no procedure is declared, use an annotated tag:
     `git tag -a <version> -m "Release <version>"`, then
     `git push origin <version>`.

## Decision Rules

- Keep changes minimal and test-backed.
- Prefer non-interactive git commands.
- Treat CI failures as first-class: reproduce, patch, and re-verify.
- Use the hosted GitHub integration for reads. When its writes are denied,
  for example with HTTP 403, check `gh auth status`, authenticate with
  `gh auth login -h github.com -p ssh -w` if needed, and continue with `gh`.

## Safety Rules

- Never use destructive recovery such as `git reset --hard` unless the user
  explicitly requests it.
- Do not push tags or publish releases without explicit confirmation.
- On branch-protected repositories, record any protection bypass in the final
  summary.

## Output Format

For filing only, report the issue URL, owning repository and duplicates checked.

End with an exit checklist:

```text
GitHub Issue Workflow: <owner>/<repo>

- Issue: #<id> / none
- Local validation: <commands> -> pass / fail
- PR: <url>, title and body complete
- Required checks: green / pending / failed
- Review threads: resolved / <unresolved count>
- Base branch: synced to <sha>
- Working branch: deleted locally and remotely
- Tag: <version> pushed / not requested
- Protection bypasses: none / <events>
```

## Failure / Uncertainty Handling

- If the repository is not hosted on GitHub, stop and say this skill does not
  apply.
- If a validation command fails, report the command and its first actionable
  failure rather than the full log.
- If CI fails for reasons unrelated to the change, report them separately
  instead of folding unrelated fixes into the PR.

## Validation

Use `references/eval-fixtures.md` to review issue-optional entry, repository
conventions, and merge gates when changing this workflow.
