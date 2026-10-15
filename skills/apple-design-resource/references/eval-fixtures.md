# Apple Design Resource Eval Fixtures

Use these prompts to check routing and output boundaries.

## Should Trigger

- "Fetch all official Apple Design Resources we can reach and tell me what is available."
- "Find the official Product Bezels and badge/logo links from Apple Design Resources."
- "Refresh the Apple UI kit and app icon template catalog for iOS/macOS."
- "Probe whether the SF Pro, SF Symbols, Figma, and Sketch resource links are alive."
- "Download the direct Apple CDN design-resource archives with a 500 MB cap."
- "Archive every Apple design resource we can still download, including earlier
  production templates, with checksums."

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
- Direct downloads should be limited to files on Apple-owned hosts and skipped unless
  `--download-direct` is passed.
- Earlier releases appear only with `--include-previous`, under
  `Previous releases`, and only while Apple still serves them, from the CDN or
  the developer site's former download path; a redirected file appears once,
  at its current location, and nothing is downloaded from the Web Archive.
- Sketch library rows (`sketch://add-library`) gain a downloadable row for the
  disk image their feed publishes, in the same section; files on other
  Apple-owned hosts are downloads, while their help pages stay links.
- An archive run with `--downloads-dir` keeps Apple's file names, writes a
  merged `manifest.json` with SHA-256, ETag, and Last-Modified, and reuses
  unchanged files on the next run. Changed upstream content is saved beside
  the retained file, never over it, and listed with its `earlier_versions`.
- `--extract-dmg` without `--accept-license` fails before any network access;
  accepted extractions record the license agreement's title and SHA-256.
