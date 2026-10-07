# Minimal Profile

Use the minimal profile for the smallest stable documentation-first Python
repository baseline that still makes Agent Guide, Index, Truth, and Governance
explicit.

This profile is intentionally small. It is not the default home for the full
public-repo GitHub/community-health surface.

## Output Map

| Target path | Source template | Required |
| --- | --- | --- |
| `AGENTS.md` | `../templates/AGENTS.md.tpl` | yes |
| `README.md` | `../templates/README.md.tpl` | yes |
| `CONTRIBUTING.md` | `../templates/CONTRIBUTING.md.tpl` | yes |
| `docs/README.md` | `../templates/docs.README.md.tpl` | yes |
| `docs/architecture/README.md` | `../templates/docs.architecture.README.md.tpl` | yes |
| `docs/architecture/versioning-and-release.md` | `../templates/docs.architecture.versioning-and-release.md.tpl` | yes |

## Not Forced In This Profile

- `docs/proposals/README.md`
- `docs/decisions/README.md`
- `docs/migrations/README.md`
- `docs/archive/README.md`
- `docs/reference/README.md`
- `docs/api/README.md`
- `LICENSE`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `SUPPORT.md`
- `GOVERNANCE.md`
- `.github/CODEOWNERS`
- `.github/ISSUE_TEMPLATE/bug.md`
- `.github/ISSUE_TEMPLATE/feature.md`
- `.github/ISSUE_TEMPLATE/_config.yml`
- `.github/pull_request_template.md`
- `.github/README.md`

## README Placement

GitHub recognizes README files in the hidden `.github`, root, and `docs`
directories. For ordinary Python repositories, this profile defaults to the
root `README.md` as the surfaced repository landing page. Do not emit
`.github/README.md` unless the target is a special GitHub profile or default
community-health repository.
