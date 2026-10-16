# Workflow Fixtures

## pull-request-without-issue

Target behavior: Land a change without requiring an issue.

Input prompt: "Fix the broken documentation link and open a pull request."

Context and files:

- A GitHub repository has no linked issue and no declared commit, title, or
  branch convention. Its validation command is available.

Expected output:

- Use the pull-request workflow, Conventional Commit subjects and titles, and
  a `<type>/<slug>` branch with a lowercase kebab-case slug.
- Include validation results in the pull request and report `Issue: none`.

Forbidden behavior:

- Require or invent an issue, add a closing keyword without an issue, include
  a tool, agent, or vendor name in the branch, or push to the default branch
  without explicit repository permission.

Acceptance checks:

- The pull request has no issue-closing line; the final checklist identifies
  the repository and pull request without inventing an issue number.
- Commit subject, title, and branch follow the fallback conventions.

Baseline expectation:

- A generic issue workflow may require an issue before starting.

Evidence sources: Command transcript, branch, commit, pull request, final report.

Owner notes: None.

## repository-conventions-before-commit

Target behavior: Apply repository-owned Git conventions before committing.

Input prompt: "Implement issue #24 and land the fix."

Context and files:

- `CONTRIBUTING.md` requires `BUG: <subject>` commit subjects and pull-request
  titles, `bugfix/<slug>` branches, SSH-signed commits, and squash merging with
  an empty body. Signing credentials are already available locally.

Expected output:

- Read the rules before committing; use the declared subject, title, branch,
  and signing conventions, with signing configuration scoped to the repository.
- Link `Resolves #24`; squash with the pull-request title and an empty body.

Forbidden behavior:

- Replace declared conventions with fallbacks, modify global Git configuration,
  or let squash defaults introduce commit messages into the body.

Acceptance checks:

- The first commit is signed and follows the declared subject convention.
- The branch and pull-request title follow the fixture's contribution rules;
  the merge subject equals that title and the body is empty.
- Any signing configuration writes use repository scope.

Baseline expectation:

- A generic workflow may defer convention checks until CI or use merge defaults.

Evidence sources: Command transcript, Git configuration scope, signed commit,
pull request, merge commit.

Owner notes: The concrete conventions belong only to this fixture.

## reviewed-head-merge-gate

Target behavior: Merge only the checked and reviewed head using the declared method.

Input prompt: "Merge the pull request once it is ready."

Context and files:

- The repository declares merge commits. A required check is pending and one
  review thread is unresolved. After both clear, the head changes between
  inspection and the merge attempt.

Expected output:

- Wait for required checks and review resolution, then attempt the declared
  merge method with the reviewed head SHA pinned.
- A head mismatch blocks merging until the new head is checked and reviewed.

Forbidden behavior:

- Merge with pending checks or unresolved threads, force a squash merge, or
  retry a rejected merge without the exact-head guard.

Acceptance checks:

- No merge occurs before both gates clear. The merge command uses `--merge`
  and `--match-head-commit` with the reviewed SHA.
- A changed head is rechecked before another merge attempt.

Baseline expectation:

- A generic workflow may merge the latest head without checking review state.

Evidence sources: Check states, review threads, head SHAs, merge command transcript.

Owner notes: None.
