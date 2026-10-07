# Search Readiness

Use this reference for indexing, crawlability, launch checks, and technical
search preflight.

## Crawl / Index Basics

Check:

- page returns an indexable status code
- page is not unintentionally blocked by robots.txt
- page does not have accidental `noindex`
- canonical points to the intended URL
- important content is visible in rendered HTML
- page is linked from crawlable pages
- sitemap includes canonical URLs that should be discovered
- redirects are intentional and avoid chains
- mobile rendering exposes the same primary content
- duplicate or parameter URLs have a clear canonical plan

## Launch Preflight

- Verify staging noindex or robots blocks are removed from production only
  when intended.
- Check sitemap freshness and submitted URL set.
- Confirm canonical, hreflang, and redirect rules match the live domain.
- Confirm analytics and Search Console properties are ready before launch.
- Record launch date so performance changes can be interpreted later.

## Robots And Removal Caution

- Robots.txt controls crawling. It is not a universal removal tool.
- Use `noindex`, removal tools, authentication, or deletion according to the
  actual goal.
- Do not block a page from crawling if Google needs to see a `noindex` tag on
  that page.

## Common Findings

- Canonical points to a staging, old, parameterized, or unrelated URL.
- Internal links point to redirected or non-canonical URLs.
- Page title and main heading do not match the page purpose.
- Important content is only loaded after user interaction.
- Sitemap includes URLs that are blocked, redirected, or non-canonical.
