# Behavior Fixtures

Run these with concrete design and artwork inputs. Keep generated documents,
rendered sheets, command results, and visual findings in the producer's
ignored validation directory. These cases establish behavior under explicit
invocation, not automatic trigger quality.

## AI-01 — New layered app icon

- Prompt: Create an editable app icon and web set from our two SVG layers.
- Input: A design entry with a colored background and two original layers.
- Expected: An editable `.icon`, 18 native exports, the web set, a contact
  sheet, renderer metadata, and a clean drift report.
- Preserve: Source artwork and design ownership; no pre-mask on native layers.
- Failure: Flattening the `.icon` to a single screenshot or fabricating native
  appearances with SVG effects.
- Acceptance: Icon Composer opens the document, all dimensions match, and
  the foreground remains recognizable across the sheet at 32 px.

## AI-02 — Existing art was edited

- Prompt: Check these generated icon assets against DESIGN.md.
- Input: One changed favicon, one missing rendition, and one extra stale file.
- Expected: Separate drift, missing, and extra results; non-zero exit.
- Preserve: Every file in the target directory.
- Failure: Overwriting the target or reporting the unchanged document as proof
  that the entire set matches.
- Acceptance: The report identifies all three changes; target hashes remain
  unchanged after checking.

## AI-03 — Missing native renderer

- Prompt: Generate every appearance on a machine without Icon Composer.
- Input: Valid design and artwork; no export-capable renderer.
- Expected: An actionable renderer diagnostic; document-only preparation can
  proceed if requested, with native rendering explicitly unverified.
- Preserve: Existing files and the native-rendering requirement.
- Failure: Drawing substitute glass effects and claiming native validation.

## AI-04 — Invalid or incomplete art

- Prompt: Generate the app icon from this design entry.
- Input: A missing layer, an SVG with live text or an external dependency,
  an unsupported field, or a malformed material value.
- Expected: Non-zero exit with the offending input identified.
- Preserve: The output destination remains absent until a complete candidate
  is generated.
- Failure: Silently dropping an input and publishing partial output.

## AI-05 — Maskable crop

- Prompt: Make the same icon work as a maskable web icon.
- Input: Foreground artwork extending to its canvas edges.
- Expected: Opaque corners and a foreground fitted within the central safe
  circle, plus a crop review.
- Preserve: The original art and native icon composition.
- Failure: A pre-rounded or transparent background, or clipping essential
  foreground in a circular crop.

## AI-06 — Adjacent work

- Prompt: Compose a social card or upload an icon to an app store.
- Expected: Identify the unowned work and preserve existing assets.
- Failure: Performing a publication operation merely because icon files are
  available.

## AI-07 — Native and web layer order

- Prompt: Keep the foreground in front of the overlapping background layer.
- Input: Opaque red and green squares at the same position, with red first
  and green last in the design entry. Exercise separate groups and two
  layers in one group.
- Expected: Both native and web exports show green at the overlap. Native
  document arrays list frontmost content first; design arrays paint last on top.
- Failure: The native export shows red while the web export shows green.
- Acceptance: Inspect the native renderer's center pixel for both cases and
  run the document-order regression.

## AI-08 — Renderer returns the wrong dimensions

- Prompt: Export the native and web icon set with the selected renderer.
- Input: A renderer returns a readable PNG whose canvas differs from the
  requested platform or web size.
- Expected: A non-zero exit naming the file and expected and actual dimensions.
- Preserve: Existing target assets; the candidate stays unpublished.
- Failure: Treating valid PNG encoding as proof of the requested dimensions.
- Acceptance: Native and web dimension regressions reject the mismatched image;
  a complete native example exports all 18 requested platform canvases.

## AI-09 — Concepts from a product brief

- Prompt: We need an icon for our habit-tracking web app; we have no artwork.
- Input: A product description and brand colors; no layers.
- Expected: Two or three original concepts, each with one idea, a silhouette,
  a palette, and a layer plan; drafted SVG layers; one entry per concept; a
  `--lint` result; and a `--sheet` comparison for the owner to choose from.
- Preserve: Brand tokens and the owner's choice of concept.
- Failure: Picking a concept for the owner, drafting text-heavy or photo-like
  art, or tracing an existing app's icon.
- Acceptance: Every drafted layer passes the SVG contract, lint findings are
  resolved or recorded, and each concept is recognizable at 32 px.

## AI-10 — Poor layer decomposition

- Prompt: Generate the app icon from this artwork.
- Input: One flattened layer with painted highlights, a drop shadow, and
  hairline details.
- Expected: Lint findings for thin shapes, and a recommendation to split the
  art into background color and two or three filled foreground groups without
  painted effects.
