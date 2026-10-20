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
| topology.md | Repository roles and cross-repository placement |
| governance.md | Shared declarations, organization settings and authorized Apps |
| brand.md / website.md | Family source, public/member generated profiles, pins and site integration |
| release.md | Organization VERSIONING extensions, capacity-bound rollout waves, measured development-cache gate, publication dependencies and downstream acceptance |
| operations.md / audit-checklist.md | Local preservation, authorized handoffs and organization acceptance |
| scripts/scan_org.py | Organization enumeration, delegation to repository observations, license grouping and local snapshot/compare |
| scripts/profile_observations.py | Public inventory and pinned member-catalog checks, private visibility, default-branch/workflow/release facts and icon resolution; checks only the observed fields; full schema validation belongs to the TypeScript renderer |
| scripts/requirements.txt | Pinned PyYAML dependency for workflow caller observations |
| templates/MAINTENANCE.md.tpl | Organization-level declarations, with member settings delegated to their owner |
| [Repository steward VERSIONING template](../../github-repo-steward/templates/VERSIONING.md.tpl) | Common policy for the organization's VERSIONING; release.md owns its organization-only sections |
| tests / references/eval-fixtures.md / evals/evals.json | Scanner regressions and behavioral inputs; dated results stay ignored |

The scanner loads `github-repo-steward/scripts/scan_repository.py` from a sibling
skill installation or explicit `--repo-steward`. Missing dependency is an
actionable failure. It does not embed or fork that implementation. Profile observations read only
the catalog fields they observe and fail when a required field is missing. The
TypeScript presentation toolchain owns full schema validation. Member checks
resolve the standard commit from a dashboard workflow calling
`<org>/.github/.github/workflows/profile.yml@<sha>`. PyYAML parses every `.yml`
and `.yaml` workflow; only `jobs.<id>.uses` values identify callers. One distinct
SHA supplies the pin. Conflicts report REVIEW with the caller files and SHAs;
absent callers leave the pin unknown. Missing PyYAML reports REVIEW naming
this skill's `scripts/requirements.txt` to install.
GitHub operations use the existing CLI login; no credentials are bundled.
Install the repository steward's pinned Python requirements in an ignored
environment for per-repository parsed workflow audits. UNKNOWN member evidence
propagates as exit 2; current FAIL is exit 1; unreadable profile evidence is
REVIEW; historical REVIEW still needs disposition.

## Validation

Run the skill-creator package validator, collection checks and diff check.
From the collection root, create `.build/org-audit-venv` with `python3 -m venv`,
then install this skill's `scripts/requirements.txt` using that environment's
Python and `-m pip install -r`. Set `ORG_TEST_OUTPUT` to a reused producer-owned
ignored directory and run `.build/org-audit-venv/bin/python -B -m unittest
discover -s skills/github-org-steward/tests -v`. Also run the
`test_missing_pyyaml_reports_owned_requirements` case with a Python that has no
PyYAML on its import path. Per-repository gate/observation tests run from their
own skill.
Rerun relevant behavior fixtures after changing routing or coordination. Label
qualitative review separately from isolated comparative benchmark evidence.
