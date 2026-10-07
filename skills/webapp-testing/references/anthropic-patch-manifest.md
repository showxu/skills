# Anthropic Patch Manifest

Source: `anthropics/skills`, `skills/webapp-testing/`, commit
`d211d437443a7b2496a3dad9575e7dddd724c585`.

## Exact Baseline

| Upstream file | Local file | Reason |
| --- | --- | --- |
| `SKILL.md` | `references/anthropic-baseline.md` | Preserve the Anthropic-compatible baseline for refresh and comparison. |
| `LICENSE.txt` | `LICENSE.txt` | Preserve upstream license terms. |
| `scripts/with_server.py` | `scripts/with_server.py` | Preserve upstream server lifecycle helper. |
| `examples/console_logging.py` | `examples/console_logging.py` | Preserve upstream example. |
| `examples/element_discovery.py` | `examples/element_discovery.py` | Preserve upstream example. |
| `examples/static_html_automation.py` | `examples/static_html_automation.py` | Preserve upstream example. |

## Patched Upstream Files

| Upstream file | Local file | Patch type | Reason | Non-claim |
| --- | --- | --- | --- | --- |
| `SKILL.md` | `SKILL.md` | Local QA integrated entrypoint | Rename public skill to `webapp-testing`, preserve local QA inventory and multi-server helper, fold in local Browser/Playwright/screenshot guidance, and route GitHub-rendered Markdown previews. | Does not keep `webapp-qa-harness` as a public alias and does not replace project-owned test suites. |

## Local-Only Files

| Local file | Responsibility | Reason | Non-claim |
| --- | --- | --- | --- |
| `agents/openai.yaml` | OpenAI UI metadata | Expose this skill in Codex/OpenAI surfaces. | Not a second trigger contract. |
| `references/source-receipt.md` | Source receipt | Record baseline source and refresh rule. | Not an execution workflow. |
| `references/qa-workflow.md` | Local QA workflow reference | Preserve server lifecycle, QA inventory, backend selection, evidence, and failure diagnosis from the superseded local name. | Does not make `webapp-qa-harness` a public skill. |
| `references/host-compatibility.md` | Host compatibility | Record Codex host assumptions and non-claims. | Does not claim all host browser backends are always available. |
| `scripts/with_web_servers.py` | Local helper | Preserve multi-server lifecycle support from the previous local QA harness. | Not an Anthropic baseline script. |
| `references/github-markdown-preview.md` | GitHub Markdown preview route | Render through GitHub's sanitizer, capture light, dark, and mobile evidence, and verify after publishing. | Does not prove GitHub mobile app rendering or change account settings. |
| `scripts/render_github_markdown.py` | Local helper | Build a local preview page from `gh api markdown` output with camo unwrapping and URL mapping. | Not an Anthropic baseline script; requires an authenticated `gh`. |
