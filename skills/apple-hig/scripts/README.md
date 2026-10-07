# Scripts

- `extract_hig_metrics.py`: fetch Apple HIG JSON pages and extract numeric
  tables, system color tables, and numeric guidance snippets into a Markdown
  metrics snapshot. Color values come from swatch image alt text and print as
  hex plus RGB; linked API names print as their titles.
  Use it to refresh `references/swiftui-hig-metrics.md` evidence before making
  exact numeric or color claims.
- `test_extract_hig_metrics.py`: run the offline fixture test for the extractor.
  It does not call the network.
- `fixtures/hig_metrics_fixture.json`: reduced HIG-shaped JSON used by the
  offline test.
