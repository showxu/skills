# RevenueCat Catalog Reconciliation

## Scope

Use this reference when App Store Connect and RevenueCat commerce catalogs must
be compared or synchronized:

- App Store Connect subscriptions and IAPs.
- RevenueCat products.
- RevenueCat entitlements and product attachments.
- RevenueCat offerings and packages.
- Drift audits, deterministic apply plans, and post-apply verification.

RevenueCat is a third-party commerce backend. Its docs govern RevenueCat
configuration, not Apple App Store Connect rules.

## Canonical Identifiers

- App Store Connect `productId` should match RevenueCat `store_identifier`.
- Product IDs should be stable once live.
- Display names, reference names, and localized names are not unique keys.
- Confirm the RevenueCat project and app platform before comparing products.

## Product Type Mapping

Use this mapping for audit reports:

| App Store Connect | RevenueCat |
| --- | --- |
| Auto-renewable subscription | `subscription` |
| Consumable IAP | `consumable` |
| Non-consumable IAP | `non_consumable` |
| Non-renewing subscription | `non_renewing_subscription` |

## Entitlement Policy

Default policy unless the user supplies a product model:

- Auto-renewable subscriptions: one entitlement per subscription group or the
  explicit entitlement map supplied by the user.
- Non-consumable IAPs: one entitlement per durable unlock product.
- Consumables: no durable entitlement by default.
- Non-renewing subscriptions: entitlement policy depends on product duration
  and backend access model; require explicit user intent.

## Package Keys

Use RevenueCat reserved package identifiers when the package duration maps
cleanly:

| Product duration | Package key |
| --- | --- |
| One week | `$rc_weekly` |
| One month | `$rc_monthly` |
| Two months | `$rc_two_month` |
| Three months | `$rc_three_month` |
| Six months | `$rc_six_month` |
| One year | `$rc_annual` |
| Lifetime non-consumable | `$rc_lifetime` |
| Other | `$rc_custom_<name>` |

## Audit Mode

Read-only audit is the default:

1. Read App Store Connect products and subscription groups.
2. Read RevenueCat project, app, products, entitlements, offerings, packages,
   and attachments.
3. Normalize identifiers and product types.
4. Report:
   - products missing in App Store Connect
   - products missing in RevenueCat
   - product type mismatches
   - entitlement policy mismatches
   - offering/package gaps
   - ambiguous app/project/platform matches
5. Stop after the report unless the user confirms an apply plan.

When local exports are available, run:

```bash
python3 skills/app-store-commerce/scripts/catalog_drift.py \
  --asc ./asc-catalog.json \
  --revenuecat ./revenuecat-catalog.json
```

## Apply Mode

Apply mode is confirmation-gated and never implicit:

1. Present the audit diff and source of truth.
2. Ask for explicit confirmation naming project, app, product IDs, target
   entitlements, offerings, packages, and backend.
3. Create missing RevenueCat app/products only when confirmed.
4. Create entitlements only when the entitlement policy is confirmed.
5. Attach products to entitlements only after products exist and product type
   is verified.
6. Create or update offerings and packages only after product attachment is
   verified.
7. Read back all touched resources and report created, updated, skipped, and
   failed items.

Never delete RevenueCat or App Store Connect resources as part of reconciliation
unless the user starts a separate deletion review.

## MCP Notes

RevenueCat MCP can be used when configured and authorized. Inspect the current
available tools before relying on exact names. Upstream examples used tool
families equivalent to:

- get/list project and apps
- list/create products
- list/create entitlements
- attach products to entitlements
- list/create offerings
- list/create packages

Use read-only API keys for audits when possible. Use write-enabled credentials
only after explicit confirmation.

## Output Shape

```text
RevenueCat Reconciliation

Mode: audit / confirmed apply
ASC source: ...
RevenueCat source: ...

ASC products:
- product_id / type / group / duration

RevenueCat products:
- store_identifier / type / entitlements / packages

Drift:
- missing_in_revenuecat: ...
- missing_in_app_store_connect: ...
- type_mismatch: ...
- entitlement_policy: ...
- offering_package_gap: ...

Requires confirmation:
- ...

Verification:
- ...
```
