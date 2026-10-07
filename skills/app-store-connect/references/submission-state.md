# Submission State

Use this reference for App Store version and review-submission state
inspection. Use `app-store-release-dryrun` for readiness checklists and blocker
fix planning.

## App And Version Status

Apple's App and submission statuses page is the authority for status meaning.
Important state families:

- **Preparation**: preparing metadata, build, assets, or review information.
- **Waiting / in review**: Apple has received or is reviewing the submission.
- **Rejected / metadata rejected / invalid binary**: action is required before
  resubmission.
- **Pending release**: Apple accepted the version, but release timing or
  developer action remains.
- **Ready for distribution**: accepted and available subject to agreements and
  availability settings.

Do not infer editability from memory. Verify the current status-specific edit
rules before changing metadata, screenshots, builds, or review items.

## Review Submission Resources

Review submissions can contain App Store versions and other review items such
as custom product page versions, experiments, app events, and background asset
versions.

Read-only questions this skill can answer:

- Is there an active submission?
- Which app version or items are in the submission?
- What is the submission state?
- Which item is blocked or unresolved?
- Who submitted or last updated the submission, if the source includes actor
  data?

For `asc`-style backends, source command shapes include:

```bash
asc review submissions-list --app "APP_ID" --paginate --output json
asc submit status --id "SUBMISSION_ID" --output table
asc submit status --version-id "VERSION_ID" --output table
```

Verify command names with the selected backend before running.

## Submission Mutations

The following are live operations and require explicit confirmation:

- create a review submission
- add or remove review items
- submit for review
- cancel a submission
- remove a build from review
- release an approved app version

For actual readiness decisions, route to `app-store-release-dryrun`. This skill can
report state and produce a confirmation-gated command plan.

## Status Report Shape

```text
App: Example App / APP_ID
Version: 1.2.3 / VERSION_ID
Submission: SUBMISSION_ID
Status: Waiting for Review
Source: App Store Connect API / selected backend
Editable surfaces: verify current Apple status rules before mutation
Next action: wait, cancel with confirmation, or inspect review items
```
