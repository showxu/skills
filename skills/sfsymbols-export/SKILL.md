---
name: sfsymbols-export
description: Export SF Symbols glyphs from the local SF Symbols app into checked-in square SVG and PNG icon assets for Codex skill metadata, UI chips, prototypes, or design-system handoff. Use when asked to create, regenerate, normalize, or troubleshoot SF Symbols-derived icon files such as icon-small.svg, icon-large.svg, and icon-large.png. Do not use for interaction design critique, generic visual design, app icon branding, raster image generation, official SF Symbols app download lookup, or frontend implementation.
---

# SF Symbols Export

## Purpose

Export SF Symbols glyphs from the local SF Symbols app into normalized square
icon assets. This skill is for repeatable icon asset maintenance, especially
Codex `agents/openai.yaml` skill icons.

## When To Use

- Add or regenerate `icon-small.svg`, `icon-large.svg`, and `icon-large.png`
  for a skill.
- Convert an SF Symbols glyph into a square SVG asset with a fixed viewBox.
- Check whether a symbol name exists in the local SF Symbols font.
- Troubleshoot non-square SVGs, excess font line height, missing icon paths, or
  stale `agents/openai.yaml` icon references.

## When Not To Use

- Interaction flow planning, IA, prototype critique, or usability review.
- Broad visual identity, illustration, marketing screenshot, or app icon work.
- Frontend, SwiftUI, UIKit, Android, or web implementation.
- Tasks that need the SF Symbols app GUI export template, animation metadata,
  localization variants, or official Apple symbol annotations.
- Finding, probing, or downloading the official SF Symbols app or Apple design
  resource links. Use `apple-design-resource`.

## Inputs To Inspect

- Target skill directory and its `agents/openai.yaml`.
- Desired SF Symbols name or glyph name.
- Desired output files, usually `assets/icon-small.svg` for `icon_small`,
  `assets/icon-large.png` for `icon_large`, and `assets/icon-large.svg` as
  the editable vector source.
- Local SF Symbols app availability at `/Applications/SF Symbols.app`.
- `apple-design-resource` catalog only when the local SF Symbols app is missing
  and the task needs the official Apple download link.

## Workflow

1. Confirm the output should be checked-in icon assets, not a runtime SF Symbol
   reference.
2. Locate the local SF Symbols fallback font:
   `/Applications/SF Symbols.app/Contents/Resources/Fonts/SFSymbolsFallback.otf`.
3. If `fontTools` is not importable, install it outside the repository, for
   example `python3 -m pip install --target /tmp/codex-fonttools fonttools`,
   then run the script with `PYTHONPATH=/tmp/codex-fonttools`.
4. Use `scripts/generate_sf_symbol_svg.py --list <query>` if the exact glyph
   name is unknown.
5. Generate square SVG files with `scripts/generate_sf_symbol_svg.py`.
6. Convert `icon-large.svg` to `icon-large.png`, for example with
   `sips -s format png assets/icon-large.svg --out assets/icon-large.png`.
7. Point `agents/openai.yaml` at `icon_small: "./assets/icon-small.svg"` and
   `icon_large: "./assets/icon-large.png"` using paths relative to the skill
   directory.
8. Validate XML, PNG dimensions, and renderability before finishing.

## Script Usage

```bash
PYTHONPATH=/tmp/codex-fonttools \
python3 skills/sfsymbols-export/scripts/generate_sf_symbol_svg.py \
  storefront \
  --out-dir product-experience/skills/app-store-aso/assets \
  --basename icon \
  --small-size 64 \
  --large-size 512
```

List matching glyph names:

```bash
PYTHONPATH=/tmp/codex-fonttools \
python3 skills/sfsymbols-export/scripts/generate_sf_symbol_svg.py \
  --list storefront
```

## Decision Rules

- Prefer `icon_small` as SVG and `icon_large` as PNG for Codex UI metadata,
  matching bundled Codex examples. Keep `icon-large.svg` as the vector source
  when it is useful for regeneration.
- Avoid raw `hb-view` exports because they include font line-height dimensions.
- Keep generated files inside the skill's own `assets/` directory when the
  skill may be copied or zipped independently.
- Use a single shared visual metaphor per collection when individual skill
  distinctions are not important.
- Use `icon_small` and `icon_large` in `agents/openai.yaml`; do not put icon
  metadata in `SKILL.md` frontmatter.

## Validation Rules

- `agents/openai.yaml` paths resolve from the skill directory.
- Generated SVGs are square: `width == height` and `viewBox="0 0 64 64"`.
- Generated PNGs are valid PNG files and square.
- `xmllint --noout <file>` succeeds.
- A system renderer such as `sips -s format png <file> --out /tmp/icon.png`
  can rasterize the SVG.
- No generated icon is a symlink when the skill is intended for independent
  installation or distribution.

## Output Format

Report:

```text
Generated:
- <skill>/assets/icon-small.svg
- <skill>/assets/icon-large.svg
- <skill>/assets/icon-large.png

Metadata:
- <skill>/agents/openai.yaml references icon-small.svg and icon-large.png

Validation:
- XML ok
- PNG ok
- Render ok
- No symlinks
```

## Failure / Uncertainty Handling

- If SF Symbols app is missing, ask the user to install it or provide a font or
  exported SVG. Use `apple-design-resource` when the user wants the official
  current SF Symbols download link.
- If a symbol name does not resolve, run `--list` with a narrower query and ask
  for a preferred glyph when multiple matches are plausible.
- If `fontTools` is unavailable and package installation is not allowed, fall
  back to manual SF Symbols app export and then normalize the SVG.
