# Minimal Export Preview

## Profile

This preview shows the expected target-repository outcome for the `minimal`
profile.

## Source Templates Used

- `templates/docs.architecture.versioning-and-release.md.tpl` ->
  `docs/architecture/versioning-and-release.md`
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
      versioning-and-release.md
```

## Intentional Omissions

This profile does not require `docs/proposals/`, `docs/decisions/`,
`docs/migrations/`, `docs/archive/`, `docs/reference/`, or `docs/api/`.

It also does not emit `.github/README.md`; normal repositories default to the
root `README.md` for GitHub's surfaced repository landing page.
