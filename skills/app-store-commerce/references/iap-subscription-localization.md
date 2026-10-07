# IAP And Subscription Localization

## Scope

Use this reference for localizing commerce-specific App Store Connect records:

- Subscription group display names.
- Auto-renewable subscription display names and descriptions.
- Consumable, non-consumable, and non-renewing subscription display names and
  descriptions.

Do not use it for app listing metadata, screenshots, or What's New text.

## Current Locale Handling

Apple's current App Store localization set is the authority. As of
2026-04-30, Apple documents 50 App Store localizations:

```text
ar-SA, bn, ca, zh-Hans, zh-Hant, hr, cs, da, nl-NL, en-AU,
en-CA, en-GB, en-US, fi, fr-FR, fr-CA, de-DE, el, gu, he,
hi, hu, id, it, ja, kn, ko, ms, ml, mr, no, or, pl, pt-BR,
pt-PT, pa, ro, ru, sk, sl, es-MX, es-ES, sv, ta, te, th,
tr, uk, ur, vi
```

Validate locale codes against current App Store Connect or the chosen backend
before live bulk operations. Older upstream examples may list fewer locales.

## Workflow

1. Resolve the app, product, subscription, and subscription group IDs.
2. List existing localizations first.
3. Build a locale matrix:
   - locale
   - product ID or group ID
   - existing display name
   - target display name
   - existing description
   - target description
   - action: create, update, skip, conflict
4. Create missing localizations only when target values are present.
5. Update existing localizations only when the user asks to update or the
   matrix marks the locale as stale.
6. Continue per-locale failures and aggregate errors. Do not stop the whole
   batch after the first locale failure unless the failure affects identity or
   authorization.
7. Verify by listing localizations again and summarizing create/update/skip
   counts.

## Field Rules

- Do not use localized display names as identifiers.
- Use the same display name across locales only if the user explicitly
  supplied it as intentional. Otherwise treat identical names across all
  locales as a review point, not proof of failure.
- Keep descriptions truthful and specific to the purchase. Do not add claims
  the app or entitlement cannot support.
- Respect current Apple field limits before upload. If a backend reports a
  different limit than memory or upstream notes, the current backend wins.
- IAP and subscription localizations can be review-facing. Do not imply they
  are private operational labels.

## Optional Backend Command Shapes

If `asc` is selected as the backend, verify command help first. Upstream
workflow examples used these shapes:

- List subscription localizations, create missing locale entries, update
  existing entries, then verify.
- List subscription group localizations, create or update display names and
  optional custom app names, then verify.
- List IAP localizations, create or update display name and description, then
  verify.
- Use ID resolver commands when the user supplied names instead of stable IDs.

Do not require `asc`; convert these into official API, UI, or manual steps
when another backend is selected.

## Output Shape

```text
Commerce Localization Plan

Source: ...
App: ...
Products/groups:
- ...

Locale matrix:
- locale / object / action / reason

Conflicts:
- ...

Requires confirmation:
- create/update localizations for ...

Verification:
- list localizations after apply
```
