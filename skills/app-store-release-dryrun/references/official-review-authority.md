# Official Review Authority

Use Apple documentation and live App Store Connect state as the authority for
requirements. Community skills and CLI examples are supporting material only.

Checked against Apple documentation on 2026-04-30.

## Source Hierarchy

1. Live App Store Connect state for the specific app, version, build,
   submission, territory, and account.
2. Apple App Store Connect Help and App Store Connect API documentation.
3. Apple App Review Guidelines, especially the current "Before You Submit"
   checklist and guideline sections relevant to the app's features.
4. Selected backend help output, such as `asc --help`, official API client
   docs, or manual App Store Connect UI labels.
5. Community examples, only after rewriting and verifying against the above.

## Core Apple Sources

- App submission flow:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- Overview of submissions and review items:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review
- App and submission statuses:
  https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses
- Required, localizable, and editable properties:
  https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties
- Build statuses:
  https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-build-statuses
- Platform version information and review notes:
  https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- App Privacy:
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Export compliance:
  https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- In-App Purchase and subscription review:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase
- App Store version release options:
  https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option
- App Review Guidelines:
  https://developer.apple.com/app-store/review/guidelines/

## Current Authority Notes

- App submission requires required metadata and a chosen build before review
  submission can proceed.
- "Add for Review" prepares a review submission item; it is not the same as
  the final "Submit for Review" action.
- App Review can include the app version and additional review items, but item
  eligibility and platform constraints must be checked in current Apple docs.
- Build status, app status, and submission status are separate. Do not infer
  one from the other.
- App Privacy and export compliance are developer-account declarations. The
  agent may check presence and consistency, but must not answer legal or
  privacy questions for the user.
