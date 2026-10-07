# Metrics And Sources

Use this reference to normalize data before interpreting market performance.

## Source Hierarchy

- Current first-party platform exports: App Store Connect, Play Console,
  Search Console, Google Analytics, ad platform reports, or backend analytics.
- Local change logs: metadata edits, screenshot updates, campaign changes,
  release dates, pricing changes, SEO changes, outages, and promotions.
- Third-party tools: ranking trackers, keyword tools, market intelligence
  platforms, or attribution tools. Useful as evidence, not authority.
- Anecdotes: support tickets, reviews, sales notes, or user feedback. Useful
  for hypotheses, not metric conclusions.

## Metric Hygiene

Record:

- source system and export date
- timezone
- date range
- country, locale, device, and channel filters
- attribution window
- metric definition used by the source
- known data delays or sampling
- included or excluded traffic sources

## Common Metric Families

- Visibility: impressions, search appearances, ranking, share of voice.
- Engagement: clicks, CTR, product page views, landing page sessions.
- Acquisition: installs, signups, trials, purchases, leads.
- Efficiency: CPC, CPT, CPA, CPI, CAC, ROAS, payback inputs.
- Quality: retention, activation, refund rate, review quality, support load.
- Guardrails: spend caps, complaint rate, policy flags, unsubscribe rate,
  bounce rate, crash rate, app review risk.

## Data Quality Checks

- Does the date range include enough pre-change and post-change data?
- Did tracking, attribution, consent, or analytics implementation change?
- Are paid and organic sources separated?
- Are countries, locales, and devices mixed?
- Did seasonality, press, outages, pricing, or product releases overlap?
- Are absolute counts large enough to support a conclusion?

## Interpretation Rules

- Use source-native metric names in the report, then define them plainly.
- Prefer trends and segment comparisons over one aggregate number.
- Treat ranking as a visibility signal, not an outcome.
- Treat conversion rate as channel- and intent-specific.
- When sources disagree, describe the difference instead of forcing a single
  number.
