# Agent Evolver Maintenance Architecture

The skill re-evaluates skills and instruction units when models, hosts or
agent tools change. It has two modes over one method: a read-only upgrade
audit, and cleanup of the findings the user approves.

- `SKILL.md` owns the trigger, modes, inputs, workflow and result.
- `references/upgrade-audit.md` owns host facts, the five dimensions, guidance audits, finding
  classes, recommendations, overlap, measurement and the report.
- `references/cleanup.md` owns the order, removal accounting, validation and
  delivery of approved changes.
- `references/instructions.md` owns how instruction files are produced,
  evaluated, changed and verified.
- `references/evidence.md` owns source classes, vendor guidance, version
  evidence and usage evidence.
- `references/eval-fixtures.md` owns behavior cases.
- `scripts/collect_sources.py` lists declared sources for exact skills.
- `scripts/usage_counts.py` counts skill use in local session logs, with
  maintenance sessions counted apart; `tests/` covers it.
- `references/licenses.md` and `LICENSE.dimillian` own retained attribution.
- `agents/openai.yaml` owns manual-entry metadata.

The caller supplies the scope, the target versions and evidence access.
Installation and the instruction rendering tool keep their own owners.

When maintaining this skill, read `SKILL.md` and this map, then only the
references and scripts the change affects. Preserve the read-only audit, the
approval gate before any target change, the with/without requirement for
retirement, and the units-not-rendered-files rule. Use skill-creator for
authoring and its eval flow, and validate the whole skill package.
