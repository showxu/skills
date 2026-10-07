# Readiness Checklist

Use this checklist after IDs and current state are known. Mark each item as
`pass`, `blocker`, `warning`, `advisory`, or `unknown`.

## App / Version / Submission State

- Correct app, platform, and version string are selected.
- There is no conflicting active submission for the same platform/version.
- App status permits the intended preparation action.
- If already Waiting for Review or In Review, switch to status monitoring or
  issue response; avoid proposing edits that Apple currently disallows.

## Build

- Correct build is selected for the App Store version.
- Build is processed and eligible for App Store submission.
- Build is not Invalid Binary, Missing Compliance, expired, rejected, or still
  processing.
- Export compliance and encryption state are resolved or explicitly listed as
  unresolved.

Use `app-store-connect` for live build lookup and status interpretation.

## Required Metadata And Localizations

- Required app-info and platform-version fields are present.
- Version number, copyright, support URL, description, keywords, promotional
  text, What's New when required, and review-facing fields are present where
  applicable.
- Each target locale has the intended required fields and no placeholder text.
- Metadata accurately reflects the app; screenshots, description, privacy
  information, and in-app purchase disclosure must not mislead users.

Use `app-store-metadata` for copy review, field limits, and local file
validation.

## Screenshots And App Previews

- Required screenshot wells are satisfied for every platform/device family the
  app supports.
- Each screenshot file is an accepted format and has no alpha transparency
  issue.
- Localized screenshot sets fit copy, avoid placeholders, and remain accurate.
- App previews, if present, meet current App Store Connect status/editability
  rules.

Use `app-store-screenshots` for asset inspection and screenshot-specific
upload readiness.

## Review Information

- App Review contact information is present and current.
- Review notes explain non-obvious features, gated flows, special hardware,
  regional behavior, and in-app purchases when relevant.
- If login is required, reviewers have a working demo account or full demo
  mode and any needed test data.
- Backend services needed during review are expected to be live and accessible.
- URLs in metadata and review notes are functional and not placeholders.

## Privacy / Rights / Compliance

- Privacy policy URL is present where Apple requires it; tvOS privacy policy
  text is present when applicable.
- App Privacy answers are completed and published or manually verified in App
  Store Connect.
- Content rights declaration is set and matches third-party content use.
- Export compliance determination is complete for the selected build.
- Age rating, regulated content, health/finance/legal claims, and child-safety
  surfaces are not guessed by the agent.

## Availability And Release Option

- Intended territory availability exists or the missing setup is called out.
- Release option is known: manual, automatic after approval, or automatic no
  earlier than a specified date.
- First releases and pre-orders have their special release behavior checked in
  App Store Connect.
- Pricing, catalog, and storefront changes are not performed by this skill.

## Additional Review Items

- IAPs and subscriptions are ready for review when they affect this version.
- Game Center components, in-app events, custom product pages, product page
  optimization tests, and asset packs are included only when intended and
  eligible.
- Items associated with different platforms are not mixed into a single
  submission.
