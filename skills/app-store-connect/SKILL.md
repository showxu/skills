---
name: app-store-connect
description: Inspect, plan, and safely operate Apple App Store Connect state for apps, App Store versions, builds, TestFlight, review submissions, beta feedback, and optional CLI/API backends. Use for ID resolution, build processing state, TestFlight groups/testers, review-submission status, App Store Connect command planning, and read-only account diagnostics. Do not use for metadata copywriting, screenshot design, ASO strategy, pricing changes, live submission, binary upload/build/export, signing, notarization, or destructive account changes without explicit confirmation.
---

# App Store Connect

## Purpose

Inspect and plan App Store Connect operations without binding the workflow to a
single third-party CLI. This skill handles account state, IDs, TestFlight,
build state, review-submission status, and read-only diagnostics.

It does not build binaries, upload binaries, sign apps, notarize apps, write
metadata copy, create screenshot assets, or submit/release apps by default.

## When To Use

- The user asks about App Store Connect apps, IDs, builds, versions,
  TestFlight, beta groups/testers, review submission status, app status, build
  status, beta feedback, or account-facing release state.
- A task needs to resolve `APP_ID`, `BUILD_ID`, `VERSION_ID`,
  `SUBMISSION_ID`, beta group IDs, tester IDs, or pre-release version IDs.
- The user asks for `asc`, App Store Connect API, App Store Connect UI, or
  backend-neutral command planning for App Store Connect operations.
- The user needs a read-only state summary before metadata, screenshot,
  preflight, ASO, pricing, or submission work.

## When Not To Use

- Metadata copy, field validation, localization files, or dry-run metadata sync:
  use `app-store-metadata`.
- What's New text or changelog drafting: use `app-store-whats-new`.
- Screenshot assets or screenshot validation: use `app-store-screenshots`.
- App Review readiness checklists: use `app-store-release-dryrun`.
- ASO, keywords, or conversion review: use `app-store-aso`.
- Pricing, subscriptions, IAP, or commerce catalog reconciliation: use
  `app-store-commerce`.
- Xcode build/export, binary upload, signing, notarization, or source-level
  crash debugging are outside this repository.

## Inputs To Inspect

- App name, bundle ID, SKU, platform, version string, build number, or known
  App Store Connect IDs.
- Desired mode: read-only inspection, dry-run command plan, or confirmed live
  operation.
- Selected backend: official API, App Store Connect UI, `asc`, manual
  instructions, or unknown.
- Existing state output from App Store Connect, API JSON, CLI table/JSON, or
  screenshots of status pages.
- Whether the operation affects testers, review state, public availability, or
  externally visible release data.

## Workflow

1. Classify the requested operation as read-only, dry-run, or live. Stop for
   explicit confirmation before tester changes, review-submission changes,
   release-state changes, deletions, or public visibility changes.
2. Resolve stable IDs before planning deeper operations. Read
   `references/id-resolution.md` when names, bundle IDs, or version strings
   need mapping to App Store Connect IDs.
3. Use official Apple state definitions first. Read
   `references/official-authority.md` for API boundaries and Apple Help pages.
4. For builds or TestFlight, read `references/builds-testflight.md`.
5. For review-submission status or release-state inspection, read
   `references/submission-state.md`. Route readiness blockers to
   `app-store-release-dryrun` when the task becomes a checklist.
6. For beta feedback, TestFlight crash reports, or App Store Connect diagnostic
   summaries, read `references/feedback-and-diagnostics.md`.
7. If using a CLI or tool backend, read `references/backend-command-rules.md`
   and verify current flags with the backend's help before writing commands.
8. Return a state report, ID map, dry-run command plan, or confirmation-gated
   operation plan.

## Reference Files To Consult

- `references/official-authority.md`: Apple documentation authority, API
  boundaries, and source hierarchy.
- `references/id-resolution.md`: deterministic ID lookup rules and ambiguity
  handling.
- `references/backend-command-rules.md`: backend-neutral command planning,
  output formats, pagination, and `asc` positioning.
- `references/builds-testflight.md`: build state, TestFlight groups/testers,
  What to Test notes, and beta review boundaries.
- `references/submission-state.md`: App Store version, review submission, and
  status interpretation.
- `references/feedback-and-diagnostics.md`: beta feedback, TestFlight crashes,
  performance diagnostics, and reporting shape.
- `references/live-operation-safety.md`: confirmation gates and live-operation
  reporting.

## Safety / Confirmation Rules

- Read-only list/view/status operations may proceed after credentials and scope
  are clear.
- Live operations require explicit confirmation naming the app, environment,
  target IDs, backend, intended mutation, and rollback/cancel path when one
  exists.
- Never submit for review, cancel review, remove testers, add external testers,
  expire builds, change availability, or change public release state as an
  implied step.
- Do not store API keys, cookies, private keys, or web-session credentials in
  the skill directory or generated output.
- Treat `asc` and browser automation as optional backends. They are not Apple
  authority.

## Decision Rules

- Prefer bundle ID over app name when resolving an app. Names are ambiguous.
- Prefer explicit IDs for mutation plans. Human-friendly names are acceptable
  only for read-only exploration.
- Use pagination for complete audits and deterministic sorting for "latest" or
  "recent" results.
- Use JSON output for machine parsing and table/Markdown output for human
  reports.
- If a request mixes state inspection with readiness remediation, split the
  response into "current state" and "next skill/action".

## Output Format

Use one of these shapes:

- **ID map**: resource type, human input, resolved ID, confidence, ambiguity.
- **State report**: app/version/build/submission/TestFlight status, source,
  timestamp, blockers, and next action.
- **Command plan**: backend, read-only commands, dry-run commands, live
  commands requiring confirmation, expected outputs.
- **TestFlight plan**: groups, testers, build eligibility, beta review state,
  What to Test notes, and confirmation gates.
- **Feedback summary**: total count, top themes/signatures, affected builds,
  device/OS spread, and source-level debugging routing note.

## Failure / Uncertainty Handling

- If the backend command surface may have changed, verify `--help` or official
  API docs before giving exact commands.
- If multiple apps, builds, versions, groups, or submissions match, stop and
  present candidates instead of selecting one.
- If App Store Connect API cannot perform a requested operation, say so and
  provide the official/manual path or route to a more appropriate skill.
- If live state is unavailable or credentials are missing, provide a read-only
  checklist and the exact data needed from the user.
