---
name: codex-thread-recovery
description: Diagnose and recover stuck local Codex Desktop or CLI threads after repeated images, oversized history, failed compaction, or reconnect loops. Use a thread ID or local JSONL rollout to produce structural diagnostics, a backed-up minimal repair candidate, and evidence of recovery. Owns scoped image-history repair and session reload guidance; does not own ChatGPT/API/cloud conversations, authentication repair, or database migration.
---

# Codex Thread Recovery

Recover one identified local thread through a staged serial workflow:
identify → measure → prepare → validate → apply → reload → verify.
Treat large image history as a hypothesis until logs or a controlled recovery
provide evidence. Preserve conversation identity, text, tool-call/output pairing,
opaque encrypted records, original media, and a byte-identical rollback input.

Read [evidence and repair boundaries](references/evidence-and-repair.md) when
classifying a failure or choosing repair scope. It owns the community sources
and the distinction between reported recovery and local adaptation. Read
[architecture](references/architecture.md) before maintaining the helper. Use
[eval fixtures](references/eval-fixtures.md) for behavior checks.

## 1. Identify the exact target and authority

- For a named chat, use the host's thread listing and bounded status tools.
  Resolve an exact thread ID and host. Do not guess among similarly named chats.
- Locate the rollout by thread metadata or an exact ID filename search in the
  configured local session directory. Use actual runtime paths. Check archived
  storage only if needed.
- Inspect installed/bundled version and storage format. The helper supports a
  regular UTF-8 JSONL file with one `session_meta.payload.id`. If storage is
  compressed, database-backed, remote, or has an unfamiliar schema, keep
  investigation read-only and use the owning runtime's supported recovery path.
- A diagnosis request authorizes diagnosis and candidate preparation. Carry an
  explicit request to repair the identified thread through the reversible
  repair; do not repeatedly ask for already granted authorization. Creating or
  invoking this skill alone does not authorize editing a thread.
- Resolve `RECOVERY_HELPER` to this skill's `scripts/rollout_recovery.py`.
  Set `ROLLOUT_PATH` to the exact selected file and `RECOVERY_DIR` to a new
  task-owned private directory outside the skill source and live sessions.
  These variable names in examples are caller-supplied paths, not global state.

If the target or permission is missing, ask only for that fact. Continue safe
candidate preparation while waiting. Preserve the original until the target
and repair authority are established.

## 2. Measure without replaying the whole conversation

```bash
python3 "$RECOVERY_HELPER" inspect --rollout "$ROLLOUT_PATH"
```

Use the thread ID, source SHA-256, file size, record types, image-bearing line
numbers, typed user/tool image locations, and latest compaction shape. The
output omits prompts and media contents. Inspect bounded logs for the first
failure, actual request bytes, transport fallback, compaction status, and
missing tool outputs. Do not print base64, credentials, or full tool bodies.

Distinguish rollout bytes, inline image characters, model tokens, serialized
request bytes, compressed bytes, and observed latency. The helper leaves
request bytes unmeasured; do not substitute file size. UI/event copies do not
prove that bytes enter the active prompt. Determine the replay boundary from
current runtime history reconstruction when necessary.

| Evidence | Action |
| --- | --- |
| Latest completed compaction retains old inline user images | Prepare `latest-compaction`. |
| No completed compaction; old typed tool/user images dominate active history | Identify exact historical records; prepare `tool-images` or `user-images` as an adaptation requiring verification. |
| Missing tool output or broken `call_id` pairing | Inspect pairing; image stripping cannot repair an absent result. Preserve evidence for a schema-aware repair. |
| Small request, service/network/authentication failure, or unavailable history | Diagnose the indicated layer; do not strip images merely because a thread is slow. |
| Disk repair succeeded but runtime keeps sending the old payload | Unload and reload the exact target session. |

## 3. Prepare the smallest reviewable candidate

```bash
python3 "$RECOVERY_HELPER" prepare --rollout "$ROLLOUT_PATH"   --workspace "$RECOVERY_DIR" --scope latest-compaction
```

For raw-history scopes, pass explicit inspected record numbers with
`--lines "$HISTORICAL_RECORDS"`. Select only completed historical image
results/messages no longer necessary in active visual context. Keep
recent/current images unless their removal is part of the authorized repair.
The helper fails if a latest compaction is absent; do not invent one or silently
switch scopes. Use a new candidate when the accepted scope changes.

The helper creates `original.jsonl`, `candidate.jsonl`, and `manifest.json`.
It replaces only typed inline `input_image` parts with an `input_text` marker;
existing text/path wrappers and lightweight image references remain intact.
Backups retain original image bytes, including uploads without separate files.
Explain that removed pixels leave active visual context and can be reintroduced
from source media or backup when needed.

Do not use regex against base64 or recursively replace arbitrary JSON strings.
Do not delete entire messages, reasoning/compaction blobs, tool-call IDs, or
failed tail turns just to reduce size. An incomplete-tail repair requires its
own evidence and complete pairing analysis; the helper does not perform it.

## 4. Validate, then apply within existing authorization

```bash
python3 "$RECOVERY_HELPER" check --workspace "$RECOVERY_DIR"
```

Require valid JSONL, the same thread identity and record count, byte-identical
unselected records, and exactly the selected image substitutions. This also
preserves unrelated text, pairing IDs and opaque encrypted values. Review
receipts and hashes; a valid candidate is not evidence of live recovery.

Before writing, establish that this exact thread is stopped and unloaded and
that no runtime/CLI writer is using it. Idle alone is insufficient. When
available, archive the exact target, confirm unload, apply, then return it to
its prior archive state. Use supported session controls and verify actual
state. Do not restart the whole app or kill shared app-server processes merely
to repair one thread while other tasks are active.

```bash
python3 "$RECOVERY_HELPER" apply --workspace "$RECOVERY_DIR" --thread-unloaded
```

`--thread-unloaded` is a caller attestation, not an unload command or a lock.
Record runtime evidence before passing it. The helper revalidates the candidate,
requires the live source to match the original hash, stages in the same
filesystem directory, and atomically replaces that file. If the source changed,
preserve new work and prepare a new candidate. Never override a mismatch.

## 5. Reload and verify actual continuation

Reload the target through the host. If authorized to submit a recovery turn,
send a short prompt asking it to confirm its current checkpoint. Otherwise
leave model-turn verification pending for the user. Permission to edit history
does not by itself authorize messaging another chat.

Require an actual completed model turn and usable thread state. Check that
the reported failure did not recur. For compaction recovery, require completed
compaction and a persisted supported checkpoint; UI text or HTTP 200 alone is
insufficient. A reload check strengthens persistence evidence. Verify task
continuity and reopen only essential images.

If the candidate fails and no new work was appended, unload the target and
restore the exact backup:

```bash
python3 "$RECOVERY_HELPER" restore --workspace "$RECOVERY_DIR" --thread-unloaded
```

Restore refuses a file changed since application. Preserve appended work for
separate merge/recovery instead of overwriting it. Keep the backup until the
user accepts recovery and retention is explicitly settled.

## Report

State the target, observed failure, measured evidence, supported versus adapted
scope, changed records and visual-context tradeoff, backup location, structural
validation, reload/model-turn results, and remaining uncertainty. Distinguish
**diagnosed**, **candidate validated**, **applied**, and **live recovery verified**.
A small file or passing helper check never proves causality or continuation.
