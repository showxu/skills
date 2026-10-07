---
name: google-play-store-assets
description: Prepare, review, validate, localize, or generate Google Play store listing visual assets, including Android phone screenshots, tablet screenshots, Chromebook screenshots, feature graphics, app icons, preview videos, alt text, and upload-readiness reports. Use for Google Play screenshot sets, 7-inch and 10-inch tablet assets, feature graphic planning, Play Console preview asset QA, and Android store asset generator workflows. Do not use for Apple App Store screenshots, Android app implementation, Google Play release submission, paid acquisition, organic search, broad growth strategy, or live Play Console uploads without explicit confirmation.
---

# Google Play Store Assets

## Purpose

Prepare Google Play store listing preview assets that are accurate,
accessible, localized when needed, and upload-ready for Play Console.

This skill covers listing assets, not Android app code, release submission,
policy adjudication, paid acquisition, organic search, or broad growth
strategy.

## When To Use

- The user asks for Google Play screenshots, Android screenshots, Play Store
  screenshot sets, feature graphics, app icons, preview videos, Chromebook or
  tablet listing assets, or store listing visual QA.
- The task involves validating Google Play image dimensions, file format,
  alpha transparency, aspect ratio, feature graphic size, app icon size, or
  preview asset readiness.
- The task asks for a screenshot generator or export workflow for Google Play
  assets.
- The task asks to translate raw Android captures into a Google Play listing
  narrative or localized asset matrix.

## When Not To Use

- Apple App Store screenshots, App Store Connect screenshot wells, or iOS
  storefront assets: use `app-store-screenshots`.
- Google Play release submission, track rollout, internal testing, policy
  status, or Play Console state operations: no published skill exists yet.
- Android UI implementation, emulator capture, Gradle builds, signing, source
  debugging, or app code.
- Organic search, paid acquisition, Apple Search Ads, Google Ads, broad growth
  strategy, or product marketing campaigns.
- Live Play Console uploads or deletion of existing assets without explicit
  user confirmation.

## Inputs To Inspect

- Target device types: phone, 7-inch tablet, 10-inch tablet, Chromebook,
  Android TV, Wear OS, Automotive, Android XR, feature graphic, app icon, and
  preview video.
- Existing raw captures, app icon, brand colors, typeface, value proposition,
  feature priority, and desired asset count.
- Current Play Console state if supplied: required sections, existing assets,
  rejection messages, alt text, or preview asset warnings.
- Locale list, source locale, RTL languages, and whether localized screenshots
  need copy adaptation or only export.
- Whether the task is validation only, narrative/copy review, generator
  planning, or upload-readiness reporting.

## Workflow

1. Define the Google Play-only scope: asset types, device types, locale list,
   asset count, and whether assets are raw captures, designed listing
   screenshots, or generator output.
2. Check current Google Play requirements before treating dimensions, counts,
   or content rules as authority. Read
   `references/google-play-preview-assets.md`.
3. Plan the asset story before layout. Read
   `references/storyboard-and-copy.md` when creating or reviewing messaging.
4. Validate local assets before upload. Read `references/asset-readiness.md`
   and run `scripts/check_play_assets.sh` when files are available.
5. For localized sets, read `references/localization.md`; adapt copy per
   locale, re-check line breaks, write localized alt text, and mirror RTL
   layouts intentionally.
6. If a generator is requested, read `references/generator-workflow.md`; keep
   the generator Google Play-specific unless the user explicitly asks for a
   cross-store generator.
7. Produce the requested output: asset checklist, screenshot narrative,
   feature graphic plan, alt text set, validation report, generator plan, or
   upload-readiness summary.

## Reference Files To Consult

- `references/google-play-preview-assets.md`: official Google Play preview
  asset requirements and recommended eligibility rules.
- `references/asset-readiness.md`: local file checks, dimensions, alpha,
  aspect ratio, filename cleanup, and upload-ready QA.
- `references/storyboard-and-copy.md`: screenshot and feature graphic narrative
  rules, copy risks, and common mistakes.
- `references/localization.md`: localized asset matrices, text expansion,
  RTL handling, and localized alt text.
- `references/generator-workflow.md`: optional Google Play web generator shape,
  export matrix, and reliability notes.

## Script Usage

Validate local files with:

```bash
skills/google-play-store-assets/scripts/check_play_assets.sh \
  --kind screenshot \
  path/to/play-assets/screenshots
```

For feature graphics:

```bash
skills/google-play-store-assets/scripts/check_play_assets.sh \
  --kind feature-graphic \
  path/to/feature-graphic.png
```

## Safety / Confirmation Rules

- Never upload assets, delete assets, publish a listing, change Play Console
  state, or approve public listing artifacts without explicit user
  confirmation.
- Do not reuse image assets, mockups, funding files, badges, or branding in
  local output unless the user explicitly provides or approves them for this
  deliverable.
- Treat web generators, export tools, and Play Console automation as optional
  backends. Verify exact commands and flags before use.
- Do not upscale low-resolution captures and claim they are production-ready
  without warning the user.
- Mark ranking, recommendation, featuring, and conversion-rate claims as
  advisory unless verified by current reliable evidence.

## Decision Rules

- Use Google Play official requirements as hard rules; treat "highly
  recommended" guidance as eligibility or promotion-readiness guidance.
- If the app supports tablets, Chromebook, Wear OS, TV, Automotive, or XR,
  inspect those device sections separately instead of reusing phone assets by
  default.
- Keep screenshots grounded in actual app or game experience. Avoid generic
  lifestyle marketing that does not show the product.
- Feature graphics should convey the app or game value and survive center
  cropping. Avoid tiny details, price/ranking claims, and store badges.
- Include alt text for graphic assets and screenshots when preparing upload
  packages.
- If the task is validation-only, do not rewrite copy or propose a generator
  unless validation exposes a structural issue.

## Output Format

Use the smallest format that fits the request:

- **Asset plan**: target device types, asset count, narrative arc, source
  captures, feature graphic, app icon, preview video, locale matrix, and export
  sizes.
- **Copy review**: asset-by-asset headline, purpose, risk, and rewrite.
- **Validation report**: file, asset kind, dimensions, format, alpha, aspect
  ratio, target match, and action needed.
- **Generator plan**: project shape, canvas sizes, image paths, export matrix,
  QA gates, and command assumptions.
- **Upload-readiness summary**: ready assets, blockers, warnings, missing alt
  text, and required user confirmation before live Play Console action.

## Failure / Uncertainty Handling

- If exact Google Play requirements may have changed, verify official Play
  Console Help before giving dimensions or counts as final.
- If a file cannot be inspected, report the missing tool or path and provide a
  manual check.
- If source captures are the wrong aspect ratio, prefer re-capture or redesign
  over stretching.
- If localized copy no longer fits, rewrite the claim for that locale rather
  than shrinking text until it becomes unreadable.
