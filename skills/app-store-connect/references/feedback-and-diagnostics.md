# Feedback And Diagnostics

Use this reference for App Store Connect and TestFlight feedback summaries.
Do not use it for source-level debugging or code fixes.

## In Scope

- TestFlight beta feedback summaries.
- TestFlight crash report inventory and grouping.
- App Store Connect diagnostic or performance report inventory when surfaced by
  the selected backend/API.
- Reports that help decide whether a build, beta, or release needs follow-up.

## Out Of Scope

- Symbolication, source-level crash debugging, Instruments, Xcode Organizer
  investigation, code fixes, or performance profiling.
- Build/upload problems before the build appears in App Store Connect.

## Read-Only Command Shapes

For `asc`-style backends, source patterns include:

```bash
asc testflight crashes list --app "APP_ID" --sort -createdDate --limit 10 --output json
asc testflight crashes list --app "APP_ID" --build "BUILD_ID" --sort -createdDate --output json
asc testflight feedback list --app "APP_ID" --sort -createdDate --limit 10 --output json
asc testflight feedback list --app "APP_ID" --build "BUILD_ID" --sort -createdDate --output json
```

Apple API resources include beta feedback crash and screenshot submissions.
Verify current endpoint fields before relying on an exact schema.

## Summary Shape

Organize feedback and crash output by:

1. total items in the inspected window
2. top crash signatures or feedback themes
3. affected builds and versions
4. device and OS spread when available
5. first seen, latest seen, or spike timing
6. recommended routing: TestFlight follow-up, App Review risk, or source-level
   debugging outside this repository

## Caveats

- App Store Connect crash and diagnostic data may lag.
- User comments may contain personal data; summarize minimally and avoid
  copying sensitive content into persistent docs.
- A high-level crash summary is operational input, not a root-cause analysis.
