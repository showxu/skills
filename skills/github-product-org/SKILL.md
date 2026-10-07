---
name: github-product-org
description: Set up, take over, maintain, and audit a GitHub product organization or collection of independently versioned packages. Owns cross-repository placement, signed PR and tag governance, automatic review, scoped GitHub Apps, brand delivery, documentation websites, coordinated publication, acceptance scans, and authorized agent handoffs. Use when adopting external code, publishing new repositories, or changing organization-wide conventions. Does not own an isolated package implementation or personal profile README.
---

# GitHub Product Org

## Purpose

Run a product organization on GitHub as a single system. The organization's
`.github` repository declares what every repository shares; each repository
owns only what is its own; automation acts through narrowly scoped GitHub Apps;
every change lands as a signed, squash-merged pull request; and the declared
state is checked against the live organization.

This skill orchestrates. It owns the organization model, the placement of
artifacts, the baseline, the maintenance loop, and the acceptance scan. Work
inside one domain routes to the skill that owns it (see Routing).

## When To Use

- Creating a new product organization or bringing an existing one to the
  baseline.
- Deciding where something belongs: a convention, community file, design
  token, rendered image, release rule, script, or agent guide.
- Adding a repository, plugin, App, secret, workflow, or required check, or
  changing an organization or repository setting.
- Changing the brand and delivering it to every repository and social preview.
- Coordinating a change that spans repositories: the app, website, tap, and
  plugins, or every package in a collection.
- Adopting external code or preparing a new repository for first publication.
- Preparing authorized agent handoffs with separate write ownership and one
  coordinated publication.
- Periodic upkeep: drift check, acceptance scan, cleanup, retrospective.

## When Not To Use

- A change confined to one repository's code with no shared-convention,
  setting, brand, or cross-repository effect; use that repository's own guide.
- A personal account profile README.
- Local workspace placement and registry upkeep; the local workspace owner
  handles that.

## Modes

| Mode | Entry | Ends with |
| --- | --- | --- |
| Bootstrap | New organization | Baseline applied, `MAINTENANCE.md` GitHub settings section true, acceptance scan clean |
| Takeover | Existing organization | Audit triaged by the owner, fixes merged, baseline applied, acceptance scan clean |
| Change | One cross-repository change | Owning artifacts updated in the same pull requests, settings check clean |
| Upkeep | Periodic | Settings check and acceptance scan clean, findings triaged |

## Organization Model

Read `references/topology.md` before placing anything. Identify the shape
first; it decides who owns meaning and how releases flow:

| | Product family | Package collection |
| --- | --- | --- |
| Under the organization | One product split across repositories: app, companion CLI, plugins | Independent packages and tools, each its own product |
| Meaning and copy | The main app repository's ProductIdentity; text rendered into images must match it | Each package repository; the organization profile describes the collection |
| Releases | Coordinated across repositories (`references/release.md`) | Each package releases on its own under the organization's shared versioning standard |
| Shared standards reach repositories through | `.github` and brand locks | `.github`, brand locks, and a template repository for new packages |

Both shapes share the rest:

- `.github` holds the organization profile, shared conventions
  (`MAINTENANCE.md`), the design system (`DESIGN.md`, `Brand/`), the default
  community files, reusable workflows, and organization scripts.
- Website, tap, and forks are separate repositories, like every app, CLI,
  plugin, or package, each owning its own code, release rules, and short
  `CONTRIBUTING.md`.
- A value lives only in the artifact that owns it; others link to it or receive
  it through a lock file or pinned reference.

## Baseline

Every public repository, unless a fork keeps upstream conventions:

- one default branch name across the organization;
- a `default branch` ruleset with no bypass: no deletion, no force push,
  signed commits, squash-merged pull requests whose required checks pass;
- a `v*` tag ruleset preventing updates and deletion of published release tags;
- squash merge only, merged branches deleted;
- workflows get a read-only token that cannot approve pull requests, at
  repository and organization level;
- actions pinned to full commits, Dependabot for actions and package
  ecosystems;
- automation acts only through a GitHub App named for what it does, with the
  narrowest permissions, installed only where it acts, its credentials stored
  only where they are used;
- a required policy check for identity, signatures, attribution, publication
  content and version consistency, alongside the repository checks;
- automatic AI review on every PR, by default Codex Automatic review, using
  the repository’s `AGENTS.md` Code Review Rules;
- the declared brand consistency check is required where the repository
  consumes generated brand assets;
- `MAINTENANCE.md` declares all of this, and the settings check proves it.

Details, commands, and failure modes: `references/governance.md`.

## Workflow

1. **Scope.** Name the mode, the repositories, and what the owner has
   authorized. Read the organization's `.github` README, `MAINTENANCE.md`,
   `DESIGN.md`, and each touched repository's README and `AGENTS.md`.
2. **Protect local state.** Snapshot every local checkout with
   `scripts/scan_org.py snapshot`. Work in a task worktree branched from the
   remote default branch, or in a fresh clone when the repository holds refs
   that must never be pushed, history will be rewritten, or the checkout is
   missing or in use (`references/operations.md`). Never edit the owner's main
   worktree, index, or stashes.
