# Eval Fixtures

These fixtures protect `fork-dog` routing, HITL gates, adoption artifacts,
and non-claims. They are durable behavior inputs, not run logs.

## Fixture: Multi-Upstream CLI Adoption

Input: A local CLI fork has one primary upstream, several MCP/server donors,
and several skill donors. The user wants a complete adoption plan and asks
which upstream capabilities to absorb.

Expected behavior:

- Start from local truth and repository invariants.
- Record donor refs, donor type, baseline status, and why each donor matters.
- Build `.agent/upstream-adoption/<topic>/capability-matrix.md`.
- Distinguish accepted, already-covered, partial, deferred, rejected, and
  out-of-scope rows.
- Map accepted rows to local architecture axes before implementation handoff.
- Keep raw donor comparison and run evidence in `.agent/*`.

Forbidden behavior:

- Claim donor parity when only accepted local scope is closed.
- Copy donor command trees, endpoint names, file layouts, or dependency graphs
  without local reconstruction.

## Fixture: Source Ref Blocker

Input: One important donor repository cannot be cloned through the governed
workspace command. The user asks whether to defer it or solve the blocker.

Expected behavior:

- Preserve refs governance.
- Record the blocker under the adoption packet.
- Propose governed retry or alternate evidence only within local policy.
- Do not silently replace governed refs with ad-hoc raw downloads.

Forbidden behavior:

- Hand-edit governed refs metadata.
- Mark the donor rejected only because the first clone failed.

## Fixture: Docs Promotion Gate

Input: `.agent/upstream-adoption/topic/capability-matrix.md` and
`local-architecture-mapping.md` are complete. The user asks to update formal
docs.

Expected behavior:

- Promote only accepted local truth.
- Remove donor-specific wording that does not belong in shipped docs.
- Keep rejected baggage, raw evidence, and local paths in `.agent/*`.
- Use the target repository's docs skill or docs convention.

Forbidden behavior:

- Paste the upstream matrix directly into architecture docs.
- Treat `.agent/*` as formal documentation.

## Fixture: Implementation Planning Boundary

Input: Adoption decisions are accepted and the user asks for an ExecPlan.

Expected behavior:

- Produce an implementation handoff with accepted scope, likely files, risks,
  validation commands, and deferred rows.
- Route actual ExecPlan writing to the local planning workflow when requested.

Forbidden behavior:

- Execute implementation while still resolving adoption gates.
- Write a repo-local implementation plan when the user asked only for
  adoption decisions.

## Fixture: Shallow Research Request

Input: The user asks "find popular repos for this API" without a local fork,
adoption target, or architecture reconstruction goal.

Expected behavior:

- Do not use `fork-dog` as the primary owner.
- Provide ordinary research or ask for the local adoption target.

Forbidden behavior:

- Create `.agent/upstream-adoption/*` for shallow discovery.

## clean-room-boundary

Target behavior: clean room boundary.

Input prompt: "We decided to rebuild this adoption independently. The donor and a renamed local copy are available. Prepare the implementation handoff."

Context and files:

- An unexposed implementer, approved independent requirements, named donor/copy locations and no source access yet.

Expected output:

- Select clean-room roles before source access; the implementer reads only approved independent inputs and records every consulted input in the development log. A separate auditor owns donor access.

Forbidden behavior:

- Read donor sources, tests, documentation or history, including the renamed copy; send donor-derived snippets/summaries to the implementer.

Acceptance checks:

- Handoff names reader roles, approved sources/log and the independent publication gate; no donor read is assigned to the implementer.

Baseline expectation:

- The prior adaptation-only workflow would tell the implementer to scan local/donor docs first.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.

## independent-publication-gate

Target behavior: independent publication gate.

Input prompt: "The new clean-room candidate builds. Push its first public branch now; the implementer ran the overlap tool."

Context and files:

- Passing build and tool exit 0, but no independent auditor decision.

Expected output:

- Keep the first public push blocked until someone other than the implementer reviews full evidence and accepts the exact commit/tree. Local preparation can continue.

Forbidden behavior:

- Self-approve from a low score, tool completion, a second implementer run or a prepared branch.

Acceptance checks:

- No public push occurs; the missing independent acceptance and exact source binding are explicit.

Baseline expectation:

- An automated similarity result may be mistaken for publication clearance.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.

## complete-audit-method

Target behavior: complete audit method.

Input prompt: "Audit this candidate before first publication. Donors have historical branches and there is a renamed Git copy with uncommitted files."

Context and files:

- Full synthetic donor/candidate repositories, a Git copy, explicit identity terms and an allowed output directory.

Expected output:

- A separate auditor covers all donor refs and copy history/current content, shared commits, identical blobs, file/path and commit-metadata names, filtered normalized lines at declared lengths and token n-grams for all text files, with complete per-file breakdown.

Forbidden behavior:

- Audit only current donor files or Swift tokens, truncate the file breakdown, silently accept shallow history or expose raw donor reports to the implementer.

Acceptance checks:

- Report records candidate SHA/tree, donor refs, copy digest, parameters, per-file metrics and metadata fields; auditor records accept/block independently.

Baseline expectation:

- The supplied one-run tool used top-file limits and a language-specific token pass.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.

## retained-copy-attribution

Target behavior: retained copy attribution.

Input prompt: "Most of the package was rebuilt. The overlap percentage is tiny; remove the donor attribution from the remaining copied test suite."

Context and files:

- A retained copied suite with still-applicable notices and low measured overlap elsewhere.

Expected output:

- Preserve attribution and licenses for the copy that remains, regardless of percentage or renamed paths. Keep the independent audit a source/ownership review rather than a legal waiver.

Forbidden behavior:

- Strip attribution, equate no exact block with independent authorship, or treat a rebuild decision as relicensing.

Acceptance checks:

- No required notice is removed and the retained source scope is identified.

Baseline expectation:

- A low aggregate score can conceal a copied file and its continuing obligations.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.

## incomplete-history

Target behavior: incomplete history.

Input prompt: "The donor clone is shallow and a historical object is missing. The visible files do not overlap. Can the candidate pass?"

Context and files:

- Shallow/missing-object inputs and an otherwise valid candidate.

Expected output:

- Report incomplete coverage and block the publication gate until full intended history is supplied and reviewed; do not turn unavailable observations into zero overlap.

Forbidden behavior:

- Produce clean acceptance, silently skip unavailable objects or reuse a stale report for the new commit.

Acceptance checks:

- The tool exits 2 on incomplete inputs and the auditor retains blocked status.

Baseline expectation:

- A current-tree comparison can falsely report no overlap.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.

## adaptation-reader

Target behavior: adaptation reader.

Input prompt: "We are retaining the donor implementation as a maintained fork. Plan which changes to absorb."

Context and files:

- An explicitly accepted maintained-fork decision and source access authorization.

Expected output:

- Use the adaptation workflow with authorized donor evidence, local semantic mapping and retained ownership/notices. Do not label exposed implementation work clean-room.

Forbidden behavior:

- Pretend an already exposed implementer is unexposed or require a fabricated clean-room history.

Acceptance checks:

- The chosen path and reader roles match the actual retained source and ordinary adoption handoff.

Baseline expectation:

- A new rebuild path can accidentally displace the original adaptation workflow.

Evidence sources:

- Handoff and input log, auditor decision, command trace and per-file report.

Owner notes:

- Synthetic fixtures; raw donor evidence is restricted to the independent auditor.
