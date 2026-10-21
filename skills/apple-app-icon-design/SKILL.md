---
name: apple-app-icon-design
description: Design, generate, and review original app icons in the style of each Apple app icon generation - Liquid Glass through Icon Composer, iOS 7-18 flat, macOS 11-15 tiles, and iOS 1-6 gloss - for Apple apps, web apps, or any project that wants an Apple-style icon. Turns a product brief into icon concepts and layered vector artwork, records them in a DESIGN.md Iconography entry, and produces an editable Icon Composer .icon document, native iOS, macOS, and watchOS appearance exports, style renderings, favicons, an apple-touch-icon, PWA and maskable web icons, comparison sheets, lint findings, and drift reports. Use for creating or redesigning app icons, choosing an icon style or generation, tuning glass material groups, matching an existing icon's look by measurement, and checking generated icons against their design source. Do not use for framework-style repository logos, social card composition, SF Symbols export, photographic or raster illustration, recreating Apple's own icons, or publishing app/store assets.
---

# Apple App Icon Design

## Purpose

Design an original app icon once, as layered artwork in a DESIGN.md entry,
and render it in the style of any Apple app icon generation for any project.
Icon Composer renders Liquid Glass natively. This skill renders the earlier
generations with measured geometry and labels them as style renderings.

## Inputs

- The product's purpose, audience, and brand colors, or an existing icon.
- The owner's `DESIGN.md`, with `app_icons` in the `## Iconography` JSON block.
- Artwork: original SVG layers drafted here, or SVG or PNG layers the owner
  supplies, relative to `DESIGN.md`.
- Delivery targets: an Apple app, a web app, or plain PNG/SVG files, and the
  styles the owner wants.

Read [design guidance](references/design.md) before drafting concepts or
layers, [generations](references/generations.md) before choosing styles,
[the input contract](references/format.md) before editing an entry,
[rendering and validation](references/rendering.md) before tuning materials
or geometry, and [reference matching](references/reference-matching.md)
before matching an existing icon's look. For a new entry, start from
`examples/DESIGN.example.md`.

## Workflow

1. Inspect the owner, existing art, brand tokens, and current icon. Keep
   design parameters in the owner's design document and artwork in its
   assets directory. When the owner wants to match an existing icon's look,
   capture the rendition the system displays and fit measured parameters
   with [reference matching](references/reference-matching.md); never
   estimate them from a screenshot.
2. Propose two or three concepts. Each names one central idea, a silhouette,
   a palette, and a layer plan: which shapes form the background color and
   each foreground group, back to front.
