---
name: cli-creator
description: Design, implement, or review production CLI products for Codex and humans, including command surfaces, global installation, structured output, diagnostics, capability inventories, OpenAPI/runtime clients, browser extractors, probe evidence workflows, MCP adapters, and bundled companion skills when self-contained CLI guidance is not enough. Use when building a durable CLI from APIs, SDKs, web apps, scripts, platform clients, or existing tools. Do not use for one-off repo scripts, standalone MCP servers without a CLI product, generic service/runtime implementation, or skill-authoring-only work.
---

# CLI Creator

## Purpose

Use this skill to create or harden a durable CLI product that future Codex
threads and humans can run by command name from any working directory.

This skill owns the CLI product system:

- command surface and product contract
- installation and distribution checks
- auth/config and `doctor` diagnostics
- structured JSON output and errors
- capability inventory and shared use-case boundaries
- capability implementation boundaries, with provider/fallback boundaries only
  when one capability has multiple interchangeable execution paths
- probe/evidence workflows for drift-prone or non-official platforms
- MCP adapters that stay thin over the same use-cases
- companion or bundled skills only when CLI help, manuals, and examples cannot
  carry the required agent guidance cleanly; `doctor` owns diagnostics

It does not own one-off scripts, standalone MCP server design, broad service
architecture, product strategy, or generic skill-package authoring.

## When To Use

- Building a durable CLI from API docs, OpenAPI, SDKs, curl examples, DevTools
  evidence, browser apps, admin tools, shell history, or existing scripts.
- Turning a repo-local tool into an installed command with help, `doctor`,
  stable JSON, tests, and docs.
- Designing or reviewing CLI command trees, resource boundaries, auth/config,
  JSON output, error envelopes, pagination, install path, or raw escape hatches.
- Building a platform client CLI that needs API/SDK/browser/local
  implementation boundaries, true multi-provider routing, generated clients,
  probe evidence, schema promotion, MCP, or a bundled skill.
- Reviewing whether CLI, MCP, docs, skills, generated metadata, and use-cases
  have drifted apart.
- Deciding whether usage guidance belongs in CLI help/manuals or in a
  companion skill.

## When Not To Use

- Do not use this for a short one-off script scoped to the current repo.
- Do not use this for a standalone MCP server when there is no CLI product
  contract. Use an MCP-specific server design workflow instead.
- Do not use this to invent product behavior, account policy, or external
  service semantics that the source material does not support.
- Do not use this for skill package creation by itself. Use the skill creation
  workflow when the owned artifact is a skill rather than a CLI product.
- Do not force OpenAPI, browser extraction, probes, MCP, or bundled skills into
  a simple CLI that does not need them.
- Do not create a companion skill just to restate command help, option lists,
  or a short recommended flow that can live in `--help`, examples, or a manual.
  Put setup and readiness checks in `doctor`.

## Inputs To Inspect

- User request, target jobs, install name, source material, and non-goals.
- Existing repo conventions: package metadata, CLI framework, tests, docs,
  generated files, auth/config helpers, and release/install path.
- Source evidence: API docs, OpenAPI, SDK docs, curl examples, DevTools traces,
  screenshots paired with network evidence, fixtures, scripts, and shell
  history.
- Existing command surfaces, MCP tools, skills, docs, generated metadata, and
  capability inventories when the project already exists.

## Workflow

1. Define the CLI product contract.
   - Name the binary, source material, first real jobs, users, and install
     scope.
   - Check whether the command name already exists with
     `command -v <tool-name> || true`.
   - Read `references/command-surface.md` before changing command behavior.
2. Select only the needed atomic capabilities.
   - Use the table below to load focused references. Do not choose a mode.
   - A simple installed CLI may need only command surface, install, structured
     output, and doctor diagnostics.
   - A drift-prone platform client may need the full contract/runtime/browser
     and probe stack.
   - A service with one clear implementation path per capability should keep
     that path internal instead of introducing provider selection.
3. Sketch or review the command surface before broad implementation.
   - Include discovery, resolve, read, write, raw escape hatch, auth/config,
     `doctor`, JSON policy, and install validation.
   - Prefer resource-oriented, jobs-first commands over endpoint-shaped names.
   - Treat CLI help, examples, and concise manuals as the first agent-facing
     guidance. Use `doctor` for setup, dependency, auth, permission, and
     readiness diagnostics. Add a skill only when the guidance needs
     cross-command judgment, complex sequencing, safety gates, or source-specific
     operating policy that would make command help noisy.
4. Choose the runtime and install shape from the source and repo.
   - Python, Swift, shell, Node, Rust, and other runtimes are all acceptable
     when they fit the source, dependencies, and distribution target.
   - Global visibility is a validation requirement, not the main design value.
