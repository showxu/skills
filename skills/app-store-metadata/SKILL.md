---
name: app-store-metadata
description: Review, prepare, validate, and localize Apple App Store metadata such as app name, subtitle, description, keywords, support URL, marketing URL, promotional text, privacy policy URL, and version-localization fields. Use for metadata files, App Store Connect field limits, localization readiness, and dry-run sync planning. Do not use for ASO strategy, screenshots, live App Store Connect edits, or app submission.
---

# App Store Metadata

## Purpose

Prepare and validate App Store metadata before it is pasted into or synced with
App Store Connect. This skill keeps field ownership, localization, limits, and
review-facing copy clear without performing live account changes by default.

## When To Use

- The user asks to review, prepare, validate, or localize App Store metadata.
- The task mentions app name, subtitle, description, keywords, promotional
  text, support URL, marketing URL, privacy policy URL, or app version
  localization fields.
- The user has local metadata JSON, `.strings`, fastlane metadata, or a planned
  App Store Connect metadata update.
- The request is about field limits, missing fields, localization coverage, or
  safe dry-run sync planning.

## When Not To Use

- App Store What's New only; use `app-store-whats-new`.
- ASO strategy, ranking, competitor keywords, or conversion optimization; use
  `app-store-aso`.
- Screenshot assets, preview videos, or product-page visual storytelling.
- Live App Store Connect writes, app submission, release state changes, pricing,
  subscriptions, or IAP changes.
- Swift implementation, Xcode build/signing, Simulator, or Instruments work.

## Inputs To Inspect

- Metadata source files: JSON, `.strings`, fastlane metadata directories, or
  user-provided copy.
- App context: app name, platform, version, primary locale, target locales, and
  whether this is the first version or a version update.
- Field ownership: app-info fields versus version-localization fields.
- Existing locale list and target storefronts.
- Any planned App Store Connect CLI command, only for dry-run review.

## Workflow

1. Identify the metadata surface.
   - App-info fields are app-level and shared across versions.
   - Version-localization fields are per App Store version and locale.
2. Load only the needed references.
   - Field ownership and limits: `references/apple-metadata-fields.md`.
   - Localization: `references/localization-workflow.md`.
   - Local files and dry-run CLI planning: `references/local-sync.md`.
   - Copy quality: `references/copy-review.md`.
3. Validate local content.
   - Use `scripts/validate_metadata.py` for JSON files, canonical metadata
     directories, or explicit field arguments.
   - Treat keyword limits as bytes, not characters.
4. Review content quality.
   - Separate required factual fields from marketing copy.
   - Flag unsupported claims, legal/privacy assertions, and vague descriptions.
   - Avoid keyword stuffing and duplicate keyword waste.
5. Check localization readiness.
   - Verify each target locale has the intended fields.
   - Do not literal-translate keywords; they should reflect local search terms.
   - Validate every locale independently.
6. Produce a safe final output.
   - Prefer a report, corrected local files, or dry-run command plan.
   - Stop before live writes unless the user explicitly asks for them and the
     relevant live-operation skill exists.

## Reference Files To Consult

- `references/_index.md`: reference map.
- `references/apple-metadata-fields.md`: official field split and limits.
- `references/localization-workflow.md`: locale coverage and adaptation rules.
- `references/local-sync.md`: local file shapes and dry-run sync planning.
- `references/copy-review.md`: metadata copy review rules.

## Safety / Confirmation Rules

- Do not upload, edit, or submit metadata in App Store Connect from this skill.
- Treat privacy, legal, health, finance, child-safety, regulated-device, award,
  certification, or compliance claims as requiring explicit source evidence.
- Do not invent app features, support guarantees, or country availability.
- If the user asks for a live write, pause and route to `app-store-connect`
  with explicit confirmation rules.

## Decision Rules

- During metadata review or validation, verify current field limits,
  editability, and required fields against Apple docs or current App Store
  Connect behavior before treating them as authoritative.
- Keep app-info and version-localization fields separate.
- Keywords are 100 bytes, comma-separated, and should not duplicate app name or
  company name.
- Description is for product-page clarity; avoid HTML and unsupported claims.
- Promotional text is separate from description and can be updated independently
  in App Store Connect, but this skill still does not perform the update.
- What's New belongs to `app-store-whats-new` when drafting from release
  evidence; this skill only validates the field as metadata.

## Output Format

For reviews:

```text
Metadata Review

Status:
- Pass / Needs work

Blocking issues:
- ...

Warnings:
- ...

Suggested edits:
- ...

Validation:
- field: current / limit

Next safe action:
- ...
```

For validation-only requests, return the script output plus concise fixes.

## Failure / Uncertainty Handling

- If the app version state is unknown, do not claim a field is editable now.
- If the metadata source format is unclear, identify the fields and ask for the
  minimum missing structure.
- If official limits are unclear or stale, verify against Apple documentation
  before giving hard rules.
- If local files and App Store Connect state may differ, label the local review
  as a file review, not an account-state review.
