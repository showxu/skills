---
name: app-store-release-dryrun
description: Dry-run the Apple App Store release or submission path before live action, auditing App Review readiness and grouping blockers across build state, metadata, screenshots, localizations, App Privacy, content rights, export compliance, review details, availability, digital goods, Game Center, and App Store Connect submission state. Use for pre-submit checks, review blocker triage, first-time release readiness, and dry-run submission reports. Do not use for live submission, App Store Connect state mutation, ASO, screenshot design, metadata copywriting, pricing/catalog operations, binary build/upload/export, signing, notarization, or source-level debugging.
---

# App Store Release Dry Run

## Purpose

Dry-run the App Store release or submission path before live action. Decide
whether an App Store version is ready to submit for App Review, and if not,
group the blockers into clear next actions.

This skill is a release-path readiness audit. It can produce reports, dry-run
command plans, and manual checklists. It does not submit, cancel, release,
change availability, update pricing, mutate metadata, or make legal/privacy
declarations by default.

## When To Use

- The user asks to dry-run an App Store release/submission path or asks
  whether an app, build, or version is ready to submit for App Review.
- The task mentions preflight, submission health, review blockers, Ready for
  Review, first app release, first IAP/subscription review, App Privacy,
  content rights, export compliance, review notes, demo account, availability,
  or release readiness.
- The user has `asc submit preflight`, App Store Connect API, CLI, or manual
  App Store Connect output and wants it interpreted.
- The task asks for a dry-run release or submission checklist without live
  App Store Connect changes.

## When Not To Use

- App Store Connect ID/state inspection only: use `app-store-connect`.
- Metadata copywriting, field editing, local metadata validation, or
  localization authoring: use `app-store-metadata`.
- Screenshot design, storyboard copy, image validation, or screenshot
  generator work: use `app-store-screenshots`.
- What's New drafting: use `app-store-whats-new`.
- ASO, keyword strategy, ranking, or conversion optimization: use
  `app-store-aso`.
- Pricing, subscription catalog setup, IAP catalog reconciliation, or
  RevenueCat reconciliation: use `app-store-commerce`.
- Xcode build/export, binary upload, signing, notarization, Simulator work, or
  source-level debugging are outside this repository.

## Inputs To Inspect

- App, platform, version string, build number, and known App Store Connect IDs.
- App Store Connect state output for app status, version status, build status,
  submission status, selected build, review details, App Privacy, availability,
  and App Review messages.
- Metadata and localization files, if the preflight includes local assets.
- Screenshot directories, if the preflight includes upload-readiness checks.
- Digital goods context: first IAP/subscription, new IAP type, subscription
  group, review screenshots, pricing/availability evidence, and review notes.
- User's intended submission mode: report only, dry-run command plan, or
  explicit live action request.

## Workflow

1. Classify the request as release dry run, quick readiness, complete
   preflight, blocker triage, first-time release, or dry-run command planning.
2. Resolve IDs and current state with `app-store-connect` when the app,
   version, build, submission, or platform is ambiguous.
3. Read only the relevant references:
   - Apple source hierarchy: `references/official-review-authority.md`.
   - Core checklist: `references/readiness-checklist.md`.
   - Blocker groups and next-action routing:
     `references/blocker-routing.md`.
   - First app release: `references/first-time-release.md`.
   - IAP/subscriptions: `references/digital-goods-and-services.md`.
   - Live-operation gates: `references/live-submission-safety.md`.
4. Run the checks in this order:
   1. App/version/submission status.
   2. Selected build and build eligibility.
   3. Required metadata and localizations.
   4. Screenshots and preview asset readiness.
   5. Review information, reviewer access, demo account, and notes.
   6. App Privacy, privacy policy, content rights, and export compliance.
   7. Availability and release option.
   8. Digital goods, Game Center, and other review items.
5. Group every issue as blocking, warning, advisory, or unknown. Do not call a
   blocker resolved without evidence.
6. Return a readiness verdict and the smallest safe next action. If the next
   action is live, require explicit confirmation and route through
   App Store Connect operation rules.

## Backend-Agnostic Command Planning

If the user wants command shapes, keep them backend-neutral first. For an
`asc`-style backend, useful read-only or dry-run shapes include:

```bash
asc submit preflight --app "APP_ID" --version "1.2.3" --platform IOS
asc validate --app "APP_ID" --version "1.2.3" --platform IOS --output table
asc release run --app "APP_ID" --version "1.2.3" --build "BUILD_ID" --dry-run
```

Verify the selected backend's current flags before presenting commands as
executable. Treat web-session commands as optional escape hatches, never as
Apple authority.

## Safety / Confirmation Rules

- Never click, run, or imply `Submit for Review`, `Submit`, `Release This
  Version`, cancellation, availability changes, pricing changes, or catalog
  changes without explicit confirmation.
- Do not decide export compliance, App Privacy answers, content rights, age
  rating, regulated claims, or legal declarations for the user.
- Do not store credentials, API keys, cookies, demo account passwords, or
  private review notes in the skill directory.
- If App Store Connect state is unavailable, label the output as a local or
  evidence-limited preflight report.

## Decision Rules

- A clean dry run is not the same as an accepted App Review result. It only
  means the known pre-submit surfaces appear ready.
- Apple official documentation and live App Store Connect state override
  community examples and remembered limits.
- App Privacy publish state may require manual App Store Connect confirmation
  when the selected backend cannot verify it.
- First IAP/subscription submissions and first-time availability often need
  App Store Connect UI or specialized commerce operations; keep them explicit.
- If an app is already Waiting for Review or In Review, switch from readiness
  audit to status interpretation and do not propose metadata/screenshot edits
  unless Apple status rules allow them.

## Output Format

Use this shape for most preflight work:

```text
App Store Release Dry Run

Verdict: Ready / Not ready / Ready with warnings / Unknown
Evidence level: live App Store Connect / API or CLI output / local files only

Blocking issues:
- surface: issue, evidence, owner/action, live-change required?

Warnings:
- ...

Advisories:
- ...

Next safe action:
- ...
```

For failure triage, include the observed error, likely surface, evidence to
collect, and one safe retry path.

## Failure / Uncertainty Handling

- If required evidence is missing, list the minimum fields or outputs needed
  instead of guessing readiness.
- If multiple apps, versions, builds, or submissions match, stop and present
  candidates.
- If backend output conflicts with Apple docs, trust current live App Store
  Connect state and cite the conflict.
- If the issue is outside App Store operations, say it is outside this skill
  family and identify the exact evidence the operations report can still use.