- Preserve: The supplied artwork until the owner approves a revision.
- Failure: Shipping the flattened art as a Liquid Glass icon, or adding more
  painted effects to compensate.
- Acceptance: The revised entry lints clean and its appearances stay legible.

## AI-11 — Styles for a web app

- Prompt: Make Apple-style icons for our web app; we deploy from Linux CI.
- Input: An entry and no Mac in the build environment.
- Expected: The owner chooses styles; `flat`, `mac-tile`, or `gloss` render
  with `rsvg-convert` alone, and each web set covers favicons, manifest
  icons, the apple-touch-icon, and the maskable image. Liquid Glass output,
  if wanted, is generated once on a Mac and committed, with the Icon
  Composer license decision left to the owner.
- Preserve: Existing web assets until `--check` reviews them.
- Failure: Imitating Liquid Glass in SVG, or claiming native rendering.
- Acceptance: Manifests say `style-rendering`, and `--check` reports `same`.

## AI-12 — Legacy style with its own art

- Prompt: Render the gloss version with our leather texture.
- Input: An entry whose `gloss` style supplies `groups` with a 1024 px PNG
  texture layer.
- Expected: Only the gloss rendering uses the texture; other styles keep the
  shared groups.
- Preserve: Shared groups and the texture's provenance.
- Failure: Replacing the shared groups or baking the texture into Liquid
  Glass layers.
- Acceptance: The gloss sheet shows the texture under the highlight; lint
  exempts the full-bleed texture group.

## AI-13 — Glass without Icon Composer

- Prompt: Icon Composer isn't installed; draw the Liquid Glass look in SVG.
- Input: A valid entry; no export-capable renderer.
- Expected: Decline the imitation; offer `--document-only` preparation and
  style renderings, with native rendering reported as unverified.
- Preserve: The native-rendering requirement for Liquid Glass.
- Failure: SVG highlights or blur labeled as Liquid Glass.

## AI-14 — Breaking out of the macOS tile

- Prompt: Let the pencil stick out of the tile in the macOS-style icon.
- Input: An entry whose pencil group's SVG extends past the 1024 box.
- Expected: `"mac-tile": {"unclipped": [N]}` for the pencil group; the tile
  and shadow render as usual and the pencil extends past the tile; other
  styles crop the pencil at the art boundary.
- Preserve: The pencil artwork and the other groups' clipping.
- Failure: Clipping the listed group, unclipping every group, or enlarging
  the tile.
- Acceptance: The mac-tile sheet shows the breakout; lint does not report
  the unclipped group as outside the shape.


## native-material-isolation

Target behavior: native material controls preserve the artwork used by other styles.

Input prompt: "Give our glass layers gradient fills, a chromatic shadow and additive
blending, while preserving our flat, mac-tile and gloss icons."

Context and files:

- Original layered SVG artwork and a DESIGN.md entry declaring all four styles.
- A candidate with group blending, specular, group/layer opacity, shadow kinds,
  and solid/automatic-gradient fills; include both chromatic shadow spellings.
- Baseline outputs from the same artwork and the pre-material script; an unchanged
  `chromatic` entry is a compatibility control.

Expected output:

- Native JSON carries the materials and uses `layer-color` for chromatic shadows.
- Native exports respond to material changes. Other styles retain their artwork.
- Lint measures SVG colors and emits informational fill notices.

Forbidden behavior:

- Recoloring or fading another style's artwork, rejecting an existing `chromatic`
  entry, treating an informational line as failure, or claiming an ignored native
  property works.

Acceptance checks:

- Compare full legacy output trees and comparison sheets byte-for-byte against
  their controls; run `--check` and require `same` for every committed file.
- Assert that both chromatic spellings produce equal native documents and native
  pixels within the existing 1/255 tolerance, without mutating the entry.
- Require native material changes larger than 1/255 and unchanged SVG asset bytes.
- Assert that fill notices do not change lint status and artwork findings remain.

Baseline expectation:

- An old skill rejects the new controls or passes `chromatic` through to native
  JSON. Its successful legacy `chromatic` outputs must still match the candidate.
- A no-skill implementation may bake materials into artwork and alter other styles.

Evidence sources:

- Generated `.icon` JSON/assets, native PNG comparisons, legacy file hashes, sheet
  bytes, lint and `--check` output, and `scripts/test_app_icons.py` results with
  `APP_ICONS_BASELINE` pointing to the pre-material script.

Owner notes:

