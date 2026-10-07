# MCP Server Design

MCP is a backend surface for agent workflows. A server is valuable only when it
lets an agent take useful actions or retrieve useful context with less
ambiguity and lower context cost than direct API docs, CLI commands, or a
static skill reference.

## Capability Boundary

Use MCP when:

- The task needs repeated live operations against an API, CLI, local service, or
  remote system.
- The agent benefits from structured schemas, discoverable tools, auth-managed
  calls, or host-mediated safety.
- The operation is reusable across projects or agents.
- A local skill can explain trigger, setup/auth, safe use, output shape,
  validation, and failure diagnosis.

Do not use MCP when:

- The task only needs static knowledge or one command.
- A plain CLI wrapper is easier to inspect, test, and repair.
- The server would expose broad mutable actions without a skill or host policy.
- The domain collection should own the behavior and MCP would only hide
  important context.

## Tool Coverage

Start from the workflows agents must complete, then map back to operations.

- Comprehensive endpoint coverage gives agents flexibility to compose tasks.
- Workflow tools help when common tasks would otherwise require many fragile
  calls.
- Avoid thin endpoint wrappers that return large payloads and force the model to
  rediscover API semantics.
- Avoid over-composed tools that hide important decisions or make validation
  opaque.

When uncertain, start with composable read/list/get/search operations plus the
few write operations the workflow truly needs. Add workflow tools after evals
show repeated multi-call friction.

## Tool Names

- Use snake_case tool names.
- Prefix with the service or bounded domain:
  - good: `github_create_issue`, `slack_send_message`
  - weak: `create_issue`, `send_message`
- Use action + resource names.
- Avoid version/date suffixes unless the service exposes truly separate APIs.

## Context Budget

- Return high-signal fields by default.
- Provide `limit` and pagination for list/search tools.
- Prefer human-readable identifiers in Markdown output, while preserving stable
  IDs in JSON/structured output.
- Avoid dumping full raw API responses unless the caller requests JSON/detail.
- Use concise default output and detailed/JSON formats for diagnosis.

## Response Shape

Good tools usually support:

- Markdown/text for human-readable agent reasoning.
- JSON or structured content for programmatic processing.
- Pagination metadata: `has_more`, `next_cursor` or `next_offset`, and counts
  when available.
- Stable identifiers and display names together.

When using the TypeScript SDK, prefer `outputSchema` and `structuredContent`
where current SDK docs support them. When using Python FastMCP, use typed return
values or Pydantic models where supported. When using Swift, keep the protocol
adapter thin and express service inputs/outputs as normal Swift models before
mapping them into MCP schemas.

## Errors

Errors should teach the agent the next move:

- Include what failed and what parameter/resource caused it.
- Suggest narrower filters, smaller limits, auth setup, or a retry path.
- Do not expose secrets, stack traces, raw tokens, or internal URLs.
- Convert rate limit, auth, permission, not-found, timeout, and validation
  failures into distinct messages.

## Safety

- Mark tool annotations: `readOnlyHint`, `destructiveHint`, `idempotentHint`,
  and `openWorldHint`.
- Treat annotations as hints, not authorization.
- Mutating tools require host/user confirmation expectations.
- Store API keys outside code, typically environment variables or host-managed
  auth.
- For local streamable HTTP servers, validate host/origin behavior and avoid
  accidentally exposing the server beyond localhost.

## Transport

- `stdio`: local, single-user, simple setup, spawned by the host as a
  subprocess. Never log protocol noise to stdout; use stderr for logs.
- `streamable HTTP`: remote or multi-client server, easier to deploy behind web
  infrastructure and auth.
- `SSE`: legacy or compatibility path. Verify current MCP docs before choosing
  it for new work.

## Review Checklist

- Is MCP the right backend for the workflow?
- Is there a driving skill/project doc that tells agents when and how to use it?
- Are tool names service-prefixed and action-oriented?
- Do descriptions match actual behavior?
- Are inputs constrained and examples included where ambiguity is likely?
- Are list/search tools paginated and bounded?
- Are mutating tools annotated and confirmation-gated?
- Are errors actionable and non-leaky?
- Are build/run/eval commands documented?
