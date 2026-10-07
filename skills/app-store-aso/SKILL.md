---
name: app-store-aso
description: Review and improve Apple App Store listing optimization strategy using keyword evidence, field utilization, localization coverage, creative conversion signals, Custom Product Pages, Product Page Optimization tests, in-app events, competitor data supplied by the user, and App Analytics evidence. Use for ASO audits, keyword hygiene, keyword gap review, listing conversion review, and advisory optimization plans. Do not use for broad growth marketing, paid acquisition, organic search, Google Play, Android stores, live App Store Connect mutations, pricing/catalog changes, release submission, screenshot asset production, metadata copywriting-only tasks, ordinary field validation, or unverified ranking algorithm claims.
---

# App Store ASO

## Purpose

Audit and improve an Apple App Store listing for discoverability and
conversion while separating Apple requirements from advisory ASO hypotheses.

This skill covers App Store listing optimization. It does not run ads, manage
pricing, change live App Store Connect state, submit review items, produce
screenshot assets, or claim secret ranking rules as fact.

## When To Use

- The user asks for App Store Optimization, ASO, keyword review, keyword gaps,
  listing optimization, product page conversion review, or competitor keyword
  comparison.
- The task involves App Store metadata utilization, keyword hygiene,
  localization coverage, screenshots or app previews as listing strategy,
  Custom Product Pages, Product Page Optimization tests, in-app events, or App
  Analytics evidence.
- The user supplies local metadata files, pulled App Store Connect metadata,
  ranking tracker output, competitor keyword data, product page screenshots,
  or analytics exports and wants an optimization report.

## When Not To Use

- Metadata copywriting-only, field limit validation, or local sync planning:
  use `app-store-metadata`.
- Screenshot design, asset generation, validation, or localization production:
  use `app-store-screenshots`.
- What's New drafting: use `app-store-whats-new`.
- App Review readiness or release-path dry runs: use
  `app-store-release-dryrun`.
- App Store Connect state lookup, TestFlight, review submissions, or live
  operation planning: use `app-store-connect`.
- Pricing, IAP/subscription catalog operations, or RevenueCat reconciliation:
  use `app-store-commerce`.
- Broad growth marketing, paid acquisition, brand campaign planning, organic search,
  Google Play, Android store listing work, or non-App-Store marketing.

## Inputs To Inspect

- App purpose, category, target audience, primary markets, current locale
  matrix, and strongest user-visible value proposition.
- Current metadata: name, subtitle, keywords, description, promotional text,
  What's New, categories, and app info/version-localization files.
- Current screenshots, app previews, app icon, Custom Product Pages, Product
  Page Optimization tests, in-app events, or product page screenshots.
- Evidence: App Analytics, search rankings, keyword popularity, competitor
  keywords, conversion rates, PPO results, CPP metrics, ratings/reviews, or
  storefront-specific findings.
- User's requested mode: audit, generation, validation, localization review,
  competitor gap review, or measurement plan.

## Workflow

1. Classify the task shape: metadata audit, keyword optimization, creative
   strategy, localization review, competitor gap review, PPO/CPP plan, or
   measurement report.
2. Load only the relevant references:
   - Apple authority: `references/official-apple-sources.md`.
   - Metadata and keyword rules: `references/metadata-keywords.md`.
   - Screenshots, previews, PPO, CPP, and in-app events:
     `references/listing-creative.md`.
   - Localization and market coverage:
     `references/localization-and-markets.md`.
   - Analytics, tests, and optional external tools:
     `references/measurement-and-tools.md`.
   - Unverified or unstable claims:
     `references/advisory-claims.md`.
3. If local metadata exists, run `scripts/audit_metadata.py` for ASO-specific
   offline checks. Use `app-store-metadata/scripts/validate_metadata.py` for
   pure field-limit validation.
4. Separate findings into:
   - Apple requirement or App Review risk.
   - Local deterministic audit finding.
   - Evidence-backed recommendation from supplied data.
   - Advisory hypothesis that needs tracking or testing.
5. Recommend the smallest safe changes first: fix errors, remove keyword
   waste, improve field utilization, localize high-priority locales, then
   propose creative or testing experiments.
6. Do not invent ranking data. If competitor, popularity, or conversion data is
   missing, provide the exact evidence needed and mark recommendations as
   hypotheses.

## Script Usage

Run the offline ASO audit when canonical metadata files are available:

```bash
python3 skills/app-store-aso/scripts/audit_metadata.py \
  --metadata-dir ./metadata \
  --primary-locale en-US
```

The script expects the common local shape:

```text
metadata/app-info/<locale>.json
metadata/version/<version>/<locale>.json
```

It checks keyword waste, field utilization, missing fields, keyword separator
issues, cross-locale keyword duplication, and description keyword coverage.

## Safety / Authority Rules

- Apple official docs and live App Store Connect state override community
  skills, ASO blog posts, and remembered limits.
- Do not present App Store ranking algorithms, screenshot OCR indexing,
  conversion multipliers, or update-frequency claims as Apple rules unless the
  user supplies current reliable evidence.
- Do not recommend competitor names, trademarks, celebrity names, offensive
  terms, irrelevant terms, or misleading claims in keywords.
- Do not upload metadata, change CPP/PPO/in-app-event state, publish assets,
  change pricing, or submit anything for review.
- Treat external tools such as Astro, Krankie, AppTweak, Sensor Tower, or App
  Radar as optional evidence sources, not dependencies or authorities.

## Decision Rules

- Prefer precise, relevant keywords over generic high-volume terms.
- Do not duplicate app name, company name, title/subtitle words, or irrelevant
  category terms in the keyword field.
- Keywords are byte-limited; verify byte count for non-ASCII locales.
- Promotional text is for conversion and timely messaging, not App Store
  search ranking.
- Description should sell the app clearly and accurately; do not stuff it with
  keywords.
- Localize keyword strategy per market. Identical keyword fields across
  locales are usually a warning, not proof of failure.
- Creative recommendations should connect metadata intent to screenshots,
  previews, CPPs, and PPO tests; route asset creation to screenshot skills.

## Output Format

Use this shape for audits:

```text
ASO Audit

Evidence level: official docs / local files / supplied analytics / advisory

Apple requirements or risks:
- ...

Deterministic audit findings:
- ...

Optimization recommendations:
- ...

Advisory hypotheses to test:
- ...

Next safe action:
- ...
```

For metadata generation, include field lengths, keyword byte counts, and
whether each recommendation is requirement-backed, evidence-backed, or
advisory.

## Failure / Uncertainty Handling

- If App Store Connect state is unknown, label edits as listing strategy, not
  editability guidance.
- If metadata files do not match the expected shape, report the missing files
  and use any explicit fields the user provided.
- If supplied ranking or analytics data is stale, say so and treat conclusions
  as directional.
- If the request drifts into ads, pricing, catalog operations, or broad growth
  marketing, state the boundary and keep only App Store listing findings.