- Material ownership and native names are defined in [format](format.md) and
  [rendering](rendering.md#native-material-schema).

## appearance-material-specialization

Target behavior: material overrides affect only the selected native appearance family.

Input prompt: "Keep the normal green layer, make it red only in Dark, and use a
separate monochrome treatment for Clear and Tinted. Adjust their opacity as needed."

Context and files:

- Original layered artwork and an entry with layer fill, layer/group opacity,
  and group material controls.
- Base-only controls and candidates with each default, dark, and tinted override;
  cover absent base values and malformed overrides separately.
- Export-capable Icon Composer with design generations 26 and 27.

Expected output:

- Each overridden property uses one native specialization array containing the
  inherited value and explicit appearance entries, with no competing scalar.
- Default retains its base unless explicitly overridden; Dark and Clear/Tinted
  use their respective overrides. Opacity and group materials follow the same rule.

Forbidden behavior:

- Emitting a scalar beside its native array, leaking Dark into Default, accepting
  partial structured overrides, or treating Clear as a separate specialization key.

Acceptance checks:

- Compare all six iOS renditions for every property and appearance override.
  Require target changes greater than 1/255 and unmatched deltas at most 1/255.
- Verify fill and group/layer opacity fallback with no explicit base value.
- Verify generation-27 refraction changes pixels; generation 26 preserves its
  native no-effect behavior for both scalar and specialized refraction values.
- Assert malformed maps, partial materials, and invalid colors are rejected;
  invalid opacity overrides identify the correct group or layer owner.

Baseline expectation:

- An old skill rejects appearance fields. A no-skill implementation may leave the
  scalar in place, silently suppressing the overrides, or use guessed Clear keys.

Evidence sources:

- Serialized documents, base/candidate PNGs and decoded channel deltas for every
  rendition, validation diagnostics, and native appearance tests in
  `scripts/test_app_icons.py`.

Owner notes:

- The native appearance mapping and generation limits are recorded in
  [rendering](rendering.md#native-material-schema).

## optional-native-dark-web-set

Target behavior: an explicit opt-in exports dark web PNGs from native iOS Dark.

Input prompt: "Provide dark favicons and manifest icons for our Liquid Glass icon."

Context and files:

- Original layered artwork with visibly distinct Default and Dark fills.
- Entries with `web_dark` omitted, false, and true; include legacy styles.
- Native iOS Dark export and pre-material producer outputs as comparison controls.

Expected output:

- Five masked PNG sizes under `web/dark/`, resized from native iOS Dark and listed
  in the manifest. Existing default web files retain their bytes.
- Other styles, source artwork, and full-bleed files are preserved.

Forbidden behavior:

- Synthesizing dark colors from artwork, changing the default set, or producing
  dark files when the option is omitted or false.

Acceptance checks:

- Check the five documented filenames and dimensions and compare each file's
  bytes with a direct resize of native iOS Dark; require manifest membership.
- Compare omitted/false output byte-for-byte against the baseline using identical
  native exports. Require no dark directory and unchanged legacy style outputs.
- Compare opt-in output with the default set: only the five dark files and the
  manifest's file list may differ.

Baseline expectation:

- An old skill rejects the opt-in field and cannot produce the dark web set.
- A no-skill implementation may derive dark colors from artwork or replace default
  files instead of adding the explicitly requested native appearance.

Evidence sources:

- Native Dark and resized PNGs, file lists, dimensions, manifest contents, baseline
  file comparisons, and the dark-web and baseline tests in `scripts/test_app_icons.py`.

Owner notes:

- Output filenames and source ownership are defined in
  [rendering](rendering.md#optional-dark-web-exports).

## reference-matching

Target behavior: matching an existing icon's look fits measured parameters of
original artwork to the rendition the system displays.

Input prompt: "Make the lines in our icon's background feel like the ones in
that app's icon in the Dock."

Context and files:

- An installed reference app on macOS 26 or later whose bundle also carries a
  legacy `.icns`.
- The owner's original line artwork, parameterized by width, spacing, and
  inset; Icon Composer for native candidate exports.

Expected output:

- A 1024 px capture from `NSWorkspace.shared.icon(forFile:)`, mapped from the
  100..923 px tile to the canvas and kept in ignored validation output.
- Local-contrast line-art maps of reference and candidates; geometry fitted
  by normalized cross-correlation in a window without foreground objects that
  keeps the rim band where lines meet it, then opacity fitted by squared
  difference with the geometry fixed.
- An overlay, 4–6x junction crops, and luminance cross-sections in the task
  report; the fitted values written into the original artwork.

Forbidden behavior:

- Fitting the bundle's `.icns`, estimating parameters from a screenshot,
  fitting opacity by correlation, masking the rim where lines merge into it,
  tracing or importing the reference's shapes or pixels, or committing the
  capture.

Acceptance checks:

- After mapping, the capture's mask matches a native macOS export with alpha
  intersection-over-union of at least 0.999; the `.icns` tile does not.
- The overlay shows no systematic fringe, and cross-sections agree in line
  width, peak, and spacing.
- A candidate that differs from the reference only in opacity is told apart
  by the contrast fit, although its correlation score equals the match's.
- Delivered artwork contains no reference pixels or traced paths.

Baseline expectation:

- Without the method, an agent estimates parameters from a downscaled raster,
  off by about 2x in practice, or fits the legacy `.icns` tile.

Evidence sources:

- Capture metadata (reference app, system version, appearance), mask
  comparison, correlation scores, and the verification images.

Owner notes:

- The method is owned by [reference matching](reference-matching.md); rim
  clearance by [rendering](rendering.md#glass-color-and-rim).

## continuous-corner-overrun

Target behavior: rounded rectangles whose corner departures exceed an edge
render without a stray segment, and lint finds that defect in any SVG layer.

Input prompt: "Our bar is 160 px tall with continuous corners of radius 70,
and there's a flat line on its side."

Context and files:

- A layer whose path joins continuous corners with straight lines along an
  edge shorter than their two departures.
- The same bar drawn with `--continuous-rect`.

Expected output:

- `--lint` reports the line that doubles back, with its position and
  length; cusps where curves meet in other artwork stay clean.
- The helper's path has no reversal, stays convex and inside its rectangle,
  and joins each blend tangentially; corners that fit keep the existing
  continuous outline byte-for-byte.

Forbidden behavior:

- Hiding the segment with a stroke or mask, or changing the owner's radii
  without reporting it.

Acceptance checks:

- The continuous-rectangle, path-reversal, and lint tests in
  `scripts/test_app_icons.py` pass, and legacy style outputs match the
  pre-change script byte-for-byte.

Baseline expectation:

- The pre-change script offers no helper and its lint stays clean while the
  stray segment renders.

Evidence sources:

- Lint output, helper path data and `info` lines, and rendered comparisons of
  the hand-joined and helper outlines.

Owner notes:

- Geometry and lint rules are owned by
  [rendering](rendering.md#continuous-rectangles).

## grid-backdrop

Target behavior: a design-grid backdrop is drawn as an original, flat texture
layer whose corner edges peel out of the glass rim.

Input prompt: "Put a subtle design grid behind our build tool's glyph, like
the grids behind developer-tool icons."

Context and files:

- An entry with an original foreground and a Liquid Glass style; the layer
  from `--grid-backdrop`.

Expected output:

- The grid in its own group with specular off, no shadow, and layer opacity
  near 0.2; lines at 25%, 50%, and 75%, the middle ones running into the rim;
  corner edges only in the corner cells, turning into the outer lines.
- Lint findings for thin lines, corner edges crossing the outline, and
  lightness against a light foreground, recorded as owner decisions.
- Style renderings, if delivered, use a style layer from
  `--grid-backdrop opacity=0.2`.

Forbidden behavior:

- Describing or packaging the result as a copy of an existing app icon,
  pairing the grid with another app's foreground motif, drawing a full inner
  border or cell edges along the rim, enabling specular on the grid, or
  drawing the corner edge as a plain rounded rectangle that leaves a stray
  segment.

Acceptance checks:

- `--lint` reports no doubled-back line; the grid tests in
  `scripts/test_app_icons.py` pass, including the edge's gap to the glass
  outline tapering from more than 18 px at the turn to under 4 px on the
  diagonal.
- Native Default and Dark exports show flat lines at small and large sizes.

Baseline expectation:

- Without the recipe, an agent draws a uniform inset border, leaves specular
  on so the lines look like embossed tubes, or hits the corner overrun.

Evidence sources:

- The generated layer, native exports, lint output, and backdrop tests.

Owner notes:

- The recipe is owned by [design](design.md#grid-backdrop); its geometry by
  [rendering](rendering.md#continuous-rectangles).

## AI-15 — Consumed copies and native review

- Prompt: Deliver the accepted icon as an organization avatar and a CLI logo,
  then check that both still match the design source.
- Input: Accepted DESIGN and layers, a native output set, and two selected
  consumed files in different repositories; one copy is subsequently edited.
- Expected: Only the avatar and logo are copied to `profile/assets/` and
  `.github/assets/logo/`. One source-owned `provenance.json` records both
  repositories, paths, output paths, SHA-256 digests, skill commit, renderer
  version, command and verification date. Regeneration in ignored scratch
  supplies the `.icon` for review and detects the changed copy by digest.
- Preserve: Product-owned design and every consumed copy until drift is
  resolved by its owner.
- Failure: Commit the `.icon`, copy the complete output directory, create a
  duplicate `exports/`, or run whole-set `--check` against selected copies.
- Acceptance: The receipt accounts for every consumed file; the changed copy
  is named, unchanged copies match, and generated intermediates stay ignored.
