---
name: app-store-screenshots
description: Prepare, review, validate, localize, or generate Apple App Store screenshot assets from device captures, app icons, copy briefs, official Product Bezels, or generator workflows. Use for App Store screenshot sets, export sizes, upload readiness, Media Manager localization, storyboard/copy QA, screenshot asset validation, and screenshot generators that frame captures in Apple device bezels. Do not use for Google Play, Android screenshots, ASO ranking claims, Swift UI implementation, Simulator automation, live App Store Connect uploads, generic product marketing, or standalone Apple Design Resources cataloging.
---

# App Store Screenshots

## Purpose

Prepare Apple App Store screenshot assets that are visually effective,
localized when needed, and upload-ready for App Store Connect.

This skill treats screenshots as App Store listing assets. It does not design
app UI, automate simulator capture, upload assets live, or handle Google Play
or Android store requirements.

## When To Use

- The user asks for App Store screenshots, screenshot sets, device screenshots,
  screenshot marketing assets, screenshot copy, screenshot localization, or
  upload-ready screenshot files.
- The task involves validating screenshot dimensions, file format, alpha
  transparency, color space, or Media Manager readiness.
- The task asks for a screenshot generator or export workflow for Apple App
  Store assets.
- The screenshot workflow needs official Apple Product Bezels or device frames;
  use `apple-design-resource` for the resource fetch/extract step.
- The task asks to translate raw app captures into a store-page narrative.

## When Not To Use

- Do not use for Google Play, Android screenshots, Android feature graphics, or
  cross-store asset generation.
- Do not use for ASO ranking or algorithm claims; route listing optimization to
  `app-store-aso`.
- Do not use for SwiftUI/UIKit view implementation, simulator automation,
  Xcode build/run/debug, signing, notarization, or binary upload workflows.
- Do not perform live App Store Connect uploads from this skill.
- Do not use for standalone Apple Design Resources lookup, probing, download,
  or extraction. Use `apple-design-resource`.

## Inputs To Inspect

- Target platforms and device families: iPhone, iPad, Mac, Apple TV, Apple
  Vision Pro, Apple Watch, iMessage.
- Existing raw captures, app icon, brand colors, typeface, product positioning,
  feature priority, and desired slide count.
- Current App Store Connect state if supplied: required device wells,
  localizations, current screenshots, rejection messages, or Media Manager
  errors.
- Locale list, source locale, RTL languages, and whether localized screenshots
  need copy adaptation or only image export.
- Whether the user needs design guidance, validation only, or a generator
  workflow.
- Official Apple Product Bezels from `apple-design-resource` when screenshots
  need device frames.

## Workflow

1. Define the Apple-only scope: platform, device families, locale list, slide
   count, and whether assets are raw captures, designed marketing screenshots,
   or generator output.
2. Check current Apple requirements before treating dimensions or upload rules
   as authority. Read `references/apple-screenshot-specs.md` for field limits,
   required device classes, and scaling caveats.
3. Plan the screenshot story before layout. Read
   `references/storyboard-and-copy.md` when creating or reviewing messaging.
4. Validate assets before upload. Read `references/asset-readiness.md` and run
   `scripts/check_screenshots.sh` when files are available locally.
5. For localized sets, read `references/localization.md`; adapt copy per
   locale, re-check line breaks, and mirror RTL layouts intentionally.
6. If a generator is requested, read `references/generator-workflow.md`; keep
   the generator Apple-only unless the user explicitly moves work to another
   repository or skill.
7. If official device frames are needed, call `apple-design-resource` to fetch,
   probe, download, or extract Product Bezels, then use the returned PNG/PSD
   paths as screenshot-generator inputs.
8. Produce the requested output: asset checklist, screenshot narrative, copy
   options, validation report, generator plan, or upload-readiness summary.

## Reference Files To Consult

- `references/apple-screenshot-specs.md`: Apple official screenshot sizes,
  minimum/maximum counts, format, required device classes, and scaling notes.
- `references/asset-readiness.md`: local file checks, alpha/color-space
  handling, filename cleanup, resizing cautions, and upload-ready QA.
- `references/storyboard-and-copy.md`: slide narrative, copy rules, examples,
  layout variety, and common mistakes.
- `references/localization.md`: locale structure, translation versus
  localization, RTL handling, and localized QA.
- `references/generator-workflow.md`: optional Apple-only web generator shape,
  export rules, and reliability notes.

## Safety / Confirmation Rules

- Never upload screenshots, delete screenshots, change App Store Connect state,
  or approve review artifacts without explicit user confirmation.
- Do not reuse image assets, mockups, funding files, badges, or branding in
  local output unless the user explicitly provides or approves them for this
  deliverable.
- Treat `asc`, frame generators, and web export tools as optional backends.
  Verify exact commands and flags before use.
- Do not upscale low-resolution input screenshots and claim they are
  production-ready without warning the user.
- Mark ASO ranking, screenshot indexing, and conversion-rate claims as
  advisory unless verified by current reliable sources.

## Decision Rules

- If the app runs on iPad, include an iPad requirement check.
- If the UI is identical across device sizes and localizations, prefer the
  highest required Apple size plus Apple's scaling model; add device-specific
  screenshots only when quality, layout, or localization needs it.
- If the task is validation-only, do not rewrite copy or propose a generator
  unless validation exposes a structural issue.
- If the task is copy/design, keep each slide to one user-visible idea and
  make the first slide the strongest benefit.
- If the task is generator creation, keep the project shape minimal and
  deterministic: stable dimensions, preloaded images, predictable filenames,
  and no hidden live upload step.

## Output Format

Use the smallest format that fits the request:

- **Screenshot plan**: device families, slide count, narrative arc, asset
  inputs, locale matrix, and export sizes.
- **Copy review**: slide-by-slide headline, purpose, risk, and rewrite.
- **Validation report**: file, dimensions, format, alpha, color space, target
  match, and action needed.
- **Generator plan**: project shape, canvas sizes, image paths, export matrix,
  QA gates, and command assumptions.
- **Upload-readiness summary**: ready assets, blockers, warnings, and required
  user confirmation before any live operation.

## Failure / Uncertainty Handling

- If exact Apple requirements may have changed, stop and verify official Apple
  documentation before giving dimensions as final.
- If a file cannot be inspected, report the missing tool or path and provide a
  manual check.
- If source captures are the wrong aspect ratio, prefer re-capture or redesign
  over stretching.
- If localized copy no longer fits, rewrite the claim for that locale rather
  than shrinking text until it becomes unreadable.
