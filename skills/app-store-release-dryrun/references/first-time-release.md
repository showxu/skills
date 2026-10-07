# First-Time Release

First public releases often fail for missing account or store setup that later
updates no longer need. Use this reference when the app has never been live on
the App Store, or when the user mentions first submission.

## Extra Checks

- App record, bundle ID, SKU, primary locale, categories, age rating, and
  app-level information are complete.
- Required platform-version metadata and localizations are complete.
- A build is selected for the target version and is eligible for submission.
- Availability exists for intended countries or regions.
- Release option is intentional. Pre-order setups can force manual release
  behavior for the first release.
- Privacy policy and App Privacy answers are complete before submission.
- Content rights and export compliance are complete.
- Review notes explain first-use flows, account requirements, hardware,
  sample data, non-obvious features, and any in-app purchases.
- Backend services needed for review are live.
- If subscriptions or IAPs are included for the first time, they are selected
  with the app version as Apple currently requires.
- Game Center components that must ship with the app version are included in
  the intended review submission.

## Common First-Time Blockers

- No initial availability for the app.
- Privacy policy URL missing for an app that needs it.
- App Privacy answers entered but not published or not verified.
- First IAP/subscription product is Ready to Submit but not included with the
  app version.
- Subscription group missing review screenshot, promotional image, pricing,
  availability, or localization evidence.
- Review notes omit demo credentials or explanation of gated features.
- App Store version is prepared, but no build is attached.
- Screenshot wells satisfy one device family but not another supported family.

## Output Notes

When first-release blockers are found, do not collapse them into a generic
"not ready" result. Show which blockers are one-time bootstrap work and which
will recur on every update.
