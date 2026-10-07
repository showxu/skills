# Compatibility Evidence

This file records version-specific observations, not executable defaults or
universal product guarantees. Recheck the current installation before use.

## Inspected Baseline — 2026-09-13

- Desktop bundle: version `26.908.40834`, build `8881`, bundle identity
  `com.openai.codex`. The inspected installation uses the display/package name
  ChatGPT. Identify runtime targets by observed app identity, not a fixed path.
- Bundled CLI: `codex-cli 0.154.0-alpha.6.2`.
- Source surfaces: packaged `app.asar` tool definitions and sidebar handlers;
  bundled CLI `app-server proxy --help` and
  `app-server generate-json-schema --experimental` output.
- Generated `ClientRequest.json` SHA-256 over canonical JSON as emitted by the
  adapter: `ebf1225940492ef31107296874eac348dfbc474d9534967a2486c0b65bce891b`.

The adapter probe found all 20 methods in its supported method set in the
generated schema. This proves schema presence, not successful calls against a
live desktop-owned server. Initialization exposes Codex home, platform, and user
agent. Account reads can expose account type/email but do not establish every
organization/workspace distinction needed for desktop routing.

## Desktop Tool and UI Findings

The package declares thread/project tools and section creation, renaming,
deletion, movement, and reordering tools described in `operations.md`. Their
availability is feature- and session-dependent. The implementation distinguishes
Codex-only task operations from mixed ChatGPT/Codex reorder inputs and maps
desktop logical sections across hosts. Server `threadSection` identity is not a
universal replacement for that mapping.

Project folder order/primary-folder semantics were also cross-checked against
the official [Projects documentation](https://learn.chatgpt.com/docs/projects).
Product/version context is available in the official
[changelog](https://learn.chatgpt.com/docs/changelog). Current installed schemas
and callable tool descriptions determine parameters at execution time.

The bundled Computer Use documentation supports AX state, element-based actions,
screenshots and coordinate fallback. Client `--help` exposes `cua mcp`; the
bundled plugin launcher starts its MCP service. This is an integration entrypoint
and does not remove target access restrictions. It is not a dedicated sidebar
CRUD CLI.

## Revalidation

1. Resolve the intended running application, host, and CLI; record versions.
2. Discover callable native tools and their current schemas.
3. Run the local adapter probe. If shapes or semantics change, update the
   adapter, operation guidance, and relevant isolated fixtures together.
4. Establish the running server's product ownership before using its methods.
5. Inspect current permitted UI controls and account restrictions.
6. Record live operation evidence separately from source/schema observations.
