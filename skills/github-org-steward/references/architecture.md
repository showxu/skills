# Maintainer guide

## Ownership

The organization skill owns shared authority, placement, organization settings,
scoped Apps, family identity/profile/pins, coordination and aggregate acceptance.
`github-repo-steward` owns one repository's GitHub-side standard, renderers,
upload procedure, local signing gates and per-repository acceptance observations.
No compatibility alias or duplicate per-repository procedure belongs here.

| File | Responsibility |
| --- | --- |
| SKILL.md | Organization-only trigger, authority, serial coordination, routing and output |
| topology.md | Repository roles and cross-repository placement |
| governance.md | Shared declarations, organization settings and authorized Apps |
| brand.md / website.md | Family source, job-grouped generated profile, pins and site integration |
| release.md | Capacity-bound rollout waves, measured development-cache gate, publication dependencies and downstream acceptance |
| operations.md / audit-checklist.md | Local preservation, authorized handoffs and organization acceptance |
| scripts/scan_org.py | Organization enumeration, delegation to repository observations, license grouping and local snapshot/compare |
| templates/MAINTENANCE.md.tpl | Organization-level declarations, with member settings delegated to their owner |
| tests / references/eval-fixtures.md / evals/evals.json | Scanner regressions and behavioral inputs; dated results stay ignored |

The scanner loads `github-repo-steward/scripts/scan_repository.py` from a sibling
skill installation or explicit `--repo-steward`. Missing dependency is an
actionable failure. It does not embed or fork that implementation. Runtime
GitHub operations use the existing CLI login; no credentials are bundled.
Install the repository steward's pinned Python requirements in an ignored
environment for its parsed workflow audit. UNKNOWN member evidence propagates
as exit 2; current FAIL is exit 1; historical REVIEW still needs disposition.

## Validation

Run the skill-creator package validator, collection checks and diff check.
Set `ORG_TEST_OUTPUT` to a reused producer-owned ignored directory and run
`python3 -B -m unittest discover -s skills/github-org-steward/tests -v` from the
collection root. Per-repository gate/observation tests run from their own skill.
Rerun relevant behavior fixtures after changing routing or coordination. Label
qualitative review separately from isolated comparative benchmark evidence.
