# Pricing And Availability

## Scope

Use this reference for App Store commerce pricing and availability operations:

- IAP price points and price schedules.
- Auto-renewable subscription prices, territory prices, price changes, and
  price preservation choices.
- App Store territory availability for paid commerce products.
- Pricing dry runs and before/after verification.

Do not use it for business pricing strategy, revenue forecasting, taxes,
StoreKit implementation, or payment processing code.

## Required Inputs

- App Store Connect app ID, bundle ID, platform, and account/team.
- Product IDs and product type: consumable, non-consumable,
  non-renewing subscription, or auto-renewable subscription.
- Subscription group and duration for subscriptions.
- Current prices and target prices by territory.
- Base territory and currency assumptions.
- Effective date, end date when relevant, and preserve-current-price behavior.
- Backend: App Store Connect UI, official API tooling, `asc`, manual UI, or
  another App Store operations tool.

## Read-Only Inventory First

Before any price or availability plan:

1. Resolve app and product IDs.
2. Export current product catalog.
3. Export current pricing, schedules, and availability.
4. Identify existing future price schedules.
5. Record source, timestamp, backend, and account/team.

If the user only needs analysis, stop after a report. Do not continue into
mutation planning.

## Planning Rules

- Plan from stable product IDs, not display names.
- Prefer a single base territory only when the user names one.
- Keep a territory matrix with current price, target price, currency, start
  date, end date, and preservation behavior.
- Treat existing future price schedules as conflicts until reviewed.
- For subscriptions, call out whether existing subscribers keep their current
  price or receive a price change according to Apple's current flow.
- Price changes can have propagation delay. Verify after the selected backend
  reports success.
- Do not present PPP, equalization, or regional tiering as business advice
  unless the user supplies that strategy. As a skill rule, these are operation
  shapes only.

## Price CSV Shape

For spreadsheet-driven dry runs, prefer a normalized CSV or JSON manifest:

```text
product_id,territory,price,currency_code,start_date,end_date,preserve_current_price,price_point_id
com.example.pro.monthly,US,4.99,USD,2026-06-01,,false,
```

Validate before dry run:

- Required columns exist.
- Product ID is known in the current catalog.
- Territory appears once per product/effective date.
- Price can map to an available Apple price point for that territory.
- Dates are explicit ISO dates when scheduling matters.
- Preserve flags are explicit for subscription price increases.

## Optional Backend Command Shapes

If `asc` is the selected backend, verify current `--help` before use. Upstream
workflow examples used these command families:

- Subscription setup: create group, subscription, initial localization, price,
  and availability, then verify.
- Subscription pricing summary: list current prices and future schedules.
- Subscription price points and equalizations: inspect available territory
  price points before scheduling changes.
- Subscription CSV import: run dry run first, then apply only after explicit
  confirmation.
- Subscription one-off change: set a single territory price only after current
  state and effective date are confirmed.
- Subscription availability: list or edit product availability by territory.
- IAP setup: create IAP, localization, and initial price schedule, then verify.
- IAP pricing summary: list current IAP prices.
- IAP price points and schedules: inspect price points and create/view price
  schedules.

Keep command examples backend-local. Do not make `asc` a required dependency
or official authority.

## Verification Report

After any confirmed live pricing or availability operation, produce:

```text
Pricing Verification

Source: ...
App: ...
Products: ...
Before export: ...
After export: ...
Applied changes:
- product_id / territory / old / new / start_date / preserve_current_price

Unchanged or skipped:
- ...

Propagation caveats:
- ...

Residual risks:
- ...
```
