# Evidence and repair boundaries

## Community evidence

These reports supply recovery principles, not universal release guarantees.
Fetch the relevant primary report when current status, storage compatibility,
or a released fix matters. Observations were reviewed on 2026-10-04. Closure
alone does not establish that every related failure was fixed. No private
rollout contents are included.

- [openai/codex #24388](https://github.com/openai/codex/issues/24388): reporters
  restored sessions after backing up and replacing only historical
  `input_image` parts inside the latest compacted `replacement_history` with
  small text markers. Identity, text, ordering and metadata were preserved.
  This supports `latest-compaction`, with loss of active historical pixels.
  It does not validate arbitrary raw-history rewrites.
- [openai/codex #31579](https://github.com/openai/codex/issues/31579): persisted
  history was repaired but requests still used stale in-memory data.
  Archive/unarchive unloaded that session; a recovery turn then completed.
  The report also involved incomplete tool history. Tail trimming is not a
  general image-repair rule; archive/unarchive is runtime-dependent.
- [openai/codex #43015](https://github.com/openai/codex/issues/43015): typed
  images produced large requests before successful compaction. Subsequent
  compaction removed old tool images and work resumed. This natural before/after
  observation did not control transport/backend conditions. It supports
  measuring aggregate active-history bytes, not a universal payload threshold
  or a proven manual raw-image repair.
- [openai/codex #41338](https://github.com/openai/codex/issues/41338): illustrates
  the gap between token estimates and inline-image request bytes. Token budgets
  alone need not bound transmission size.
- [openai/codex PR #40994](https://github.com/openai/codex/pull/40994) enables
  retained-image budgeting by default. [#33493](https://github.com/openai/codex/issues/33493)
  contains later image-history problems. Verify the installed/bundled runtime
  and current evidence before recommending a flag or promising upgrade recovery.

## Local helper contract

The Python helper is an independently written standard-library implementation
of narrow image substitutions. It is not an official Codex repair API or
upstream patch. Its local schema contract is:

| Scope | Exact supported container | Selection |
| --- | --- | --- |
| `latest-compaction` | `compacted.payload.replacement_history[].content[]` for `type:message, role:user` | Latest compacted record only; require a history list. |
| `tool-images` | `response_item.payload.output[]` for `function_call_output` or `custom_tool_call_output` | Explicit historical JSONL lines. |
| `user-images` | `response_item.payload.content[]` for `type:message, role:user` | Explicit historical JSONL lines. |

Only `type:input_image` parts with a string `image_url` beginning `data:image/`
and containing `;base64,` are replaced. Preserve remote/file references and
all other parts. String-encoded outputs are unsupported. Select by semantic
location and replay boundary, not every occurrence of an image keyword.
Existing markers/path wrappers survive; a marker does not retain visual
semantics or create a filesystem source that never existed.

Raw-history scopes adapt the reported principles. Establish record
age/completion, original-media preservation and failure evidence before
application. Selected line numbers are case-local inputs. Opaque compaction
and encrypted reasoning state stays opaque; do not edit internal strings,
synthesize checkpoints, or migrate databases to make a candidate fit.

Inspection hashes the source before/after streaming its records. Memory is
proportional to the largest record, not the whole file. A huge individual
record can still be expensive; use a supported runtime export if it exceeds
available resources. Console output omits prompts and media. Preparation
requires a fresh directory and makes recovery files private. These files are
sensitive even when console diagnostics are content-free.

Apply/restore revalidate backup/candidate hashes and the exact semantic diff,
preserve source permissions, and use atomic same-directory replacement. Hash
checks detect observed changes but do not provide a session-writer lock.
Independently verified runtime unloading is the concurrency precondition.
Restore accepts only the exact applied candidate hash; it cannot overwrite
new conversation records.

## Recovery evidence

Keep three independent facts visible:

1. Structural integrity: JSONL and exact permitted substitutions pass.
2. Operational recovery: a real model turn completes after reload.
3. Task continuity: the retained checkpoint is understood and essential images
   can be reopened when necessary.

A successful repair supports the intervention in that case. Changing model,
network, history and runtime together weakens causal attribution. Prefer one
intervention at a time; preserve request-size/error measurements when available.
Never infer billing loss or exact network limits from file bytes.
