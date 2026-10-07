# Upstream / Donor Taxonomy

Classify each upstream before extracting ideas. One donor can have multiple
roles, but each role should name what to extract and what to avoid.

## Contents

- Official Platform / API Donor
- Official Package / Library Donor
- Mature Community Implementation
- Product / UX Donor
- Protocol / API Donor
- Test / Fixture Donor
- Naming / Documentation Donor
- Anti-Pattern Donor

## Official Platform / API Donor

Examples: Apple frameworks, browser APIs, protocol specifications, official
SDKs, system tools.

Extract:

- stable platform semantics
- lifecycle rules
- error, cancellation, and permission behavior
- naming that reflects platform concepts
- interoperability boundaries

Avoid:

- assuming the local framework must mirror every platform type
- copying platform implementation constraints into portable layers
- treating one platform's lifecycle as universal

Inspection questions:

- What semantics are stable enough to become local architecture truth?
- Which behavior is platform-specific adapter work?
- Which names clarify local concepts rather than merely echoing the platform?

## Official Package / Library Donor

Examples: official package APIs, first-party examples, reference libraries.

Extract:

- public API shape
- supported extension points
- configuration model
- test fixture expectations
- documented invariants

Avoid:

- copying package internals as architecture
- inheriting dependency graph or release constraints
- adopting file layout without local ownership reasons

Inspection questions:

- Which public shapes are durable?
- Which internals are accidental?
- What local facade or adapter would preserve the useful contract?

## Mature Community Implementation

Examples: widely used open-source libraries, production-proven community
frameworks, battle-tested examples.

Extract:

- practical capability coverage
- failure handling and edge cases
- extension model
- performance and test practices
- compatibility behavior

Avoid:

- importing project-specific abstractions
- copying workaround layers that only serve the donor's history
- treating popularity as local fit

Inspection questions:

- What hard-earned behavior should the local model preserve?
- Which choices are tied to the donor's runtime, host, or migration history?
- What is the smallest local semantic model that covers the same need?

## Product / UX Donor

Examples: competitor products, first-party app flows, mature product surfaces.

Extract:

- interaction model
- state model
- onboarding and recovery paths
- terminology that reduces user confusion
- workflow boundaries

Avoid:

- visual clutter
- brand-specific surface decisions
- product-specific navigation or monetization coupling
- copying screenshots as architecture

Inspection questions:

- Which user states and transitions matter locally?
- Which interaction semantics affect local software architecture?
- Which product-artifact facts should be handed off to the product owner
  instead of becoming architecture truth here?
- Which visual or product choices are irrelevant baggage?

## Protocol / API Donor

Examples: app-server protocols, REST/GraphQL APIs, streaming protocols, bridge
contracts, gateway patterns.

Extract:

- resource model
- request/response semantics
- event and stream shapes
- authorization and reconnect states
- compatibility constraints

Avoid:

- wrapping protocols in custom layers without a reason
- mixing transport concerns into domain semantics
- assuming protocol internals belong in public API

Inspection questions:

- What is the boundary between protocol, SDK, adapter, and host?
- Which states must be modeled explicitly?
- Which transport details should stay private?

## Test / Fixture Donor

Examples: official test suites, compatibility fixtures, benchmark suites,
sample inputs, golden files.

Extract:

- fixture contract
- edge-case taxonomy
- baseline and regression expectations
- test naming and scenario coverage
- acceptance behavior

Avoid:

- donor harness assumptions
- brittle golden-file layout
- infrastructure-specific test runner coupling

Inspection questions:

- What behavior should local tests prove?
- Which fixture shapes are portable?
- Which harness mechanics are donor-specific?

## Naming / Documentation Donor

Examples: official docs, high-quality reference docs, community terminology,
domain glossaries.

Extract:

- names that clarify local semantic concepts
- documentation structure that helps agents route work
- invariant descriptions
- user-facing term distinctions

Avoid:

- copying brand voice
- adopting donor names for concepts that differ locally
- letting docs structure dictate module structure

Inspection questions:

- Does the name reduce ambiguity in the local framework?
- Does the docs structure express architecture truth or only donor packaging?
- What should be cited as evidence instead of copied?

## Anti-Pattern Donor

Examples: donor systems with useful warning signs, overbuilt designs, brittle
APIs, abandoned abstractions, failed coupling.

Extract:

- failure modes
- boundary risks
- complexity traps
- migration hazards
- test gaps

Avoid:

- adopting the anti-pattern because it is familiar
- treating a failure as proof that the capability is unnecessary
- overstating lessons beyond the evidence

Inspection questions:

- What local design decision would avoid this failure?
- Which accepted capability still matters?
- What boundary rule should be recorded?
