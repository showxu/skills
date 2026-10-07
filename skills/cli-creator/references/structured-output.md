# Structured Output

## Purpose

Stable machine-readable output is what lets agents compose CLI commands
without scraping human tables.

## Policy Choices

Decide and document:

- global `--json` flag versus per-command output flag
- pass-through API payload versus CLI-owned envelope
- success shape
- error shape
- pagination metadata
- file/artifact output references
- schema/version fields if consumers need stability over time

## Recommended Envelope

Use a small envelope when the CLI owns composition, diagnostics,
implementation or provider attribution, pagination, or artifact paths:

```json
{
  "ok": true,
  "command": "resource.action",
  "data": {},
  "meta": {
    "implementation": "api",
    "limit": 20,
    "cursor": null
  }
}
```

Errors should be structured and must not expose credentials:

```json
{
  "ok": false,
  "error": {
    "code": "auth_missing",
    "message": "Authentication is not configured.",
    "hint": "Run the setup command or set the documented environment variable."
  }
}
```

When the target already has a stable output contract, preserve it unless it
prevents agent-safe composition.

## Rules

- Human output may be optimized for readability. JSON output is a contract.
- JSON errors must be valid JSON even when the command exits non-zero.
- Do not include full tokens, cookies, secrets, or sensitive headers.
- Paginated list output should expose `limit`, `next_cursor` or equivalent,
  and whether the result is truncated.
- File-producing commands should emit absolute or cwd-relative artifact paths
  consistently and document which one is used.
- Test at least one success and one failure output shape.
