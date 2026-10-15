# Maintainer guide

The skill is a staged serial workflow owning one repository's GitHub-side
standard. Authority resolution and audit precede mutations. It supports personal
repositories and organization members through the same contract.

| Surface | Responsibility |
| --- | --- |
| SKILL.md | Triggers, authority, serial stages, participation, routing, output |
| standard.md / governance.md | Overridable defaults, inheritance, signed work and immutable publication |
| ci.md | Ecosystem-neutral CI and pin observation patterns |
| presentation.md / renderers.md | Copy, headers, demonstrations, renderer input contracts |
| upload.md | Owner browser procedure, temporary Apple Events fallback, independent receipt |
| audit.md | Full semantic audit and bounded mechanical settings projection |
| scripts/configure-clone.sh / prepush-check.sh | Task-clone signing and repository-owned validation gates |
| scripts/render_social.py / render_terminal.py | Outlined card layout and light/dark recorded-session rendering |
| scripts/presentation.py | Shared design binding, digest and control-character validation |
| scripts/scan_repository.py | Accepted-ancestry signatures/subjects, tag type/signatures, parsed reusable-pin drift, workflow/content observations and license digest; reused by organization aggregation |
| scripts/requirements.txt | Pinned safe YAML parser for reusable-workflow caller discovery |
| scripts/audit_repo.py | Read-only settings capture and expected/observed comparison |
| tests / references/eval-fixtures.md / evals/evals.json | Helper regressions and durable behavioral inputs; execution output is ignored |

Variable inputs belong to the served project. DESIGN shape is intentionally
not guessed: the recipe binds resolved values to its reviewed design digest.
No project fonts, brand colors, key paths, check names or membership lists are
bundled. The icon and ecosystem release owners retain their implementations.

Validate with the skill-creator package validator, `sh -n` for shell helpers,
and `python3 -B -m unittest discover -s skills/github-repo-steward/tests -v` from
the collection root. Tests use `REPO_STEWARD_TEST_OUTPUT` under the collection's
ignored `.build/`. Use an ignored virtual environment with
`scripts/requirements.txt` installed for the scanner and its pin tests. The
tests use synthetic Git repositories, captured API pages and ephemeral SSH
signing fixtures; no owner keys or network. Font rendering smoke checks additionally need fonttools and a licensed input
font; do not bundle a workstation font into the skill. Run the behavior fixtures as qualitative review or isolated paired evals; label the
evidence correctly. Static package checks do not prove live uploads or triggers.
