---
name: apple-framework-icon-design
description: Design, generate, and review original icons in the style of Apple developer framework icons, from the Iconography section of a DESIGN.md, in three styles - isometric slabs of stacked colored bands with a raised glyph or standing objects, volumetric front-facing tiles with an extruded glyph and glass panels, or flat gradient tiles - all with Apple's continuous corner. Use when creating a repository, package, or product icon or logo in this style, assigning hues, glyphs, and styles across an icon family, regenerating icons after a DESIGN.md change, checking checked-in logos for drift, or checking the generator's fidelity against reference icons. Produces DESIGN.md Iconography entries, SVG and PNG icons, contact sheets, drift reports, and fidelity reports. Never reproduces Apple marks, SF Symbols, or another company's logo. Do not use for README layout, social preview or banner composition, SF Symbols export, raster illustration, or platform app icon documents and renditions.
---

# Apple Framework Icon Design

## Purpose

Keep a family of framework-style icons consistent and reproducible. The
design parameters live in the owner's `DESIGN.md`; this skill turns them into
icons, helps choose a style and parameters for new members, and proves that
checked-in logos still match their source.

## When To Use

- A new repository or product needs an icon that matches an existing family.
- A family needs hues, glyphs, or ramps assigned or rebalanced.
- An icon entry in `DESIGN.md` changed and logos must be regenerated.
- Checked-in `Logo.svg` files must be verified against `DESIGN.md`.
- A family has no `DESIGN.md` yet and needs its first Iconography section.

## When Not To Use

- README headers, badges, banners, or social preview cards built from
  existing icons.
- Exporting SF Symbols or any third-party glyph set.
- Photographic, painted, or raster illustration.
- Platform app icon documents, appearance renditions, asset catalogs, or web
  icon sets.
- Brand strategy, naming, or logo work outside these styles.

## Inputs To Inspect

- The owner's `DESIGN.md`: organization `.github` repository or project root.
  Read its frontmatter tokens and the `## Iconography` JSON block.
- Existing icons and where each repository keeps them, usually
  `Documentation/Assets/Logo.svg` and `Logo.png` or `Docs/Assets/`.
- The new member's purpose, to choose a glyph that says what it does.
- Hues already in use (`design_icons.py DESIGN.md --tints`).

## Workflow

1. Find the `DESIGN.md`. If there is none, start from
   `examples/DESIGN.example.md` for slabs or `examples/DESIGN.tiles.example.md`
   for tiles, and keep only real tokens.
2. For a new icon, pick parameters with `references/geometry-and-color.md`:
   the family's style, a hue spaced away from existing hues, a ramp mode, a
   glyph from the library or a custom path, and the rotation rule for that
   glyph.
3. Add or edit the entry in the Iconography block. Field names and glyphs are
   listed in `references/iconography-format.md`.
4. Render into a scratch directory:
   `design_icons.py DESIGN.md --out /tmp/icons --name NAME --png`.
5. Review with a contact sheet on white and dark backgrounds at header and
   table sizes: `design_icons.py DESIGN.md --sheet /tmp/sheet.svg`. Compare
   against the failure patterns in `references/geometry-and-color.md`.
6. Iterate on the entry, not on the SVG. Never hand-edit generated files.
7. Copy the accepted SVG and 1024 px PNG into the repository's assets.
8. Run the drift check for every repository in the family:
   `design_icons.py DESIGN.md --check NAME=PATH ...`.
9. After changing geometry constants or ramps in the generator, run
   `design_icons.py --fidelity REFDIR` against the owner's reference icons
   and compare with the figures in `references/geometry-and-color.md`.

## Reference Files To Consult

- `references/geometry-and-color.md`: fixed geometry and its measurement,
  styles, ramp behavior, hue spacing, glyph rotation, fidelity figures, and
  observed failures. Read before choosing parameters.
- `references/iconography-format.md`: the JSON block, every field, the glyph
  library, standing objects, panels, and custom glyphs. Read when editing
  entries.
- `references/eval-fixtures.md`: behavior fixtures for this skill.
- `scripts/README.md`: commands, dependencies, and exit codes.

## Decision Rules

- `DESIGN.md` is the source of truth. A logo that differs from its entry is
  drift: regenerate it, or update the entry if the change was intended.
- Geometry constants are shared by the whole family and are not per-icon
  options.
- A family keeps one shape: stacked slabs, or front-facing tiles, where
  volumetric and flat may mix. Changing a family's shape is an owner
  decision.
- Reference icons are for comparison only. Keep them out of the repository,
  and do not trace them.
- Each member has its own hue. Members may share a hue only when one is the
  family's umbrella icon.
- Glyphs are plain paths drawn for this style. Do not trace, embed, or imitate
  SF Symbols, Apple marks, or another company's logo. Colors and general
  styles may be referenced.
- No text inside icons.
- Prefer a library glyph; add a custom glyph only when none says what the
  member does.

## Validation Rules

- `--check` reports `same` for every family member.
- The contact sheet shows each icon clearly on white and on `#0d1117` at
  160 px and 40 px, and no two members are confused at 40 px.
- SVGs are square, XML-valid, and contain no fonts or embedded rasters.
- PNGs are 1024 px square and match their SVGs.
- Check the SVG at its actual display sizes in supported browsers, including
  Safari when applicable, since rendering can differ from PNG exports.
- After a generator change, `--fidelity` silhouette IoU stays at or above the
  figures recorded in `references/geometry-and-color.md`.

## Output Format

```text
DESIGN.md: <path>
Changed entries: <names or none>
Generated: <files>
Contact sheet: <path>
Drift check: <n same, n drift, n missing>
Fidelity: <mean silhouette IoU per style, or not run>
Open questions: <hue, glyph, or style decisions for the owner, or none>
```

## Failure / Uncertainty Handling

- If two candidate glyphs are equally plausible, render both on one contact
  sheet and ask the owner to pick.
- If `rsvg-convert` is missing, write SVGs only and report that PNGs and
  sheets were not rendered.
- If `--check` reports drift that the owner did not intend, stop before
  overwriting the logo and report which entry and file disagree.
