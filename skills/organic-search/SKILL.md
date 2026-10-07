---
name: organic-search
description: Audit or prepare organic search operations for websites and landing pages, including SEO readiness, indexing visibility, Search Console evidence, title links, meta descriptions, crawlability, sitemaps, robots directives, canonical signals, structured data, internal links, query/page performance, and SERP presentation. Use for organic search channel reviews and search visibility preflight. Do not use for paid search ads, App Store ASO, Google Play assets, broad content strategy, live CMS changes without confirmation, or guaranteed ranking claims.
---

# Organic Search

## Purpose

Review and prepare web pages for organic search visibility using official
source hierarchy, crawl/index/readability checks, Search Console evidence, and
SERP presentation review.

This skill covers organic search operations, not paid search, App Store ASO,
Google Play listing work, or broad content strategy.

## When To Use

- The user asks for SEO, organic search, indexing, Search Console review,
  search visibility, sitemap, robots.txt, canonical, title/meta, structured
  data, internal link, query/page performance, or SERP snippet review.
- The task involves a website, landing page, documentation page, blog, launch
  page, product page, or help content intended to be found through web search.
- The user supplies URLs, HTML, Search Console exports, sitemap files,
  analytics, page copy, or search result screenshots.

## When Not To Use

- Paid search, Google Ads, Apple Ads, Meta ads, campaign setup, budgets, or
  conversion tracking: use `paid-acquisition`.
- App Store keyword optimization, PPO/CPP, App Analytics, or App Store listing
  optimization: use `app-store-aso`.
- Google Play screenshots, feature graphics, or store listing visual assets:
  use `google-play-store-assets`.
- Market message drafting without search-specific evidence: use
  `market-messaging`.
- Broad content strategy, editorial calendars, brand strategy, or guaranteed
  ranking promises.

## Inputs To Inspect

- Target URLs, page purpose, audience, query intent, market, language, and
  business goal.
- Current HTML or CMS fields: title, meta description, headings, canonical,
  robots meta, internal links, structured data, images, alt text, and content.
- Technical files and signals: sitemap, robots.txt, redirects, status codes,
  hreflang, mobile rendering, and duplicate URLs.
- Search evidence: Search Console performance, indexing reports, URL
  inspection, query/page data, search appearance, countries, devices, and
  date ranges.
- Requested mode: readiness audit, issue triage, snippet rewrite, structured
  data review, Search Console report, or launch preflight.

## Workflow

1. Classify the task: search readiness, crawl/index issue, SERP presentation,
   structured data, content/query fit, Search Console performance, or launch
   preflight.
2. Read `references/official-search-sources.md` when exact Google Search
   behavior, eligibility, or policies matter.
3. Read `references/search-readiness.md` for crawlability, indexing, sitemap,
   robots, canonical, mobile, and duplicate URL checks.
4. Read `references/serp-presentation.md` for title links, meta
   descriptions, snippets, and page copy alignment.
5. Read `references/structured-data.md` when the page has schema markup or a
   rich result goal.
6. Read `references/search-console-performance.md` when using Search Console
   data or comparing query/page performance.
7. Produce findings by severity and confidence. Separate official
   requirements, implementation issues, content-fit recommendations, and
   measurement next steps.

## Reference Files To Consult

- `references/official-search-sources.md`: current official Google Search
  source hierarchy and source links.
- `references/search-readiness.md`: crawl, index, sitemap, robots, canonical,
  mobile, URL, and launch checks.
- `references/serp-presentation.md`: title links, meta descriptions, snippets,
  headings, and visible content alignment.
- `references/structured-data.md`: schema markup review and rich result
  eligibility checks.
- `references/search-console-performance.md`: Search Console metrics,
  dimensions, comparisons, and interpretation caveats.

## Safety / Authority Rules

- Google Search Central and Search Console documentation override SEO blogs,
  third-party tools, and remembered ranking advice.
- Do not guarantee rankings, indexing, traffic, featured snippets, rich
  results, or exact timelines.
- Do not recommend cloaking, keyword stuffing, link schemes, hidden text,
  misleading structured data, doorway pages, scraped content, or other spammy
  tactics.
- Do not change live CMS, DNS, robots, sitemap, redirects, analytics, or
  Search Console settings without explicit confirmation.
- For legal, medical, financial, or safety content, mark expertise and claim
  evidence risks rather than approving compliance.

## Decision Rules

- Start with eligibility and crawl/index basics before polishing snippets.
- Search work should help users and search engines understand the same page;
  do not create separate copy for bots.
- Match page content to query intent before optimizing titles or descriptions.
- Structured data must describe visible, accurate page content.
- Robots.txt manages crawling, not all indexing cases. Use the right blocking
  or removal method for the goal.
- Use Search Console trends as evidence, not as a full market model.

## Output Format

```text
Organic Search Review

Scope:
- URL(s):
- Goal:
- Evidence:

Blocking issues:
- ...

Search readiness issues:
- ...

SERP presentation recommendations:
- ...

Structured data / technical notes:
- ...

Measurement next step:
- ...
```

For snippet rewrites, include current title/description, proposed version,
page intent, query fit, and risk notes.

## Failure / Uncertainty Handling

- If live pages are inaccessible, review supplied HTML or fields and list what
  must be checked in a browser or crawler.
- If Search Console data is missing, provide a readiness audit and request the
  exact report export needed for performance interpretation.
- If a claim depends on current Google behavior, verify official docs before
  treating it as a rule.
