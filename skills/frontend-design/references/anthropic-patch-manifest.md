# Anthropic Patch Manifest

Source: `anthropics/skills`, `skills/frontend-design/`, commit
`d211d437443a7b2496a3dad9575e7dddd724c585`.

## Exact Baseline

| Upstream file | Local file | Reason |
| --- | --- | --- |
| `SKILL.md` | `references/anthropic-baseline.md` | Preserve the Anthropic-compatible baseline for refresh and comparison. |
| `LICENSE.txt` | `LICENSE.txt` | Preserve upstream license terms. |

## Patched Upstream Files

| Upstream file | Local file | Patch type | Reason | Non-claim |
| --- | --- | --- | --- | --- |
| `SKILL.md` | `SKILL.md` | Local integrated entrypoint | Add local maintenance notes, product-behavior preservation, host metadata references, local quality rules, and the boundary with `webapp-builder`. | Does not replace the Anthropic frontend design baseline, does not make this skill a product source-of-truth owner, and does not make this skill the repo-level Web app engineering owner. |

## Local-Only Files

| Local file | Responsibility | Reason | Non-claim |
| --- | --- | --- | --- |
| `agents/openai.yaml` | OpenAI UI metadata | Expose this skill in Codex/OpenAI surfaces. | Not a second trigger contract. |
| `references/source-receipt.md` | Source receipt | Record baseline source and refresh rule. | Not an execution workflow. |
| `references/host-compatibility.md` | Host compatibility | Record Codex host assumptions and non-claims. | Does not claim native Claude artifact behavior in Codex. |
