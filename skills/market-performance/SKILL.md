---
name: market-performance
description: Build, review, or interpret market performance evidence across store listings, organic search, paid acquisition, launch campaigns, rankings, impressions, clicks, conversions, experiment logs, and before/after reports. Use for metric definitions, baselines, channel performance summaries, ranking tracker output, A/B or PPO result review, and evidence-backed recommendations. Do not use for broad growth strategy, SEO implementation audits, paid campaign setup, live account changes, financial forecasting, or unsupported algorithm and conversion claims.
---

# Market Performance

## Purpose

Organize market performance evidence so recommendations are grounded in
observable data, clear metric definitions, and stated confidence.

This skill does not promise growth or infer secret platform algorithms. It
turns available evidence into baselines, experiment records, channel reports,
and safe next actions.

## When To Use

- The user asks for market performance review, baseline setup, KPI definition,
  ranking tracker interpretation, conversion review, experiment logging,
  before/after comparison, or channel performance summary.
- The task uses App Analytics, Play Console, Search Console, Google Analytics,
  ad reports, ranking trackers, store metadata versions, campaign dates, or
  launch notes as evidence.
- The user wants to know whether a change appears to have helped, what data is
  missing, or how to structure the next measurement cycle.

## When Not To Use

- Broad growth strategy, business planning, market sizing, revenue forecasting,
  or pricing strategy.
- App Store keyword and listing optimization without supplied performance
  data: use `app-store-aso`.
- Organic search readiness, indexing, structured data, or SEO page audits:
  use `organic-search`.
- Paid campaign setup, budget safety, tracking setup, or policy preflight:
  use `paid-acquisition`.
- Copywriting, positioning, launch messaging, or screenshot copy:
  use `market-messaging`.
- Live account edits, campaign changes, listing changes, or privacy/legal
  declarations.

## Inputs To Inspect

- Channel and surface: App Store, Google Play, web organic search, paid ads,
  landing page, email, launch, social, or mixed.
- Data source, export date, timezone, attribution window, date range, segment,
  and filters.
- Metrics: impressions, clicks, CTR, page views, product page views, installs,
  conversion rate, spend, CPC, CPT, CPA, ROAS, retention, ranking, query,
  keyword, country, device, or cohort.
- Change log: metadata edits, screenshots, pricing, launch, campaign changes,
  SEO changes, product releases, seasonality, outages, promotions, or policy
  events.
- Requested mode: metric dictionary, baseline, experiment log, performance
  readout, anomaly triage, or next-measurement plan.

## Workflow

1. Classify the evidence task: baseline, metric dictionary, experiment review,
   channel report, ranking readout, anomaly check, or decision memo.
2. Read `references/metrics-and-sources.md` to normalize metric meanings and
   source reliability.
3. For controlled or semi-controlled changes, read
   `references/experiments-and-comparisons.md`.
4. For channel reports, read `references/channel-performance.md`.
5. For unsupported ranking, algorithm, or conversion claims, read
   `references/advisory-claims.md` before making recommendations.
6. Separate observations, likely explanations, competing explanations,
   missing data, and next safe actions.

## Reference Files To Consult

- `references/metrics-and-sources.md`: metric definitions, source hierarchy,
  date range hygiene, attribution caveats, and data quality checks.
- `references/experiments-and-comparisons.md`: baselines, change logs,
  before/after comparisons, experiment records, and confidence levels.
- `references/channel-performance.md`: store, search, paid, landing page, and
  launch performance readout shapes.
- `references/advisory-claims.md`: unstable ranking, algorithm, uplift, and
  causation claims.

## Safety / Authority Rules

- Do not claim causation from a simple before/after comparison unless the
  evidence supports it.
- Do not mix paid and organic traffic, countries, devices, or attribution
  windows without labeling the mix.
- Do not create or change campaigns, budgets, listings, pricing, tracking, or
  public assets without explicit confirmation and the relevant channel skill.
- Treat third-party benchmark numbers, algorithm claims, and "best practice"
  multipliers as advisory unless the user supplies reliable current evidence.
- Preserve privacy: do not request or expose personal data when aggregate
  metrics are sufficient.

## Decision Rules

- Define the metric before interpreting it.
- Compare like with like: same channel, same country, same device class, same
  time window, same attribution logic, and similar seasonality when possible.
- Keep a change log next to every performance readout.
- Separate leading indicators from outcomes. Impressions, rankings, and CTR
  are not installs or revenue.
- Prefer confidence labels over false precision: observed, likely,
  directional, inconclusive, or unsupported.

## Output Format

Use this shape for reports:

```text
Market Performance Readout

Scope:
- Channel:
- Date range:
- Segments:
- Source:

Metric definitions:
- ...

Observed changes:
- ...

Likely explanations:
- ...

Competing explanations:
- ...

Confidence:
- ...

Next measurement action:
- ...
```

For experiment logs, include hypothesis, change, start/end dates, affected
surfaces, guardrail metrics, result, confidence, and follow-up.

## Failure / Uncertainty Handling

- If data is missing, state the exact export or metric needed.
- If the date range is too short, mark the result as preliminary.
- If multiple changes overlap, avoid single-cause conclusions and propose a
  cleaner measurement design.
- If the user asks for growth strategy, convert the request into measurement
  artifacts: baseline, experiment log, channel readout, or next evidence plan.
