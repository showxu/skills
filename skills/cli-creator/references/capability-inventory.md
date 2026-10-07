# Capability Inventory

## Purpose

Use a capability inventory when the CLI surface is shared by multiple adapters,
implementation paths, or artifacts: CLI commands, MCP tools, generated
metadata, docs, bundled skills, tests, provider support when it exists, and
use-cases.

The inventory prevents drift by making product behavior the source of truth.

## Own This When

- The project has both CLI and MCP.
- A companion or bundled skill teaches agents how to use the CLI.
- Generated docs or schemas describe public behavior.
- Multiple implementation paths or providers implement overlapping
  capabilities.
- The command tree is large enough that coverage can regress silently.

## Suggested Fields

Use project-native syntax, but capture these concepts:

- capability id, such as `note.read` or `project.logs.list`
- public command path
- MCP tool name if exposed
- use-case or handler owner
- input schema owner
- output schema owner
- implementation owner, and provider support only when multiple providers exist
- auth/config requirements
- docs/skill references
- tests or probes that prove the capability

## Rules

- Capability is the product contract. Endpoint paths, DOM extractors, and MCP
  methods are implementation details until mapped to a capability.
- CLI and MCP should call shared use-cases instead of duplicating behavior.
- Implementation ownership should be explicit for every capability.
- Provider support must be explicit only when multiple providers exist.
- Do not turn fixed implementation ownership into a public provider matrix. A
  command with one best API, SDK, library, browser extractor, or local workflow
  should keep that implementation path internal and stable.
- Docs and bundled skills should describe capabilities that actually exist.
- Tests should fail when a public command or MCP tool has no capability row.
