# CLI Creator Architecture

## Skill Boundary

`cli-creator` is a staged engineering skill for CLI products. It owns the
method for turning source evidence and existing tool behavior into a durable
command-line product that can be installed, validated, and reused by agents.

It is not a generic architecture skill, service runtime skill, MCP-only skill,
or skill package authoring skill. Those concerns may provide inputs or
follow-up implementation details, but the owned artifact here is the CLI
product system.

## File Responsibilities

| File | Responsibility |
| --- | --- |
| `SKILL.md` | Runtime entrypoint, trigger contract, workflow, atomic reference selection, validation, and final response shape. |
| `agents/openai.yaml` | Manual entry surface for the same contract. |
| `references/command-surface.md` | Command tree and product-surface design rules. |
| `references/install-distribution.md` | Runtime/install/distribution validation rules. |
| `references/structured-output.md` | Stable JSON, error, pagination, and artifact output rules. |
| `references/doctor-diagnostics.md` | `doctor`, auth/config, and environment diagnostics rules. |
| `references/capability-inventory.md` | Capability/use-case convergence across CLI, MCP, docs, skills, and generated metadata. |
| `references/openapi-runtime.md` | OpenAPI/codegen/runtime-policy/transport boundary. |
| `references/browser-extractors.md` | Browser DOM extractor contracts and generated browser runner data. |
| `references/probe-evidence.md` | Probe/evidence/schema/diagnosis workflow. |
| `references/mcp-adapter.md` | MCP thin-adapter convergence with CLI use-cases. |
| `references/bundled-skill.md` | Companion and bundled skill rules. |
| `references/eval-fixtures.md` | Durable behavior fixtures for review and trigger quality. |

## Atomic, Not Modal

This skill does not define modes such as standard, platform-client, or
MCP-backed. Those labels make agents choose a package before understanding the
target. Instead, agents inspect the target CLI and load only the atomic
capabilities needed for the current product surface.

Examples:

- A shell wrapper for a local workflow may need command surface, install,
  structured output, and doctor diagnostics.
- A Swift package command may need command surface, install, structured output,
  and bundled skill guidance.
- A media or official-API CLI may need fixed implementation ownership, where
  each command has one best SDK/API/library/local path and no public provider
  selector.
- A non-official platform client may need capability inventory, OpenAPI
  runtime, browser extractors, probe evidence, MCP adapter, and bundled skills.

## Input Priority

1. User request and target repo facts.
2. Existing CLI product contracts: command help, tests, docs, use-cases,
   generated metadata, MCP tools, and skills.
3. Source evidence: official docs, OpenAPI, SDKs, scripts, DevTools evidence,
   fixtures, and redacted samples.
4. This skill's references.

Do not copy a reference pattern into a project unless the target product needs
that capability.

## Validation Owner

The target repo owns its build, test, install, and generated-artifact checks.
This skill owns selecting the right validation classes and requiring
cross-directory smoke tests for installed CLIs.
