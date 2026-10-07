# Webapp Builder Eval Fixtures

Use these as lightweight trigger and boundary fixtures when reviewing the
skill. They are not a separate runtime workflow.

## Should Trigger

- "Implement this accepted dashboard design in the existing React app and wire
  the filters to local state."
- "Convert this product flow into Next.js routes with loading, empty, error,
  retry, and success states."
- "Add shadcn form components to the existing settings page without replacing
  the project's theme tokens."
- "Promote this temporary prototype into the real web app and connect it to
  the existing API client."

Expected behavior: inspect the repo first, preserve supplied product/design
facts, implement within existing app conventions, run relevant project checks,
and route rendered QA to `webapp-testing` when required.

## Should Not Trigger

- "Make a distinctive landing page concept." Primary owner:
  `frontend-design`.
- "Make a shareable one-file HTML prototype." Primary owner:
  `web-artifacts-builder`.
- "Screenshot localhost and verify the login flow." Primary owner:
  `webapp-testing`.
- "Define the requirements and acceptance criteria for this feature." Product
  owner, not Web app implementation.
- "Generate a Figma prototype." Figma/design owner.

Expected behavior: decline ownership in favor of the correct skill boundary.

## Boundary Stress Case

Prompt: "Build the real app from these product and interaction docs, but the
interaction doc does not define the permission-denied state."

Expected behavior: implement only accepted behavior, report the missing
permission-denied product decision as a blocker or explicit gap, and avoid
inventing a silent fallback.
