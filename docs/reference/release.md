# Release

Release status: partly manual. [CI](../../.github/workflows/ci.yml) runs
repository validation; [VERSIONING](../../VERSIONING.md#release-procedure)
describes acceptance, tagging and publication by the maintainer.

Version rules for `showxu/skills`, covering tags, release timing, choosing the
next version and the changelog, are in [VERSIONING](../../VERSIONING.md). This
document records the repository's release facts and mechanics and does not
restate those rules.

## Components and Version Sources

The repository ships one `showxu-skills` plugin for Claude Code and Codex.

| Shipped component | Version meaning | Version source | Mirrors and derived fields | Update and read-only check |
| --- | --- | --- | --- | --- |
| `showxu-skills` plugin | Plugin release version | [VERSIONING](../../VERSIONING.md#version-source) | [VERSIONING](../../VERSIONING.md#version-source) | Manual update; `python3 -B scripts/check_repository.py` and `claude plugin validate .` |

## Compatibility Surface

Consumers depend on the plugin and marketplace names `showxu-skills`, the
skill names under [`skills/`](../../skills/), and the installation routes in
[`README.md`](../../README.md). VERSIONING classifies changes to this surface.

## Dependencies and Verified Combinations

Each skill's `SKILL.md` and declared requirements identify its dependencies
and required tools. [upstreams.yaml](../../upstreams.yaml) records tracked
sources; [CI](../../.github/workflows/ci.yml) declares the environments and
tool versions used by repository checks.

A collection-wide matrix of verified Claude Code and Codex version
combinations is not established. Host installation checks follow
[Plugin Distribution](../skill-authoring.md#plugin-distribution).

## Derived Metadata and Drift Checks

Version updates are manual; a version-generation command is not established.
`python3 -B scripts/check_repository.py` reads `VERSION` and checks the three
mirrors, plugin and marketplace identities, skill packages and committed
publication content. `claude plugin validate .` validates the Claude marketplace
manifest. Run changed skills' declared checks as
[CONTRIBUTING](../../CONTRIBUTING.md) requires.

## Candidate, Acceptance and Publication

Publication follows [VERSIONING's release procedure](../../VERSIONING.md#release-procedure),
including its tag name and message. The accepted artifact is the
repository tree at the accepted merge commit. Publication requires the
maintainer's repository write access and configured signing identity;
[CONTRIBUTING](../../CONTRIBUTING.md) records the review and merge requirements.

CI validates candidates. Automated release publication and a separate
collection build are not established. The marketplace sources are recorded in
[Plugin Distribution](../skill-authoring.md#plugin-distribution).

## Evidence Reuse and Invalidation

Use CI results for the exact candidate commit and the changed skills'
validation output. [MAINTENANCE](../../MAINTENANCE.md#validation) distinguishes
repository validation from behavioral evidence.

Automated evidence reuse and invalidation are not established. Review evidence
against the candidate's source, dependencies, check definitions, toolchain and
host environment; rerun affected checks when those inputs change. Installation
evidence follows [Plugin Distribution](../skill-authoring.md#plugin-distribution).

## Entry Points and Artifact Retention

Run commands from the repository root.

| Operation | Existing command or explicit manual procedure | Required access |
| --- | --- | --- |
| Version update and check | Manually update `VERSION` and its mirrors; `python3 -B scripts/check_repository.py` | Local repository write access |
| Candidate validation and build | `python3 -B scripts/check_repository.py`; `claude plugin validate .`; changed skills' declared checks; separate collection build not established | Local checkout and required tools |
| Status and interrupted-run recovery | Automated status and recovery not established; manually inspect Git, PR checks and tag/publication state before continuing VERSIONING's procedure | Local checkout; repository read access |
| Acceptance and publication | [VERSIONING's release procedure](../../VERSIONING.md#release-procedure) on the accepted merge commit | Maintainer repository write access and signing identity |
| Cleanup | Manually inventory and remove reproducible temporary outputs under `.build/` | Local filesystem access |

Keep temporary outputs under the ignored `.build/` directory, as
[MAINTENANCE](../../MAINTENANCE.md#validation) specifies. The task that creates
them owns cleanup. Preserve unique source changes, required evidence, active
processes and necessary rollback artifacts. Keep private paths and individual
run status in local records.
