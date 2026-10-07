# Capability Ledger

States: `covered`, `compressed`, `moved`, `deferred`, `blocked`,
`non-capability`.

## Source Scope

- Source:
- Commit:
- Paths:
- Candidate local owner:
- Authority requirement:
- Target collection rules consulted:
- Upstream/source-scope handoff:
- Cursor fields frozen:

## Capability Rows

| Source item | Effective information | Local destination | State | Reason | Authority status |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

Each row must have exactly one state from the allowed state list. Do not write
state alternatives such as `covered or moved`, `compressed/deferred`, or
conditional prose in the `State` cell. `covered` needs a concrete existing
destination. `compressed` needs the local equivalent and why behavior is not
lost. `moved` / `deferred` need an owner or destination and preserved evidence.
`blocked` needs a concrete blocker. `non-capability` must not hide setup,
permission, validation, failure-mode, or guardrail material.

## Section / Recipe / Guardrail Parity

States: `preserved`, `compressed`, `official-replaced`, `moved`, `deferred`,
`blocked`, `dropped-duplicate`, `non-capability`.

| Source section / recipe / guardrail | Local owner | Local equivalent | State | Reason |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Record meaningful headings, named workflows, examples, negative examples,
warning signs, required reads, preferred output shapes, scripts, templates,
validation checks, failure modes, and safety stops. Do not mark a section
covered by generic best-practice wording unless the local equivalent is named.

## Tool / Resource Handover

| Source item | Operations / value | Setup / auth | Output shape | Safety boundary | Validation / failure modes | Backend / adapter candidate | Owner / destination | Authority status | Preserved evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  |  |

## Closeout

- Source item count:
- Ledger row count:
- Missing rows:
- Duplicate mappings:
- Compression risks:
- Deferred rows with owner/reason:
- Moved rows with destination/evidence:
- Authority gaps:
- Section / recipe / guardrail parity:
- Non-skill handover rows:
- Proposed local edits:
- Validation:
- Upstream coverage receipt or cursor decision needed:
- Upstream cursor mutations performed by distiller: none
