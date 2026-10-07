# Live Submission Safety

Preflight ends before live App Store Connect mutations. If the user explicitly
asks to submit, cancel, release, edit availability, change pricing, or mutate
review items, require confirmation and route the live operation through App
Store Connect operation rules.

## Confirmation Must Name

- App name and App Store Connect app ID.
- Platform.
- Version string and App Store version ID.
- Build ID or build number when a build is affected.
- Review submission ID when editing or submitting a draft submission.
- Selected backend: App Store Connect UI, official API tooling, `asc`, or
  another tool.
- Exact mutation: add for review, submit for review, cancel, remove item,
  release, change availability, edit content rights, or another operation.
- Expected rollback or cancel path when one exists.

## Never Imply These As Final Steps

- Submit for Review.
- Cancel or remove a submission from review.
- Release This Version.
- Change territory availability or pricing.
- Add/remove IAPs, subscriptions, Game Center components, or other review
  items.
- Publish App Privacy answers.
- Confirm export compliance, content rights, age rating, or legal statements.

## Safe Final Actions From This Skill

- Readiness report.
- Missing evidence list.
- Dry-run command plan.
- Manual App Store Connect checklist.
- Confirmation prompt for a separate live operation.
- Status-monitoring plan when Apple is processing or reviewing.
