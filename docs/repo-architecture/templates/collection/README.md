# <collection-name>

`<collection-name>` is a Codex / Claude skill collection for <domain>.

This README is both the collection manual and the documentation index. It
defines the collection scope, install/use surface, layout, and links to focused
docs.

## Scope

This collection owns <owned outputs>.

It does not own <common false matches>.

## Skills

- `<skill-name>`: <what it does>.

## Capability Matrix

| Capability | Primary skill | Also routes to | Coverage |
|---|---|---|---|
| <capability> | `<skill-name>` | none | Published |

## Input Boundaries

Use <trusted inputs>. Do not treat <weak inputs> as authority unless the task
explicitly asks for that boundary.

## Install In Codex

Install a specific skill directory into `$CODEX_HOME/skills` rather than
linking the repository root.

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$(pwd)/skills/<skill-name>" \
  "${CODEX_HOME:-$HOME/.codex}/skills/<skill-name>"
```

Restart Codex after installing so it picks up the new skill.

## Repository Layout

- `.claude-plugin/`: Claude Code marketplace metadata.
- `docs/`: collection documentation and architecture notes.
- `skills/`: authoritative skill definitions and skill-local supporting files.

## Documentation Index

- `docs/README.md`: collection documentation index.
- `AGENTS.md`: repository-local agent routing and operating contract.
