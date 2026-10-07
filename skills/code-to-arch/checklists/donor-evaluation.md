# Donor Evaluation Checklist

Use this checklist before accepting an upstream as design evidence.

- Is this donor official, mature, production-proven, or strongly aligned?
- Is it a capability donor, API donor, UX donor, test donor, naming donor, or
  anti-pattern donor?
- What local architecture question can this donor answer?
- What is the reusable semantic core?
- Which capabilities are stable across donor implementation details?
- Which APIs or call-site shapes are worth comparing?
- Which tests, fixtures, or compatibility cases are reusable?
- What assumptions are local to the donor?
- What product, runtime, deployment, or dependency assumptions should not be
  inherited?
- What evidence should be cited?
- Is any fact mutable enough to require official or primary-source
  verification?
- Would this donor still matter if the local implementation uses a different
  file layout or dependency graph?
