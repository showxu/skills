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