3. Draft each concept as vector layers on a 1024 px canvas, or adopt the
   owner's layers. Use filled shapes with clear edges, no text unless the
   brand requires it, and no painted highlights, shadows, or masks. Give SVG
   artwork the colors needed by the earlier styles. For Liquid Glass, use
   native layer `automatic-gradient` fills for modeled color, `solid` for
   uniform color, and group glass and blend controls for overlapping material.
   The [Apple icon study](references/rendering.md#apple-icon-material-study)
   records why gradients, translucency, and compositing matter; tune them
   together and inspect every appearance. Use native appearance overrides for
   fills, layer/group opacity, and group materials when an appearance needs
   different contrast. Default, Dark, and the shared Clear/Tinted family can
   be tuned separately without changing the source artwork.
4. Add each concept as an entry, run `--lint`, and render the candidates
   with `--sheet`. Ask the owner to choose; iterate on the entry and layers,
   never on generated files.
5. Choose styles from the delivery target. Apple apps ship Liquid Glass with
   an explicit `design_generation`; other projects may use any style. Record
   them under `styles`, with style artwork overrides only where a style needs
   different art. Set entry `web_dark: true` when a web target also needs
   masked dark icons from the native iOS Dark export; it is off by default.
6. Generate each style into the producer's ignored output directory with
   `scripts/app_icons.py DESIGN.md --name NAME --style STYLE --out OUTPUT`.
   Inspect the contact sheet on light and dark backgrounds at 160 px and
   32 px, every native appearance, and the circular maskable crop.
7. For Liquid Glass, regenerate the `.icon` into ignored scratch and open it
   in Icon Composer to verify editability and materials. Adopt adjustments
   into the entry, then regenerate. The document is a review intermediate,
   not a committed asset.
8. After acceptance, copy only consumed files to their owning locations and
   record each in the icon owner's `provenance.json` as described below. For
   GitHub presentation, avatar and marks belong in `profile/assets/` and
   repository logos in `.github/assets/logo/`. Check by regenerating into
   ignored scratch and comparing SHA-256 digests for each recorded output and
   consumed copy. Report differences instead of overwriting.

Concept choice, style choice, and visual acceptance require the owner's
judgment; lint, rendering, exports, and drift checks are deterministic
commands. The skill does not own uploads, store submissions, signing, or
releases.

## Decisions and Boundaries

- Design for recognition: one idea, few shapes, a simple background, and a
  silhouette that survives 32 px and the Clear and Tinted appearances.
- Liquid Glass comes only from Icon Composer. A missing renderer permits
  `--document-only` preparation and leaves native rendering unverified. Never
  imitate glass in SVG or label a style rendering as native.
- Earlier generations are style renderings of the same layers. Their
  geometry is measured and recorded in [rendering](references/rendering.md);
  the gloss highlight is a documented approximation.
- Use original art. Do not trace, recreate, or imitate Apple's icons, Apple
  hardware, SF Symbols, or another company's logo. Preserve the scope and
  provenance of explicitly supplied brand assets. Reference matching measures
  parameters for original art; its captures are never traced, shipped, or
  redistributed.
- Icon Composer ships with Xcode, and Apple's license terms govern native
  renders. Using them outside an Apple-platform app is the owner's decision;
  style renderings do not use Apple software or templates.
- Existing output directories are preserved. Compare with `--check`, or
  generate a separate candidate for review.

## Validation

- `--lint` reports `clean`, or each finding is fixed or recorded as an owner
  decision.
- The `.icon` opens in Icon Composer with the intended groups and source art,
  and all 18 platform/appearance exports have the correct dimensions.
- Each style's web set contains `favicon.svg`, 16 and 32 px favicons, 192 and
  512 px icons, a 1024 px avatar, a full-bleed 180 px apple-touch-icon, and a
  full-bleed 512 px maskable image whose essential content stays inside the
  central safe circle. With `web_dark`, Liquid Glass also includes five
  masked PNGs under `web/dark/`; verify them against native iOS Dark.
- Regeneration into ignored scratch reproduces the SHA-256 digest of every
  consumed file recorded in `provenance.json`; missing files and digest
  differences are reported. `--check` compares complete scratch output sets,
  including missing and extra files, rather than a directory of selected
  consumed copies.
- The manifest labels each output `native` or `style-rendering`.
- A fit to a reference icon agrees in the overlay, junction crops, and
  luminance cross-sections of [reference matching](references/reference-matching.md#5-verify).
- After changing geometry, rerun the measurements in
  [rendering](references/rendering.md), and run the
  [behavior fixtures](references/eval-fixtures.md) and package checks before
  presenting the skill as ready.

## Consumed icon provenance

Keep one `provenance.json` per icon with its source layers. GitHub-only sources
live in `.github/design/icons/<name>/`; product design, including an icon the
product ships, stays with the product. Record the product's README logo as a
consumed export too. Commit only the consumed copies; regenerate the `.icon`
document into ignored scratch when it is needed for review.

```json
{
  "icon": "<name>",
  "skill": "apple-app-icon-design",
  "skill_commit": "<full showxu/skills SHA used for verification>",
  "command": "<exact command>",
  "renderer": "<ictool bundle and short version>",
  "verified_at": "YYYY-MM-DD",
  "copies": [
    {"repository": "<owner/name>", "path": "<repo-relative path>", "output": "<skill output path>", "sha256": "<hex>"}
  ]
}
```

`output` is relative to the generated output directory. Verify both that
output and the consumed copy against `sha256`. Native regeneration runs with
Icon Composer on macOS; CI can compare consumed copies to recorded digests.

## Output

Report the chosen concept, the design entry, styles and targets, output
paths, renderer versions, lint result, contact sheets, drift result, visual
findings, and any unverified requirement. Keep machine paths and execution
logs in the local task report, outside reusable skill material.

## Resources

- [Design guidance](references/design.md)
- [Generations](references/generations.md)
- [Input contract](references/format.md)
- [Rendering and geometry validation](references/rendering.md)
- [Reference matching](references/reference-matching.md)
- [Behavior fixtures](references/eval-fixtures.md)
- [Commands](scripts/README.md)
- [Apple Human Interface Guidelines: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Apple Icon Composer](https://developer.apple.com/icon-composer/)
- [Apple's creation guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Create icons with Icon Composer](https://developer.apple.com/videos/play/wwdc2025/361/)
