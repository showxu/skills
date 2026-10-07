# Official Authority

Use Apple sources as authority for App Store Connect state, limits, API
capability, and role behavior:

- App Store Connect API overview:
  https://developer.apple.com/documentation/appstoreconnectapi
- Apps API collection:
  https://developer.apple.com/documentation/appstoreconnectapi/apps
- Builds API collection:
  https://developer.apple.com/documentation/appstoreconnectapi/builds
- Review submissions API collection:
  https://developer.apple.com/documentation/appstoreconnectapi/review-submissions
- Beta App Review Submissions API collection:
  https://developer.apple.com/documentation/appstoreconnectapi/beta-app-review-submissions
- App and submission statuses:
  https://developer.apple.com/help/app-store-connect/reference/app-and-submission-statuses/
- App build statuses:
  https://developer.apple.com/help/app-store-connect/reference/app-build-statuses
- TestFlight overview:
  https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview

## Source Hierarchy

1. Current Apple documentation and observed App Store Connect behavior.
2. Official API schema, endpoint docs, and response fields.
3. Selected tool backend documentation or `--help`.
4. Community skills and examples.

## API Boundaries

- App Store Connect API changes production account data. Treat mutation
  endpoints as live operations.
- The Apps API manages existing apps. Apple's Apps API docs state that new app
  records are created on the App Store Connect website, not through the Apps
  API.
- Builds appear as API resources after they have been uploaded and processed by
  Apple tooling. Build creation/upload mechanics are outside this skill.
- Review submissions are first-class API resources and can include App Store
  versions, custom product page versions, app events, experiments, and other
  submission items.
- Beta app review submissions represent Apple's review of a TestFlight build
  before external testing.

## Backend Notes

- `asc` is a third-party CLI. Use it only as an optional backend and verify
  current flags with `--help`.
- Browser automation is an escape hatch for operations that Apple exposes only
  in the web UI. It must use a visible user-owned session and stop before final
  commit actions.
- Binary upload flows are not implemented here; this skill may only observe
  resulting build state after the upload appears.
