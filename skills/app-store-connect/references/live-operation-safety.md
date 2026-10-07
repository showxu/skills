# Live Operation Safety

Use this reference before any operation that changes App Store Connect state.

## Safe By Default

Usually safe:

- list apps, versions, builds, groups, testers, submissions
- read one app/build/version/submission
- inspect current status
- create a dry-run command plan
- summarize user-provided output

Still avoid leaking credentials or personal tester data in reports.

## Confirmation Required

Require explicit user confirmation before:

- submitting for App Review or Beta App Review
- canceling, removing, or changing review submissions
- adding/removing tester groups or testers
- inviting testers
- expiring builds or stopping testing
- changing build group access
- changing public release timing or availability
- mutating App Store Connect metadata, screenshots, review details, privacy,
  pricing, commerce, or legal declarations

## Confirmation Prompt Shape

Before live action, state:

```text
Target app:
Platform:
Resource IDs:
Operation:
Backend:
Evidence already checked:
Expected result:
Rollback/cancel path:
```

Then wait for an explicit confirmation that names the operation.

## Reporting After Live Actions

If a confirmed live action runs, report:

- exact target and resource IDs
- command or API endpoint family used
- status before and after
- output evidence
- remaining risks or pending Apple processing
- next read-only check
