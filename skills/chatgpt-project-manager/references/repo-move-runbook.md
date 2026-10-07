# Repo Move Runbook

Use this runbook when a repository directory is moved or renamed and Codex
threads should continue to point at the moved repository.

## Order

1. Inspect thread state before moving anything.
2. Back up the repository with `.git`, untracked files, and any sibling repos
   that must remain separate.
3. Move the repository from a stable parent directory, not from inside the
   directory being moved.
4. Run batch cwd migration only after the target cwd exists.
5. Verify aggregate DB counts and rollout cwd alignment.
6. Scan adjacent Codex state for stale path references.

## Commands

Dry-run batch impact:

```bash
python3 <skill-dir>/scripts/migrate_threads_cwd.py \
  --old-cwd /old/repo/path \
  --target-cwd /new/repo/path
```

Apply batch migration:

```bash
python3 <skill-dir>/scripts/migrate_threads_cwd.py \
  --old-cwd /old/repo/path \
  --target-cwd /new/repo/path \
  --apply
```

Apply batch migration with historical turn-context workspace remap:

```bash
python3 <skill-dir>/scripts/migrate_threads_cwd.py \
  --old-cwd /old/repo/path \
  --target-cwd /new/repo/path \
  --remap-turn-context \
  --apply
```

Verify final state:

```bash
python3 <skill-dir>/scripts/verify_threads_cwd.py \
  --old-cwd /old/repo/path \
  --target-cwd /new/repo/path
```

Scan nearby Codex references:

```bash
python3 <skill-dir>/scripts/scan_cwd_references.py \
  --cwd /old/repo/path \
  --target-cwd /new/repo/path
```

## Interpretation

- A successful batch migration requires `exact old` to be `0` in every selected
  DB and `target rollout mismatches` to be `0`.
- Default migration updates `threads.cwd`, git metadata, and current-thread
  `session_meta.cwd` records. Use `--remap-turn-context` only when the old path
  is a workspace root move and historical `turn_context.cwd` /
  `workspace_roots` should be prefix-remapped too.
- Old subpaths are not migrated automatically. Review them one by one because
  they may point to sibling repos, stale directories, or intentionally separate
  workspaces.
- If the new cwd is nested under the old cwd prefix, pass `--target-cwd` so
  target rows and references are not misreported as stale old subpaths.
- Adjacent state scan is advisory. This skill can identify stale global config
  or automation references, but those files may be owned by Codex app or
  automation tools.

## Safety

- Do not patch before the target cwd exists.
- Do not trust per-thread success logs alone; always verify aggregate counts.
- Keep repo backups separate from thread DB/rollout backups.
- If Codex has cached the old cwd, durable migration can be complete while the
  live shell still needs a refresh or thread reopen.
