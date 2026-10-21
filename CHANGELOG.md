# Changelog

## Unreleased

- Release once per completed change in the steward's version policy: a change
  spanning several pull requests or repositories releases when all of it has
  landed, and its in-progress commits are pinned by full SHA without version
  comments; release pins carry `# vX.Y.Z`. ExecPlans for work that changes
  anything released name their release points before execution.
- Render deterministic social-preview PNGs and public/member organization
  profiles in the TypeScript presentation toolchain and Action, with shared
  catalog validation, DESIGN tokens, WebAssembly still-image decoding and byte
  checks. Require explicit social font variations and reject decoder warnings
  or recovered raster errors. Replace the Python renderers and recipes; member
  rendering takes an explicit standard commit.
- Describe the organization standard's reusable presentation and profile
  workflows: presentation assets follow each caller's catalog `kind`, the
  social preview icon resolves from the caller or the pinned standard, and
  member dashboards call the profile workflow from a job named `check`.
- Observe member-profile catalog pins from reusable workflow callers in the
  organization steward through parsed YAML workflows, independently of the
  renderer implementation, with caller files and SHAs reported for conflicts.
- Provide the organization family DESIGN template in Google's DESIGN.md format,
  carrying every terminal, social preview and profile token the toolchain
  reads.

Upgrading from 0.1.x, following the
[renderer reference](skills/github-readme-design/references/renderers.md):

- Replace vendored copies of `render_profile.py`, `render_social.py` and
  `presentation.py` and their recipe files with the Action's `profile` and
  `social-preview` assets, or the `src/cli.ts` commands, pinned by full commit
  SHA.
- Move profile icon sizes and social preview geometry from recipes into DESIGN
  front matter: the `profile-*` and `social-preview-*` spacing and components,
  and `fontSize`, `lineHeight` and `fontVariation` on each `social-preview-*`
  typography token, as in the organization family template. Social previews
  read the variable font; static instances are no longer needed for them.
- Add `organization.about` and each repository's `kind`, `title` and `about`
  to the catalog.
- Remove `catalog` from member profile input and pass the standard commit as
  `--catalog-revision`; the reusable profile workflow supplies
  `job.workflow_sha`.
- Commit each card as `.github/assets/social-preview/social-preview.png`, and
  remove card SVGs and layout receipts.

## 0.1.1

- Use MINOR for breaking changes and PATCH otherwise during 0.x; let the owner
  begin the compatibility promise at 1.0.0, then evolve interfaces compatibly
  with roughly yearly planned majors, MINOR features and PATCH fixes in the
  steward's version policy.

## 0.1.0

- Ship the `showxu-skills` plugin for Claude Code and Codex, with marketplace
  and direct skill installation routes.
- Provide skills for product planning and documentation, design and user
  experience, Web app implementation and testing, go-to-market and App Store
  work, software engineering and GitHub stewardship, and skill authoring and
  evaluation.
- Include the [scripted terminal presentation toolchain](skills/github-readme-design/references/renderers.md#terminal)
  and [GitHub Action](skills/github-readme-design/scripts/action.yml) for
  recording sessions, rendering light/dark SVGs from DESIGN, and checking
  recording and image bytes in CI.
- Include presentation layout references for
  [developer products and organization profiles](skills/github-readme-design/references/design.md)
  and [apps](skills/github-readme-design/references/design-apps.md).
