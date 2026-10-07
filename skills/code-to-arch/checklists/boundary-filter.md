# Boundary Filter Checklist

Use this checklist to decide what not to inherit.

- Does this upstream shape leak product-specific assumptions?
- Does the file layout belong locally?
- Does the dependency graph fit local boundaries?
- Does the donor runtime model fit the local runtime layer?
- Does this concept belong in public API, private runtime, adapter, renderer,
  host integration, docs, or tests?
- Is this naming semantic or just donor-specific?
- Is the behavior stable enough to become architecture truth?
- Is the donor's test harness separate from the behavior the tests prove?
- Does this interaction model carry useful state semantics, or only visual
  clutter?
- Would adopting this donor shape make future local phases harder?
- Is upstream being kept as evidence unless intentionally forked?
- Has every accepted donor idea been reconstructed in local terms?
