# ID Resolution

Resolve App Store Connect resource IDs before planning live operations.

## Preferred Inputs

- App: bundle ID first, then SKU, then exact app name.
- Version: app ID + platform + version string.
- Build: app ID + platform + version string + build number when available.
- TestFlight group: app ID + exact group name.
- Tester: email address plus app/team context.
- Review submission: app ID + platform + state + submitted date.

## Rules

- Do not auto-select when more than one candidate matches.
- Use pagination for complete lists.
- Use deterministic sorting for recent/latest resources.
- Preserve both the human label and opaque ID in reports.
- Include confidence: exact match, filtered match, or ambiguous candidate.

## Read-Only Lookup Shape

Use backend-specific commands only after selecting a backend. For `asc`, the
source patterns are:

```bash
asc apps list --bundle-id "com.example.app" --output json
asc apps list --name "Exact App Name" --paginate --output json
asc builds list --app "APP_ID" --sort -uploadedDate --limit 10 --output json
asc versions list --app "APP_ID" --paginate --output json
asc testflight groups list --app "APP_ID" --paginate --output json
asc testflight testers list --app "APP_ID" --paginate --output json
asc review submissions-list --app "APP_ID" --paginate --output json
```

Verify exact command names with `asc --help` before running.

## ID Map Output

```text
Resource: App
Input: com.example.app
Resolved ID: 1234567890
Confidence: exact bundle ID match
Source: App Store Connect API / selected backend
Next use: build lookup, version lookup, TestFlight state
```

## Ambiguity Output

```text
Multiple apps matched "Example":
1. Example App / com.example.app / APP_ID_1
2. Example Beta / com.example.beta / APP_ID_2

No live operation should run until the target is selected.
```
