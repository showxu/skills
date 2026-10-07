# Maintainer Guide

## File Responsibilities

| File | Owns |
| --- | --- |
| `SKILL.md` | Trigger contract, modes, organization model summary, baseline, workflow, safety gates, routing table, validation, output |
| `references/topology.md` | Repository roles, placement map, documentation layout, licenses, naming |
| `references/governance.md` | Identity and signing, default branch, rulesets, repository and Actions settings, GitHub Apps, drift declaration, token scopes |
| `references/brand.md` | Design sources, rendering and delivery pipeline, typography, icons, social previews |
| `references/website.md` | Website role, deployment, catalog reconciliation, visual checks |
| `references/release.md` | Versions, tags, changelogs, tap and plugin updates, release order |
| `references/audit-checklist.md` | Takeover and upkeep audit items, how to find them, usual class |
| `references/operations.md` | Working area, audit and triage, change discipline, cleanup, authorized in-place rewrite, agent handoffs, acceptance, retrospective, pitfalls |
| `references/eval-fixtures.md` | Behavior fixtures |
| `evals/evals.json` | Runnable inputs and expected outcomes for the publication and governance fixtures; execution results stay outside the skill |
| `scripts/configure-clone.sh` | Per-clone identity, signing, credential helper, pre-push hook |
| `scripts/prepush-check.sh` | The pre-push gate |
| `scripts/scan_org.py` | Current workflow observations, license grouping, remote acceptance scan, local snapshot and comparison |
| `templates/MAINTENANCE.md.tpl` | Expected settings and review declaration |
| `tests/` | Executable gate and scanner regression cases |

## Boundaries

- Scripts that run from the operator's machine against any organization live
  here. Pipelines that run inside an organization (renderer, brand sync and
  check, settings check, reusable workflows) live in that organization's
  `.github`; this skill describes them and points to the reference
  implementation.
- Domain detail owned by a sibling skill stays there; this skill keeps only
  the organization-level decisions and the routing.
- No organization names, emails, key paths, or machine paths in reusable
  files; they arrive as parameters or environment.

## Validation

- `python3 <skill-creator>/scripts/validate_skill_package.py <this skill>`.
- `sh -n scripts/*.sh`; compile Python in memory or direct bytecode to the
  producer-owned ignored output directory.
- Set `ORG_TEST_OUTPUT` to that ignored directory and run
  `python3 -m unittest discover -s tests -v`. Tests create and remove fixture
  repositories and an ephemeral signing key; they never contact a remote.
- Exercise the gate in a scratch repository: a signed owner commit passes; a
  commit with an attribution trailer, a foreign identity, or no signature
  fails.
- Run `scan_org.py snapshot` and `compare` on a directory of checkouts; a
  tampered baseline must produce FAIL for status, index, stash, or worktree
  changes.
- Use `scan_org.py remote --work-dir <ignored-empty-directory>` so clone
  outputs remain owned and the location can be reused.
- Rerun the fixtures in `references/eval-fixtures.md` after changing the
  trigger, routing, gates, or baseline.
