# Apple Metadata Fields

## Source Authority

Official Apple sources win over community examples when limits, required
fields, localization support, or editability may have changed.

Useful official sources:

- App information:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/app-information>
- Platform version information:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information>
- Required, localizable, and editable properties:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/>
- App Store Version Localizations API:
  <https://developer.apple.com/documentation/appstoreconnectapi/app-store-version-localizations>
- App Store localizations:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations>

## Field Ownership

App-info fields are app-level:

- `name`
- `subtitle`
- `privacyPolicyUrl`
- `privacyChoicesUrl`
- `privacyPolicyText`
- primary language and category-related app information

Version-localization fields are per app version and locale:

- `description`
- `keywords`
- `marketingUrl`
- `promotionalText`
- `supportUrl`
- `whatsNew`

Do not mix the two surfaces in one upload plan unless the workflow explicitly
handles both.

## Core Limits

| Field | Limit | Notes |
| --- | --- | --- |
| Name | 2-30 characters | Localized app name. |
| Subtitle | 30 characters | Appears under the app name. |
| Promotional Text | 170 characters | Separate from description. |
| Description | 4000 characters | Plain text; HTML is not supported. |
| Keywords | 100 bytes | Comma-separated; do not duplicate app name or company name. |
| What's New | 4000 characters | Version updates only; localizable. |
| App Review Notes | 4000 bytes | Reviewer-facing notes, not customer-facing metadata. |

## Required And Editable Caveat

Required, localizable, and editable status depends on the App Store surface,
platform, app status, and version state. If the current account state is not
available, report field-level validation separately from editability.

## URL Fields

For support, marketing, privacy, and privacy choices URLs:

- include the full URL with protocol
- use a public URL the reviewer or customer can access
- do not invent support, privacy, or data-rights claims
