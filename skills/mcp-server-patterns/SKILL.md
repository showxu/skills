---
name: mcp-server-patterns
description: Design, implement, or review MCP servers and MCP-backed skill/tool backends for agents. Use when building an MCP server, wrapping an external API as MCP tools, choosing stdio versus streamable HTTP, designing tool schemas/descriptions/annotations, adding pagination and response formats, writing MCP server tests or evals, or reviewing whether an MCP server is useful to an agent. Do not use for merely calling an already-available MCP tool, installing a bare MCP server without a skill/workflow owner, or domain-specific product implementation.
---

# MCP Server Patterns

## Purpose

Use this skill when MCP is the backend shape for an agent workflow. It provides
MCP server design, implementation, review, and evaluation patterns so the
server exposes useful, safe, and discoverable tools rather than thin API
wrappers.

This skill does not replace a domain skill. The domain skill owns task context;
the MCP server owns executable operations.

## When To Use

- Building or reviewing an MCP server.
- Turning an external API, CLI, or local service into MCP tools.
- Deciding whether an operation belongs in MCP, CLI, app URL scheme, or a
  plain skill reference.
- Designing tool names, schemas, descriptions, annotations, response shapes,
  pagination, errors, transport, auth, and safety boundaries.
- Creating read-only eval questions that test whether agents can actually use
  the server.

## When Not To Use

- Do not use this just to call an already installed MCP tool.
- Do not promote a bare MCP server as useful unless there is a skill/workflow
  owner that explains trigger, setup/auth, safety, output, validation, and
  failure handling.
- Do not route Swift, design, market, product, or app-store domain decisions
  here unless the current task is specifically the MCP/tool backend.
- Do not rely on stale SDK examples; verify current MCP and SDK docs before
  coding.

## Inputs To Inspect

- Target workflow and the agent task the server should enable.
- Existing API/CLI/service docs, auth model, rate limits, pagination, data
  model, and error responses.
- Host/client expectations: local stdio, remote streamable HTTP, OAuth/API key,
  account scope, and whether multiple clients will connect.
- Existing local skill or project docs that will drive this MCP server.

## Workflow

1. Read `references/design.md` first for the MCP capability boundary.
2. Decide whether MCP is the right backend. If a skill reference or CLI command
   is enough, do not create a server.
3. Choose tool coverage:
   - Prefer comprehensive, composable API coverage when agents may need
     flexibility.
   - Add workflow tools only when they remove real multi-call friction.
4. Design the tool contract before coding: names, input schema, output schema,
   response formats, pagination, annotations, errors, and safety gates.
5. Choose the implementation language from the host boundary, not from an
   upstream default. Use `references/implementation-shapes.md` for Swift,
   TypeScript, and Python selection rules.
6. Build shared infrastructure before tools: API client, auth, pagination,
   response formatting, error mapping, logging, and transport setup.
7. Validate build/runtime behavior without hanging the main process.
8. Use `references/evaluation.md` when writing evals or reviewing quality. Keep
   MCP server protocol, model runner protocol, and Codex/agent runtime behavior
   separate.

## Decision Rules

- A useful MCP server lets an agent complete real tasks with low ambiguity,
  bounded context, actionable errors, and clear safety hints.
- Tools should be discoverable across multiple servers: use service-prefixed,
  action-oriented names such as `github_create_issue`.
- Prefer structured outputs where supported, while still returning concise text
  for humans.
- List/search tools must enforce limits and expose pagination metadata.
- Mutating or external-world tools need explicit annotations and confirmation
  expectations in the driving skill or host workflow.
- Streamable HTTP fits remote/multi-client servers; stdio fits local
  single-user integrations.
- Swift is preferred when the MCP server belongs inside a Swift package, Xcode
  workflow, macOS app, or Apple-toolchain workspace. TypeScript is a strong
  public/default reference for npm, remote, MCPB, or broad host compatibility.
  Python fits scripting/data/local automation and Python-first API clients.
- Treat SSE and SDK API details as mutable; verify current docs before
  implementing.

## Validation Rules

Use the least invasive checks first:

```bash
swift build
swift test
npm run build
npx @modelcontextprotocol/inspector
python -m py_compile <server>.py
timeout 5s python <server>.py
```

Do not run a stdio server directly without a timeout or external session; it
may wait for MCP client input indefinitely.

## Output Format

For design/review tasks, return:

```text
Boundary: <why MCP is or is not the right backend>
Transport: <stdio | streamable HTTP | deferred>
Tools: <candidate tools or review findings>
Schemas: <input/output shape notes>
Safety: <auth, destructive operation, approval, and logging notes>
Validation: <commands/evals to run>
Open questions: <only blockers>
```

For implementation tasks, edit the relevant project files and finish with the
build/test/eval status.

## Source Receipts

This skill distills:

- ComposioHQ `awesome-codex-skills/mcp-builder/`
- ComposioHQ `awesome-claude-skills/mcp-builder/`
- Anthropic `skills/mcp-builder/`

Preserved source-specific guardrails: agent-centric workflow design, context
budget, actionable errors, service-prefixed tool names, structured and Markdown
responses, pagination, annotations, transport choice, security checks, and
read-only stable evals.
