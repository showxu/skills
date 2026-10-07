# Official Apple Sources

Checked against Apple documentation on 2026-04-30. Use these sources before
treating App Store metadata limits, product-page surfaces, or review behavior
as authoritative.

## Source Hierarchy

1. Live App Store Connect state for the app, locale, version, CPP, PPO test, or
   in-app event.
2. Apple App Store Connect Help and Apple Developer App Store pages.
3. App Store Connect Analytics definitions and reports.
4. User-supplied ranking, keyword, competitor, or conversion data.
5. Community ASO examples and upstream skill content, only as advisory input.

## Core Sources

- Creating your product page:
  https://developer.apple.com/app-store/product-page/
- App information:
  https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Platform version information:
  https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Required, localizable, and editable properties:
  https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties
- Screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Custom Product Pages:
  https://developer.apple.com/app-store/custom-product-pages/
- Configure custom product pages:
  https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions
- Product Page Optimization:
  https://developer.apple.com/app-store/product-page-optimization/
- Product Page Optimization analytics:
  https://developer.apple.com/help/app-store-connect-analytics/acquisition/product-page-optimization
- In-App Events:
  https://developer.apple.com/app-store/in-app-events/
- Offer In-App Events:
  https://developer.apple.com/help/app-store-connect/offer-in-app-events/offer-in-app-events/

## Stable Apple Facts

- App name is 2-30 characters.
- Subtitle is up to 30 characters.
- Promotional text is up to 170 characters and can be updated without a new
  app version.
- Description is up to 4000 characters, plain text, required, and localizable.
- Keywords are up to 100 bytes, required, localizable, comma-separated, and
  should not duplicate app name or company name.
- Apple says promotional text does not affect App Store search ranking.
- App previews can be up to three per product page localization.
- Custom Product Pages can vary screenshots, promotional text, app previews,
  and assigned keywords; they must be approved before they are visible.
- Product Page Optimization can test up to three alternate product-page
  versions against the original.
- In-App Events can appear on the product page and in search results; event
  metadata has its own Apple limits and review rules.
