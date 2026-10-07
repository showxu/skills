# Apple Design Resource Eval Fixtures

Use these prompts to check routing and output boundaries.

## Should Trigger

- "Fetch all official Apple Design Resources we can reach and tell me what is available."
- "Find the official Product Bezels and badge/logo links from Apple Design Resources."
- "Refresh the Apple UI kit and app icon template catalog for iOS/macOS."
- "Probe whether the SF Pro, SF Symbols, Figma, and Sketch resource links are alive."
- "Download the direct Apple CDN design-resource archives with a 500 MB cap."

## Should Not Trigger Alone

- "Review this iOS screen against HIG." Use `apple-hig`.
- "Export the `square.and.arrow.up` SF Symbol as SVG." Use `sfsymbols-export`.
- "Apply the Apple Music DESIGN.md template." Use `design-md-template`.
- "Implement this Liquid Glass SwiftUI toolbar." Use SwiftUI implementation skills.
- "Prepare App Store screenshots for iPhone and iPad." Use App Store screenshot skills.

## Expected Catalog Facts

- The catalog should include source URL, fetch timestamp, resource rows, counts,
  generated snapshot path, and probe/download metadata when requested.
- Rows should keep section context and classify link kind plus resource family.
- Direct downloads should be limited to Apple CDN resources and skipped unless
  `--download-direct` is passed.
