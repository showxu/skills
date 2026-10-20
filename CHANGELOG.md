# Changelog

## Unreleased

- Render deterministic social-preview PNGs and public/member organization
  profiles in the TypeScript presentation toolchain and Action, with shared
  catalog validation, DESIGN tokens, WebAssembly still-image decoding and byte
  checks. Require explicit social font variations and reject decoder warnings
  or recovered raster errors. Replace the Python renderers and recipes; member
  rendering takes an explicit standard commit.
- Observe member-profile catalog pins from reusable workflow callers in the
  organization steward through parsed YAML workflows, independently of the
  renderer implementation, with caller files and SHAs reported for conflicts.

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
