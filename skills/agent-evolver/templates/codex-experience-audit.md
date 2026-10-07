# Scheduled Codex Experience Audit

Use `agent-evolver` with topic `codex-experience` in evidence-audit mode
for this workspace.

Target:

- Treat the automation `cwd` or `cwds` as the target repository or
  repositories.
- This prompt can run against any repository type. Do not assume the target is
  an agent skill collection unless the repository evidence shows that.

Scope:

- Read automation-local memory for this automation when it exists. Extract
  operational lessons, prior backlog signals, previous output-format
  corrections, and ledger-scope lessons. Treat it as an index and
  policy-history source, not as target-repo skill drift authority.
- Inspect project guidance, existing local skills, installed shared skills,
  Codex memory, rollout summaries, and raw sessions only when summaries are
  insufficient.
- Scan memory and rollout summaries every run. If raw current or archived
  sessions are needed, use an automation-local processed-evidence ledger with
  `collect_evidence.py --evidence-ledger <path> --no-update-evidence-ledger`.
  This first pass must only read the ledger for skips and collect candidate
  records; do not mark newly scanned raw sessions as processed before triage.
- For every scanned raw session file, assign exactly one disposition:
  `used-as-evidence`, `irrelevant/no-match`, `duplicate/covered`, `no-change`,
  `watch`, `accept-update`, `needs-owner-decision`, or
  `untriaged/incomplete`.
- Record raw-session `no-change` and `watch` outcomes in the ledger too, but
  only after that disposition has been assigned. Do not ledger
  `untriaged/incomplete` candidates; list them in the report for the next run.
- To write judged raw sessions to the ledger, rerun the helper with
  `--update-evidence-ledger` and either a uniform `--ledger-disposition` or a
  `--ledger-disposition-file` keyed by the helper output's `ledger_key`
  records. Do not use blanket write mode for a mixed or unjudged candidate set.
- Look for repeated workflows, repeated failures, stale skill instructions,
  missing validation rules, and recurring context agents had to rediscover.
- If Codex session evidence points to a skill's official docs, API docs, CLI
  help, schemas, resource endpoints, or observed host behavior being stale,
  record an official-knowledge verification question. Verify that source
  separately if source verification is also within the requested scope.
- Prefer updating an existing skill over proposing a new one.
- Recommend no change when evidence is weak or the work belongs in ordinary
  code, docs, release, CI/CD, product, or domain-specific collections.

Output:

- Evidence reviewed.
- Automation-local memory lessons and routed signals, if any.
- Skipped evidence sources and why.
- Processed-evidence ledger path, when raw sessions were scanned.
- Raw session files scanned and skipped by the ledger, including file path,
  session id or fallback identity, content hash, and `ledger_key`, when
  applicable.
- Raw session disposition for each scanned file, including any
  `untriaged/incomplete` candidates left unledgered.
- Existing skills and observed drift.
- Repeated workflows or failures.
- Official-knowledge verification questions.
- Suggested updates.
- Suggested new skills.
- Do-not-create decisions.
- Destination owner for accepted update packets:
  - `skill-creator` for each independently updatable existing target skill.
  - repository architecture review for new skills, splits, renames,
    ownership conflicts, or collection boundaries.
- Decision bucket for each actionable item:
  - `accept update`
  - `watch`
  - `no-change`
  - `needs owner decision`
- Priority order.
- Owner decisions needed.
- Backlog-ready summary using:
  `date | target repo | pattern | evidence | proposed action | decision | owner | closed by`

Safety:

- Do not create, edit, delete, split, merge, stage, commit, push, or open PRs.
- Produce recommendations and update packets only. Mutations require a separate
  explicit owner request and should run through the destination owner rather than
  this scheduled audit.
