# Changelog

## Unreleased

## 0.1.2

- Keep version rules only in `VERSIONING.md` and a repository's release facts
  and mechanics in its release reference. `pyproject-docs` writes
  `docs/reference/release.md`, with a compatibility surface section, in place
  of `docs/architecture/versioning-and-release.md`; its agent guide routes,
  review rule, indexes and export checks follow it. To upgrade a project, move
  the old document's facts into the release reference and update inbound
  links; its rules are VERSIONING's.
- `github-repo-steward` reports documents that restate version rules as
  duplicate owners, `github-org-steward` routes member documentation to the
  ecosystem documentation skills, and `repository-docs` places release
  mechanics in `docs/reference/release.md`.

## 0.1.1

- Document GitHub's social-preview upload eligibility: public repositories,
  and private repositories that already have an uploaded image; only public
  repositories share the preview.
- Verify GitHub social-preview uploads by decoded RGBA pixels and organization
  avatars by PSNR, with read-only receipts, bounded cache retries and upload
  verification in organization audits.

## 0.1.0

- Ship the `showxu-skills` plugin for Claude Code and Codex, with marketplace
  and direct skill installation routes.
- Provide skills for product planning and documentation, design and user
  experience, Web app implementation and testing, go-to-market and App Store
  work, software engineering and GitHub stewardship, and skill authoring and
  evaluation.
- Include the [TypeScript presentation toolchain](skills/github-readme-design/references/renderers.md)
  and [GitHub Action](skills/github-readme-design/scripts/action.yml): scripted
  terminal sessions rendered as light/dark SVGs, social-preview PNGs and
  public/member organization profiles, all from DESIGN tokens through the
  official DESIGN.md parser, with byte checks in CI.
- Describe the organization standard's reusable presentation and profile
  workflows: presentation assets follow each caller's catalog `kind`, logos
  match their recorded icon provenance, and member dashboards call the profile
  workflow from a job named `check`.
- Include presentation layout references for
  [developer products and organization profiles](skills/github-readme-design/references/design.md)
  and [apps](skills/github-readme-design/references/design-apps.md): GitHub
  presentation design sources in `.github/design/`, assets in
  `.github/assets/`, and consumed icon copies recorded in per-icon provenance.
- Provide DESIGN.md templates in Google's format, including the organization
  family template with every terminal, social preview and profile token.
- Observe member-profile catalog pins from reusable workflow callers in the
  organization steward.
- Define the steward's version policy: during 0.x, breaking changes bump MINOR
  and everything else PATCH; the owner begins the compatibility promise at
  1.0.0; a change releases once when it is complete, its in-progress commits
  are pinned by full SHA, and release pins carry `# vX.Y.Z`.
- Standardize `docs/` for repositories without an ecosystem documentation
  adapter, and name release points in ExecPlans that change anything released.
