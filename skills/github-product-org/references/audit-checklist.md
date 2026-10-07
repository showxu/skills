# Audit Checklist

Use in Takeover and Upkeep. Each row names what to look for, how to find it
within a bounded audit, and the usual class. The owner still decides each
finding; "usual class" is the recommended default.

## Repository Content

| Look for | How | Usual class |
| --- | --- | --- |
| Per-version process files: acceptance reports, evidence, release notes per version, agent goal ledgers | `git ls-files` for version numbers in names; `Archive/`, `Reference/` | Delete; keep only the current pair if a template needs it; add an anti-accumulation check |
| Documents holding current facts in the wrong owner (acceptance docs, `RELEASE.md` beside a versioning document) | Read documents named by README and AGENTS routes | Distill into the owner, then delete |
| Documents naming secrets, variables, workflows, or branches that no longer exist | Grep for credential and workflow names; compare with the settings section | Fix through a pull request |
| Stale agent skills, proposals, navigation files not linked from any route | Search for references to each file | Delete |
| Brand copies outside the organization lock: per-repository renderers, icons, banners | `Tools/Brand`, `Assets/Brand`, `Scripts/brand*`, images in `.github/` | Retire into the organization brand system; keep files the build needs, delivered through the lock |
| Community files duplicating the organization's | `CODE_OF_CONDUCT.md`, `SUPPORT.md`, `GOVERNANCE.md`, templates per repository | Delete the copies; keep a short `CONTRIBUTING.md` |
| A repository `.github/ISSUE_TEMPLATE/` that hides the shared templates | Directory exists | Move needed fields into the shared templates, delete the directory |
| Tracked agent state, operator paths, secrets | `.agent/` in `git ls-files`; `scan_org.py remote` | Remove through a pull request; rotate any real secret |
| README or AGENTS.md carrying history, local paths, or process notes | Read them | Rewrite to current facts |
| `LICENSE` differing among repositories with the same license | `scan_org.py remote` license digests | Make identical from the next release |
| Fixtures and validators that look stale but are read by tests | Search callers | Keep |
| Anything whose purpose is unclear | - | Insufficient evidence; ask |

## Git and Remote State

| Look for | How | Usual class |
| --- | --- | --- |
| Default branch name differing across repositories | `gh repo list --json defaultBranchRef` | Rename (owner decision) |
| Merged remote branches, agent branches | `git ls-remote --heads`; match tips to merged pull request heads | Bundle, then delete |
| Fork branches that only copy upstream | Compare each with the upstream ref | Delete; keep the maintained release branch |
| Lightweight or unsigned tags | `scan_org.py remote` | Keep if published; sign new tags |
| Tool identities or attribution trailers in history | `scan_org.py remote` | Normal fixes by PR; an explicitly authorized history cleanup rewrites in place and accounts for retained refs |
| Variant author names under the owner email | `scan_org.py remote` | Keep; local mailmap if the owner wants |
| Stale open pull requests and draft releases | `gh pr list`, `gh release list` | Close or publish; owner decision |

## Settings and Automation

| Look for | How | Usual class |
| --- | --- | --- |
| Missing or bypassable rulesets, wrong required check names | Settings check | Fix |
| Merge commits or rebase allowed, merged branches kept | Settings check | Fix |
| Workflow token write by default, Actions allowed to approve pull requests, at repository or organization level | Settings check | Fix |
| Unpinned actions, missing `permissions:`, no Dependabot | Read workflows | Fix |
| Automation committing with `git commit` or opening pull requests with the workflow token | Read workflows | Move to an App token and API-created commits |
| Apps with broad permissions, installed on all repositories, or with credentials stored where unused | Settings check; installation page | Narrow, then update `MAINTENANCE.md` |
| Manual steps that should be automated (tap formula updates, catalog refresh) | Release history | Add App-driven update pull requests |

## Presentation

| Look for | How | Usual class |
| --- | --- | --- |
| Missing About description, topics, homepage | `gh repo view --json description,repositoryTopics,homepageUrl` | Fix from the owner of meaning and copy |
| Missing or outdated social previews, avatar, profile README | GraphQL `openGraphImageUrl`, organization page | Re-render, upload, verify by hash |
| Fork description not saying what the fork maintains | `gh repo view` | Fix |

## Local State (report only)

| Look for | How | Usual class |
| --- | --- | --- |
| Private agent refs, stale local branches, stashes, dirty worktrees, extra worktrees | `scan_org.py snapshot`; `git for-each-ref`; `git worktree list` | Never push; align or delete only with owner approval and proof |

## Publication and Review Coverage

| Look for | How | Usual class |
| --- | --- | --- |
| Stale upstream product wording mixed with valid attribution | Compare current claims with owned code and source notices | Fix stale claims; retain applicable provenance |
| Release attachments containing workstation paths or internal material | Scan downloaded archive members and verify hashes/provenance | Replace only through an authorized release operation |
| Missing release-tag protections | Inspect the declared tag-pattern ruleset | Protect updates/deletion; preserve legacy published tags |
| License mismatch or missing vendored-suite license | Inspect LICENSE and LICENSE.txt, SPDX and NOTICE by scope | Reconcile owned facts; never infer relicense authority |
| DocC landings without icons/colors, including merged roots | Read emitted metadata and image bytes at hosted URLs | Repair the owning catalog or documented build-time default |
| No reviewer installation or automatic trigger coverage | Inspect installation scope, provider settings and latest applicable PR | Enable within authorization; record explicit deferrals |
| AGENTS.md lacks Code Review Rules or drifts from its canonical source | Compare with the documentation template and derivation check | Fix in the owning template, then sync by PR |
| Claimed completion based only on intent, a screenshot or stale CI | Match requirements to current source, run and artifact receipts | Gather the missing evidence; keep the item incomplete |
