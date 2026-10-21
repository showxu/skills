# Maintainer guide

The skill is a staged serial workflow owning one repository's GitHub-side
standard. Authority resolution and audit precede mutations. It supports personal
repositories and organization members through the same contract.

| Surface | Responsibility |
| --- | --- |
| SKILL.md | Triggers, authority, serial stages, participation, routing, output |
| standard.md / governance.md | Overridable defaults, inheritance, signed work and immutable publication |
| templates/VERSIONING.md.tpl | Shared version policy template; repository values fill its placeholders |
| ci.md | Ecosystem-neutral CI and pin observation patterns |
| information.md | What each product kind states, value owners, copy and demonstration content |
| upload.md | Owner browser procedure, temporary Apple Events fallback, independent receipt |
| audit.md | Full semantic audit and bounded mechanical settings projection |
| scripts/configure-clone.sh / prepush-check.sh | Task-clone signing and repository-owned validation gates |
| scripts/scan_repository.py | Accepted-ancestry signatures/subjects, tag type/signatures, parsed reusable-pin drift, workflow/content observations and license digest; reused by organization aggregation |
| scripts/requirements.txt | Pinned PyYAML for workflow discovery and Pillow for upload verification |
| scripts/audit_repo.py | Read-only settings capture and expected/observed comparison |
| scripts/verify_upload.py | Read-only social-preview RGBA and organization-avatar PSNR verification with private JSON receipts |
| tests / references/eval-fixtures.md / evals/evals.json | Helper regressions and durable behavioral inputs; execution output is ignored |

Variable inputs belong to the served project. No project brand values, key
paths, check names or membership lists are bundled. README layout and image
rendering belong to `github-readme-design`; the icon and ecosystem release
owners retain their implementations.

Validate with the skill-creator package validator, `sh -n` for shell helpers,
and `python3 -B -m unittest discover -s skills/github-repo-steward/tests -v` from
the collection root. Tests use `REPO_STEWARD_TEST_OUTPUT` under the collection's
ignored `.build/`. Use an ignored virtual environment with
`scripts/requirements.txt` installed for the scanner, pin tests and image
verification. Upload tests generate images and inject GraphQL/HTTP evidence. The
tests use synthetic Git repositories, captured API pages and ephemeral SSH
signing fixtures; no owner keys or network. Run the behavior fixtures as
qualitative review or isolated paired evals; label the evidence correctly. Static package checks do not prove live uploads or triggers.
