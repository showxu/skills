# Proposal Doc Format

Use this rule when writing or normalizing documents under `docs/proposals/*`.

## Purpose

- Keep design-in-progress proposals concise, structured, and easy to review.
- Prepare change without treating the proposal as current architecture truth or
  an adopted decision record.

## Recommended Sections

- `# <title>`
- `Status`
- `Authors / Owners`
- `Summary`
- `Motivation`
- `Proposed Change`
- `Detailed Design`
- `Compatibility / Migration Impact`
- `Alternatives Considered`
- `Related Documentation`

## Format Expectations

- Keep the proposal focused on one change or one tightly related change set.
- Use the document to explain what is being proposed, why, and how.
- Keep current truth in `docs/architecture/*` until the proposal is adopted
  and architecture files are updated explicitly.
- Move adopted rationale into `docs/decisions/*` when the change becomes a
  decision record.

## Does Not Replace Truth Or Decisions

- Do not treat a proposal as the current repository model.
- Do not use a proposal as the only record of an adopted decision.
- Do not leave architecture truth implied only through proposal text.

## Basis

This rule is inspired by mature language and framework proposal processes. It
does not import any external review process.
