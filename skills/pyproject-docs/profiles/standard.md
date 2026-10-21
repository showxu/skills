# Standard Profile

Use the standard profile for the first public-repo-complete Python repository
baseline.

This profile extends beyond `minimal` with proposal, history, reference, and a
fuller GitHub/community-health surface. That distinction is intentional.

## Output Map

Apply the [community-file inheritance decision](README.md) to `if local` rows.

| Target path | Source template | Required |
| --- | --- | --- |
| `AGENTS.md` | `../templates/AGENTS.md.tpl` | yes |
| `README.md` | `../templates/README.md.tpl` | yes |
| `CONTRIBUTING.md` | `../templates/CONTRIBUTING.md.tpl` | if local |
| `LICENSE` | `../templates/LICENSE.tpl` | yes |
| `CODE_OF_CONDUCT.md` | `../templates/CODE_OF_CONDUCT.md.tpl` | if local |
| `SECURITY.md` | `../templates/SECURITY.md.tpl` | if local |
| `SUPPORT.md` | `../templates/SUPPORT.md.tpl` | if local |
| `GOVERNANCE.md` | `../templates/GOVERNANCE.md.tpl` | yes |
| `.github/CODEOWNERS` | `../templates/CODEOWNERS.tpl` | yes |
| `docs/README.md` | `../templates/docs.README.md.tpl` | yes |
| `docs/architecture/README.md` | `../templates/docs.architecture.README.md.tpl` | yes |
| `docs/reference/release.md` | `../templates/docs.reference.release.md.tpl` | yes |
| `docs/proposals/README.md` | `../templates/docs.proposals.README.md.tpl` | yes |
| `docs/decisions/README.md` | `../templates/docs.decisions.README.md.tpl` | yes |
| `docs/migrations/README.md` | `../templates/docs.migrations.README.md.tpl` | yes |
| `docs/archive/README.md` | `../templates/docs.archive.README.md.tpl` | yes |
| `docs/reference/README.md` | `../templates/docs.reference.README.md.tpl` | yes |
| `.github/ISSUE_TEMPLATE/bug.md` | `../templates/.github.ISSUE_TEMPLATE.bug.md.tpl` | if local |
| `.github/ISSUE_TEMPLATE/feature.md` | `../templates/.github.ISSUE_TEMPLATE.feature.md.tpl` | if local |
| `.github/ISSUE_TEMPLATE/config.yml` | `../templates/.github.ISSUE_TEMPLATE.config.yml.tpl` | if local |
| `.github/pull_request_template.md` | `../templates/.github.pull_request_template.md.tpl` | if local |

## README Placement

GitHub recognizes README files in the hidden `.github`, root, and `docs`
directories. For ordinary Python repositories, this profile defaults to the
root `README.md` as the surfaced repository landing page. Keep
`.github/README.md` out of default exports unless the target is a special
GitHub profile or default community-health repository.

## Not Forced In This Profile

- `docs/api/README.md`
- `.github/README.md`
