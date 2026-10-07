# Topology and Placement

## Repository Roles

| Role | Shape | Typical name | Owns | Notes |
| --- | --- | --- | --- | --- |
| Organization | Both | `.github` | Profile README, `MAINTENANCE.md`, `DESIGN.md`, `Brand/`, default community files, reusable workflows, organization scripts | Owns its shared code and documentation license. Public, or GitHub will not apply its community files. |
| Main app | Product family | product name | Product source, ProductIdentity (meaning, positioning, copy), app releases | The product's source of truth for words. |
| Companion CLI | Product family | `<tool>-cli` | CLI source and releases | Distributed through the tap. |
| Plugins | Product family | `plugin-<host>` | One host integration each; a manifest declaring the minimum host version | Notify the website after each release. |
| Package | Package collection | `<language>-<name>` | Package source, its products and supported platforms, its release policy | Command-line tools ship through the tap. |
| Template | Package collection | `<language>-package-template` | The layout, CI, and release checks new packages start from | A GitHub template copies once; existing packages do not follow its changes, so carry them over by pull request. |
| Agent skills | Either | `skills` | Agent skills for the organization's repositories | Released like a package. |
| Website | Both | `<org>.github.io` | Pages, docs, setup guides, catalogs, release reconciliation | Deployed by GitHub Pages from the default branch. |
| Homebrew tap | Both | `homebrew-tap` | Formulae rendered from reviewed templates | Updated by automation pull requests. |
| Fork | Both | upstream name | A maintained patch line | Keeps upstream branch names, license, and community files; tags `X.Y.Z-<org>.N`. |

Private repositories on the Free plan get no rulesets; keep anything that needs
enforcement public or budget for a paid plan.

## Placement Map

| Artifact | Lives in | Never in |
| --- | --- | --- |
| Conventions every repository shares | `.github/MAINTENANCE.md` | Each repository's README |
| Expected GitHub settings, Apps, credentials | `.github/MAINTENANCE.md` "GitHub settings" section | Hidden config files, issue comments |
| A repository's own version and release rules | `Documentation/Architecture/VersioningAndRelease.md`, or its README when it has no Documentation | `MAINTENANCE.md` |
| Visual identity | `.github/DESIGN.md` and `Brand/config.json` | Consumer repositories (they receive exports) |
| Product meaning and copy | Product family: main repository ProductIdentity. Package collection: each package repository | `DESIGN.md`, the website |
| Rendered brand files | `.github/Brand/Exports/`, delivered to `Documentation/Brand/` (packaged docs) or `.github/brand/` (social previews) with a lock | Hand-edited copies |
| Code of conduct, support, governance, issue and pull request templates | `.github` only | Repositories |
| `CONTRIBUTING.md`, `SECURITY.md` | `.github` as fallback; a repository keeps a short `CONTRIBUTING.md` with its build and verification commands, and its own `SECURITY.md` only when scope differs | - |
| `LICENSE`, `CODEOWNERS`, `dependabot.yml`, workflows | Each repository (not inherited) | `.github` as a fallback |
| Agent guide | `AGENTS.md` per repository: shared first-principles and canonical-artifact sections, then a task route through that repository's documents | README |
| Agent working state | `.agent/`, local and untracked | Any commit |
| Process material: audits, evidence, per-version reports | The owner's scratch area; release records in the GitHub Release | Committed files |

A repository's own `.github/ISSUE_TEMPLATE/` replaces the organization's
templates entirely, so repository-specific fields belong in the shared
templates.

## Documentation Layout

- `README.md` is the entry point and index.
- `Documentation/Architecture/` holds current design truth,
  `Documentation/Reference/` operating detail, `Documentation/Decisions/`
  accepted rationale.
- `Scripts/` holds scripts; executables use kebab-case names with an
  extension, imported Python modules use snake_case.
- Per-version process files are not committed; release notes are rendered from
  `CHANGELOG.md` and version-independent templates. Add an anti-accumulation
  check when a repository has a history of piling them up.
- Shipped documents describe current facts and supported behavior. History
  stays in commits, pull requests, changelogs, and decision records.

## Licenses

- Pick per role and keep same-license `LICENSE` files byte-identical; the
  acceptance scan groups them by digest.
- A license change applies from the next release; published releases keep
  theirs. Bundled third-party material keeps its license, listed in
  `THIRD_PARTY_NOTICES.md`.
- Legal documents (license, EULA, privacy) change only with explicit owner
  approval.

## Naming

- Repositories: role-based as above.
- GitHub Apps: say what they do (`<Product> Release Notifier`,
  `<Product> Updater`), not "Automation" or "Bot". Renaming an App changes its
  slug and bot login and keeps its client ID and keys.
- Credentials: `<PREFIX>_APP_CLIENT_ID` variable and `<PREFIX>_APP_PRIVATE_KEY`
  secret. Choose the prefix once; renaming a secret needs a new key, because
  secret values cannot be read back.
- Default branch: one name for the organization; renaming it later means a
  rename per repository plus every local clone (`references/governance.md`).

## Adopting External Code

Inventory source revision, license, copyright notices, modifications and
vendored test suites before changing product names or packaging. Remove stale
upstream feature claims from current prose; retain still-applicable ownership
and provenance. A package collection can choose one license for original work
and SPDX headers while its NOTICE identifies third-party material and terms.
That choice does not relicense dependencies or vendored fixtures.

Keep notices required by the original license. For example,
[Apache-2.0 section 4](https://www.apache.org/licenses/LICENSE-2.0) requires
license delivery, change notices and relevant source attribution. Retain the
license beside a vendored test suite. Record unresolved redistribution rights
as a publication decision instead of inventing a grant.

A claimed independent rewrite needs evidence of how it was produced and a
provenance review. Exact-block comparison, including a six-line threshold,
is only a diagnostic signal: a clean comparison cannot prove independence or
justify deleting required attribution. Route uncertain license interpretation
to the owner; preserve the facts while independent implementation work proceeds.
