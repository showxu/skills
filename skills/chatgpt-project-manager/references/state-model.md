# Codex Thread CWD State Model

This reference documents the local state shape observed for Codex desktop
durable threads. It is version-sensitive and should be treated as an internal
implementation detail, not a public API.

The supported app surfaces establish product-visible project assignment and
thread state. The SQLite/rollout model below is empirical recovery knowledge;
it must not be presented as the official internal implementation contract.

## Supported App State

Codex project assignment is a product-owned state surface separate from cwd:

- Read a thread's official `projectId` from the supported Codex thread-listing
  surface.
- Resolve that id to its ordered local folder bindings through the supported
  Codex project surface, retaining the primary folder and any worktree mapping.
- Treat an official UI drag between projects as a project-assignment operation.
  It may leave the durable execution cwd unchanged.
- Do not treat a local SQLite `threads.project_id` value as authoritative for
  the official assignment. It can be absent or differ from the supported app
  surface. Do not patch it directly.

When supported app reads are unavailable, project assignment is unknown. Local
cwd inspection remains valid, but it cannot prove where the UI groups the
thread.

## Primary Files

- `~/.codex/sqlite/state_*.sqlite`: one active local state database layout. The
  relevant table is usually `threads`.
- `~/.codex/state_*.sqlite`: legacy local state database layout. These files
  can coexist with the active layout and may be stale; treat them as fallback
  candidates, not as the only source of truth.
- `threads.cwd`: durable execution workspace path used when restoring a thread.
- `threads.rollout_path`: JSONL conversation log path for the thread.
- Rollout `session_meta` records: JSONL records whose `payload.cwd` mirrors
  session cwd metadata. A rollout can contain multiple `session_meta` records.
  Treat only records whose payload id matches the canonical thread id as
  authoritative; fork/parent records can also appear in the same rollout.
- Rollout `turn_context` records: per-turn context records that can include
  `payload.cwd` and `payload.workspace_roots`. They are not the preferred
  durable cwd source, but Codex metadata extraction can use them when no
  session cwd has been established.

## Workspace Layers

There are five workspace layers with different ownership:

- Official project assignment: product-owned `projectId`, resolved to the
  saved folder bindings through the supported app surface. This controls UI
  project membership and is not the durable command cwd.
- Durable DB cwd: `threads.cwd` is the primary persistent thread workspace
  binding.
- Durable rollout cwd: matching current-thread `session_meta.payload.cwd` is
  session metadata and should be kept aligned with `threads.cwd`. Id-less
  single `session_meta` records are a legacy fallback. `turn_context.cwd` is
  inspected and may be explicitly remapped for workspace-root repair.
- Live shell cwd: the current host-provided command context, visible as shell
  `pwd` or `environment_context.cwd`. The migration scripts can inspect it but
  cannot directly mutate the parent Codex host process.
- Tool-call workdir: a per-command override chosen by the agent when invoking a
  tool. It is not persisted, does not write back to DB or rollout state, and is
  not a migration target.

The practical precedence for a command is:

```text
explicit tool_call.workdir > live shell/environment cwd > durable restored cwd
```

Changing durable state is how this skill influences future
`environment_context.cwd` values. It is not a direct environment patch.
Changing official project assignment is not part of that precedence and does
not by itself change command execution.

## Rollout Metadata Extraction

The observed Codex extraction path treats rollout metadata as a stream, not as a
single first-line header:

- `session_meta` affects thread metadata only when its payload id matches the
  canonical thread id. This avoids applying parent/fork session metadata to the
  child thread.
- Matching `session_meta.payload.cwd` is the authoritative rollout cwd. If
  several matching records exist, later matching records can supersede earlier
  values.
- `turn_context.payload.cwd` is considered only as a fallback when no session
  cwd has been set yet. It should not override a valid matching session cwd.
- `turn_context.payload.workspace_roots` may still carry old workspace paths
  after a repo move. Rewrite it only in explicit old-prefix remap mode.

Therefore repair scripts must scan the whole JSONL file. Reading or rewriting
only the first line is insufficient for modern rollouts and can miss drift or
patch the wrong thread metadata.

## Migration Invariants

Choose the invariant from the user's intent:

- Project membership change: official project assignment equals the requested
  project. A different execution cwd may be intentional.
- Execution-cwd repair: requested target cwd equals DB cwd and rollout
  effective cwd.
- Combined membership and execution move: assignment equals the requested
  project, and DB/effective rollout cwd equal the explicitly resolved execution
  target. The target may be a secondary folder, subdirectory, or worktree.

Choose changes by intent. Moving a thread into a project changes membership;
changing where commands run also changes execution bindings. Resolve a path-only
destination if its meaning is ambiguous. Section placement and sorting do not
establish execution intent.

For a clean durable cwd migration, these values should agree:

- the requested target cwd
- the `threads.cwd` value for the thread id
- the rollout effective cwd, preferably from current-thread `session_meta`
  records
- the last current-thread `session_meta.payload.cwd` value when multiple
  matching records are present

When the current process has already been reopened or moved by the host, the
active shell `pwd` should also agree. If DB and rollout already match the
target but shell `pwd` still shows the old cwd, durable migration is complete
and the remaining issue is host refresh/reopen latency.

