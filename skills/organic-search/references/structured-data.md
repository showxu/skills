# Structured Data

Use this reference when a page includes schema markup or aims for rich result
eligibility.

## Review Rules

- Structured data must represent visible, accurate page content.
- Use a type that matches the page's real primary content.
- Include required and recommended properties only when the values are true.
- Avoid marking up hidden, misleading, expired, fake, or irrelevant content.
- Validate syntax and eligibility with current official tools when available.
- Check whether the rich result type is still supported for Google Search.

## Common Operations

- Identify existing JSON-LD, Microdata, or RDFa.
- Compare markup to visible page content.
- Check required and recommended fields for the selected feature.
- Validate with Rich Results Test or Schema Markup Validator when appropriate.
- Record warnings separately from blockers.

## Output Shape

```text
Structured Data Review

Page:
Detected types:
Goal:
Syntax issues:
Content mismatch:
Missing required fields:
Recommended improvements:
Official validation needed:
```

## Boundaries

This reference does not implement schema in code by default. If implementation
is requested, edit the target site according to its framework and verify the
rendered output.
