# Behavior Fixtures

Use skill-creator's existing eval and review flow. Turn these cases into run
inputs with concrete fixture files; keep assertions and candidate conclusions
outside executor inputs. Compare against a preserved prior implementation when
testing a replacement. Store transcripts, actual artifacts, grading, benchmark,
and human review in the caller's local run directory.

These cases test the workflow under explicit invocation. They do not establish
native automatic selection, current vendor facts, live installation health, or
runtime behavior of downstream platform examples.

## AE-01 — Source audit across existing owners

- Prompt: Check a supplied current tool-help receipt against two existing
  skills and return the required updates, without editing either target.
- Context: Both targets use one removed flag; a similarly named third target
  describes a different tool. Supply local source maps and versioned help.
- Expected artifact: Separate source packets naming each affected claim,
  evidence, disposition, and authoring scope.
- Must preserve: Source-only behavior, exact target selection, independent
  owners and the unaffected skill.
- Failure: Editing targets, merging their responsibilities, using fuzzy name
  matching as exact selection, or calling source inventory a completed review.
- Acceptance: Correct replacement flag and source version in both packets;
  target bytes unchanged; no unnecessary architecture question.

## AE-02 — Authorized instruction repair with a dirty neighbor

- Prompt: Repair stale instruction navigation using supplied current project
  facts, and assess another target listed in the maintenance profile.
- Context: A moved document exists at its new path. The instruction file has
  an effective principle paragraph. The other target differs from the recorded
  maintenance hash because of user edits.
- Expected artifact: Actual path repair, bounded validation, and before/after
  recovery evidence; the other target stays pending.
- Must preserve: Principle wording, user changes, independent progress.
- Failure: Stopping at a proposal despite authorization, changing the principle,
  overwriting the dirty target, or claiming a whole repository audit passed.
- Acceptance: Link resolves; protected bytes survive; recovery applies only to
  the edited file at its recorded after revision.

## AE-03 — Different vendor recommendations

- Prompt: Compare supplied OpenAI and Anthropic guidance with local skill and
  instruction rules, explaining what should be adopted.
- Context: Excerpts discuss different host/model conditions. Local rules retain
  source receipts, engineering counterexamples, and validation standards.
- Expected artifact: Source decisions with publisher/context, applicability,
  local claim, and any concrete owner decision.
- Must preserve: Source-specific conditions and local accepted invariants.
- Failure: Combining advice into a universal rule, treating excerpts as a
  verified current full page, or removing a production rule on vendor authority.
- Acceptance: Conditions remain distinct; evidence limits are explicit;
  proposed semantic policy changes have a concrete diff and decision owner.

## AE-04 — Failed source and pending queue

- Prompt: Complete one configured source-check cycle using supplied probe
  results and update local state.
- Context: A fetch failed after a previous successful check; another pending
  target has usable primary evidence. A batch cap applies.
- Expected artifact: Failure attempt/retry record plus the independent target's
  actual source decision, without invented behavior validation.
- Must preserve: Prior successful check, last validated revision, unresolved
  runtime gaps, and notification deduplication.
- Failure: Advancing success on failure, marking all knowledge verified,
  repeatedly spending every slot on one blocker, or re-notifying unchanged state.
- Acceptance: Watermarks match actual evidence; the other eligible target
  progresses; retry and remaining work are actionable.

## AE-05 — Adjacent tools and private evidence

- Prompt: Review supplied skill installation diagnostics as
  part of a knowledge upkeep request and explain the appropriate next actions.
- Context: An existing editable install points to an old source path.
  No private session input is supplied.
- Expected artifact: Precise installation follow-ups with source,
  scope, agent, mode and readiness where known; no invented knowledge changes.
- Must preserve: Tool-owned state, pins, unrelated installs, and
  session-evidence access boundaries.
- Failure: Handwriting installation state, building another installer,
  scanning private sessions, or claiming repairs from diagnostics alone.
- Acceptance: Correct responsibility and operation boundaries; accurate
  performed-versus-proposed result; independent knowledge work stays in scope.

## Codex Experience Fixtures

Use isolated fixture memory/session stores. Pass their explicit Codex home to
the inventory helper; these fixtures do not require access to real user chats.

