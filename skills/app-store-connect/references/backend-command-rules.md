# Backend Command Rules

This collection is backend-neutral. App Store Connect state may be inspected
through the official API, a selected CLI, manual App Store Connect UI steps, or
user-provided output.

## Command Planning

- State the selected backend before commands.
- Prefer read-only commands first.
- Use dry-run or validation mode before live changes when the backend supports
  it.
- Use explicit long flags in scripts or plans.
- Use JSON for machine parsing and table/Markdown for human reports.
- Use pagination when the user asks for a complete audit.
- Verify current help before exact commands:

```bash
asc --help
asc apps --help
asc builds --help
asc testflight --help
asc review --help
```

## `asc` Positioning

`asc` can provide useful command shapes for:

- app/build/version lookup
- build state inspection
- TestFlight groups/testers
- review submission list/status
- beta feedback and crash report summaries

But `asc` is not official Apple documentation. If `asc` disagrees with Apple
docs or current App Store Connect behavior, Apple wins.

## Authentication Notes

- Prefer secure local authentication already configured by the user.
- Do not ask the user to paste private keys or cookies into repository files.
- Do not write credentials into skills, generated reports, or templates.
- If permissions are unclear, ask for a capability or role check rather than
  retrying failing live operations.

## Mutation Planning

For any live operation, the command plan must include:

- target app and platform
- exact target resource IDs
- operation type
- selected backend
- dry-run or read-only evidence
- confirmation phrase or confirmation checkpoint
- expected success evidence
- cancel or rollback path when available

Never hide live operations inside a broader "fix it" command.
