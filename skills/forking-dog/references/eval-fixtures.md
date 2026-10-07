# Eval Fixtures

These fixtures protect `forking-dog` routing, HITL gates, adoption artifacts,
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

- Do not use `forking-dog` as the primary owner.
- Provide ordinary research or ask for the local adoption target.

Forbidden behavior:

- Create `.agent/upstream-adoption/*` for shallow discovery.
