# GitHub Flow Fixtures

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
