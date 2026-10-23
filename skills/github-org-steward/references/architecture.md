# Maintainer guide

## Ownership

The organization skill owns shared authority, placement, organization settings,
scoped Apps, family identity/profile/pins, coordination and aggregate acceptance.
`github-repo-steward` owns one repository's GitHub-side standard, README
information, upload procedure, local signing gates and per-repository acceptance
observations. `github-readme-design` owns README and profile layout and the
renderers.
No compatibility alias or duplicate per-repository procedure belongs here.

| File | Responsibility |
| --- | --- |
| SKILL.md | Organization-only trigger, authority, serial coordination, routing and output |
| topology.md | Data/document `.github`, executable `github-workflows`, member and template roles; promotion and pinning |
| governance.md | Rules versus checkers, enforced standard revision, organization settings and authorized Apps |
| brand.md / website.md | Family source, locally rendered and committed public/member profiles, pins and site integration |
| release.md | Organization VERSIONING extensions, capacity-bound rollout waves, measured development-cache gate, publication dependencies and downstream acceptance |
| operations.md / audit-checklist.md | Local preservation, authorized handoffs and organization acceptance |
| scripts/scan_org.py | Organization enumeration, delegation to repository observations, license grouping and local snapshot/compare |
| scripts/profile_observations.py | Public inventory, member-catalog observations, private visibility, default-branch/workflow/release facts and icon resolution; full schema validation belongs to the TypeScript renderer |
| templates/MAINTENANCE.md.tpl | Organization-level declarations, with member settings delegated to their owner |
| [Repository steward VERSIONING template](../../github-repo-steward/templates/VERSIONING.md.tpl) | Common policy for the organization's VERSIONING; release.md owns its organization-only sections |
| tests / references/eval-fixtures.md / evals/evals.json | Scanner regressions and behavioral inputs; dated results stay ignored |

The scanner loads `github-repo-steward/scripts/scan_repository.py` from a sibling
skill installation or explicit `--repo-steward`. Missing dependency is an
actionable failure. It does not embed or fork that implementation. Profile observations read only
the catalog fields they observe and fail when a required field is missing. The
TypeScript presentation toolchain owns full schema validation. Member dashboards
are rendered locally. The scanner compares the member input's repository names
with the current public catalog on `.github`'s default branch. Missing or extra
members produce a FAIL listing the differences and the need to regenerate the
dashboard locally. Matching membership produces INFO; declared operational facts
are checked against GitHub. The renderer owns the generated output contract and
accepts the selected `.github` commit through `--catalog-revision`.

The family's `github-workflows` owns reusable workflows and scripts/checkers,
self-tests with fixture packages and independent versions. Its organization
check runs from thin callers in `.github` CI for membership, About completeness
and declared/live settings, recording the enforced `.github` revision. Shared
changes pass fixtures and one representative member before rollout.
GitHub operations use the existing CLI login; no credentials are bundled.
Install the repository steward's pinned Python requirements in an ignored
environment for per-repository parsed workflow audits. UNKNOWN member evidence
propagates as exit 2; current FAIL is exit 1; unreadable profile evidence is
REVIEW; historical REVIEW still needs disposition.

## Validation

Run the skill-creator package validator, collection checks and diff check.
From the collection root, set `ORG_TEST_OUTPUT` to a reused producer-owned
ignored directory and run `python3 -B -m unittest discover -s
skills/github-org-steward/tests -v`. The organization tests use the Python
standard library. Per-repository gate/observation tests run from their own skill.
Rerun relevant behavior fixtures after changing routing or coordination. Label
qualitative review separately from isolated comparative benchmark evidence.
