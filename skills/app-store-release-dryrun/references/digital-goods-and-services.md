# Digital Goods And Services

Use this reference when the app sells in-app purchases, subscriptions, digital
content, paid features, credits, or other digital goods.

This skill checks review readiness only. It does not design pricing, create
products, reconcile RevenueCat, edit catalogs, or decide business strategy.

## IAP / Subscription Readiness Checks

- Product or subscription exists in App Store Connect.
- Status is ready for the intended review path.
- Required product metadata is complete: reference name, product ID,
  localizations, display name, description, price, and availability where
  applicable.
- App Review screenshot is present for each IAP/subscription that requires it.
- Review notes explain how App Review can find, purchase, restore, or test the
  item.
- The app binary exposes the item clearly enough for review.
- Privacy policy URL exists when the app sells digital goods.
- If this is the first IAP/subscription or the first time adding a new type,
  check Apple's current requirement to include it with a new app version.

## First-Review Behavior

Apple's current App Store Connect help says first IAPs or subscriptions, or a
new product type, should be included with a new app version. After one or more
IAPs/subscriptions are approved for the app, later products can use their
separate review path when eligible.

For a first review, report both conditions:

- Product readiness: metadata, screenshot, pricing, availability, and review
  notes are complete.
- App-version inclusion: the item or subscription group is selected with the
  version when Apple requires it.

## Backend Notes

Upstream `asc` examples include validation commands for IAPs and
subscriptions, and web-session escape hatches for some first-review
subscription attachment paths. Locally, treat those as optional backend
guidance:

```bash
asc validate iap --app "APP_ID" --output table
asc validate subscriptions --app "APP_ID" --output table
```

If a backend reports `MISSING_METADATA`, read row-level diagnostics literally:
review screenshot, promotional image, pricing, availability, localization,
offer readiness, and app/build evidence can all be separate issues.

## Boundary

Pricing tiers, territory pricing, subscription group structure, product
catalog creation, and RevenueCat drift are commerce operations. Keep them as
preflight blockers or deferred notes here; do not implement catalog changes
from this skill.
