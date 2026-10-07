# Skill Authoring

This document defines collection-local structure expected for skills in
`<collection-name>`.

Create this file only when the collection has domain-specific authoring rules
that are not already covered by the root skill-authoring contract. If the
collection is still thin, keep this file absent and record only the docs index
in `docs/README.md`.

## Scope

Skills in this collection own <domain workflows>.

They do not own <common false matches>.

## Boundary Ownership

Apply the root skill-authoring boundary model before adding route language to a
skill:

- Leaf skills should define their own artifact, operation, and state boundary.
  They may preserve handoff evidence, but should describe next ownership by
  responsibility rather than hardcoding sibling names.
- Route stubs may name a concrete next entrypoint only for compatibility,
  migration, or discoverability, and must not execute the downstream workflow.
- Orchestrator skills may name concrete owners when routing is their output
  contract.

When a boundary changes, record whether the skill is acting as a leaf, route
stub, or orchestrator, and keep the current skill's own contract first.

## Expected Skill Shape

Use this section shape unless a skill has a clear reason to vary:

- Purpose
- When To Use
- When Not To Use
- Inputs To Inspect
- Workflow
- Reference Files
- Decision Rules
- Validation Rules
- Output Format
- Failure / Uncertainty Handling

## Naming

Use names that describe stable knowledge owners or durable tool surfaces. Avoid
names that describe only a usage mode, such as `review`, `audit`, or `helper`,
when the same knowledge system also applies to new work.

## Conservation Standard

When absorbing source-derived workflow material, preserve:

- setup assumptions and required local state
- good and bad workflow shapes
- failure modes and diagnosis paths
- validation commands and evidence expectations
- safety boundaries for live accounts, external services, or destructive
  actions

Do not compress workflow material into a pure glossary.
