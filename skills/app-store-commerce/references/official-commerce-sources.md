# Official Commerce Sources

Last verified: 2026-04-30.

## Source Hierarchy

1. Current App Store Connect state and official Apple documentation.
2. Official App Store Connect API documentation and backend help for the
   selected tool.
3. RevenueCat official documentation for RevenueCat-only concepts.
4. Community skills, CLI examples, blog posts, and remembered behavior.

Community sources can shape workflow and examples, but they are not authority
for current Apple rules, price behavior, locale availability, review
requirements, or API support.

## Apple References

- App Store Connect Help: [Overview for configuring in-app
  purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/overview-for-configuring-in-app-purchases/).
- App Store Connect Help: [Create an in-app
  purchase](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/).
- App Store Connect Help: [Set a price for an in-app
  purchase](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase/).
- App Store Connect Help: [Overview of auto-renewable
  subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/overview-of-auto-renewable-subscriptions/).
- App Store Connect Help: [Manage pricing for auto-renewable
  subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/).
- App Store Connect Help reference: [In-app purchase and subscriptions pricing
  and availability](https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/in-app-purchase-and-subscriptions-pricing-and-availability/).
- App Store Connect Help reference: [App Store
  localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/).
- App Store Connect API: use Apple's current API documentation for resource
  and endpoint support before using exact mutation commands.

## RevenueCat References

- RevenueCat docs: [Configuring
  products](https://www.revenuecat.com/docs/projects/configuring-products).
- RevenueCat docs: [Entitlements](https://www.revenuecat.com/docs/getting-started/entitlements/ios-products).
- RevenueCat docs: [Offerings](https://www.revenuecat.com/docs/getting-started/displaying-products).
- RevenueCat docs: [MCP](https://www.revenuecat.com/docs/tools/mcp).
- RevenueCat docs: [MCP setup](https://www.revenuecat.com/docs/tools/mcp/setup).
- RevenueCat docs: [MCP tools
  reference](https://www.revenuecat.com/docs/tools/mcp/tools-reference).
- RevenueCat docs: [MCP best practices and
  troubleshooting](https://www.revenuecat.com/docs/tools/mcp/best-practices-and-troubleshooting).

## Current-Source Notes

- Apple currently lists 50 App Store localizations. Upstream examples
  with shorter static locale lists are stale for live bulk operations.
- Apple documents IAP metadata, pricing, availability, and screenshot fields
  as review-facing App Store Connect data. Treat product metadata changes as
  review-sensitive unless the current App Store Connect flow proves otherwise.
- RevenueCat terminology is RevenueCat authority only. It does not define what
  Apple accepts in App Store Connect or App Review.
