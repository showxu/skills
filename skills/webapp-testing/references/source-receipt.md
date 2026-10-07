# Webapp Testing Source Receipt

## Baseline Source

- Source: `anthropics/skills`
- Commit: `d211d437443a7b2496a3dad9575e7dddd724c585`
- Source path: `skills/webapp-testing/`
- Local baseline copy: `references/anthropic-baseline.md`
- Mirrored assets:
  - `scripts/with_server.py`
  - `examples/console_logging.py`
  - `examples/element_discovery.py`
  - `examples/static_html_automation.py`
- License: `LICENSE.txt`

## Local Maintenance Model

- Active workflow: `SKILL.md`.
- Anthropic baseline receipt: Playwright local webapp testing and server helper
  workflow preserved in `references/anthropic-baseline.md`.
- Local carried-forward capability: superseded `webapp-qa-harness` QA
  inventory, multi-server helper, backend selection, and evidence model.
- Host compatibility: `references/host-compatibility.md`.

## Refresh Rule

When refreshing from Anthropic, restore baseline content and helper examples
first, then reapply only patch-manifest rows and keep `SKILL.md` as the
seamless local entrypoint. Do not restore `webapp-qa-harness` as a public name.
