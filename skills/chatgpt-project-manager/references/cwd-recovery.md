# Execution Cwd Recovery

Use this workflow only when Codex execution location must change or durable
execution state is inconsistent. Project membership and sidebar order have their
own operations. Read [state-model.md](state-model.md) before local recovery.

## Inspect and Choose the Invariant

Resolve the exact thread and requested execution path. Use `CODEX_THREAD_ID`
only for an explicitly current-thread task. Verify that the target exists and
is the intended root, secondary folder, subdirectory, or worktree. Do not infer
the target from the shell cwd or primary project folder when intent is unclear.

Read official project membership and folder bindings through supported surfaces;
unknown product state remains unknown. Inspect local durable state separately:

```bash
python3 <skill-dir>/scripts/inspect_thread_cwd.py \
  --thread-id <thread-id> --target-cwd <absolute-target>
```

The helpers honor `CODEX_HOME` or explicit `--codex-home`. They search the active
`sqlite/state_*.sqlite` layout before legacy `state_*.sqlite`. For a different
configured database location, resolve it first and select `--db` explicitly on
the single-thread helpers. Automatic batch discovery covers only its documented
active/legacy layouts. Run from a stable directory such as `/` if saved cwd no
longer exists and command startup otherwise fails.

Report DB path, thread ID, current/target cwd, effective rollout cwd, relevant
metadata history, git root/branch/origin, and live shell state. A membership move
with unchanged cwd is only incomplete when execution relocation was requested.

## Repair

Prefer a supported execution-setting operation and verify its actual effect.
Use guarded local repair only when that route is unavailable or leaves durable
drift. Ensure the user has authorized this execution repair and the concrete
target; do not repeatedly request the same authorization.

```bash
python3 <skill-dir>/scripts/patch_thread_cwd.py \
  --thread-id <thread-id> --target-cwd <absolute-target> \
  --sync-git-from-target-cwd
```

The command previews by default. Add `--apply` for the authorized write. The
helper creates and verifies SQLite/rollout backups before changing state.
Normal recovery appends current-thread `session_meta` while preserving original
records. It does not replace an actively written rollout to normalize history.

Git metadata comes from the repository containing the target cwd. If no such
repository exists, `--sync-git-from-target-cwd` clears stored branch/origin.
It does not select a child repository. Use `--branch`, `--origin-url`, or
`--clear-git` only for specifically requested overrides.

For a filesystem workspace-root change that also requires historical context
remapping, add `--old-cwd <old-root> --remap-turn-context`. This rewrites selected
cwd/workspace-root prefixes and is an explicit offline repair, not normal
current-thread append mode. Keep unrelated paths and parent/fork records intact.

## Batch and Verification

Use [repo-move-runbook.md](repo-move-runbook.md) after the filesystem operation
has placed the repository at its target. Repository file movement/backups have
separate ownership from these thread-state helpers.

```bash
python3 <skill-dir>/scripts/migrate_threads_cwd.py \
  --old-cwd <old-root> --target-cwd <new-root>
python3 <skill-dir>/scripts/verify_threads_cwd.py \
  --old-cwd <old-root> --target-cwd <new-root>
python3 <skill-dir>/scripts/scan_cwd_references.py \
  --cwd <old-root> --target-cwd <new-root>
```

Review the batch preview; add `--apply` for authorized execution. Use a stable
`--backup-root` and `--manifest` for a batch report. Exact old-cwd matches are
migrated; old subpaths need separate review. If a historical root remap is
requested, the batch command also supports `--remap-turn-context`.

Success requires zero remaining exact old-cwd rows and zero target effective-cwd
mismatches in every selected DB. Historical matching metadata may retain old
cwd values. Confirm original conversation records survive. If live shell cwd
lags durable state, report the remaining host refresh/reopen need.

Adjacent config/automation path matches are advisory; update automations through
their product tools when requested. Do not treat these references as thread cwd.

If a patch fails after DB mutation, the helper restores previous DB fields. If
rollout mutation also occurred, restoration must not overwrite subsequent
appends. Preserve the backup path and failure evidence when safe rollback cannot
be established. Never claim that a backup alone proves conversation consistency.
