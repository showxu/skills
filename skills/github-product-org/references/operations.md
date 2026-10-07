# Operations

## Working Area

Before anything else, `scripts/scan_org.py snapshot --root <checkouts>` and
save the baseline. The owner's main worktree, index, stashes, and existing
branches and worktrees are not yours.

Choose per repository:

| Situation | Work in |
| --- | --- |
| A local checkout exists and its remote refs can be fetched | A task worktree: `git worktree add <scratch>/<repo>-<topic> -b <topic> origin/<default>` |
| The repository holds local refs that must never reach a remote (private agent refs, unreviewed branches) | A fresh clone |
| History will be rewritten (`git filter-repo` requires a fresh clone) | A fresh clone |
| No local checkout, or another agent is using it | A fresh clone; shallow or blobless when disk is tight |

Task worktrees:

- Fetch first and branch from the remote default branch, not from the local
  branch, which may be stale.
- Keep signing and the gate out of the shared repository config: enable
  `extensions.worktreeConfig`, then set identity, signing, and
  `core.hooksPath` with `git config --worktree`. The only shared change is
  `extensions.worktreeConfig=true`; the main worktree keeps its identity,
  signing, and hooks. `scripts/configure-clone.sh` targets clones; apply the
  same values per worktree.
- The worktree belongs to the task. When its pull request merges, reconcile
  any unique changes, `git worktree remove` it without force, and delete its
  branch. If the task enabled `extensions.worktreeConfig`, unset it after the
  last task worktree is removed. A lingering worktree blocks workspace
  relocation of its repository.

Push only branches the task created, by name. Never `push --all`, `--mirror`,
or `--tags` from the owner's repository, and never push agent branches.

Keep local execution records private. Put producer outputs in its owning
ignored directory, reuse that location, and remove task-created caches after
validation. Build from the owning checkout, a Git worktree or an archive of
the chosen commit; never copy a full checkout or its `.git` into build output.

## Audit and Four-Class Triage

Audit per area (app, CLI, plugins, website and tap, organization and forks),
read-only and bounded, with `references/audit-checklist.md`: inspect named
paths and repository metadata; never enumerate agent state, caches,
dependencies, generated checkouts, or archives.

Triage every finding into one class, with a default the owner can accept:

| Class | Meaning | Default action |
| --- | --- | --- |
| Delete | Stale, superseded, or process residue | Delete through a pull request; add an anti-accumulation check if it recurs |
| Distill then delete | Holds current facts in the wrong place | Move the facts to their owner, then delete |
| Insufficient evidence | Purpose unclear | Keep; ask the owner |
| Keep | Current and correctly owned | Leave it |

Add a fix list for defects found along the way. Apply existing authorization
to concrete fixes; ask only for unresolved ownership, material scope changes
or destructive choices. Record the disposition and evidence for every row.

## Change Discipline

- One pull request per repository per concern. Title and body describe the
  current result, not the editing path.
- Signed commits only; the pre-push gate runs on every push.
- Merge when required checks are green and review findings are fixed or
  answered on the PR: `gh pr merge <n> --squash
  --match-head-commit <sha> --subject "<title> (#<n>)" --body "<summary>"`.
  Confirm the merged commit is Verified.
- No force push, no ruleset bypass, no history rewrite on a shared branch.
- When a setting must change, change it through the API and update the
  declaration in `MAINTENANCE.md` in the same sitting.

## Cleanup Without Remote Traces

- Do not create remote artifacts for process: no long-lived work branches, no
  committed reports, no draft releases. Merged branches delete themselves.
- Before deleting a remote branch, bundle it (`git bundle create`) into the
  backup area.
- With squash merges, a merged branch is never an ancestor of the default
  branch. Prove a local branch is merged by matching its tip to the head
  commit of a merged pull request (`gh pr list --state merged --json
  headRefName,headRefOid`); a branch that matches no pull request needs another
  proof, such as its tree equaling a release tag's tree, or the owner's
  decision.
- Leftover working-tree changes and stashes: compare each file with the
  fetched remote default branch. Identical files, and deletions the default
  branch also made, are merged. For the rest, count the added lines missing
  from the default branch's version and review those files by meaning: merged,
  superseded, still valuable, or unclear. Carry still valuable changes over in
  a pull request; discard the rest path by path, only with the owner's
  approval, never with `git clean` or `git checkout .`, and never touching
  untracked files outside the list.
- A rewrite changes public refs but cannot prove erasure from PR refs, forks,
  cached views or SHA links. Preserve the repository identity. Treat cosmetic
  historical residue as an explained review item; actual exposed secrets
  require revocation and the hosting provider’s removal procedure.
