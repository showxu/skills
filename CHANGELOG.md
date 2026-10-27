# Changelog

## Unreleased

## 0.1.6

- github-repo-steward configures a clone's identity, SSH signing and
  allowed-signers list on its own with `scripts/configure-signing.sh`, without
  the push gate; `scripts/configure-clone.sh` still requires its checks and
  now delegates signing to it. Both use `ALLOWED_SIGNERS` when set, otherwise
  the clone's configured list, and fall back to `allowed_signers` in the Git
  directory. They append the owner's line when missing and keep every other
  signer; a list that is repository content is only read. Governance covers
  rerunning after a reclone or reinstall, rebuilding the list from the signing
  keys registered on GitHub, and keeping retired keys after rotation.

## 0.1.5

- agent-evolver re-evaluates a skill collection, named skills or a set of
  instruction units for a new model, host or agent-tool version, or for newly
  published official agent guidance, and applies only the findings the user
  approves. Audits are read-only and measure each item's listing and context
  cost; guidance audits cover only the items a recommendation concerns.
  Approved cleanup follows a fixed order with removal accounting and
  before/after trigger evals. Instruction changes edit units and are verified
  by regeneration, doctor and readback in fresh sessions.
  `scripts/usage_counts.py` counts skill use per host, apart from maintenance
  of the collection's own repository.
- agent-evolver no longer runs scheduled evolution batches or delivers pull
  requests and issues itself, and its official-knowledge and Codex-experience
  topics and `scripts/collect_evidence.py` are replaced by the audit above.
  Request an upgrade audit after a model, host or agent-tool release instead
  of scheduling agent-evolver.

## 0.1.4

- repository-docs and the GitHub stewards edit the instruction units of a
  repository that generates `AGENTS.md` with the `agents` CLI and regenerate,
  instead of editing the generated file. The stewards keep organization-shared
  units in `.github`'s `.agent/instructions/shared/` and commit a repository's
  units, declaration, lock and generated `AGENTS.md` together.

## 0.1.3

- Framework icons support layered custom glyphs with per-part colors or linear
  gradients, surface-only details, and texture paths in face units. Icon glyph
  policy belongs to the owning project.
- Terminal demos soft-wrap wide command and output lines within the 830 px
  canvas, with dim continuation markers and unwrapped accessible transcripts.
  Recordings whose lines fit retain identical SVG bytes; titles must still fit.
- GitHub stewardship separates `.github` rules/data from independently versioned
  `github-workflows` automation, promotes checks shared by two members, and uses
  lowercase repository-owned `scripts/` with script-free templates. Member CI
  requires `policy` and `validate`; shared changes pass fixtures and a
  representative member before rollout. To upgrade an existing organization,
  move reusable workflows and checkers into `github-workflows`, repin member
  callers, move member-specific helpers to `scripts/`, and align required
  checks with the resulting `policy` and `validate` contexts.
- Profiles, social previews and terminal SVGs render/check locally and commit
  their outputs. Member dashboards compare membership with the current public
  catalog and regenerate locally when it drifts. To upgrade, replace CI
  presentation rendering with local render/check commands and committed
  outputs, and use ecosystem validation's `demo` switch for CI recording checks.
- `github-readme-design` supports `terminal check --recording-only` and the
  Action's `recording-only` input for the ecosystem validation `demo` switch,
  with recording diffs and no DESIGN, font or SVG requirement.
- `github-repo-steward` creates a new repository from the template its
  organization declares and replaces the declared identity values with
  `scripts/apply_template_identity.py`; without a template it assembles the
  repository from the ecosystem initializer, the docs skill export and the
  standard.
- Skills track work done in place in the task plan and file issues only for
  work handed to another owner or recorded publicly (`github-flow`,
  `github-org-steward`, `coding-plan`, `repository-docs`, `pyproject-docs`).
- The `showxu-skills` plugin manifest for Codex is the portable Agent Plugins
  `plugin.json` at the repository root, with the Codex interface under
  `extensions.com.openai`; `.codex-plugin/plugin.json` is removed. Codex needs
  CLI 0.147.0 or later to install the plugin. `skill-creator` publishes Codex
  plugins with the root manifest and checks the Codex inventory in the
  installed cache. To upgrade, install Codex CLI 0.147.0 or later, run
  `codex plugin marketplace upgrade showxu-skills` and
  `codex plugin add showxu-skills@showxu-skills`, verify the installed version,
  then restart Codex. Update custom manifest readers to use `plugin.json`.

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
- `skill-creator` places a collection's version source and mirrors in its
  VERSIONING.
- The `VERSIONING` template's release timing no longer describes how other
  repositories reference a release; workflow integration guides and release
  references own that.

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
