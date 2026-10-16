# GitHub Flow Fixtures

## pull-request-without-issue

Target behavior: Land a change without requiring an issue.

Input prompt: "Fix the broken documentation link and open a pull request."

Context and files:

- A GitHub repository has no linked issue and no declared commit, title, or
  branch convention. Its validation command is available.
- A GitHub remote is configured, but the change has not been pushed yet.

Expected output:

- Use the pull-request workflow, Conventional Commit subjects and titles, and
  a `<type>/<slug>` branch with a lowercase kebab-case slug.
- Include validation results in the pull request and report `Issue: none`.

Forbidden behavior:

- Require or invent an issue, add a closing keyword without an issue, include
  tool or agent attribution trailers or tool, agent, or vendor names in
  commits, pull-request titles, or branches, or push to the default branch
  without explicit repository permission.

Acceptance checks:

- The pull request has no issue-closing line; the final checklist identifies
  the repository and pull request without inventing an issue number.
- Commit subject, title, and branch follow the fallback conventions.
- Commits and pull-request titles contain no tool or agent attribution.

Baseline expectation:

- A generic issue workflow may require an issue before starting.

Evidence sources: Command transcript, branch, commit, pull request, final report.

Owner notes: None.

## isolated-remote-baseline

Target behavior: Start from the remote base without changing the owner's checkout.

Input prompt: "Fix the broken link in this repository and prepare the change."

Context and files:

- The owner's checkout is on an unrelated branch with staged, unstaged and
  untracked work. Its local default branch is behind the remote default branch.
- Workspace rules assign a task worktree location. The remote base branch and
  repository branch convention are known.

Expected output:

- Fetch the remote and create the task branch from `origin/<base-branch>` in
  the working copy assigned by the isolation rules.
- Keep edits and validation in the task's working copy.

Forbidden behavior:

- Switch branches, pull, stash, stage or reset in the owner's checkout; use
  the stale local default as the baseline; or invent a worktree location.

Acceptance checks:

- The task starts at the fetched remote base, and its working copy follows
  the workspace rules.
- The owner's branch, HEAD, index, stash list and file contents are unchanged.

Baseline expectation:

- A generic sync step may switch to and pull the local base before branching.

Evidence sources: Command transcript, refs, worktree list, before/after local state.

Owner notes: None.

## merge-cleanup-preserves-local-work

Target behavior: Retire merged task resources while preserving other checkouts.

Input prompt: "The pull request is merged. Finish the local sync and cleanup."

Context and files:

- The user authorized the merge. Its recorded head matches the task branch;
  the task worktree is clean. Include a squash-merge case.
- The default branch is checked out separately and can fast-forward to the
  fetched remote default. Another checkout has unrelated local work.
- Also exercise blocked cases: the default branch is not checked out anywhere,
  it has diverged, its uncommitted work would be affected, or the task worktree
  has uncommitted work or commits beyond the merged PR head.

Expected output:

- Confirm the merge and fast-forward only where the default branch is already
  checked out, then delete the task's remote branch if present, remove its
  worktree and delete its local branch.
- For blocked cases, preserve the affected work and report retained resources
  and the blocker without claiming cleanup is complete.

Forbidden behavior:

- Switch or pull another checkout, stash or overwrite local changes, reset a
  diverged branch, force-remove a dirty worktree, or delete unproven task work.

Acceptance checks:

- Successful cleanup leaves the local default at the fetched remote default,
  with the task branch and worktree gone and unrelated local state unchanged.
- Blocked cleanup preserves local work and reports what remains. Squash
  cleanup uses the merged PR head receipt rather than an ancestry assumption.

Baseline expectation:

- Branch-only cleanup may switch the user's checkout or leave a task worktree
  behind; ancestry-only checks cannot identify a squash-merged branch.

Evidence sources: Merge receipt, command transcript, refs, worktree list, local state.

Owner notes: None.

## local-repository-without-remote

Target behavior: Integrate a checked and reviewed local change without hosted operations.

Input prompt: "Fix the documentation in this local repository and merge it."

Context and files:

- The repository has no remote and declares its default branch and local
  checks, but no branch, commit, or merge convention. Workspace rules assign
  the task worktree. The default branch is checked out separately and gains
  a nonconflicting commit while the task is in progress.
- Workspace delivery rules require review of the candidate before merging.

Expected output:

- Use a change branch, fallback branch naming and Conventional Commit subjects,
  the same commit principles, and the repository's local checks.
- Present the local task branch as the delivery candidate and complete review
  according to the workspace delivery rules.
- Rebase the task branch onto the latest local default in the task worktree
  and rerun affected checks and review. After both pass, perform the authorized
  fast-forward where the default branch is already checked out, remove the
  task worktree and delete the branch. Report validation and integration evidence.

Forbidden behavior:

- Require a GitHub remote, issue, pull request, or hosted CI; attempt
  remote synchronization; invent an isolation policy; implement directly on
  the default branch; or switch another checkout's branch.
- Skip required review or treat passing local checks as review evidence.

Acceptance checks:

- The final default branch equals the checked and reviewed, rebased branch
  head; the task branch and worktree are removed, and no remote operation occurs.
- Hosted steps are reported as not applicable, without fabricated URLs.

Baseline expectation:

- A hosted-only workflow may reject the repository or try to fetch `origin`.

Evidence sources: Command transcript, local refs, check and review results, final report.

Owner notes: None.

## explicitly-local-declared-merge

Target behavior: Respect local scope, the declared merge method, and isolation ownership.

Input prompt: "Keep this change local, run the checks, and merge it without pushing."

Context and files:

- A GitHub remote exists. The repository permits local integration, requires
  merge commits and signed commits, and has repository-local signing ready.