3. **Identity gate.** Give every clone or task worktree the owner identity,
   SSH signing, and the pre-push gate: `scripts/configure-clone.sh` for clones,
   worktree-scoped config for worktrees, so the owner's shared repository
   config stays unchanged.
4. **Audit (takeover and upkeep).** Bounded, read-only, per area, following
   `references/audit-checklist.md`. Triage into four classes and let the owner
   decide each row (`references/operations.md`).
5. **Change.** One pull request per repository per concern. Update the owning
   artifact and its declaration together: a setting with `MAINTENANCE.md`, a
   token with `DESIGN.md` and re-rendered exports, a release rule with the
   repository's versioning document. Merge only with green required checks,
   review findings fixed or answered on the PR, squash, and the head commit
   pinned. Record an explicit owner deferral of advisory review in the
   declaration; do not report it as enabled.
6. **Deliver cross-repository artifacts.** Brand: render in `.github`, sync each
   consumer by pull request, then upload social previews and verify their
   hashes (`references/brand.md`). Website and releases:
   `references/website.md`, `references/release.md`.
7. **Verify.** Run the organization's settings check and
   `scripts/scan_org.py remote`; compare local checkouts with
   `scripts/scan_org.py compare`; check what scripts cannot see by hand.
8. **Retrospect and retire.** Fix each recurrence in the artifact or skill that
   owns it, then delete scratch clones, temporary scripts, and, with the
   owner's approval, backups.

## Safety Gates

Stop and ask the owner before:

- deleting anything with remote effect: repositories, branches, tags,
  releases, Apps, secrets;
- rewriting published history; an authorized cleanup rewrites in place by
  default, while repository recreation requires its own explicit request
  (`references/operations.md`);
- moving or replacing a published tag, release asset, or pinned commit;
- relaxing a ruleset, adding a bypass, or force pushing;
- creating, rotating, or relocating a private key or secret;
- changing licenses, legal documents, or visibility.

Pages that require sudo or a passkey (App settings, installation settings,
some organization settings) must be completed by the owner in their own
browser. Do not write private keys to disk; pipe them into `gh secret set`.

## Routing

This skill names owners because routing is part of its output.

| Work | Owner |
| --- | --- |
| Issue to merged pull request in one repository | `github-issue-workflow` |
| Homebrew formula, tap, `brew` behavior | `homebrew` |
| Swift package or CLI release readiness | the Swift release skills (`swiftpm-github-release`) |
| Design tokens file shape and templates | `design-md-template` |
| Apple framework-style icon family | `apple-framework-icon-design` |
| Native layered app icon and web renditions | `apple-app-icon-design` |
| Documentation roles and review-rule format | `repository-docs` |
| Swift package README, DocC and documentation templates | `swiftpm-docs` |
| Website UI implementation and browser QA | `frontend-design`, `webapp-builder`, `webapp-testing` |
| Interface and marketing copy | `ux-writing` |
| App Store listing and release | the `app-store-*` skills |
| Creating or revising a skill found in the retrospective | `skill-creator` |

Hand over the organization context the owner needs: the baseline it must keep,
the owning artifact, and the pull request discipline.

## Validation

- Settings: the organization's settings check (reference implementation:
  `Scripts/check-settings.py` in the reference organization's `.github`)
  reports no differences.
- Remote: `python3 scripts/scan_org.py remote --org <org> --identity <owner-email>
  --allowed-signers <file> --work-dir <ignored-empty-directory>` exits 0;
  every REVIEW line is explained.
- Local: `python3 scripts/scan_org.py compare --root <dir> --baseline <file>`
  reports no unrelated-state changes.
- Manual: reviewer installation and scope (`gh api orgs/<org>/installations`),
  actual review evidence on the latest applicable PR, social previews by hash,
  website in every supported language and breakpoint, one real install from
  the tap. App installation alone does not prove automatic review is enabled.
- Use `templates/MAINTENANCE.md.tpl` to declare expected settings and review
  behavior, filling its values from the organization’s accepted policy.

## Output

Report, in this order: what changed, with pull request links; the settings
check and scan results; REVIEW items with their disposition; decisions the
owner still owes; what was retired.

## References

- `references/topology.md`: repository roles, placement map, documentation
  layout, licenses, naming.
- `references/governance.md`: identity and signing, branches, rulesets, merge
  and Actions settings, GitHub Apps, credentials, drift declaration.
- `references/brand.md`: design system, rendering, delivery, social previews,
  typography and font licensing.
- `references/website.md`: website role, deployment, catalog reconciliation,
  release notifications, visual checks.
- `references/release.md`: versions, tags, changelogs, immutability, tap and
  plugin updates.
- `references/audit-checklist.md`: what to look for in takeover and upkeep
  audits, how to find it, and its usual class.
- `references/operations.md`: the maintenance loop, four-class triage, cleanup
  without remote traces, exceptional procedures, GitHub and tooling pitfalls.
- `references/architecture.md`: maintainer guide for this skill.
- `templates/MAINTENANCE.md.tpl`: organization settings and review declaration.
- `references/eval-fixtures.md`: behavior fixtures.
