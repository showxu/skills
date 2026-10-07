# Blocker Routing

Always keep the report action-oriented. A blocker is useful only when the user
can see what evidence caused it and what safe next action is available.

## Blocker Groups

- **Local asset/copy**: metadata file missing a field, screenshot invalid,
  localized copy overflow, placeholder text, broken URL in local evidence.
  Route to `app-store-metadata`, `app-store-screenshots`, or
  `app-store-whats-new`.
- **App Store Connect state**: app/version/build/submission state is missing,
  ambiguous, processing, invalid, rejected, or not editable. Route to
  `app-store-connect` for read-only lookup or confirmation-gated operations.
- **Backend/API fixable**: selected backend has a verified non-live or
  confirmation-gated operation for metadata sync planning, build attachment,
  review detail update, content rights, or review-submission construction.
  Present commands only after verifying current backend flags.
- **Manual/App Store Connect UI**: the public API or selected backend cannot
  reliably perform the step, or the action is legal/privacy/account-sensitive.
  Give the exact App Store Connect surface to inspect.
- **Privacy/legal/compliance**: App Privacy, content rights, export
  compliance, age rating, regulated claims, or certification evidence need
  user-owned answers. The agent may check completeness, not decide truth.
- **Commerce setup**: IAP/subscription pricing, availability, product
  metadata, subscription group setup, or RevenueCat reconciliation. Keep
  readiness notes here, but route catalog changes to `app-store-commerce`.
- **Waiting on Apple**: build processing, review in progress, processing after
  removal, status propagation, or manual release propagation. Give polling or
  monitoring guidance instead of edit guidance.
- **Outside repository scope**: build/export/upload/signing/notarization,
  app-code crashes, Simulator automation, or source debugging. Record only the
  App Store evidence needed for the operations report.

## Severity Rules

- **Blocking**: prevents submission or makes a submitted item predictably
  invalid based on current evidence.
- **Warning**: may cause rejection or delay, but the app can technically reach
  submission.
- **Advisory**: quality or review-risk recommendation without confirmed
  blocking evidence.
- **Unknown**: readiness cannot be determined from available evidence.

## Readiness-First Answer Order

For "can I submit?" questions, answer in this order:

1. Verdict: ready, not ready, ready with warnings, or unknown.
2. Blocking issues.
3. Which blockers can be resolved locally, by read-only/dry-run planning, by
   confirmation-gated App Store Connect operation, or only manually.
4. Exact next safe action.

## Command Shape Guidance

For an `asc`-style backend, compressed command shapes from upstream release
skills map to local purposes like this:

- `submit preflight`: fastest non-mutating readiness check.
- `validate`: deeper API-visible readiness audit.
- `release run --dry-run`: end-to-end rehearsal.
- `release stage`: confirmation-gated preparation without final submit.
- `review submissions-*`: explicit review-submission construction when
  multiple review items need to be included.

Do not treat any of these as mandatory dependencies. Verify the selected
backend before use.
