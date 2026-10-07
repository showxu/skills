---
name: apple-app-icon-design
description: Design, generate, and review layered Apple app icons from owner-supplied SVG or PNG artwork and a DESIGN.md Iconography entry. Produces an editable Icon Composer .icon document, native iOS, macOS, and watchOS appearance exports, an avatar, favicons, an apple-touch-icon, a maskable web icon, contact sheets, and drift reports. Use for creating app icons, tuning glass material groups, regenerating appearance variants, and checking generated icon assets against their design source. Do not use for framework-style repository logos, social card composition, SF Symbols export, raster illustration, or publishing app/store assets.
---

# Apple App Icon Design

## Purpose

Keep editable artwork, native appearance exports, and web icons tied to one
design entry. Icon Composer supplies native materials, lighting, and platform
masks. Static web icons use a flat rendering of the same foreground layers.

## Inputs

- The owner's `DESIGN.md`, with `app_icons` in the `## Iconography` JSON block.
- Original or explicitly supplied SVG or PNG layers, relative to that file.
- Intended platforms, brand colors, recognizable foreground, and output owner.
- Existing generated files when reviewing drift.

Read [the input contract](references/format.md) before editing an entry and
[rendering and validation](references/rendering.md) before choosing materials.
For a new family, start with `examples/DESIGN.example.md` and replace its
example artwork and identity with the real design.

## Workflow

1. Inspect the owner, existing art, and current icon. Keep the design parameters
   in the owner's design document and artwork in its assets directory.
2. Prepare flat foreground layers on a 1024 px canvas. Outline text and keep
   platform masks out of the source artwork. Split meaningful depth levels
   into groups; do not bake native glass highlights into those layers.
3. Set the background and material groups in the design entry. Preserve the
   recognizable silhouette across appearances and at small sizes.
4. Generate into the producer's ignored output directory with
   `scripts/app_icons.py DESIGN.md --name NAME --out OUTPUT`.
5. Inspect the contact sheet on light and dark backgrounds. Check each
   platform at 160 px and 32 px, all exported appearances, the circular crop,
   and the small web icons. Native exports can coincide on platforms where
   the renderer shares an appearance; report what the renderer produced.
6. Open the `.icon` in Icon Composer to verify editability and inspect any
   material issue. Adopt adjustments into the design entry, then regenerate;
   an edited output alone is not the source of truth.
7. After acceptance, copy the dedicated output directory to its owning asset
   location and run `--check` against it. Report any differences instead of
   overwriting them. Regenerate previews when source artwork changes.

This is a staged workflow. Design choices and visual acceptance require
judgment; document generation, exports, and drift checking are deterministic
commands. It does not own uploads, store submissions, signing, or releases.

## Decisions and Boundaries

- Keep each icon recognizable in Default, Dark, Clear, and Tinted appearances.
  For thin or busy artwork, simplify the glyph or reduce material effects;
  do not claim success solely from a successful export.
- Use Apple's renderer for native masks. The SVG continuous corner is for
  flat web assets; it is measured separately and is not applied to `.icon`
  foreground layers.
- Use original art. Do not fetch, trace, or recreate Apple marks, SF Symbols,
  or another company's logo as a substitute for original artwork. Preserve
  the scope of explicitly supplied brand assets and their provenance.
- A missing renderer permits `--document-only` preparation, but leaves native
  rendering and visual validation incomplete. Do not substitute drawn glass
  effects and label them as native renditions.
- The export tool's format is version-dependent. Validate with the installed
  Icon Composer and record its version in the output manifest.
- Existing output directories are preserved. Compare with `--check`, or
  generate a separate candidate for review.

## Validation

- The `.icon` opens in Icon Composer with the intended groups and source art.
- All 18 platform/rendition combinations export successfully, with the
  correct dimensions. Inspect the output rather than assuming all 18 differ.
- The web set contains a 1024 avatar, an SVG favicon, 16 and 32 px favicons,
  a 180 px apple-touch-icon, and a 512 px maskable image.
- Touch and maskable images have full-bleed opaque backgrounds. Essential
  maskable foreground stays inside the central safe circle.
- `--check` reports `same` for every file and detects missing and extra files.
- After changing corner geometry, rerun the mask comparison described in
  [rendering](references/rendering.md).
- Run the [behavior fixtures](references/eval-fixtures.md) and package checks
  before presenting the skill as ready.

## Output

Report the design entry, `.icon` path, native export count and dimensions,
renderer version, contact sheet, web set, drift result, visual findings, and
any unverified requirement. Keep machine paths and execution logs in the
local task report, outside reusable skill material.

## Resources

- [Input contract](references/format.md)
- [Renderer and geometry validation](references/rendering.md)
- [Behavior fixtures](references/eval-fixtures.md)
- [Commands](scripts/README.md)
- [Apple Icon Composer](https://developer.apple.com/icon-composer/)
- [Apple's creation guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Create icons with Icon Composer](https://developer.apple.com/videos/play/wwdc2025/361/)
