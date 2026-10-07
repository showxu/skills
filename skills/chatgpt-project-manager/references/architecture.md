# Architecture

This is a staged serial skill. The agent resolves intent, identity, product
ownership, and verification. Helpers handle protocol framing, parameter checks,
pagination, guarded dispatch, journaling, and cwd recovery. It does not require
subagents or implement a UI automation engine.

## Owners

- `SKILL.md`: trigger, object-management contract, workflow, and output.
- `operations.md`: native/app-server/UI routing and operation semantics.
- `computer-use.md`: UI procedures under the active host's documentation and
  permission rules.
- `app-server.md` and `scripts/sidebar_app_server.py`: adapter to an explicitly
  selected running Codex server, not a replacement owner of desktop state.
- `cwd-recovery.md`, `state-model.md`, `repo-move-runbook.md`, and cwd scripts:
  conditional execution-directory recovery.
- `eval-fixtures.md`: behavioral scenarios. `scripts/tests/`: isolated tests.
  `compatibility.md`: dated interface evidence.

Account/workspace, backend, host, IDs, endpoints, paths, ordering, app versions,
and UI labels are runtime input or discovered state. Keep machine-specific
values out of executable defaults and reusable instructions.

## Adapter Boundary

The adapter exposes sidebar-related Codex methods present in the selected
binary's generated schema. It uses `app-server proxy --sock` to connect to an
existing server. Parameter shapes are checked locally; the server owns full
protocol semantics and authorization. Writes require an observed binding,
scoped IDs, current-state checks, and a durable attempt journal.

These checks cannot make several requests transactional, establish workspace
identity absent from the protocol, or equate server state with desktop state.
The agent establishes that mapping and verifies through the product owner.
The journal guards operation-ID reuse; it is not a scheduler, automatic retry
engine, cross-device lock, or cloud rollback mechanism.

## Validation

From the repository root:

```bash
python3 -m unittest discover -s skills/chatgpt-project-manager/scripts/tests -v
python3 skills/skill-creator/scripts/validate_skill_package.py skills/chatgpt-project-manager
git diff --check
```

Tests use a temporary fake proxy, generated-shape schema fixtures, and isolated
SQLite/rollout files. Recheck real schemas with the adapter `probe` command.
Report live verification separately and use explicitly selected test objects
for authorized writes. Behavioral fixtures are not measured agent benchmarks.