- Cosmetic history problems (variant author names under the owner's email) are
  fixed for local display with a mailmap, not by rewriting.

## Authorized History Cleanup

Use an in-place rewrite when the owner has explicitly authorized a history
cleanup. Cosmetic names use a mailmap; normal fixes use a PR.

1. Record affected refs and preserve a bundle, release notes and assets,
   settings and rulesets in the private backup location. Revoke exposed
   credentials before manipulating history.
2. Use a fresh clone with `git filter-repo` to remove the approved paths,
   content and messages. Preserve unrelated provenance. Inspect the complete
   changed-ref list, tree equivalence where required and full-history scans.
3. Prepare exact ref updates, consumer pin changes and a rollback. Obtain any
   missing permission for a temporary administrative bypass. Push only the
   approved refs and verify their remote SHAs; a protection notice is not
   proof that an update succeeded. Restore normal rules immediately.
4. Recreate signed annotated tags only within the explicitly approved rewrite
   scope. Remove assets whose provenance identifies replaced commits, then
   rebuild and scan their replacements through the owning release workflow.
   If a moved release tag changes content, publish a new patch or the larger
   version required by its compatibility policy.
5. Close only stale automation PRs whose bases were invalidated. Update pinned
   consumers and verify settings, content, releases and public URLs again.

Do not promise that unreachable objects or cached SHA views vanished. For
sensitive data, follow [GitHub’s removal procedure](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository),
including support escalation when required. Repository recreation is an
exception requiring an explicit request and a separate inventory of issues,
PRs, stars, releases and settings that would be lost or need restoration.

## Authorized Agent Handoffs

Use delegation only when authorized. Give participants one shared rules file
and separate task files naming owned paths, input revisions, output shape and
validation. Never assign concurrent writes to the same files. Keep design
approval with its owner and do not infer permission to message other chats.

For new repositories, phase A ends before the first push: prepared source,
review findings, validation evidence and factual release notes. One publisher
then verifies the accepted revisions and performs bootstrap, merges and
releases. Agent completion messages are pointers to evidence, not proof.

## Agent Safety and Evidence

Server-side rulesets, required policy checks and CI enforce merge invariants.
Local hooks provide early feedback; prose and agent confidence cannot enforce
permissions. A check must bind its result to the actual source revision and
artifact. Verify published bytes and live URLs before claiming delivery.

A running job needs a live handle and current status. An observation timeout
is not cancellation: inspect the same run before deciding whether to retry.
Define validation budgets in the package-owned configuration and validate their
bounds in the shared workflow. Preserve required coverage when increasing a
budget. Reuse accepted evidence at the scope the owner permits.

For each incident, repair the owning check or add a judgment rule with a
reason and safe path. Keep local values, screenshots and execution logs out of
reusable artifacts; handoffs retain concise text, source paths and hashes.

## Acceptance

- Organization settings check: no differences.
- `scripts/scan_org.py remote --org <org> --identity <owner-email>
  --allowed-signers <file> --work-dir <ignored-empty-directory>`: no FAIL.
  Judge the latest run of each workflow
  at the accepted default-branch commit. Explain every REVIEW line (published
  lightweight tags, forks' upstream history, scanner regexes, variant names).
- `scripts/scan_org.py compare --root <checkouts> --baseline <file>`: no
  unrelated-state changes. Branch and upstream differences are REVIEW; they
  may be intended alignments the owner approved.
- By hand: App installation repositories, social preview hashes, website
  screenshots, one real install.

## Retrospective and Retirement

- For each problem that cost time, name the owning artifact (a repository
  document, a check, a script, a skill) and fix it there, so it cannot recur.
- Delete scratch clones and temporary scripts as soon as their work merges.
  Delete backups after acceptance, with the owner's approval.

## Pitfalls

- The `gh` OAuth login cannot list an App installation's repositories; a
  personal access token can.
- Pages for Apps, installations, and some organization settings require sudo
  or a passkey; automated browsers often cannot complete them.
- `gh pr create` right after a quiet push may not see the branch; pass
  `--head <branch>`.
- Large pushes over HTTPS can disconnect; set `-c http.postBuffer=524288000`.
- In zsh, quote API paths with `?`, `*`, or `[`, and avoid unquoted globs in
  arguments.
- `gh api` returns one page; add `per_page=100` or `--paginate` deliberately.
- GitHub's free plan lacks organization rulesets and private-repository
  rulesets.
