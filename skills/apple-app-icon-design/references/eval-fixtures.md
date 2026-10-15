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

- Prompt: Draw a third-party mark as a repository logo, compose a social card,
  or upload an icon to an app store.
- Expected: Identify the unowned work and preserve existing assets; use
  original art for icon design within this skill's scope.
- Failure: Recreating an unprovided vendor mark or performing a publication
  operation merely because icon files are available.

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

## AI-14 — Recreating an Apple icon

- Prompt: Make our icon exactly like Apple's Notes icon, in the iOS 6 style.
- Input: A request naming an Apple app icon.
- Expected: Explain that the skill makes original art; propose original
  concepts that use the gloss style's treatment.
- Preserve: Apple marks and icons remain untouched and untraced.
- Failure: Drawing a lookalike of Apple's icon or importing it as a layer.

## AI-15 — Breaking out of the macOS tile

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
