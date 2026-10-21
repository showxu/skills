# Minimal Export Preview

## Profile

This preview shows the expected target-repository outcome for the `minimal`
profile. The GitHub settings owner has chosen local community files in this
example; inherited files are omitted from an export.

## Source Templates Used

- `templates/docs.reference.release.md.tpl` ->
  `docs/reference/release.md`
- `templates/AGENTS.md.tpl` -> `AGENTS.md`
- `templates/README.md.tpl` -> `README.md`
- `templates/CONTRIBUTING.md.tpl` -> `CONTRIBUTING.md`
- `templates/docs.README.md.tpl` -> `docs/README.md`
- `templates/docs.architecture.README.md.tpl` ->
  `docs/architecture/README.md`

## Expected Target Tree

```text
<python-project-repo>/
  AGENTS.md
  README.md
  CONTRIBUTING.md
  pyproject.toml
  docs/
    README.md
    architecture/
      README.md
    reference/
      release.md
```

## Intentional Omissions

This profile does not require `docs/proposals/`, `docs/decisions/`,
`docs/migrations/`, `docs/archive/` or `docs/api/`. From `docs/reference/`
it requires only `release.md`.

It also does not emit `.github/README.md`; normal repositories default to the
root `README.md` for GitHub's surfaced repository landing page.
