# Eval fixtures

Durable inputs for qualitative review or isolated paired evals. Results stay in
the producer-owned ignored eval workspace, outside this package.

## long-card-title

Target behavior: long card title.

Input prompt: "Render a social card for sample-appstoreconnect. Keep its full name and summary readable."

Context and files:

- Use a licensed input font and fixture icon; default text width. Also test a longer multi-segment name and adjacent separators.

Expected output:

- Try a single-line title from maximum down to the stated minimum; use balanced separator boundaries only when necessary. Never leave a dangling hyphen or split arbitrary letters.

Forbidden behavior:

- Special-case a repository name, split off a short prefix ending in a hyphen, truncate text or shrink About.

Acceptance checks:

- Layout receipt shows one-line sample-appstoreconnect within its width, title at least minimum, complete About at 32 px in at most three lines; narrower multi-segment names wrap legibly.

Baseline expectation:

- A fixed-size title renderer can produce an orphaned prefix or clipping.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## social-card-icon

Target behavior: social card icon validation and embedding.

Input prompt: "Render our social preview using this accepted PNG app icon, then check that the exported card is current."

Context and files:

- A project recipe, licensed fonts and a square 1024 px PNG app icon. Exercise
  JPEG and WebP variants, an outlined SVG containing an embedded raster, nested
  XHTML iframe/srcdoc and img/srcset, MathML, unknown SVG elements and attributes,
  style declarations, external presentation URLs, animation and metadata with
  foreign children. Include a real app-icon PNG and a generated framework-logo
  SVG, a nonsquare raster, an unsupported format and a 256 px raster at the
  default icon size. Include corrupt PNG pixel streams with valid chunk
  checksums, truncated JPEGs and a corrupt later animation frame, both as files
  and embedded SVG images.

Expected output:

- Preserve the accepted icon's exact bytes in a base64 image data URI at the
  recipe's icon position and size. Accept self-contained SVGs with PNG, JPEG or
  WebP base64 images; report clear validation failures for invalid inputs.

Forbidden behavior:

- Replace the icon's style, upscale a small raster, allow other non-fragment
  references or active SVG content, or overwrite exports during `--check`.

Acceptance checks:

- Decoding the card's raster data URI reproduces the input file byte for byte;
  the layout receipt records that file's SHA-256.
- Square rasters at or above `icon_size` pass; nonsquare, too-small, unsupported
  and corrupt rasters fail. Each raster is verified and fully decoded in every
  frame. SVGs retain only allowlisted SVG-namespace elements, attributes and
  value functions. Metadata contents are dropped. Only `use` accepts fragment
  links and only `image` accepts matching PNG, JPEG or WebP base64 data links;
  attribute `url()` references must be fragments. Foreign namespaces outside
  metadata, unknown elements/attributes, styles, animation, scripts and live
  text fail at every depth. DOCTYPE/entity declarations and processing
  instructions fail in UTF-8 and UTF-16 input.
- Both real icon types still render complete social cards with deterministic
  receipts and unchanged icon pixels compared with their source exports.
- Repeated renders and `--check` are deterministic. Changing icon bytes,
  including metadata alone, causes `--check` to fail without changing exports.

Baseline expectation:

- A blocklist can admit foreign-namespace elements or attributes carrying
  active content; structure-only raster checks can accept undecodable pixels.

Evidence sources:

- Input bytes, generated SVG and layout receipt, validation errors and command
  exit codes.

Owner notes:

- Fixture images are synthetic; their dimensions are case inputs. The minimum
  accepted raster dimensions come from the recipe's rendered icon size.

## open-source-app-readme

Target behavior: open-source app README layout.

Input prompt: "Lay out the README of example-team/parcel-app, an open-source macOS app shipped as a notarized DMG and a Homebrew cask, with a bundled CLI. The information set is attached; no DESIGN applies."

Context and files:

- `evals/files/open-source-app.json`: download channels with checksum and
  cask, the released build's requirements, capabilities, first-run steps,
  permissions, privacy statement and policy, support, release notes, the
  bundled CLI, building from source and license, each with its owner. No
  DESIGN applies, so project defaults are chosen and recorded.

Expected output:

- Use the app layout: header, download block with the DMG and checksum, the
  cask and a requirements line, light/dark screenshots planned from the
  released build, what you can do, getting started, permissions and privacy
  with the privacy policy link, support, release notes, building from source,
  Contributing and License, plus a short bundled CLI section. Use supplied
  values unchanged and report a missing statement instead of inventing it.

Forbidden behavior:

- Use the library or CLI skeleton for the whole page, invent requirements or
  asset names, or lead with build instructions.

Acceptance checks:

- The section order follows the app readers, every statement matches the
  information set, the social preview follows the shared rules, and
  screenshots are planned in light and dark.

Baseline expectation:

- A README designer may reuse a library skeleton for an app.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## closed-source-app-readme

Target behavior: closed-source app README layout.

Input prompt: "Lay out the README for example-team/parcel-ios, a closed-source iOS app on the App Store, in a private repository. The information set is attached; no DESIGN applies."

Context and files:

- `evals/files/closed-source-app.json`: store link and official badge
  artwork, requirements, the store screenshot set, capabilities, permissions,
  privacy statement and policy, terms, support and release notes, each with
  its owner. No DESIGN applies.

Expected output:

- Use the same app layout with the official App Store badge artwork unchanged,
  the store screenshot set, and the supplied privacy statements and policy
  link; link the terms instead of build, Contributing and License sections.
  Private visibility changes nothing else.

Forbidden behavior:

- Skip the design because the repository is private or closed source, alter
  official badge artwork, or add build-from-source steps.

Acceptance checks:

- The response keeps the app layout, places the privacy policy in the
  permissions and privacy section, and replaces source sections with terms.

Baseline expectation:

- A README designer may treat a private or closed-source repository as out
  of scope.

Evidence sources:

- Executor output, command trace, generated artifacts and captured observations.

Owner notes:

- Fixture values are synthetic inputs, not reusable project conventions.

## shared-profile-rendering

Target behavior: Render both organization views with catalog-owned icons and groups.

Input prompt: "Render our public and maintainer profiles from the supplied catalog, member input and DESIGN recipe."

Context and files:

- Neutral inputs in tests/fixtures/profile; full catalog pin and matching digest, two job groups and all three release states.

Expected output:

- Use render_profile.py for both layouts with one icon per row, the four documented sizes unless overridden, live badges/fallbacks and correct relative-link rebasing. Return byte checks and light/dark review scope.

Forbidden behavior:

- Omit row icons, duplicate catalog groups in member input, insert policy/status prose, permit active link schemes or claim placeholder hosts were live-tested.

Acceptance checks:

- Both goldens and --check pass; CI badge URLs carry each member input's declared default branch; missing/extra operational members, stale digests, hostile markup and unsafe schemes fail or escape as documented.

Baseline expectation:

- An organization-specific generator can lose icons or drift between the two inventories.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.