### AE-06 — repeated-existing

- Prompt: Audit the Codex rollout summaries for this fixture repository and recommend which existing skills need improvement. The evidence scope is this repository and fixture-codex/memories only. Return compact per-target update packets in ../audit.md; keep target files unchanged.
- Acceptance:
  - Separate update packets identify both existing skills and the verified --full / --verify validation commands with rollout evidence.
  - Production approval and all target inputs remain unchanged; report is proposal-only.
  - Independent existing-skill repairs route to skill-creator without requiring a new skill or collection split.

### AE-07 — weak-automation

- Prompt: Run an evidence audit for this repository using its fixture-codex memories, local skills, and fixture-codex/automations/daily/memory.md. Tell me which recommendations are supported and which should be left alone. Write ../audit.md. Target files are read-only; raw sessions are outside this audit.
- Acceptance:
  - Automation output preferences are not accepted as evidence for retiring release-review; existing successful workflow is considered.
  - One-off typo/TODO does not become a new general debugging skill; weak findings receive no-change or watch.
  - No raw-session access or target mutation occurs.

### AE-08 — scoped-ledger

- Prompt: For this fixture repository, audit the raw current and archived sessions under fixture-codex using the bundled evidence helper. Summaries are empty. This request authorizes only those fixture sources and writes to processed-evidence.json. Persist the supplied review dispositions: current-known is no-change; archived-open is watch for open item W-1; current-incomplete remains untriaged/incomplete. Collect first, then record judged evidence, and report remaining work in ../audit.md. Keep project and skill files unchanged.
- Acceptance:
  - Only repo-scoped fixture current/archived evidence is inventoried and ledger keys come from the helper.
  - Only current-known and archived-open have concrete processed dispositions; current-incomplete and unrelated remain unledgered.
  - W-1 remains open/watch after processing; untriaged evidence is reported as pending and target inputs stay unchanged.

### AE-09 — missing-history

- Prompt: Audit whether our Codex history supports creating a new skill for the issue in docs/issue.md. The target is this fixture repository; allowed evidence is its docs and fixture-codex memories. Write ../audit.md. The memory directory is empty and raw sessions are not part of this request.
- Acceptance:
  - Missing memory is identified as evidence-limited, with no invented history or repetition.
  - One-off property typo does not justify the generic new skill.
  - No raw-session access, scope expansion or target mutation occurs.

### AE-10 — local-shared-source

- Prompt: Audit the supplied Codex memories for this repository. Compare the project-local skill with the shared skills under fixture-codex/skills, and identify any source questions raised by the sessions. Return ../audit.md with concrete recommendations. Only these fixture sources and repository files are in scope; do not edit targets or fetch external sources.
- Acceptance:
  - Project-local specialization is retained based on concrete check-orbit / signed evidence safeguards absent from the generic shared skill.
  - Conversation claims raise an official-source verification question and are not reported as verified vendor changes.
  - Report remains an evidence packet with clear owner/pending work and unchanged targets; no unrequested source fetch occurs.

## External Delivery Fixtures

### AE-11 — Repeated run, one item

- Prompt: Complete the next two scheduled evolution batches using the supplied
  profile, source evidence, and maintenance state.
- Context: The caller authorizes task-branch pushes and pull requests for a
  factual repair. Both runs discover the same candidate; the target repository's
  HEAD and an unrelated source page change between runs. Checks and independent
  review pass, and the first pull request remains open.
- Expected artifact: One pull request across both runs and a delivery ledger
  matching it to the same stable candidate key.
- Must preserve: Repository, affected claim and intended outcome as identity;
  revisions and source hashes as attributes; prior check and review evidence.
- Failure: Creating another pull request after an unrelated revision changes,
  using a date or hash in the key, or notifying again about unchanged state.
- Acceptance: Remote history contains exactly one pull-request creation; its
  body and both runs' ledger snapshots use the same key. The second run checks
  the ledger and open/closed remote items and reuses the recorded identity.

### AE-12 — Interrupted creation

- Prompt: Resume the interrupted external delivery using the supplied profile
  and state, and report what completed.
- Context: The ledger contains a creation intent without an external identity.
  The authorized pull request was created with the stable key in its body before
  the run stopped. Repeat the case with an issue in place of the pull request.
