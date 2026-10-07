# Bundled Or Companion Skill

## Purpose

Create a companion or bundled skill when future Codex threads should use the
CLI reliably without rediscovering setup, auth, IDs, safe read paths, and write
behavior, and when that guidance cannot be expressed cleanly through CLI help,
examples, or a concise manual.

The CLI should be self-contained for ordinary use. A companion skill is an
optional external operating guide for judgment and policy, not the default
place for basic usage instructions.

## Need Check

Before creating or expanding a companion skill, decide whether the guidance
belongs in the CLI instead.

Prefer CLI help, examples, or a manual when the guidance is:

- a command list or option reference
- a short recommended run flow
- stable safety wording tied to flags or permissions
- output examples or JSON contract notes

Prefer `doctor` when the need is setup, dependency, auth, permission, endpoint,
version, or readiness diagnostics. `doctor` may explain remediation, but it
should not become the workflow guide.

Use a companion skill when the guidance needs:

- cross-command sequencing with branching decisions
- source-specific operating policy that should not clutter help
- non-obvious safety judgment for live writes or external actions
- drift-prone platform evidence and when to re-probe it
- agent-specific constraints, such as when to avoid a raw escape hatch or MCP
  adapter

## Skill Content

The skill should teach operation order, not mirror the entire CLI reference.

Include:

- how to verify the command exists
- first discovery command, usually `<tool> --help`
- diagnostic command, usually `<tool> doctor`, when setup or readiness matters
- auth/config setup path
- discovery or resolve command for common IDs
- safe read path
- intended write or draft path when supported
- raw escape hatch and when to avoid it
- structured output expectations
- three copy-pasteable examples
- what not to do without explicit user approval when live writes or account
  mutation are involved
- pointers to the CLI manual or command help instead of duplicated option
  reference

## Rules

- Keep acquisition/execution in the CLI, not in the skill.
- Keep API reference details in CLI docs or reference files.
- Keep simple recommended flows in CLI help, examples, or manuals.
- Keep setup and readiness diagnostics in `doctor`.
- Keep the skill aligned with the capability inventory and command help.
- Update the companion skill in the same slice as command behavior changes.
- Do not ship a companion skill whose only unique content is a command list,
  option list, or basic getting-started flow.
- Validate the skill package when it is shipped with the CLI or marketplace.
