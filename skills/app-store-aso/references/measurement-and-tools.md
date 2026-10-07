# Measurement And Tools

Use this reference when the user supplies ranking, analytics, competitor, PPO,
CPP, or external ASO tool output.

## Evidence Sources

- App Analytics: impressions, product page views, downloads, conversion rate,
  retention-related downstream metrics where available.
- Product Page Optimization: treatment conversion rate, confidence, and
  whether Apple marks a treatment better, worse, or inconclusive.
- Custom Product Pages: page-specific impressions, downloads, conversion rate,
  and downstream value metrics.
- In-App Events: event impressions, event page views, downloads, app opens,
  reminders, subscriptions, and sales where applicable.
- Ranking trackers and ASO tools: keyword position, popularity, competitors,
  gap lists, trend history, and storefront.

## Optional External Tools

Upstream skills mention Astro MCP and Krankie. Locally, treat them as optional
evidence sources:

- Astro-style tools can provide competitor keyword extraction, keyword
  suggestions, popularity, and current ranking data. Upstream command intent
  maps to: get current tracked keywords, add per-store tracking, extract
  competitor keywords, get keyword suggestions, check rankings, then diff
  against local metadata.
- Krankie-style tools can track local keyword positions over time and export
  structured data. Upstream command intent maps to: search/add/list tracked
  apps, add/list tracked keywords, run checks, inspect current rankings,
  inspect movers, inspect rank history, check last-run status, and request JSON
  output for agent parsing.
- AppTweak, Sensor Tower, App Radar, Appfigures, and similar tools can provide
  external ASO evidence when the user supplies their output.

Do not make any external tool a dependency. If the data is absent, skip gap
analysis and state the exact data needed.

## External Tool Output To Ask For

For keyword gap work, ask for:

- app ID and storefront
- locale
- current keyword field
- tracked keyword positions with dates
- keyword popularity or volume score
- competitor app IDs or competitor keyword exports
- rank history or movers since the last metadata change

Keep install commands and account setup out of the skill unless the user asks
for that specific external tool.

## Reporting Rules

- Always include the storefront, locale, date, and source for ranking data.
- Separate current rank from search volume or popularity.
- Separate competitor gaps from recommended changes.
- Treat one measurement snapshot as directional, not proof.
- For changes, define a baseline and re-check window before claiming impact.

## Test Planning

Good ASO experiments have:

- one primary hypothesis
- one primary metric, usually conversion rate or keyword rank for a target
  storefront
- a fixed locale/storefront
- a baseline date
- a clear no-change comparison period or PPO control
- a rollback or hold decision if results are inconclusive

Avoid claiming causality from simultaneous metadata, screenshot, pricing,
traffic, and app-update changes.

## Ratings, Reviews, And Update Cadence

Ratings, reviews, review responses, and update timing can affect user trust and
conversion. Treat ranking impact claims as advisory unless backed by current
evidence.

- Use App Store review themes to identify product-page trust gaps.
- Coordinate What's New with `app-store-whats-new`.
- Do not prescribe code-level rating prompt implementation from this skill.
- Do not claim a fixed update frequency as an Apple ranking rule.
