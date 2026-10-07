# Apple Field Notes

## Official Boundary

Apple's App Store Connect Help calls the field **What's New in this Version**.
It describes the changes in the version, such as new features, UI
improvements, or bug fixes.

Operational constraints:

- Limit: 4000 characters.
- Not available for the first app version.
- Required for subsequent version updates.
- Localizable.
- Distinct from Promotional Text, which is limited to 170 characters and can be
  updated without a new app submission.

Related official sources:

- App Store Connect Help: Platform version information
  <https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information>
- App Store Connect Help: Required, localizable, and editable properties
  <https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/>
- App Store Connect API: App Store Version Localizations
  <https://developer.apple.com/documentation/appstoreconnectapi/app-store-version-localizations>

## What This Skill Does Not Decide

This skill does not decide whether the app is ready to submit, whether the
version is editable, or whether the metadata should be uploaded. Route those
questions to `app-store-connect` or `app-store-release-dryrun`.

## Practical Checks

- Count characters in the final text before delivery.
- Mention the version only if the user asks for a title or the output is not
  pasted directly into App Store Connect.
- Do not include markdown bullets if the user needs plain text; App Store
  fields are plain text.
- If writing for multiple locales, validate each locale separately because text
  expansion can push translations over the limit.
