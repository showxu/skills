# Anthropic Patch Manifest

Source: `anthropics/skills`, `skills/web-artifacts-builder/`, commit
`d211d437443a7b2496a3dad9575e7dddd724c585`.

## Exact Baseline

| Upstream file | Local file | Reason |
| --- | --- | --- |
| `SKILL.md` | `references/anthropic-baseline.md` | Preserve the Anthropic-compatible baseline for refresh and comparison. |
| `LICENSE.txt` | `LICENSE.txt` | Preserve upstream license terms. |
| `scripts/init-artifact.sh` | `scripts/init-artifact.sh` | Preserve upstream scaffold helper. |
| `scripts/bundle-artifact.sh` | `scripts/bundle-artifact.sh` | Preserve upstream single-file bundle helper. |
| `scripts/shadcn-components.tar.gz` | `scripts/shadcn-components.tar.gz` | Preserve upstream component asset archive. |

## Patched Upstream Files

| Upstream file | Local file | Patch type | Reason | Non-claim |
| --- | --- | --- | --- | --- |
| `SKILL.md` | `SKILL.md` | Local integrated entrypoint | Generalize Claude artifact wording to shareable HTML artifacts, add product-behavior preservation, and fold in local quality rules. | Does not make artifacts production frontend architecture or product sources of truth. |

## Local-Only Files

| Local file | Responsibility | Reason | Non-claim |
| --- | --- | --- | --- |
| `agents/openai.yaml` | OpenAI UI metadata | Expose this skill in Codex/OpenAI surfaces. | Not a second trigger contract. |
| `references/source-receipt.md` | Source receipt | Record baseline source and refresh rule. | Not an execution workflow. |
| `references/host-compatibility.md` | Host compatibility | Record Codex host assumptions and non-claims. | Does not claim Claude artifact display semantics in Codex. |
