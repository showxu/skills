# Host Compatibility

This skill is Anthropic-compatible but runs in Codex hosts as a local skill.

## Codex Behavior

- Use Browser when it is available and the task needs visible local browser
  inspection.
- Use Playwright CLI or interactive sessions when Browser is unavailable,
  unsuitable, or explicitly bypassed.
- Use `scripts/with_server.py` for Anthropic-compatible single-helper usage and
  `scripts/with_web_servers.py` for local multi-server orchestration.

## Non-Claims

- This skill does not make Browser, Playwright, or OS screenshot permissions
  universally available.
- This skill does not mutate live accounts without explicit confirmation.
- This skill does not replace project-owned tests when the project defines
  them.
