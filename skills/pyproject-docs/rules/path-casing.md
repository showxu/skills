# Path Casing

Use this rule when scaffolding, normalizing, auditing, or exporting Python
repository documentation.

## Principle

The canonical Python documentation tree uses lowercase path segments under
`docs/`.

Use these role directories:

- `docs/architecture/`
- `docs/proposals/`
- `docs/decisions/`
- `docs/migrations/`
- `docs/archive/`
- `docs/reference/`
- `docs/api/` when API reference is intentionally published

Use lowercase kebab-case file stems for non-index Markdown documents under
those role directories:

- `docs/architecture/runtime-contracts.md`
- `docs/architecture/providers.md`
- `docs/proposals/browser-extractor-contract.md`
- `docs/decisions/use-openapi-runtime.md`
- `docs/migrations/click-to-typer.md`
- `docs/reference/source-bundles.md`

Keep root and conventional special files in their established forms:

- `AGENTS.md`
- `README.md`
- `CONTRIBUTING.md`
- `LICENSE`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `SUPPORT.md`
- `GOVERNANCE.md`
- `.github/CODEOWNERS`
- `.github/`

## Normalization Guidance

- Do not create or preserve `Documentation/*` as the final Python docs tree.
- Do not mix variants such as `docs/Architecture/`,
  `Documentation/architecture/`, or `documentation/reference/`.
- When importing an existing repository that uses non-canonical docs paths,
  treat path normalization as in-scope documentation migration work.
- Record path migration risk in `.agent/PLANS.md` when case-only or path-only
  changes may be risky on case-insensitive filesystems.
- Do not apply lowercase naming to conventional root and GitHub files.
