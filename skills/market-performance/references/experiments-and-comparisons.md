# Experiments And Comparisons

Use this reference for baselines, A/B tests, PPO or CPP reviews, campaign
tests, before/after comparisons, and launch readouts.

## Baseline Record

```text
Surface:
Primary metric:
Guardrail metrics:
Baseline date range:
Segments:
Current asset or copy version:
Known events during baseline:
Data source:
```

## Change Record

```text
Change:
Reason:
Owner:
Start date and timezone:
Affected channels:
Unaffected comparison groups:
Expected primary movement:
Risks:
Rollback or next action:
```

## Confidence Levels

- Controlled: randomization or a platform experiment is available and the
  test design is valid.
- Directional: comparison is reasonable but not randomized.
- Weak: multiple changes, small sample, short window, or noisy seasonality.
- Unsupported: no usable baseline, unclear source, or missing metric.

## Before / After Rules

- Use the same weekday pattern where possible.
- Compare segments separately before using a total.
- Exclude launch day, outage day, or tracking-change day when it distorts the
  trend and document the exclusion.
- Do not infer causation when multiple major changes overlapped.
- Include guardrail metrics so a gain in one metric does not hide harm in
  another.

## Experiment Log Output

```text
Hypothesis:
Surface:
Variant or change:
Baseline:
Run window:
Primary metric:
Guardrails:
Result:
Confidence:
Decision:
Follow-up:
```
