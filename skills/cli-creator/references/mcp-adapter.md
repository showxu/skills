# MCP Adapter

## Purpose

Use MCP when agents need tool calls for the same CLI product capabilities.
MCP should be a thin adapter over shared use-cases, not a second product
implementation.

## Rules

- Capability inventory owns whether a behavior is exposed through MCP.
- MCP tool schemas should be generated or checked against the same input
  schemas used by CLI/use-cases when practical.
- MCP tool names should be discoverable and action-oriented.
- Do not shell out to the CLI from MCP unless the CLI is intentionally the only
  stable execution boundary and the overhead is accepted.
- Do not duplicate endpoint calls in MCP when core use-cases already exist.
- Do not expose provider parameters on MCP tools unless the capability contract
  declares multiple supported providers for that tool.
- Do not expose implementation parameters just because the code uses multiple
  libraries or adapters. A capability with one intended implementation path
  should keep that path behind the use-case.
- Keep pagination, errors, and structured outputs agent-friendly.
- Transport choice is separate from product capability: stdio may fit local
  single-user use; streamable HTTP may fit remote or multi-client use.

## Validation

- MCP tool inventory matches capability inventory.
- CLI command and MCP tool for the same capability call the same use-case.
- Input schemas and implementation/provider exposure do not drift.
- Tool descriptions explain effects, required auth, and returned data without
  becoming API reference dumps.