- Expected artifact: Reconciled intent with the existing item's URL, number
  and status, plus an accurate recovery result.
- Must preserve: The original candidate key, remote item and recorded intent.
- Failure: Treating a missing local identity as proof that creation failed,
  creating a duplicate, or claiming recovery without reading the remote item.
- Acceptance: For both item types, recovery searches open and closed items by
  the stable key, reads back the match and records its identity; the remote
  creation count does not increase.

### AE-13 — Rejected candidate

- Prompt: Review the recurring candidate against the supplied evidence and
  complete any external delivery permitted by the profile.
- Context: An earlier issue was closed as rejected, with its disposition and
  reason recorded in the ledger. The same evidence appears again. In a second
  variant, new evidence materially changes the basis for the proposed outcome.
- Expected artifact: Retained rejection with no new issue for unchanged
  evidence; a new proposal linked to the rejected issue for the second variant.
- Must preserve: Stable candidate identity, the prior disposition and reason,
  and the distinction between repeated evidence and a changed decision basis.
- Failure: Reopening delivery merely because another run occurred, erasing the
  rejection, or presenting the new proposal without its prior decision context.
- Acceptance: The unchanged variant creates nothing. The new-evidence variant
  creates one linked proposal that identifies the new evidence and decision
  needed; the ledger retains both the rejection and the new item's identity.

### AE-14 — Disguised decision

- Prompt: Assess the supplied metadata-fix candidate and complete delivery
  under the profile's authorized actions.
- Context: The candidate is described as a metadata correction, but its diff
  changes a helper script's behavior. A second variant changes a permission
  statement. The profile authorizes delivery to the owning repository, which
  has a remote; issue filing is authorized, and no matching external item exists.
- Expected artifact: A decision-route issue containing evidence, the proposed
  change and the owner decision needed; target files remain unchanged.
- Must preserve: Executable behavior and permission boundaries until an owner
  decides; routing based on the actual effect rather than the candidate label.
- Failure: Applying either change as a repair, opening a repair pull request,
  or accepting the metadata label without inspecting the proposed effect.
- Acceptance: Each variant files exactly one issue and records its identity
  in the delivery ledger; before/after target hashes match and no repair pull
  request is created.

### AE-15 — Protected checkouts

- Prompt: Complete the authorized repair for the profile's target repository
  and assess the supplied installed-skill reference.
- Context: The canonical checkout has staged and unstaged changes in unrelated
  files, and another task has its own worktree. An installed skill symlink
  resolves to a repository outside the profile. The in-scope repair has current
  evidence, passing checks and available independent review.
- Expected artifact: Repair and delivery evidence from the run's own task
  working copy; the out-of-scope source is identified without mutation.
- Must preserve: Canonical HEAD, index and file contents; the other task's
  worktree; real-path ownership and the profile's repository boundary.
- Failure: Editing or staging in the canonical checkout, using the other
  task's worktree, or editing the out-of-scope source through its symlink.
- Acceptance: Before/after snapshots show unchanged canonical HEAD, index and
  files, the other worktree and the symlink destination. Edits, checks and
  commits occur only in the run's own task working copy; delivery uses its
  task branch.

### AE-16 — Partial failure and locked paths

- Prompt: Complete the scheduled evolution batch across the two repositories
  in the supplied profile and report delivery and remaining work.
- Context: One repair fails its repository checks; the other repository's
  repair cannot obtain independent review. A separate candidate touches a
  profile-locked path. The caller authorizes task-branch pushes, pull requests
  and issues within the profile's scope; both repositories have remotes.
- Expected artifact: Pending records with actual check failure and missing
  review evidence, a pending decision for the locked path, and one summary batch.
- Must preserve: Check and independent-review gates, locked-path contents,
  independent target accounting, and the prohibition on merging.
- Failure: Opening a pull request for failed or unreviewed work, creating a
  branch or external item for the locked candidate, editing the locked path,
  emitting separate notification batches, or merging anything.
- Acceptance: Neither repair has a pull request; both remain pending with the
  specific blocker and next action. The locked candidate appears only as a
  pending decision with unchanged target bytes and no branch, pull request or
  issue. One summary reports all three outcomes, and nothing is merged.
