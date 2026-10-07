# Tracking And Attribution

Use this reference when reviewing paid acquisition measurement setup.

## Tracking Inputs

- conversion event name and source
- tag, pixel, SDK, server-side event, or analytics event
- conversion category and optimization setting
- attribution window
- UTM convention
- landing page URL and redirects
- consent or privacy constraints
- analytics destination and reporting owner

## UTM Convention

Use a stable convention before launch:

```text
utm_source=<platform>
utm_medium=paid
utm_campaign=<campaign-name-or-id>
utm_content=<creative-or-ad-id>
utm_term=<keyword-or-audience-when-relevant>
```

Keep names lowercase, consistent, and durable. Do not put personal data in
UTMs.

## Conversion Validation

- Confirm the conversion event matches the campaign objective.
- Confirm the event fires on the intended user action, not every page view.
- Confirm redirects preserve click and UTM parameters.
- Confirm app campaigns use the intended app event or store attribution path.
- Confirm duplicate browser and server events are deduplicated when both are
  used.
- Confirm analytics and ad platform reports will be comparable enough for the
  decision being made.

## Reporting Caveats

- Different platforms use different attribution windows and modeling.
- Ad platform conversions may not equal backend conversions.
- Privacy, consent, browser changes, and app tracking limits can reduce
  observability.
- When tracking is uncertain, label optimization recommendations as risky.
