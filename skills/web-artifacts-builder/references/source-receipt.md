# Web Artifacts Builder Source Receipt

## Baseline Source

- Source: `anthropics/skills`
- Commit: `d211d437443a7b2496a3dad9575e7dddd724c585`
- Source path: `skills/web-artifacts-builder/`
- Local baseline copy: `references/anthropic-baseline.md`
- Mirrored assets:
  - `scripts/init-artifact.sh`
  - `scripts/bundle-artifact.sh`
  - `scripts/shadcn-components.tar.gz`
- License: `LICENSE.txt`

## Local Maintenance Model

- Active workflow: `SKILL.md`.
- Anthropic baseline receipt: artifact scaffold, React/Tailwind/shadcn stack,
  and single-file bundling workflow preserved in
  `references/anthropic-baseline.md`.
- Local patches: recorded in `references/anthropic-patch-manifest.md`.
- Host compatibility: `references/host-compatibility.md`.

## Refresh Rule

When refreshing from Anthropic, restore baseline content and scripts first,
then reapply only patch-manifest rows and keep `SKILL.md` as the seamless local
entrypoint.
