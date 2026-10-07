# Builds And TestFlight

## Build State

Use Apple build status definitions as authority. A build may require attention,
be processing, be available for TestFlight, or be invalid/expired.

Read-only questions this skill can answer:

- Which builds exist for this app/version/platform?
- Is the build processed or still waiting on Apple?
- Does the build show export-compliance or beta-review issues?
- Which build is attached to an App Store version?
- Which TestFlight groups or testers can access it?

For `asc`-style backends, source command shapes include:

```bash
asc builds list --app "APP_ID" --sort -uploadedDate --limit 10 --output json
asc builds info --build-id "BUILD_ID" --output json
asc builds info --app "APP_ID" --latest --version "1.2.3" --platform IOS --output json
```

Do not use this skill for binary upload, Xcode archive/export, signing,
notarization, or build-system fixes.

## TestFlight Operations

TestFlight operations are live account operations when they affect testers,
groups, build access, invitations, or external beta review.

Read-only inspection:

```bash
asc testflight groups list --app "APP_ID" --paginate --output json
asc testflight testers list --app "APP_ID" --paginate --output json
```

Live operation examples that require explicit confirmation:

- create or delete beta groups
- add or remove testers
- invite testers
- add or remove builds from groups
- submit a build for external beta review
- expire or stop testing a build

## Apple TestFlight Facts To Preserve

- TestFlight lets teams distribute beta builds, manage testers, and collect
  feedback.
- Builds can be tested for up to 90 days.
- External testing may require Beta App Review, especially the first build
  added to a group.
- Internal and external tester eligibility and limits are role- and
  account-dependent; verify current Apple Help before final action.
- Test information for external testing is separate from App Store metadata.

## What To Test Notes

When the user asks for TestFlight notes:

- Keep them tester-facing and specific.
- Name the feature or scenario to test.
- Include known risks only when useful to testers.
- Do not reuse App Store What's New copy blindly; beta notes can be more
  direct and task-oriented.

If the task is only copywriting the notes, produce text. If it changes a build
localization or tester-facing TestFlight state, require confirmation.
