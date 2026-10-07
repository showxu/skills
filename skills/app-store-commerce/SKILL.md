---
name: app-store-commerce
description: Audit and plan Apple App Store commerce operations for pricing, availability, in-app purchases, auto-renewable subscriptions, subscription or IAP localizations, and RevenueCat catalog reconciliation. Use for read-only catalog drift reports, pricing schedule planning, territory availability checks, product ID mapping, entitlement/offering/package review, and confirmation-gated commerce operation plans. Do not use for StoreKit implementation, business pricing strategy, live price/catalog changes without explicit confirmation, ASO, metadata copywriting, release submission, signing, notarization, Google Play, or broad growth marketing.
---

# App Store Commerce

## Purpose

Handle App Store commerce operations safely: pricing and availability, IAP and
subscription catalog review, subscription or IAP localizations, and
RevenueCat catalog reconciliation.

This skill is operations-first. It can audit, plan, and prepare confirmation
packets, but it must not silently change prices, product availability,
subscriptions, IAPs, RevenueCat entitlements, offerings, or packages.

## When To Use

- The user asks about App Store pricing, territory pricing, price schedules,
  price points, availability, IAPs, auto-renewable subscriptions,
  subscription groups, subscription localizations, or IAP localizations.
- The task involves catalog drift between App Store Connect and RevenueCat,
  product ID mapping, RevenueCat products, entitlements, offerings, packages,
  or package identifiers.
- The user supplies App Store Connect exports, `asc` output, RevenueCat MCP
  output, local JSON manifests, pricing CSVs, localization spreadsheets, or
  product catalogs and wants an audit or operation plan.

## When Not To Use

- StoreKit code, server receipt validation, transaction handling, paywalls, or
  Swift implementation: use development skills outside this collection.
- Metadata copywriting or generic app listing localization: use
  `app-store-metadata`.
- ASO, keyword, conversion, PPO, CPP, or listing strategy: use
  `app-store-aso`.
- App Review readiness for a release: use `app-store-release-dryrun`.
- App Store Connect build, TestFlight, beta feedback, or submission state:
  use `app-store-connect`.
- Business pricing strategy, revenue modeling, taxes, finance, paid acquisition, organic search,
  Google Play, Android stores, or broad growth marketing.

## Inputs To Inspect

- App name, bundle ID, platform, App Store Connect app ID, team, account, and
  selected backend.
- Product catalog: product IDs, reference names, product types, subscription
  groups, durations, territories, current prices, price schedules, and
  availability.
- Localization data: locale, display name, description, subscription group
  display name, and existing localization state.
- RevenueCat data: project ID, app ID or bundle ID, store identifier, product
  type, entitlements, offerings, packages, and product attachments.
- Requested mode: read-only audit, dry-run plan, manifest validation, or
  confirmed live operation.

## Workflow

1. Classify the request as read-only audit, dry-run planning, or confirmed
   live operation. Stop before any live pricing, availability, catalog,
   localization, entitlement, offering, or package mutation unless the user
   explicitly confirms the exact operation.
2. Load only the relevant references:
   - Apple and RevenueCat authority: `references/official-commerce-sources.md`.
   - Pricing and availability:
     `references/pricing-and-availability.md`.
   - IAP, subscription, and group localizations:
     `references/iap-subscription-localization.md`.
   - RevenueCat reconciliation:
     `references/revenuecat-catalog-reconciliation.md`.
   - Confirmation gates and mutation safety:
     `references/live-operation-safety.md`.
   - Local manifest shape:
     `references/commerce-manifest.md`.
3. For local App Store Connect and RevenueCat JSON exports, run
   `scripts/catalog_drift.py` before recommending catalog writes.
4. Resolve stable identifiers before planning changes. Product IDs and
   RevenueCat store identifiers are the primary join keys; display names are
   never unique identifiers.
5. Produce a report or plan that separates Apple requirements, current-state
   facts, third-party backend notes, advisory recommendations, and actions
   requiring explicit confirmation.

## Script Usage

Run the local drift audit when both App Store Connect and RevenueCat catalog
exports or manifests are available:

```bash
python3 skills/app-store-commerce/scripts/catalog_drift.py \
  --asc ./asc-catalog.json \
  --revenuecat ./revenuecat-catalog.json
```

Use `--json` for machine-readable output. The script is read-only and only
compares local files.

## Safety / Confirmation Rules

- Read-only list/export/status operations may proceed after scope is clear.
- Live operations require explicit confirmation naming the app, account/team,
  backend, product IDs, operation, territories, prices, dates, RevenueCat
  project/app when relevant, and verification plan.
- Never change prices, availability, IAPs, subscription groups, subscription
  products, product localizations, RevenueCat products, entitlements,
  offerings, packages, or attachments as an implied step.
- Never delete App Store Connect or RevenueCat commerce resources through this
  skill. If deletion is requested, pause and require a separate explicit plan.
- Do not store API keys, private keys, issuer IDs, cookies, or RevenueCat
  tokens in the skill directory or generated output.

## Decision Rules

- Official Apple documentation and live App Store Connect state override
  community skill examples and remembered limits.
- Treat `asc` as an optional backend, not official authority. Verify current
  command help before using exact flags.
- Product IDs should be stable once live. Do not rename or reuse product IDs
  as a cleanup tactic.
- List current localizations before create/update plans. Create only missing
  localizations unless the user asked to update existing values.
- For RevenueCat, match App Store Connect `productId` to RevenueCat
  `store_identifier`. Avoid display-name matching.
- Consumable products normally should not receive durable entitlements unless
  the user explicitly defines that policy.
- Pricing recommendations are operational unless backed by user-supplied
  business data. Do not invent price strategy or revenue forecasts.

## Validation Rules

- Confirm product IDs, product types, subscription groups, duration/package
  mapping, territories, start dates, and end dates before mutation planning.
- Verify all locale codes against current App Store Connect behavior before
  bulk localization operations.
- For price CSVs, validate required columns, duplicate territories, date
  format, price-point availability, and preservation flags before dry run.
- For RevenueCat, verify project, app platform, products, entitlements,
  offerings, packages, and product attachments after any confirmed apply.
- Compare before/after exports after a live operation and report residual
  drift or propagation caveats.

## Output Format

Use one of these shapes:

- **Commerce audit**: source, timestamp, app, product count, current risks,
  drift findings, missing evidence, next safe action.
- **Pricing plan**: app/product IDs, territories, current prices, target
  prices, effective dates, preservation behavior, backend, dry-run command or
  checklist, confirmation needed.
- **Localization plan**: product/group IDs, locale matrix, create/update/skip
  counts, field lengths, conflicts, per-locale failures.
- **RevenueCat reconciliation**: ASC products, RevenueCat products,
  entitlement policy, offerings/packages, drift table, apply steps requiring
  confirmation, verification plan.

## Failure / Uncertainty Handling

- If official docs, backend flags, or account state may have changed, verify
  current source or backend help before giving exact mutation commands.
- If IDs are ambiguous, present candidates and stop instead of selecting one.
- If RevenueCat and App Store Connect disagree, report drift first and do not
  apply a fix until the source of truth is named.
- If the task drifts into engineering implementation or business strategy,
  state the boundary and keep only App Store commerce operations findings.
