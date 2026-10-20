# Eval fixtures

Durable inputs for qualitative review or isolated paired evals. Results stay in
the producer-owned ignored eval workspace, outside this package.

## scripted-cli-quick-look

Target behavior: Make the CLI Quick look reproducible from the built product.

Input prompt: "Plan the Quick look assets and README markup for our CLI using the accepted session and DESIGN."

Context and files:

- Supplied CLI information, accepted DESIGN, a freshly built executable and
  session commands with optional fixture files. Planning only.

Expected output:

- Place `script.yml`, optional `fixture/`, committed `recording.json` and
  `terminal-light.svg`/`terminal-dark.svg` under `.github/assets/terminal/`.
  Use the documented recorder and renderer, with CI re-recording against the
  built executable and comparing the recording and both SVGs byte for byte.

Forbidden behavior:

- Hand-write captured output, treat rendering a stale recording as a CI
  re-record, or claim a planning response executed the toolchain.

Acceptance checks:

- README markup has `<picture>`, the dark `prefers-color-scheme` source,
  the light `<img>` fallback and meaningful session alt text at the standard
  paths. The plan links to the recording/rendering toolchain contract.

Baseline expectation:

- An image-only demo plan may keep plausible but stale output without
  checking what the current product actually prints.

Evidence sources:

- Asset plan, README markup and toolchain handoff.

Owner notes:

- Session content and DESIGN values arrive as inputs.

## product-kind-assets

Target behavior: Select assets by product kind and preserve source ownership.

Input prompt: "Prepare the presentation asset plan for our CLI, library, app, tap, organization profile and website from the supplied information sets and shared DESIGN."

Context and files:

- Accepted product kinds, icons and content for all six surfaces; the tap
  distributes the CLI and the website uses the organization identity.

Expected output:

- Apply the product-kind matrix: CLI terminal assets, app screenshots,
  library logo/social preview, tap product icon, organization profile assets
  and website organization icon. Use the standard kind directories and names.
- Describe script → capture → render and the corresponding CI comparison or
  native-export receipt, with selections owned by the catalog.

Forbidden behavior:

- Give every kind a terminal or screenshots, invent a tap icon, add a website
  social-preview requirement, or claim native exports were reproduced in CI.

Acceptance checks:

- Every matrix row is represented; reproducible outputs use regeneration
  checks, local native outputs keep receipts, and logo comparison targets the
  exports at the pinned standard.

Baseline expectation:

- A one-size asset checklist may generate unnecessary assets or lose native
  export provenance.

Evidence sources:

- Per-surface asset plan and declared input/CI ownership.

Owner notes:

- This tests selection and production contracts, not renderer execution.

## ui-test-screenshot-scenes

Target behavior: Keep screenshot scenes declarative and driving code in UI tests.

Input prompt: "Plan light and dark README screenshots of the app's editor for two locales and a device our CI cannot run. The accepted DESIGN supplies the frame and background."

Context and files:

- Accepted app information, UI tests, target devices, appearances and locales.
  Some scenes can run in CI; others require local native capture.

Expected output:

- Define `.github/assets/screenshots/script.yml` scenes naming UI test,
  device, appearance and locale; record captures in `capture.json`; place
  driving code in the product's UI tests and apply DESIGN's background/frame
  to `<scene>-light.png` and `<scene>-dark.png`.
- Regenerate with tolerance where CI can capture; verify a provenance receipt
  otherwise. Store screenshot sets may reuse the captures through their owner.

Forbidden behavior:

- Put UI-driving code in assets, invent visual values or tolerance numbers,
  require unavailable CI capture, or substitute a README video file.

Acceptance checks:

- Each scene has all four selectors, capture metadata and final appearance
  paths; CI-capable and local-capture scenes have the appropriate evidence
  contract. App Store screenshot ownership remains distinct.

Baseline expectation:

- A screenshot list may omit reproducible scenes or move product test code
  into presentation assets.

Evidence sources:

- Scene plan, file layout, UI-test ownership and capture/CI evidence plan.

Owner notes:

- Devices, locales and scene names are supplied case inputs.

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

## scripted-terminal

Target behavior: Reproducible terminal recording, outlined rendering and CI drift checks.

Input prompt: "Build our CLI, regenerate its light and dark README demo from
the supplied script and organization standard, then verify the committed assets."

Context and files:

- `scripts/test/fixtures/`: fixed recording, Google-format DESIGN front matter,
  licensed variable font, and a tiny executable/session fixture. The session
  exercises hidden setup, file writes, copies, empty output and assertions.
- Exercise an edited output line, added/removed steps, an SVG-only difference,
  a broken DESIGN reference, contrast warning, ambiguous fonts, an unsupported
  glyph, width overflow, a non-px dimension, a fixed environment override,
  stderr, nonzero exit and a timeout.

Expected output:

- Record the real built executable in the documented fixed environment; show
  only visible steps. Render both appearances from resolved DESIGN components,
  merging each dark component over its base, and outline the selected font
  variation without shaping. Return byte-check results and the visual-review
  scope, with complete regenerated artifacts when drift occurs.

Forbidden behavior:

- Fabricate successful output, rewrite varying data beyond home-path/trailing-LF
  normalization, invent missing terminal styling, install into an installed
  skill or globally, overwrite committed assets during check, or claim a local
  golden render proves GitHub visual acceptance.

Acceptance checks:

- `npm test` passes type checking and Node tests; both golden SVGs match bytes.
  Missing glyphs and overflow identify the step; lint diagnostics identify the
  file, token and rule. Environment overrides and unknown keys fail.
- A clean `terminal check` exits zero; an edited output line exits one naming
  its command, with a unified diff and a complete artifact directory. SVG-only
  drift names the file and DESIGN/renderer change. Usage errors exit two.
- Failure, assertion and timeout paths remove the sandbox. The fixture's
  `equals` assertion includes its exact final newline.

Baseline expectation:

- A recording that CI never executes can remain plausible after product
  behavior changes; live SVG text can vary with the viewer's installed fonts.

Evidence sources:

- Script, recording, golden SVG bytes, command output, CI matrix results and
  the accepted light/dark visual review.

Owner notes:

- Fixture styling and font bytes belong to this test case. Actual consumers
  supply their own pinned DESIGN and licensed fonts.
