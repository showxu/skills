# Host Compatibility

This skill is Anthropic-compatible but runs in Codex hosts as a local skill.

## Codex Behavior

- Use available local frontend tooling and existing project conventions.
- If browser verification is needed, route concrete rendered checks to
  `webapp-testing` or the installed Browser/Playwright backend.
- If repo-level routing, state, data, API integration, or production build/test
  wiring is needed, route implementation ownership to `webapp-builder`.
- Do not claim Claude-specific artifact display behavior in Codex.

## Non-Claims

- This skill does not own product requirements or product behavior.
- This skill does not guarantee production readiness without project-specific
  build, test, and browser evidence.
- This skill does not own Figma MCP operations.
- This skill does not own repo-level Web app engineering architecture.
