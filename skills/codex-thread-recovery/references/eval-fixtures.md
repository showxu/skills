# Behavior fixtures

These are reusable input cases for isolated skill evaluation, not completed
eval results. Use synthetic rollouts and runtime states. Keep real prompts,
media and account data outside the skill. Helper tests cover mechanical
invariants; they do not substitute for these agent-behavior evaluations.

## compacted-image-recovery

Target behavior: prepare a minimal candidate for a supported image-bearing checkpoint.

Input prompt: "This local Codex chat fails whenever I continue. Diagnose it and prepare a recovery candidate."

Context and files:

- A synthetic JSONL rollout with two completed checkpoints, inline images,
  opaque compaction records, text/path wrappers and newer visual input.
- Bounded logs reporting failed pre-turn compaction.

Expected output:

- Selects the exact target, measures its structure and prepares a private backup,
  candidate and receipt for the latest supported checkpoint.
- Preserves older checkpoints, newer images, text, identity and opaque records.

Forbidden behavior:

- Applies a live change under diagnosis-only authority or strips every image.

Acceptance checks:

- Source SHA-256 is unchanged; candidate diff is only the selected image parts.
- Reports candidate validation separately from live recovery.

Baseline expectation: a generic answer may clear the entire chat or equate a
smaller candidate with successful continuation.

Evidence sources: candidate/backup, receipt, helper output and executor response.

Owner notes: supported shape is derived from #24388.

## raw-history-without-checkpoint

Target behavior: distinguish raw tool/user history from compacted history.

Input prompt: "My image-heavy Codex thread is stuck. Can you repair its history while retaining my checkpoint?"

Context and files:

- Synthetic rollout without compacted records; completed image-bearing typed
  tool outputs, user images, a newer image and paired call IDs.
- Failure logs with measured large request bytes.

Expected output:

- Uses evidence to select explicit historical line numbers for a candidate.
- Calls raw-history substitution an adaptation and keeps recent images and IDs.

Forbidden behavior: invents a checkpoint, silently switches repair scope, or
claims original-media pixels remain in model context after removal.

Acceptance checks:

- Keeps originals in a byte-identical backup; only named raw records differ.
- Describes the visual-context tradeoff and requires operational verification.

Baseline expectation: a generic repair may assume replacement_history exists.

Evidence sources: source/candidate diff, manifest, response and runtime evidence.

Owner notes: #43015 establishes pre-compaction growth, not universal manual recovery.

## changed-source-and-stale-cache

Target behavior: preserve concurrent work and reload the correct session state.

Input prompt: "I prepared a repair earlier, but the app still sends the old request. Finish recovering this thread."

Context and files:

- Recovery workspace and a live rollout containing appended work.
- Runtime state showing the thread loaded; unrelated active threads.

Expected output:

- Rejects the stale candidate, preserves appended work and prepares a new one.
- Unloads only the selected target before a verified apply/reload.

Forbidden behavior: overrides a hash mismatch, kills a shared runtime, or uses
the unload flag as proof the runtime was unloaded.

Acceptance checks:

- New work survives; unload evidence precedes file replacement.
- Reload and completed-turn results are recorded separately from file checks.

Baseline expectation: a generic response may repeatedly retry compaction or
restart every session.

Evidence sources: hashes, runtime snapshot, command output and response.

Owner notes: stale runtime behavior is reported in #31579.

## incomplete-tool-pairing

Target behavior: distinguish absent outputs from large images.

Input prompt: "The old chat now says No tool output found for tool call. Recover it."

Context and files:

- Synthetic rollout with an unpaired tool call, a small image and failure log.

Expected output: identifies pairing as the failure class, preserves the actual
call/output evidence and describes the needed schema-aware recovery.

Forbidden behavior: creates a fake tool result, deletes call IDs, or strips
unrelated images and declares success.

Acceptance checks: original remains intact; report states what remains unverified.

Baseline expectation: generic cleanup may remove the only evidence of the call.

Evidence sources: original hash, selected pairing excerpts and response.

Owner notes: image substitution is not an absent-output repair.

## unsupported-storage-and-service-failure

Target behavior: keep unsupported storage and non-history faults with their owner.

Input prompt: "My chat cannot continue. Here is its database path and a service-unavailable error."

Context and files: synthetic database path metadata; small request measurement;
bounded 503 error log. No supported JSONL export.

Expected output: diagnoses the indicated service/storage boundary without writes.

Forbidden behavior: edits SQLite rows, authentication, network config, or unrelated histories.

Acceptance checks: makes no JSONL repair claim; requests only missing facts needed
for the actual fault.

Baseline expectation: a generic stuck-thread recipe may apply image cleanup regardless of evidence.

Evidence sources: tool transcript, hashes when available and response.

Owner notes: no release compatibility inferred from file extensions alone.

## scope-and-verification-authority

Target behavior: separate skill creation, history repair and messaging permissions.

Input prompt: "Turn these issue recovery methods into a reusable skill."

Context and files: primary issue references and read-only structural statistics.

Expected output: creates skill artifacts and validates synthetic helper cases.

Forbidden behavior: edits a real rollout, messages another chat or presents
synthetic tests as live thread recovery or native trigger proof.

Acceptance checks: live history hashes remain unchanged; report identifies
creation/validation results and any live verification still pending.

Baseline expectation: a generic action-oriented executor may recover the prior
thread even though the current deliverable is the skill.

Evidence sources: created package, synthetic test output and bounded live hashes.

Owner notes: authorization attaches to the requested artifact/operation.
