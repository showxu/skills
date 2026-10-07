# Agent Evolution Maintenance Architecture

This skill owns Agent evolution through topic-specific evidence and shared
per-target decisions. Official knowledge and Codex experience are topics of
the same skill. Each topic owns its collection, evidence thresholds and access
rules; the common workflow owns disposition, authorized repair, authoring
handoff and resulting state. Load topics from the actual task scope.

- SKILL.md owns trigger, modes, workflow, scope, and result.
- source-verification.md owns primary evidence, source maps and audit packets.
- codex-experience.md owns scoped memory/session collection and audit workflow.
- codex-evidence-rules.md owns behavioral evidence, candidate thresholds,
  processed-session ledger semantics and recommendation-only audit scope.
- instruction-and-skill-changes.md owns preservation and multi-source adoption.
- state-and-recovery.md owns durable progress/cache separation and recovery.
- eval-fixtures.md owns reusable behavior cases.
- scripts/collect_sources.py owns deterministic source-reference inventory.
- scripts/collect_evidence.py owns Codex evidence inventory and processed-session
  ledger mechanics. Its CLI and ledger identities remain stable across installs.
- templates/codex-experience-audit.md owns the optional scheduled experience
  audit prompt; an existing job must select and authorize that topic explicitly.
- references/licenses.md and LICENSE.dimillian own retained source attribution.
- agents/openai.yaml owns UI metadata.

The caller supplies targets or discovery scope, topics, mode and optional
state paths. This skill keeps its evidence, pending work and recovery state
using state-and-recovery.md. Current discovery determines collection-wide
target membership; previous records preserve progress and validation identity.

Source verification and experience evidence can justify an accepted reusable
rule in the owning skill, with attribution and applicability conditions. The
watch list, last-check result and current backlog belong to the project profile
and state; registering a link does not make its contents adopted knowledge.
Source receipts required by a skill's provenance contract remain in that skill.

Scheduling and installed skill links retain their existing product/tool owners.
Codex-specific paths and mechanics stay inside the experience topic. Source
freshness and processed-session state remain distinct; completing evidence
triage never marks an improvement implemented.

Before maintaining this skill, read its entry and this map, then only the
references and helpers affected. Preserve primary-source authority, scoped
source-only behavior, accepted instruction principles, source patch contracts,
validation integrity, session access and mutation gates, per-target ownership
and recovery semantics. Evidence-only experience audits remain proposal-only;
the common workflow continues only concrete authorized changes.

Use skill-creator for authoring and its existing evaluation/review flow.
Validate the whole skill package. Behavior cases must exercise source-only
work, authorized completion, multi-vendor guidance, pending/failed source
handling, scoped session triage and deduplication, adjacent responsibilities,
and protected user changes. Do not claim
host/runtime or proxy-trigger results that were not actually observed.
