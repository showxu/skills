# Command Surface

## Purpose

Design the CLI around jobs and resources that users and agents actually need,
not around internal endpoint names or implementation shortcuts.

## Required Inventory

Before changing commands, identify:

- binary name and install scope
- top-level resources
- first real jobs
- stable IDs, URLs, slugs, names, and resolve paths
- read surfaces, write surfaces, and destructive surfaces
- pagination, filtering, sorting, and output volume limits
- raw escape hatch needs
- human output and JSON output expectations

## Surface Shape

Prefer this shape when the domain supports it:

- `tool --help` shows the major resource groups.
- `tool doctor` checks setup.
- `tool init` or `tool auth ...` stores config only when env-only setup is
  painful.
- discovery commands find containers, accounts, projects, workspaces, repos,
  queues, channels, dashboards, users, or similar top-level resources.
- resolve commands turn URLs, names, slugs, and links into stable IDs.
- read commands fetch exact objects and list/search collections.
- write commands perform one named action each.
- raw escape hatches use honest names such as `request`, `api`, or
  `tool-call`.

## Self-Contained Guidance

Design the CLI to be self-contained for ordinary human and agent use.

Use command help, examples, and concise manuals for guidance that is stable,
short, and directly tied to the command contract:

- what the command does and does not do
- required auth, config, permissions, or risk flags
- the recommended discovery entry point, usually `<tool> --help`
- common read paths and intended write paths
- output modes, including `--json`
- links or pointers to a manual when the workflow needs more context

Use `doctor` for setup, dependency, auth, permission, version, endpoint, and
readiness diagnostics. It may include actionable remediation hints, but it
should not be the primary workflow guide.

Do not create a companion skill just to repeat command names, option lists, or a
short recommended flow. Use a skill only when future agents need judgment that
would make help output noisy, such as multi-step operating policy, cross-command
decision making, complex setup, live-write safety boundaries, or drift-prone
source evidence.

## Design Rules

- Sketch the command tree before broad implementation.
- Keep command names short, shell-friendly, and resource-oriented.
- Do not expose only a generic `request` command.
- Do not make upstream argv compatibility more important than a clean local
  product contract unless the user explicitly requires compatibility.
- Do not hide writes behind broad automation verbs such as `fix`, `debug`,
  `auto`, or `sync-all`.
- Prefer bounded list commands with `--limit`, cursor, offset, or documented
  defaults.
- Keep read and mutation surfaces visibly separated in command grouping and
  help text.
- Use the narrowest stable resource ID for writes.
- Add `--dry-run`, `draft`, or `preview` when the external service naturally
  supports it. Do not fake a dry-run that cannot be validated.
- Keep simple agent instructions inside the CLI's self-contained guidance
  before adding a bundled or companion skill.

## Review Checks

- Can a future agent discover the needed ID without broad guessing?
- Can the command be run from a different repo without hidden cwd assumptions?
- Does help output reveal the major capabilities without reading the README?
- Does help, examples, or a manual cover simple usage guidance before a skill
  is introduced?
- Does `doctor` cover setup and readiness diagnostics without becoming the
  workflow guide?
- Are writes explicit and narrow?
- Is raw access available without becoming the main interface?
- Are JSON output and errors documented for each command family?
