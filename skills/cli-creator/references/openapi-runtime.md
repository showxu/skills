# OpenAPI Runtime

## Purpose

Use OpenAPI when endpoint shape is stable enough to maintain as a contract.
Use generated clients and models for request/response shape, while keeping
local runtime behavior in hand-written runtime/adapter code.

## Layering

```text
OpenAPI contract
  -> generated client/models
  -> local operation policy registry
  -> runtime transport
  -> core use-cases
  -> CLI / MCP / skills
```

## Runtime Policy

OpenAPI can carry local vendor extensions for runtime policy, such as:

```yaml
operationId: searchItems
x-runtime-policy:
  auth: cookie
  signing: web
  host: main
  implementation: api
  risk: read
```

The extension is local policy. It is not a request field and must not be sent
to the external service unless the service explicitly defines it as wire data.

Use a project-specific extension name when the repo already has one, for
example `x-<tool>-runtime`. Keep the meaning documented.

## Codegen Rules

- Prefer established OpenAPI generators over writing a full generator.
- Do not hand-edit generated files.
- Keep generated clients pure: no cookies, signing, retries, risk gates,
  browser fallback, or secret handling inside generated code.
- Use minimal template overrides only when operation identity or packaging
  cannot be exposed reliably any other way.
- Keep capability input schemas separate from wire request schemas unless they
  are truly the same shape.
- Avoid generic JSON request bodies for stable POST operations when the request
  shape is known.

## Runtime Rules

- Runtime chooses host, auth, signing, cookies, retry, cache, and fallback from
  the operation policy registry.
- Public provider selection is not required for OpenAPI-backed CLIs. A service
  may have one generated-client implementation path for a capability.
- Use-cases call operation ids or local flows, not scattered hardcoded URIs.
- Tests should prove runtime uses operation policy rather than path-prefix
  heuristics.
- Diagnostics should preserve capability-level attribution when one endpoint
  supports multiple capabilities.
