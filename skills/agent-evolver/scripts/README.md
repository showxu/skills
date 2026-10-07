# Evidence Inventory Helpers

## collect_evidence.py

Run from any project repository to collect a bounded evidence inventory before
writing a Codex experience audit.

```bash
python3 /path/to/agent-evolver/scripts/collect_evidence.py \
  --root /path/to/project \
  --term important-module-or-script
```

By default the script scans project guidance, existing local skills, Codex
memory, and rollout summaries. It does not scan raw session files unless
`--include-sessions` is passed.

For recurring automations, include automation-local memory as policy and
backlog context:

```bash
python3 /path/to/agent-evolver/scripts/collect_evidence.py \
  --root /path/to/project \
  --automation-id <automation-id>
```

Use `--automation-memory /path/to/memory.md` when the automation memory lives
outside the default `$CODEX_HOME/automations/<id>/memory.md` path.

For recurring raw-session scans, pass an automation-local ledger path:

```bash
python3 /path/to/agent-evolver/scripts/collect_evidence.py \
  --root /path/to/project \
  --include-archived-sessions \
  --no-update-evidence-ledger \
  --evidence-ledger "${CODEX_HOME:-$HOME/.codex}/automations/<job>/processed-evidence.json"
```

The ledger is read-only by default: it skips records already processed for the
same target repo, source, session id, and content hash, but it does not mark new
raw sessions processed.

After report triage, write ledger entries only for files with a concrete
disposition:

```bash
python3 /path/to/agent-evolver/scripts/collect_evidence.py \
  --root /path/to/project \
  --include-archived-sessions \
  --evidence-ledger "${CODEX_HOME:-$HOME/.codex}/automations/<job>/processed-evidence.json" \
  --update-evidence-ledger \
  --ledger-disposition-file /path/to/dispositions.json
```

Use a uniform `--ledger-disposition no-change` only when every scanned file has
the same conclusion. For mixed outcomes, use a disposition JSON object keyed by
the helper output's `ledger_key` values. Do not ledger untriaged candidates.

## collect_sources.py

Inventory declared source references for exact skills in a repository:

```bash
python3 /path/to/agent-evolver/scripts/collect_sources.py \
  --root /path/to/repository --skill exact-skill-name --json
```

Repeat `--skill` for multiple exact targets. `--term` is fuzzy discovery only.
The output inventories source locations; source verification remains a separate
judgment in the official-knowledge topic.
