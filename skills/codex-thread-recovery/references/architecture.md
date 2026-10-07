# Codex thread recovery architecture

This skill owns one staged serial workflow for identified local Codex JSONL
sessions. The agent selects scope from runtime/log evidence; the helper owns
backup, shaping, validation and guarded replacement. The runtime owns session
loading, compaction, model execution, database storage and concurrency.

| Artifact | Responsibility |
| --- | --- |
| `SKILL.md` | Trigger, diagnosis, repair authority, unload/reload and operational verification. |
| `agents/openai.yaml` | Manual entry into the same workflow. |
| `references/evidence-and-repair.md` | Primary evidence, supported shapes, adaptation limits and helper semantics. |
| `references/eval-fixtures.md` | Durable behavior fixtures, without execution claims. |
| `scripts/rollout_recovery.py` | Content-free inspection, private backup/candidate/receipt, exact-diff checks and guarded atomic apply/restore. |
| `scripts/test_rollout_recovery.py` | Synthetic deterministic regression coverage using temporary files. |

Keep personal paths, real thread IDs, prompts, images, diagnostics and recovery
outputs outside the source package. This skill does not synchronize upstream
repositories or guarantee issue resolution. Review compatibility through primary
sources; do not infer new schemas from field names. Unknown formats stay with
their runtime/storage owner.

Run bundled tests and the skill-creator package validator for mechanical
changes. Behavioral fixtures require isolated executor runs for benchmark
claims. Synthetic tests do not prove automatic triggering, UI unloading,
real model continuation or restoration of an actual user's thread.
