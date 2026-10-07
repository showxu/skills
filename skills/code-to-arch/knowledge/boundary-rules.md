# Boundary Filtering Rules

Use these rules to decide what not to inherit from upstream.

- Extract capability, not product coupling.
- Extract semantics, not accidental implementation shape.
- Extract API ergonomics, not dependency baggage.
- Extract tests and fixtures, not test harness assumptions.
- Extract interaction model, not visual clutter.
- Extract naming only when it clarifies local concepts.
- Preserve repo boundaries.
- Preserve module boundaries.
- Preserve runtime, adapter, renderer, host, and product-layer boundaries.
- Product / UX donor facts may inform architecture only when they affect local
  software semantics, state, workflow boundaries, API shape, or runtime
  boundaries. Route product artifacts, PRD content, discovery decisions,
  package placement, and interaction-design source truth to the product owner.
- Keep upstreams in references unless intentionally forked.
- Do not make local architecture depend on donor implementation details unless
  explicitly accepted.
- Do not promote upstream file layout to local layout without an ownership
  reason.
- Do not let one donor's product states define all local states.
- Do not collapse protocol boundaries into custom wrappers unless the wrapper
  is a deliberate local abstraction.
- Do not treat donor tests as sufficient local acceptance criteria until they
  are mapped to local behavior.
- `Docs/Architecture` is local truth; upstream is evidence.
- `Docs/Reference` holds current reference facts in product language: protocol
  and API references, compatibility references, and cited specifications.
  Donor notes and comparisons stay with the task.
- `Docs/Proposals` may hold options that are not current truth.
- `Docs/Decisions` should record accepted architecture decisions and rationale.
- `.agent` plans are execution control, not architecture truth.
- `AGENTS.md` routes agents to truth; it should not become the full manual.

## Boundary Questions

- Which local owner would maintain this concept if the donor disappeared?
- Is the extracted behavior portable across the local framework's intended
  hosts?
- Does this dependency belong in the local module where the behavior would
  live?
- Is the donor name semantic, or does it only make sense inside the donor?
- Would adopting this shape make local docs less clear?
- Can the local framework expose a narrower public surface?
- What future implementation would this decision force?
