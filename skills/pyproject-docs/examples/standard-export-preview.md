# Standard Export Preview

## Profile

This preview shows the expected target-repository outcome for the `standard`
profile. The GitHub settings owner has chosen local community files in this
example; inherited files are omitted from an export.

## Source Templates Used

- `templates/docs.reference.release.md.tpl` ->
  `docs/reference/release.md`
- `templates/AGENTS.md.tpl` -> `AGENTS.md`
- `templates/README.md.tpl` -> `README.md`
- `templates/CONTRIBUTING.md.tpl` -> `CONTRIBUTING.md`
- `templates/LICENSE.tpl` -> `LICENSE`
- `templates/CODE_OF_CONDUCT.md.tpl` -> `CODE_OF_CONDUCT.md`
- `templates/SECURITY.md.tpl` -> `SECURITY.md`
- `templates/SUPPORT.md.tpl` -> `SUPPORT.md`
- `templates/GOVERNANCE.md.tpl` -> `GOVERNANCE.md`
- `templates/CODEOWNERS.tpl` -> `.github/CODEOWNERS`
- `templates/docs.README.md.tpl` -> `docs/README.md`
- `templates/docs.architecture.README.md.tpl` ->
  `docs/architecture/README.md`
- `templates/docs.proposals.README.md.tpl` -> `docs/proposals/README.md`
- `templates/docs.decisions.README.md.tpl` -> `docs/decisions/README.md`
- `templates/docs.migrations.README.md.tpl` -> `docs/migrations/README.md`
- `templates/docs.archive.README.md.tpl` -> `docs/archive/README.md`
- `templates/docs.reference.README.md.tpl` -> `docs/reference/README.md`
- `.github` issue and pull request templates

## Expected Target Tree

```text
<python-project-repo>/
  AGENTS.md
  README.md
  CONTRIBUTING.md
  LICENSE
  CODE_OF_CONDUCT.md
  SECURITY.md
  SUPPORT.md
  GOVERNANCE.md
  pyproject.toml
  docs/
    README.md
    architecture/
      README.md
    proposals/
      README.md
    decisions/
      README.md
    migrations/
      README.md
    archive/
      README.md
    reference/
      README.md
      release.md
  .github/
    CODEOWNERS
    ISSUE_TEMPLATE/
      bug.md
      feature.md
      config.yml
    pull_request_template.md
```

## Intentional Omissions

This profile does not force `docs/api/`. Add it only when the repository
intentionally publishes authored or generated Python API reference.

It also does not emit `.github/README.md`; normal repositories default to the
root `README.md` for GitHub's surfaced repository landing page.
