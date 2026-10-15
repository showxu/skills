# Maintainer guide

The orchestrator owns adoption decisions and handoffs. Adaptation readers can
inspect donors; clean-room implementers cannot. Only a separate auditor owns
the restricted overlap evidence and first-public-push acceptance. This topology
is part of the explicit clean-room contract; it does not authorize spawning or
contacting other agents automatically.

| Surface | Owns |
| --- | --- |
| SKILL.md | Adoption path selection, roles, gates and orchestration |
| references/clean-room.md | Implementer boundary, development log, independent gate and diagnostic contract |
| scripts/overlap_audit.py | Read-only candidate versus full-history/local-copy overlap evidence |
| templates/ | Adoption scope, handoff and closeout, including conditional clean-room records |
| references/eval-fixtures.md / evals/evals.json | Durable behavior inputs; raw reports and run artifacts are private outputs |
| tests/ | Synthetic Git history/copy, lexical filtering, filename and CLI failure regressions |

The overlap tool generalizes the supplied audit method. All repository paths,
identity terms, syntax choices, diagnostic lengths and n-gram sizes are inputs
or documented defaults. It does not decide legal rights or audit acceptance.
Source tracking/cursors and domain implementation remain with their owners.

Validation: skill-creator package validation, root collection/publication and
whitespace checks; set `OVERLAP_TEST_OUTPUT` to the collection's ignored
`.build/fork-dog-tests` and run `python3 -B -m unittest discover -s
skills/fork-dog/tests -v`. Fixtures are qualitative review unless run with the
skill-creator isolated paired evaluation flow; do not invent benchmark evidence.
