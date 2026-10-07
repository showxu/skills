# Reconstruction Patterns

Use these patterns to rebuild upstream ideas locally after boundary filtering.

## Contents

- DSL Reconstruction
- Runtime Abstraction
- Protocol / Facade Reconstruction
- Documentation Truth Reconstruction
- Test Harness Reconstruction
- UX Flow Reconstruction
- Semantic Model Reconstruction
- Layered Architecture Reconstruction

## DSL Reconstruction

Use when upstream examples reveal a clear authoring shape or declarative
semantic model.

Output looks like:

- local DSL concepts
- minimal public call-site examples
- type and builder boundaries
- docs explaining semantic intent

Avoid:

- turning the DSL into a general-purpose copy of the donor framework
- importing every layout or runtime feature
- letting syntax style override local semantics

## Runtime Abstraction

Use when multiple donors share runtime behavior but differ in transport,
storage, rendering, recording, or host integration.

Output looks like:

- public semantic model
- private runtime interface
- adapter or recorder boundary
- phase plan for backends

Avoid:

- exposing backend-specific details in public API
- accepting all future backends before the first slice is clear
- coupling production runtime to test or benchmark harnesses

## Protocol / Facade Reconstruction

Use when an upstream protocol, SDK, or app-server contract should be consumed
without leaking transport details into the local product model.

Output looks like:

- protocol evidence summary
- local SDK or facade boundary
- state and error model
- reconnect, authorization, and stale-state semantics

Avoid:

- wrapping a protocol only to rename it
- mixing bridge, gateway, relay, and app-domain responsibilities
- choosing network-provider-specific architecture too early

## Documentation Truth Reconstruction

Use when the main output is local architecture truth rather than code.

Output looks like:

- `Docs/Architecture` update for current truth
- `Docs/Reference` for accepted reference facts
- `Docs/Proposals` for options
- `Docs/Decisions` for accepted choices
- README or AGENTS.md routing updates when needed

Avoid:

- burying current truth inside donor comparison notes
- treating execution plans as architecture truth
- leaving future agents dependent on hidden chat context

## Test Harness Reconstruction

Use when donors provide useful fixture contracts, benchmark practices,
compatibility cases, or regression gates.

Output looks like:

- local fixture taxonomy
- acceptance scenarios
- baseline or regression policy
- harness boundary separate from production runtime

Avoid:

- copying donor harness mechanics
- making production code depend on benchmark runners
- preserving brittle golden-file layout without local need

## UX Flow Reconstruction

Use when product or UX donors reveal useful state transitions, onboarding,
approval, recovery, or empty-state behavior.

Output looks like:

- local state model
- interaction sequence
- screen or surface responsibilities
- product boundary between app, SDK, and service

Avoid:

- copying visual clutter or brand-specific flows
- turning a competitor product architecture into local architecture
- treating screenshots as complete requirements

## Semantic Model Reconstruction

Use when upstreams reveal a domain vocabulary, object graph, capability
taxonomy, or behavior contract.

Output looks like:

- local concepts and invariants
- public API or docs vocabulary
- mapping from donor terms to local terms
- rejected names and concepts

Avoid:

- copying names that do not match local meaning
- modeling every donor object
- hiding unresolved semantic conflicts

## Layered Architecture Reconstruction

Use when donors show several useful layers but the local framework needs its
own boundaries.

Output looks like:

- layer responsibilities
- dependency direction
- adapter points
- deferred layers
- implementation phases

Avoid:

- adopting donor layer count or file layout by default
- introducing bridge, gateway, relay, renderer, or host layers before they have
  separate responsibilities
- collapsing layers that protect local ownership
