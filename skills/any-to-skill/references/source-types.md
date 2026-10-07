# Source Types

## skill-source

A `skill-source` contains actual skill files, prompts, references, scripts, or
agent workflows.

`any-to-skill` handling:

- identify changed skill paths, trigger surfaces, references, scripts, and
  workflow files
- route the source to candidate local collections
- decide whether the current ask needs `skill-distiller`
- preserve source id, repo, path, commit, and owner evidence for the handoff

Do not perform capability compression here. Use `skill-distiller` for the
capability ledger, information conservation, section/recipe parity,
compression, and handover audit.

## curated-index

A `curated-index` lists other repositories or resources.

Handling:

- treat descriptions as discovery metadata
- follow original linked repositories before proposing local integration
- record each original source candidate when the intake is broad
- avoid treating index summaries as authority

## signal-source

A `signal-source` provides trend, prompt, internal-doc, product behavior, or
ecosystem signals.

Handling:

- extract topics or verification questions
- verify mutable facts against official or primary sources before local rules
- do not carry prompt/internal-doc wording into local skills

## tool and resource rows

Any source can include MCP servers, CLIs, editor extensions, app connectors,
tool services, official docs, public specs, resources, articles, or agent
workflow prompts.

`any-to-skill` handling:

- classify the row kind, source path, source commit, and candidate owner
- identify whether the row is direct skill-source material, discovery-only,
  authority candidate, tool/backend candidate, or future owner material
- pass routing-grade facts in the handoff packet when distillation is needed
- route standalone tools to a future tool/MCP owner when no current task-first
  skill can carry them
- treat official docs/specs as authority candidates, not as direct skill copy

Do not build the tool/resource handover ledger here. `skill-distiller` records
operations, setup/auth, host state, output shape, safety boundary, validation
path, failure modes, backend/adapter potential, owner/destination, authority
status, and preserved evidence.
