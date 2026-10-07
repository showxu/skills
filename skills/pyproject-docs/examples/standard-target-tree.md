# Standard Target Tree

This example shows a common normalized end-state for a Python repository.

## Role Map

- Route: `AGENTS.md`
- Index: root and directory `README` files
- Proposal: `docs/proposals/*`
- Truth: `docs/architecture/*`
- History: `docs/decisions/*`, `docs/migrations/*`, `docs/archive/*`
- Governance: `.github/*` and root governance files
- Reference: `docs/reference/*`
- API Reference: `docs/api/*` when intentionally published
- Temporary State: `.agent/*`

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
  src/
    <package>/
  tests/
  docs/
    README.md
    architecture/
      README.md
      versioning-and-release.md
      package-layout.md
      generated-artifacts.md
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
    api/
      README.md
  .github/
    CODEOWNERS
    ISSUE_TEMPLATE/
      bug.md
      feature.md
      _config.yml
    pull_request_template.md
    workflows/
      ci.yml
```

This is a profile example, not a mandatory file-for-file export. The authority
is the role boundary, not the exact filename list.
