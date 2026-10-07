# Eval Fixtures

Use these fixtures to review whether `cli-creator` applies the right atomic
capabilities without turning every CLI into a heavyweight platform framework.

## Fixture: Simple Installed Script

Input: A repo has a shell script that exports logs and the user wants it
available as `logs-export` from any directory.

Expected behavior:

- Use command surface, install/distribution, structured output, and doctor
  diagnostics.
- Do not introduce OpenAPI, browser extractors, probes, MCP, or bundled skills
  unless the user asks for agent reuse.
- Validate `command -v logs-export`, `logs-export --help`, and a cross-cwd
  smoke test.

## Fixture: Official OpenAPI CLI

Input: A service provides official OpenAPI, token auth, list/read/create
endpoints, and the user wants a durable CLI.

Expected behavior:

- Use command surface, install/distribution, structured output,
  doctor diagnostics, and OpenAPI runtime.
- Generate or use client/models from OpenAPI.
- Keep auth/config and retries in runtime/adapter code.
- Add request builder and JSON error tests.

## Fixture: Fixed Implementation Media CLI

Input: A media platform has an official API for search/comments/channel data,
one mature downloader library, and one transcript library. The user wants a
complete durable CLI.

Expected behavior:

- Use command surface, install/distribution, structured output, doctor
  diagnostics, and implementation ownership in the capability inventory.
- Keep each command bound to its natural implementation path: official API for
  API reads, downloader library for downloads, transcript library for
  transcripts.
- Do not add a public `--provider` or provider matrix unless one capability
  has multiple interchangeable execution paths with the same output contract.
- Future no-API or browser alternatives stay as reference/fallback candidates
  until their output contract and need are proven.

## Fixture: Drift-Prone Platform Client

Input: A non-official platform client must support API reads, browser DOM
fallback, MCP, and an agent skill.

Expected behavior:

- Use capability inventory, OpenAPI runtime, browser extractors,
  probe evidence, MCP adapter, bundled skill, and all base CLI product
  capabilities.
- Keep browser DOM schemas separate from OpenAPI.
- Require probes/evidence before stabilizing external payload shapes.
- Verify CLI/MCP/skill/docs/use-cases converge on one capability contract.

## Fixture: MCP-Only Request

Input: The user asks to build only an MCP server for an existing service, with
no CLI product.

Expected behavior:

- Do not use `cli-creator` as the primary owner.
- Route to an MCP-specific server design workflow.
- Preserve any CLI considerations as optional future integration notes only.

## Fixture: Skill-Only Request

Input: The user asks to create a skill that teaches an existing installed CLI.

Expected behavior:

- Do not treat this as CLI implementation unless the installed CLI is broken or
  incomplete.
- Use the skill creation workflow for the skill package.
- Use `bundled-skill.md` only as content guidance if the skill is CLI-facing.