5. Implement the owning layers.
   - Keep CLI adapters thin over use-cases when capabilities are shared.
   - Keep generated clients pure; put auth, signing, cookies, retries, policy,
     fallback, and diagnostics in runtime/adapter code.
   - Keep MCP and bundled skills pointed at the same capability/use-case
     contract instead of duplicating behavior.
6. Validate from outside the repo.
   - Run project build/lint/tests.
   - Run `command -v <tool-name>`, `<tool-name> --help`, and
     `<tool-name> --json doctor` or the closest project equivalent from `/tmp`
     or another repo.
   - Add specialized contract, implementation/provider, MCP, probe, and skill
     checks when those atomic capabilities are used.

## Atomic Capabilities

| Capability | Load when |
| --- | --- |
| `references/command-surface.md` | Designing command trees, resource boundaries, discovery, resolve, read/write, raw escape hatches, or help output. |
| `references/install-distribution.md` | Making the CLI globally visible, choosing Python/Swift/shell/Node/Rust install paths, or testing cross-directory execution. |
| `references/structured-output.md` | Defining `--json`, output envelopes, errors, pagination, artifact paths, or stable machine-readable output. |
| `references/doctor-diagnostics.md` | Adding or reviewing `doctor`, auth/config checks, environment checks, version checks, or setup diagnostics. |
| `references/capability-inventory.md` | Keeping CLI, MCP, docs, skills, generated metadata, use-cases, and implementation/provider ownership converged. |
| `references/openapi-runtime.md` | Using OpenAPI, codegen, generated clients/models, request serialization, runtime policy, or custom transport. |
| `references/browser-extractors.md` | Using Playwright/browser DOM extraction, browser evidence, extractor contracts, normalizers, or generated browser runner data. |
| `references/probe-evidence.md` | Maintaining non-official or drift-prone surfaces through raw evidence, sanitized evidence, observed schemas, stable contracts, and diagnosis. |
| `references/mcp-adapter.md` | Exposing CLI capabilities through MCP without duplicating CLI logic. |
| `references/bundled-skill.md` | Shipping a companion or bundled skill after CLI help, examples, and manuals are insufficient, and `doctor` cannot cover the needed diagnostics. |

## Decision Rules

- A durable CLI is a product contract, not a wrapper around whatever endpoint
  or script was nearest.
- Commands should be composable and resource-oriented. Avoid hiding writes
  inside broad verbs such as `fix`, `auto`, or `debug`.
- Auth and config should use boring, inspectable paths first: environment,
  user config, and explicit one-off flags only when necessary.
- Raw request/tool-call escape hatches are useful, but they must not be the
  only useful interface.
- Stable JSON must be designed and tested as a contract. Human table output
  can change more freely.
- Prefer one clear implementation path per capability. Introduce public
  provider selection only when the same capability has multiple
  interchangeable execution paths that can satisfy the same output contract.
- Use OpenAPI and codegen when endpoint shape is stable enough to own as a
  contract. Keep local runtime behavior out of generated files.
- Use browser extraction when the web UI is the honest source of evidence or
  fallback behavior. Keep DOM output schemas separate from OpenAPI.
- Use probes for drift-prone external behavior. Scripts produce facts and
  diffs; agents propose diagnosis and contract/runtime updates.
- MCP is an adapter over the same use-cases, not a second implementation.
- A durable CLI should be self-contained for ordinary human and agent use.
  Good `--help`, examples, and manuals should close the basic usage loop, while
  `doctor` closes the setup and readiness diagnostic loop, before a companion
  skill is considered.
- A companion skill should teach ordering, setup, safe reads, intended writes,
  examples, non-goals, and judgment that cannot fit cleanly in the CLI's
  self-contained guidance. It should not become an API reference dump or a
  duplicate help page.

## Validation

Use the smallest relevant checks first, then broaden when the CLI product
surface is shared across adapters or contracts:

```bash
command -v <tool-name> || true
<tool-name> --help
<tool-name> --json doctor
```

Also run the repo's format, lint, typecheck, build, and test commands. For
contract-governed platform clients, add checks for generated artifacts,
capability coverage, OpenAPI/runtime policy, implementation/provider support, MCP
schemas, probe coverage, and bundled skill validation.
When a companion skill is proposed, first validate that the same guidance cannot
be better served by command help, examples, or a manual, and that setup or
readiness checks cannot be handled by `doctor`.

## Final Response

For implementation work, summarize:

- command surface created or changed
- owning layers touched
- install/global visibility result
- help, structured output, and `doctor` behavior
- MCP/skill/contract/implementation/provider/probe convergence if relevant
- validation commands and results
- remaining live-auth, live-write, or external-service limits