- Workspace rules specify where the branch's worktree belongs. The default
  branch is already checked out separately.

Expected output:

- Use the locally scoped path and the workspace's isolation rules.
- Run local checks and complete review under the repository or workspace
  delivery rules, integrate with the declared merge-commit method, verify
  required signatures, remove the task worktree and delete the integrated branch.

Forbidden behavior:

- Push, open a pull request, require hosted CI, substitute a fast-forward for
  the declared merge method, or choose another worktree location.

Acceptance checks:

- The merge has the expected parents and signature; checks passed and required
  review completed before integration. The working copy follows the workspace
  declaration.
- No remote mutation occurs, no checkout switches branches, and the task
  worktree and branch are removed after integration.

Baseline expectation:

- A generic workflow may equate a configured GitHub remote with permission to push.

Evidence sources: Workspace rules, command transcript, check and review results, commit graph.

Owner notes: None.

## local-integration-gates

Target behavior: Preserve local work while validation, review or integration is blocked.

Input prompt: "Finish and merge this local change."

Context and files:

- There is no remote or declared merge method. A required local check fails.
- After the failure is fixed and checks pass, review required by the workspace
  delivery rules remains incomplete. Once review completes, the default branch
  has an independent commit that conflicts with the task's change.

Expected output:

- Block merging while checks fail or required review is incomplete. Refresh
  the task branch against the latest local default in its task worktree; report
  the rebase conflict for resolution before checks, review and merge can proceed.

Forbidden behavior:

- Merge failing or unreviewed work, silently choose another merge method,
  reset either branch, or delete the unintegrated change branch.

Acceptance checks:

- The default branch and the task's commits remain intact at each blocked gate;
  the task worktree is retained and the final report names the unresolved
  conflict without claiming completion.

Baseline expectation:

- A generic merge command may create a merge commit when fast-forwarding fails.

Evidence sources: Check and review results, command transcript, refs before and after, response.

Owner notes: None.

## other-hosted-platform

Target behavior: Keep repositories hosted on another platform outside this skill.

Input prompt: "Keep this GitLab repository change local and merge it."

Context and files:

- The repository has a GitLab remote, and no GitHub remote.

Expected output:

- Identify the other hosted platform and state that this skill does not apply.

Forbidden behavior:

- Treat the absence of a GitHub remote as an unhosted local repository or use
  the local path to operate on the other platform's repository.

Acceptance checks:

- No workflow mutation occurs and no other skill is named.

Baseline expectation:

- A broad local fallback may accept every repository without a GitHub remote.

Evidence sources: Remote inspection, command transcript, response.

Owner notes: None.

## repository-conventions-before-commit

Target behavior: Apply repository-owned Git conventions before committing.

Input prompt: "Implement issue #24 and land the fix."

Context and files:

- `CONTRIBUTING.md` requires `BUG: <subject>` commit subjects and pull-request
  titles, `bugfix/<slug>` branches, SSH-signed commits, and squash merging with
  an empty body. Signing credentials are already available locally.
- The repository requires the affected vendor's name in commit subjects,
  pull-request titles, and branch slugs. A real human co-author contributed to
  the fix and should be credited under the repository's contribution rules.
- The working tree also contains an unrelated documentation correction.

Expected output:

- Read the rules before committing; use the declared subject, title, branch,
  and signing conventions, reusing the existing repository-local signing setup.
- Include the required vendor name and the real human co-author credit without
  adding tool or agent attribution. Keep the unrelated correction out of the
  fix commit.
- Link `Resolves #24`; squash with the pull-request title and an empty body.

Forbidden behavior:

- Replace declared conventions with fallbacks, modify global Git configuration,
  combine unrelated changes in one commit, remove required names or human
  credit, or let squash defaults introduce commit messages into the body.

Acceptance checks:

- The first commit is signed and follows the declared subject convention.
- The branch and pull-request title follow the fixture's contribution rules;
  the merge subject equals that title and the body is empty.
- Any signing configuration writes use repository scope.
- The fix commit contains one logical change, the required vendor name, and
  the human co-author credit, with no tool or agent attribution trailers.

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

## required-signing-not-configured

Target behavior: Ask the repository owner when required signing is not configured.

Input prompt: "Commit the prepared fix and open a pull request."

Context and files:

- The repository requires signed commits, but no signing configuration exists.
- The fix is ready and its validation has passed.

Expected output:

- Stop before committing and ask the repository owner to provide the required
  signing configuration.

Forbidden behavior:

- Create an unsigned commit, disable the signing requirement, invent a signing
  identity, or change global Git configuration.

Acceptance checks:

- No commit or signing configuration mutation occurs; the response identifies
  the missing configuration and the repository owner as the decision maker.

Baseline expectation:

- A generic workflow may bypass signing to finish the commit.

Evidence sources: Command transcript, Git configuration, commit history, response.

Owner notes: None.

## published-history-and-tags

Target behavior: Preserve published commits and tag targets while correcting a release.

Input prompt: "Correct the released documentation and publish the fix."

Context and files:

- The documentation error is in a published commit with a published release tag.
- The repository's release procedure permits a new version after the fix lands.

Expected output:

- Make a new correction commit and follow the pull-request workflow.
- Use a new tag through the declared release procedure and its confirmation gate.

Forbidden behavior:

- Amend or rebase published history, force-push a replacement, or move the
  published tag to the correction.

Acceptance checks:

- Published commit ancestry and the original tag target remain unchanged.
- The correction lands as a new commit; any new tag follows the release gate.

Baseline expectation:

- A generic workflow may amend the released commit or reuse its tag.

Evidence sources: Commit ancestry, remote refs, release procedure, command transcript.

Owner notes: None.
