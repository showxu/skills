---
name: github-repo-steward
description: Set up, maintain, present, and audit one GitHub repository, whether personally owned or an organization member. Use a repository URL or checkout to resolve the applicable standard, configure settings and community health, establish CI and release hygiene, prepare README headers and Quick looks, render social cards and terminal demos, upload accepted previews, or report evidence-backed drift. An organization's .github standards are authoritative; otherwise use documented overridable defaults. Does not own organization-wide decisions, package implementation, documentation architecture, icon design, or ecosystem release mechanics.
---

# GitHub Repo Steward

Own one repository's complete GitHub-side standard and evidence of conformance.
Use the same workflow for new work, maintenance and audit. A personal repository
is a first-class target; organization membership is optional.

## Authority and inputs

1. Identify the exact owner/repository, owner type, default branch, fork status,
   visibility, accepted source revision, task scope and existing authorization.
2. Read its README, AGENTS, CONTRIBUTING, MAINTENANCE, VERSIONING, DESIGN and
   declared checks where present. Preserve local work; use a fresh clone or a
   task worktree from the remote default branch. Never copy a checkout or its
   `.git` into build output.
3. For an organization member, inspect the organization's `.github` on its
   actual default branch. Read the shared maintenance, versioning, design,
   workflow integration and community defaults. Record the standard revision.
   Apply that standard rather than these defaults. An inaccessible standard is
   unknown, not evidence that no standard exists. Resolve conflicts with the
   standard owner; do not silently override it in one member repository.
4. If no organization standard applies, use [defaults](references/standard.md).
   Existing repository policy and explicit owner choices override defaults.
   Document choices in the repository's owning documents. Branch names, check
   contexts, licenses, topics, paths, keys, colors, fonts and release patterns
   come from those owners; do not import another project's values.

The workflow is staged and serial. Semantic decisions resolve authority and
copy; helpers compare settings and render deterministic assets. No delegation
or concurrent writers are implied.

## Workflow

1. **Inspect.** Record applicable standard, observed revision and scope. Use the
   [audit matrix](references/audit.md) to gather read-only evidence for settings,
   community health, CI, versions and presentation. Check accepted commit
   signatures and Conventional Commit subjects, signed annotated release tags
   with their peeled targets, and reusable-workflow pin drift. Audit-only
   requests end in that report without mutations.
2. **Prepare.** Make a bounded change list. Preserve valid historical records,
   legal notices and external authorship. For signed owner work, configure only
   the task clone or worktree using [governance](references/governance.md).
   Run repository-owned checks, not a second competing content policy.
3. **Apply.** Put settings declarations and their live changes together; source
   changes use signed PRs. Use the [CI contract](references/ci.md) for policy and
   validation separation, safe concurrency, full pins and drift observations.
   Ecosystem validation stays with its ecosystem owner.
4. **Present.** Resolve current About, topics and homepage from the repository's
   product. Prepare its header and Quick look with
   [presentation](references/presentation.md). Render social cards and recorded
   terminal demos using [renderers](references/renderers.md). Review the exact
   images in light and dark before publication.
5. **Publish.** Follow the repository's issue/PR workflow; require checks for the
   accepted head and resolved findings. Squash with the PR title, an empty body
   and `--match-head-commit`. Read back the merge and verification state. Upload
   accepted preview bytes only after their source is merged, through the owner's
   signed-in browser using [upload and verification](references/upload.md).
6. **Verify and retire.** Re-read live settings, inherited files, exact required
   contexts, metadata and served images. Match evidence to current commits.
   Remove task-created outputs and worktrees from their producer-owned ignored
   locations; preserve only required evidence and report retained sizes/reasons.
   Never discard the owner's local changes as cleanup.

## Version and release hygiene

Use the applicable version policy and one version source. Keep a CHANGELOG with
Unreleased. New release tags are signed, annotated and immutable; verify their
remote peeled commit. Preserve published legacy tags and history. A tagged
mistake ships as a new patch, or the larger version required by compatibility.
Retry interrupted publication against the same accepted tag without replacing
existing assets. Release builds, platform matrices, packages, stores and consumer
installation procedures belong to the ecosystem's release skill.

## Boundaries and routing

This skill owns repository settings, conformance, GitHub presentation and
rendering/upload evidence. It does not own the following artifacts or decisions:

| Work | Owner |
| --- | --- |
| Shared standards, organization settings, placement, profile, catalog, pins or coordinated rollout | `github-org-steward` |
| Documentation roles, architecture and review-rule format | `repository-docs` |
| Issue triage, implementation and PR lifecycle | `github-issue-workflow` |
| Framework icon family or app icons | `apple-framework-icon-design`, `apple-app-icon-design` |
| Ecosystem release mechanics | The ecosystem's release skill (for SwiftPM, `swiftpm-github-release` when installed) |

Hand over the repository, applicable standard revision, accepted source, scoped
change and evidence. Do not implement another owner's policy by copying it here.

## Participation and failure handling

Reuse existing authorization. Ask only for missing facts or material choices:
new license/visibility, destructive remote deletion, protection relaxation,
credentials, a conflicting standard, or an unapproved live action. Prepare the
reviewable diff or plan first when safe. Audit and ordinary reversible work can
continue. Do not rewrite published history, move tags or use a bypass to fix a
normal failure. Rotate exposed credentials through their owner.

The owner performs login, passkeys and sensitive settings. Never read browser
credentials, cookies, storage tokens or session databases. Apple Events
JavaScript is an owner-enabled temporary fallback, described in the upload
procedure, with an explicit turn-off handback.

A pending workflow or unavailable API stays pending/unknown. Do not retry a live
job merely because observation timed out. Installation of a reviewer is not
proof of automatic review; record an owner deferral accurately.

## Output and maintenance

Report the applicable standard and revision, changes with PRs, checks and
accepted SHAs, drift with evidence, unknowns/owner decisions, preview receipts,
and cleanup. An audit must pair each expected value with its observed value,
source and disposition; a green helper result alone is not a complete audit.

Maintainers: read [architecture](references/architecture.md), run package
validation, the helper tests and [fixtures](references/eval-fixtures.md).
