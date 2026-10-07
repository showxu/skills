# Channel Performance

Use this reference when producing a performance readout for a specific market
channel.

## Store Listing

Inspect:

- impressions or product page views
- conversion rate to install or acquisition
- country and locale split
- source type if available
- metadata and screenshot change dates
- ratings, reviews, crashes, and release timing as context

Route optimization work to `app-store-aso`, `app-store-metadata`,
`app-store-screenshots`, or `google-play-store-assets` when the report turns
into asset or listing changes.

## Organic Search

Inspect:

- queries, pages, countries, devices, search appearance, impressions, clicks,
  CTR, and average position
- indexing or crawl issues that might explain visibility changes
- title, snippet, content, structured data, internal link, or canonical
  changes

Route readiness and implementation checks to `organic-search`.

## Paid Acquisition

Inspect:

- spend, impressions, clicks, CPC/CPT, conversions, CPA/CPI, ROAS inputs,
  campaign objective, conversion source, and date range
- budget or bid changes
- creative, landing page, and tracking changes
- platform policy or delivery warnings

Route campaign setup, budget safety, policy preflight, or live edits to
`paid-acquisition`.

## Landing Page / Launch Surface

Inspect:

- sessions, source/medium, CTR, conversion events, bounce or engagement, and
  downstream conversion
- copy, CTA, page speed, device split, form or checkout failures, and launch
  timing

Route messaging changes to `market-messaging` and SEO readiness to
`organic-search`.

## Report Rule

Every channel report should end with:

- one evidence-backed observation
- one uncertainty or competing explanation
- one next measurement action
