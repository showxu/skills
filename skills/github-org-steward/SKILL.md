---
name: github-org-steward
description: Set up, maintain, coordinate, and audit organization-wide GitHub standards and publication. Use an organization URL, repository inventory or cross-repository change to own the shared .github standard, repository placement, organization settings and scoped Apps, family DESIGN, job-grouped profile/catalog, pins, coordinated releases, acceptance scans and authorized handoffs. Applies each member's GitHub standard through github-repo-steward. Does not own an isolated personal or member repository's settings/presentation, package implementation, icon construction or ecosystem release mechanics.
---

# GitHub Org Steward

Own what only an organization has: shared standards, cross-repository placement,
organization settings, scoped Apps, family consistency, the organization profile
and coordinated publication. One repository's complete GitHub-side standard is
owned by `github-repo-steward`; invoke it for each member instead of restating
its procedures here.

## Scope and authority

Use for a new organization, takeover, shared convention change, family rollout,
periodic organization audit or explicitly authorized handoff. A request confined
to one personal or member repository routes to its repository owner below.

Read the organization's `.github` README, AGENTS, MAINTENANCE, VERSIONING,
DESIGN and workflow integration guidance first, then touched repositories'
guides and checks. The shared standard is authoritative for members. Values
come from this organization, its repositories or explicit owner decisions;
never import another organization's names, branches, paths, colors or key setup.

Resolve [topology and placement](references/topology.md): a product family has
dependency-ordered publication; a package collection has independently released
members. Both use `.github` for shared standards, with repository-owned code,
checks and accepted exceptions. A template seeds new members; it does not update
existing ones.

This is an organization orchestrator with sequential handoffs. Delegation needs
explicit authorization and disjoint write ownership; a routing table is not
permission to spawn agents or message other sessions.

## Workflow

1. **Scope and protect.** Name the organization, mode, repositories, accepted
   standard revision and authorized changes. Snapshot any local checkout area
   before work, using `scripts/scan_org.py snapshot`. Keep the owner's worktrees,
   index, stashes and local-only changes untouched. See
   [operations](references/operations.md).
2. **Audit.** Read shared declarations and live organization state with the
   [audit checklist](references/audit-checklist.md). Invoke
   `github-repo-steward` in audit mode for each in-scope repository. Aggregate
   their expected/observed findings and authority gaps; classify fix, keep,
   distill to owner, insufficient evidence. Audit-only scope ends without
   mutations. Reuse already granted authorization for concrete fixes.
3. **Establish shared truth.** Change the owning `.github` standard first.
   Organization settings/App changes update its MAINTENANCE declaration in the
   same reviewed change, using [governance](references/governance.md). Shared
   workflow changes require syntax validation and an accepted consumer run at
   the proposed pin before a broad rollout. Plan capacity-bound waves and the
   measured cache-adoption gate in [coordinated publication](references/release.md)
   before dispatch. Version rules stay in VERSIONING; visual tokens stay in DESIGN.
4. **Apply per repository.** Invoke `github-repo-steward` with the repository,
   standard revision, accepted source and scope. It owns settings, inherited
   community health, CI patterns, release hygiene, headers, Quick looks, social
   cards, terminal demos, upload verification and the repository audit. Each
   consumer advances through its own PR; record its accepted head and merge.
5. **Deliver organization surfaces.** Apply [family and profile](references/brand.md),
   [website integration](references/website.md) and
   [coordinated publication](references/release.md). Keep catalog membership
   generated from authoritative inventory. Organization profile copy, umbrella
   icon and pins are reviewed as one public entry surface. Per-repository image
   production and upload stay with the repository steward.
6. **Accept.** Run the organization's settings check and the cross-repository
   acceptance scanner below. Reconcile every repository report with its current
   accepted SHA, live check status and published artifacts. Confirm profile,
   membership, pin order, scoped App installations and working public URLs.
   Unknowns stay unknown; a prepared branch is not a delivered change.
7. **Retire.** Compare local state with the starting snapshot, remove task-owned
   outputs and worktrees, retain only required evidence and report sizes/reasons.
   Record recurrence fixes in the artifact that owns them.

## Routing

This skill owns the routing and handoff map. It does not own the following
domain artifacts or their implementation procedures:

| Work | Owner |
| --- | --- |
| One repository's complete GitHub-side standard, presentation or audit | `github-repo-steward` |
| Documentation roles and review-rule format | `repository-docs` |
| Issue implementation and PR flow | `github-issue-workflow` |
| Homebrew formulae, tap operations or installation | `homebrew` |
| Upstream adoption, maintained forks and source conservation | `fork-dog` |
| Visual identity file shape and templates | `design-md-template` |
| Personal account profile | `github-profile-readme` |
| Framework icon family or app icons | `apple-framework-icon-design`, `apple-app-icon-design` |
| Ecosystem release procedures | That ecosystem's release skill, e.g. `swiftpm-github-release` for Swift packages |
| Website implementation and browser QA | `frontend-design`, `webapp-builder`, `webapp-testing` |
| Interface/marketing copy | `ux-writing`, `market-messaging` |
| App Store operations | The relevant `app-store-*` skill |
| Creating or improving a skill | `skill-creator` |

A handoff carries owner/repository, shared revision, owned paths, accepted input,
constraints, expected output, checks and evidence. Do not copy another owner's
contract into this skill.

## Participation and safety

Use existing authorization. Prepare concrete reviewable artifacts before asking
for missing scope or approval. The owner completes passkeys/login, App permission
increases, installation changes, credentials and browser permission toggles.
Do not invent Apps, keys or secrets merely because automation is possible.

Destructive remote deletion, legal/visibility changes or protection relaxation
need explicit scope. Published history, tags and assets remain immutable under
the applicable repository standard; ordinary cleanup never rewrites them.
Do not infer permission to discard local changes or contact unrelated chats
from another agent's report. Preserve source notices and correct history
artifacts; an empty word search is not an ownership proof.

## Validation and output

- Shared standard: its declared checks, plus a pinned consumer run for shared
  automation changes; GitHub settings declarations match live state.
- Coordination: size rollout waves from current total and runner-class
  capacity, measure development build caches against a threshold set before
  the trial, and require cache-free release workflows that preserve running
  and queued releases. Use [coordinated publication](references/release.md).
- Each repository: invoke `github-repo-steward`; aggregate its report rather
  than treating the organization scanner as a complete conformance audit.
- Remote observation: `python3 scripts/scan_org.py remote --org <org>
  --identity <owner-email> --allowed-signers <file>
  --work-dir <ignored-empty-directory>`. Per-repository observations execute
  from the repository steward package. Use `--repo-steward <skill-dir>` when
  the skills are installed separately. Explain all REVIEW lines and pending runs.
- Local preservation: `python3 scripts/scan_org.py compare --root <checkouts>
  --baseline <snapshot.json>` reports no unrelated status/index/stash/worktree
  changes. Intended ref alignments require their own evidence.
- Manual: actual App selection and reviewer behavior, organization profile in
  light/dark, catalog membership and links, umbrella identity, pin order and
  dependent publication receipts. Installation alone does not prove automatic
  review is active.

Report changes/PRs and accepted SHAs, applicable standard, settings and per-repo
results, organization-surface verification, unknowns/owner decisions and cleanup.
Maintainers use [architecture](references/architecture.md) and
[eval fixtures](references/eval-fixtures.md).
