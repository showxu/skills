# De-collectionize Local Collections

This file records the local collection retirement that moved the former
`product-experience` and `software-engineering` skills into root `skills/`.

## Retired Local Collections

| Former path | Former git state | Disposition |
| --- | --- | --- |
| `product-experience/` | Child git checkout existed, but had no commits on `main`; no `HEAD` commit was available. | Skills moved to root `skills/`; selected docs moved to root `docs/` or `docs/provenance/`; former collection directory retired. |
| `software-engineering/` | Child git checkout existed, but had no commits on `main`; no `HEAD` commit was available. | Skills moved to root `skills/`; selected docs moved to root `docs/` or `docs/provenance/`; former collection directory retired. |

## Active Model

- Root `skills/` is the active local skill directory.
- Root `.claude-plugin/marketplace.json` is the active local marketplace.
- Root docs and `AGENTS.md` own active routing.
- The external Swift skill repository remains source-owned and linked through
  `collections.yaml`.

## Historical Material

Former collection docs retained for audit are under:

- `docs/provenance/retired-collections/`
- `docs/provenance/product-management-distillation/`

They are historical and superseded; active routing must use root docs.