When both membership and execution changes were requested, report each against
its own target. One may be complete while the other remains pending. A different
primary project folder and thread cwd alone do not establish an error.
Never repair official assignment by editing private SQLite project fields.

For batch migrations, verify the invariant at the database aggregate level, not
only at the per-thread command level. A successful run has:

- zero selected DB rows whose `threads.cwd` exactly equals the old cwd
- the expected number of rows whose `threads.cwd` equals the target cwd
- zero target rows whose rollout effective cwd differs from the target cwd

Legacy `~/.codex/state_*.sqlite` files may coexist with active
`~/.codex/sqlite/state_*.sqlite` files. Treat each DB as an independent state
surface for verification. Do not assume a thread id patched in one DB is patched
in the other DB.

If the saved cwd no longer exists, the host may fail to start shell commands
from the thread's default cwd. Run repair commands from a stable directory such
as `/` and pass the intended target path explicitly.

`threads.git_origin_url` and `threads.git_branch` are metadata derived from the
git repository containing `threads.cwd`. During a cwd migration, resolve git
from the target cwd itself. If the target cwd is inside a git repository, store
that repository's origin URL and current branch. If the target cwd is not inside
any git repository, clear both metadata fields. Do not inherit old git metadata
and do not inspect child directories to choose a repository.

Do not add automatic UI refresh behavior unless Codex exposes a stable,
documented local interface for it. The safe post-migration action is to inspect
state and tell the user whether a refresh/reopen may still be needed.

## Backups

Before writes, back up:

- the SQLite DB using SQLite's backup API
- any sibling `-wal` and `-shm` files for forensic recovery
- the rollout JSONL file

Backup creation is not enough. Before mutating state, verify:

- the SQLite backup is readable with `pragma quick_check`
- the backup contains the original `threads` row for the target thread id
- the rollout backup parses as JSONL
- the rollout backup hash matches the source rollout hash immediately after
  copying

Keep backups under `~/.codex/backups/thread-cwd-migration-YYYYmmdd-HHMMSS`.
Single-thread default backups include microseconds and the thread id to avoid
collisions during fast repeated calls. Batch migrations should use one migration
root and one child backup directory per DB label and thread id.

Filesystem repository backups are outside this state model. When a repo move is
coordinated with cwd migration, create repository backups separately before
moving files and before patching Codex state.

## Conversation Consistency

Cwd migration must preserve the conversation log, not merely produce a backup.
For rollout JSONL, post-patch validation should compare the backed-up rollout
with the written rollout structurally:

- original record count cannot shrink
- original JSONL records must remain in the same order
- for normal current-thread cwd patches, records present before the patch must
  remain structurally unchanged and a new current-thread `session_meta` record
  may be appended
- for explicit rewrite/remap patches, allowed changes to records present before
  the patch are limited to current-thread `session_meta.payload.cwd`, id-less
  legacy `session_meta` fallback cwd, and explicitly selected
  `turn_context.payload.cwd` / `workspace_roots` prefix remaps
- foreign parent/fork `session_meta` records, message records, tool calls, and
  response items must remain structurally identical
- trailing new records may be tolerated only when they were appended after the
  backup and all original records still validate

If validation fails after the rollout was replaced, automatic rollback is safe
only when the current rollout hash still matches the just-written hash. If the
file changed again, do not overwrite it with the backup because that can delete
newly appended records; stop and report the backup path for manual recovery.

## Known Risks

- Codex can change its private DB or rollout schema without preserving this
  recovery path. Re-inspect the local layout before every write.
- An official UI drag can create a project-assignment/cwd split that looks
  complete in the sidebar but still executes from the old repository.
- Local SQLite project fields can be absent or stale while the supported Codex
  app surface reports a valid project assignment.
- Codex may cache thread state while the app is running.
- The active shell process may keep its old cwd until the thread is reopened or
  the host starts a new command context.
- A future tool call can still run in an old directory if the agent explicitly
  passes that old path as `workdir`; this is a per-call override, not durable
  state drift.
- Replacing an active rollout file can detach Codex's open write fd from the
  visible path and lose later records on restart. Normal cwd patches must append
  a new `session_meta` record instead of replacing the file.
- Explicit rollout rewrites are for offline repair paths such as
  `--remap-turn-context`; use a size and mtime guard before replacing the file.
- A backup without structural validation can preserve a bad or stale state
  without proving the current conversation survived the migration.
- Rollout files can contain foreign `session_meta` records from parent/fork
  histories. Do not patch `session_meta` records whose payload id differs from
  the target thread id.
- `turn_context` remaps can alter historical per-turn context. Keep that as an
  explicit `--old-cwd` prefix rewrite, not the default single-thread patch.
- A migration writes both the DB row and rollout metadata. If the second write
  fails after the first one succeeds, restore the first write from the
  pre-migration values before exiting.
- Per-thread patch success is not enough for batch work. Recount old and target
  cwd rows after the batch and rerun or investigate remaining exact old rows.
- Old cwd subpaths are not exact matches. Review them manually because they may
  be separate repos or stale directories that should not follow the parent move.
- Manually forking a thread by duplicating DB rows is not validated.
