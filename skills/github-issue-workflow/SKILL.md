---
name: github-issue-workflow
description: Take a GitHub issue from triage to a merged, test-backed pull request, then clean up and optionally tag a release. Use for fixing or implementing a GitHub issue, issue-linked branch naming, test-first fixes, pull request hygiene, diagnosing failing CI check runs, post-merge branch cleanup, and issue-driven release tags. Do not use for release readiness audits without an issue to land, store or package-manager publishing, or repositories hosted outside GitHub.
---

# GitHub Issue Workflow

## Purpose

Run one GitHub issue through a minimal, test-backed change: sync, branch,
failing test, fix, pull request, green CI, merge cleanup, and an optional
release tag.

## When To Use

- The user asks to fix, implement, or close a GitHub issue.
- A pull request has failing CI checks that need diagnosis and a root-cause
  fix.
- A merged pull request needs local sync and branch cleanup.
- The user wants an issue fix released as a new tag.

## When Not To Use

- Release readiness audits or version/tag consistency checks without an issue
  to land; use the ecosystem's release skill, such as `swiftpm-github-release`
  for Swift packages.
- App Store, TestFlight, notarization, codesigning, or package-manager
  publishing.
- Repositories hosted outside GitHub.

## Inputs To Inspect

- Issue text, linked pull requests, and the base branch.
- Git status, branch, and remotes.
- The build manifest, such as `Package.swift`, and the tests around the
  affected code.
- Repo-local CI workflows, Makefile tasks, and contribution docs for the
  validation commands the repository already uses.
- Current check runs on the pull request head.

## Workflow

1. Sync and baseline:
   - `git fetch --prune origin`
   - `git switch <base-branch>`, then `git pull --ff-only`
   - collect the issue text, PR state, changed files, and current CI checks.
2. Branch and scope:
   - issue-linked: `<prefix>/<type>/issue-<id>-<slug>`; without an issue id:
     `<prefix>/<type>/<slug>`.
   - `<prefix>` is the repository's existing agent branch prefix, otherwise
     the running agent's name, such as `codex`, `cursor`, or `claude`.
   - `<type>` is one of `fix`, `feat`, `docs`, `ci`, `refactor`, `chore`,
     `release`.
   - `<slug>` is lowercase kebab-case, usually 3 to 6 words.
   - Examples: `codex/fix/issue-3-non-swift-output`,
     `codex/docs/issue-12-readme-swift-version`,
     `codex/ci/macos-latest-swift-testing`.
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
     their outcomes, and `Resolves #<id>` for the linked issue.
5. CI stabilization:
   - inspect check runs with
     `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`;
   - read failures with `gh run view <run-id> --job <job-id> --log-failed`;
   - patch only the failing root cause, rerun local validation, and push fix
     commits;
   - when the user prefers an infrastructure fix over a code fallback, update
     the CI runner or toolchain explicitly and state the rationale in the PR.
6. Merge cleanup:
   - confirm the PR is merged;
   - fast-forward the local base branch to the remote head;
   - delete the working branch locally and on the remote.
7. Release tag, only when the user asks for a release:
   - run the ecosystem's release readiness check when one exists, such as
     `swiftpm-github-release` for Swift packages;
   - align release-facing metadata first, such as README version tables,
     dependency examples, and manifest version fields like the
     `Package.swift` tools-version;
   - after the user's confirmation, create and push an annotated tag:
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

End with an exit checklist:

```text
GitHub Issue Workflow: <owner>/<repo>#<id>

- Local validation: <commands> -> pass / fail
- PR: <url>, title and body complete
- CI: green / documented exceptions
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
