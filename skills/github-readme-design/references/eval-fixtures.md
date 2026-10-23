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
  built executable and comparing only `recording.json` through validation's
  `demo` switch. Render/check SVGs locally and commit them.

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
- Describe local script → capture → render/check and demo-only CI recording
  comparison, with selections owned by the catalog.

Forbidden behavior:

- Give every kind a terminal or screenshots, invent a tap icon, add a website
  social-preview requirement, or claim native exports were reproduced in CI.

Acceptance checks:

- Every matrix row is represented; outputs use local regeneration checks,
  native outputs keep receipts, and local logo comparison targets the exports
  at the accepted standard. CI checks only the CLI recording.

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
  The declared devices and locales are available for local native capture.

Expected output:

- Define `.github/assets/screenshots/script.yml` scenes naming UI test,
  device, appearance and locale; record captures in `capture.json`; place
  driving code in the product's UI tests and apply DESIGN's background/frame
  to `<scene>-light.png` and `<scene>-dark.png`.
- Capture, render and check screenshots locally; keep a provenance receipt. Store screenshot sets may reuse the captures through their owner.

Forbidden behavior:

- Put UI-driving code in assets, invent visual values or tolerance numbers,
  require unavailable CI capture, or substitute a README video file.

Acceptance checks:

- Each scene has all four selectors, capture metadata and final appearance
  paths and local capture/check evidence. App Store screenshot ownership remains distinct.

Baseline expectation:

- A screenshot list may omit reproducible scenes or move product test code
  into presentation assets.

Evidence sources:

- Scene plan, file layout, UI-test ownership and local capture evidence plan.

Owner notes:

- Devices, locales and scene names are supplied case inputs.

## long-card-title

Target behavior: long card title.

Input prompt: "Render a social card for sample-appstoreconnect. Keep its full name and summary readable."

Context and files:

- Use the fixture DESIGN, catalog, licensed font and icon; derive the text width from DESIGN. Also test a longer multi-segment name and adjacent separators.

Expected output:

- Try a single-line title from maximum down to the stated minimum; use balanced separator boundaries only when necessary. Never leave a dangling hyphen or split arbitrary letters.

Forbidden behavior:

- Special-case a repository name, split off a short prefix ending in a hyphen, truncate text or shrink About.

Acceptance checks:

- The 1280×640 PNG shows one-line sample-appstoreconnect within its width, title at least 40 px, complete About at the fixture DESIGN size in at most three lines; narrower multi-segment names wrap legibly.

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

- A complete DESIGN, catalog, licensed fonts and a square 1024 px PNG app icon. Exercise
  JPEG and WebP variants, an outlined SVG containing an embedded raster, nested
  XHTML iframe/srcdoc and img/srcset, MathML, unknown SVG elements and attributes,
  style declarations, external presentation URLs, animation and metadata with
  foreign children. Include a real app-icon PNG and a generated framework-logo
  SVG, a nonsquare raster, an unsupported format and a 256 px raster at the
  fixture DESIGN icon size. Include corrupt PNG pixel streams with valid chunk
  checksums, JPEGs with truncated scan data but intact end markers, corrupt WebP
  pixel data, APNG and animated WebP, both as files and embedded SVG images.

Expected output:

- Render the accepted icon at DESIGN's position and size into the PNG with the
  pinned WebAssembly rasterizer. Accept PNG, JPEG and WebP, including validated
  embedded rasters in self-contained SVGs; report clear failures for invalid inputs.

Forbidden behavior:

- Replace the icon's style, upscale a small raster, allow other non-fragment
  references or active SVG content, or overwrite exports during `social-preview check`.

Acceptance checks:

- The internal SVG embeds PNG/JPEG bytes unchanged. WebP is decoded by pinned
  WebAssembly into a lossless PNG before rasterization. The output is 8-bit
  RGBA at 1280×640, with no text or time chunks.
- Square rasters at or above DESIGN's icon size pass; nonsquare, too-small, unsupported
  and corrupt rasters fail, including decoder warnings or recovered errors.
  Corrupt-stream failures name the file. Each still raster is fully decoded by WebAssembly.
  APNG and animated WebP fail with a message naming the icon file, including
  when embedded in SVG. SVGs retain only allowlisted SVG-namespace elements,
  attributes and value functions. Metadata contents are dropped. Only `use` accepts fragment
  links and only `image` accepts matching PNG, JPEG or WebP base64 data links;
  attribute `url()` references must be fragments. Foreign namespaces outside
  metadata, unknown elements/attributes, styles, animation, scripts and live
  text fail at every depth. DOCTYPE/entity declarations and processing
  instructions fail in UTF-8 and UTF-16 input.
- Both real icon types still render complete social cards without clipping.
- Repeated renders and `social-preview check` are deterministic. Pixel drift
  fails the byte check without changing exports and can produce a separate
  regenerated artifact. Metadata that does not affect pixels need not change
  the PNG.

Baseline expectation:

- A blocklist can admit foreign-namespace elements or attributes carrying
  active content; structure-only raster checks can accept undecodable pixels.

Evidence sources:

- Input bytes, internal SVG and output PNG, validation errors and command
  exit codes.

Owner notes:

- Fixture images are synthetic; their dimensions are case inputs. The minimum
  accepted raster dimensions come from DESIGN's rendered icon size.

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

Input prompt: "Render our public and maintainer profiles from the supplied catalog, member input, pinned standard revision and DESIGN."

Context and files:

- Neutral inputs in scripts/test/fixtures/profile; a full standard commit supplied
  through --catalog-revision, two job groups and all three release states.

Expected output:

- Use the TypeScript profile command for both layouts with one icon per row,
  the four required DESIGN component sizes, live badges/fallbacks and correct
  relative-link rebasing. Return local byte checks and light/dark review scope;
  commit the generated outputs.

Forbidden behavior:

- Omit row icons, duplicate catalog groups in member input, insert policy/status prose, permit active link schemes or claim placeholder hosts were live-tested.

Acceptance checks:

- Both unchanged Markdown goldens and profile check pass. CI badge URLs carry
  each member input's declared default branch. Missing/extra operational members,
  missing/invalid member revisions, hostile markup and unsafe schemes fail or
  escape as documented. Public rendering rejects a member revision; member input
  contains maintenance navigation and operational facts only.

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
  glyph, wide command/output lines, an over-long title, a non-px dimension,
  a fixed environment override, stderr, nonzero exit and a timeout. Include a
  directory or non-executable file supplied as the executable, nested destination and fixture symlinks,
  and SIGINT/SIGTERM before the first command and during managed filesystem work.
- Exercise FIFO, directory and symlink expectation/write targets, restrictive
  directory modes from commands and fixture copies, persistent removal errors,
  and signed, fractional and exponent CSS variation values.

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
  Missing glyphs identify the step; over-long titles fail with title context.
  Wide commands and output soft-wrap at whole glyphs within an 830 px canvas,
  preserving whitespace and color roles. Dim vector continuation markers sit
  in left padding without shifting columns, height includes added rows, and
  the description retains the unwrapped transcript. Exact fits stay on one row;
  recordings whose lines fit remain byte-identical.
  Lint diagnostics identify the file, token and rule. Environment overrides and
  unknown keys fail.
- A clean `terminal check` exits zero; an edited output line exits one naming
  its command, with a unified diff and a complete artifact directory. SVG-only
  drift names the file and DESIGN/renderer change. Usage errors exit two.
- Failure, assertion and timeout paths remove the sandbox. The fixture's
  `equals` assertion includes its exact final newline.
- Invalid executable paths fail before sandbox creation. Copies require fresh
  destinations; managed writes refuse destination symlinks at every depth.
  Fixture symlinks cannot escape `fixture/`. Errors identify the offending path.
- SIGINT and SIGTERM remove the sandbox throughout its lifetime, terminate any
  running command process group and return 130 and 143 respectively.
- Non-regular expectation/write targets fail before opening, naming the path.
  Cleanup restores directory permissions without following symlinks; any
  remaining removal failure names its path and exits nonzero.
- Variation numbers accept CSS signs, decimals and exponents. Malformed values
  and a `wght` setting fail; weight remains owned by `fontWeight`.

Baseline expectation:

- A recording that CI never executes can remain plausible after product
  behavior changes; live SVG text can vary with the viewer's installed fonts.

Evidence sources:

- Script, recording, golden SVG bytes, command output, CI matrix results and
  the accepted light/dark visual review.

Owner notes:

- Fixture styling and font bytes belong to this test case. Actual consumers
  supply their own pinned DESIGN and licensed fonts.

## recording-only-validation

Target behavior: Keep CI demo validation independent of rendering assets.

Input prompt: "Check the CLI demo in CI after a release build. DESIGN and fonts are unavailable, and the SVGs are stale; the recording is current."

Context and files:

- A built executable, terminal `script.yml` and committed `recording.json` exist. Also exercise a changed command output and missing executable/assets arguments.

Expected output:

- Use `github-workflows` ecosystem validation with `demo` enabled; it invokes `terminal check --recording-only` or the Action with `recording-only: true`. Matching recording passes; drift reports changed steps and the unified diff without modifying committed files.

Forbidden behavior:

- Require DESIGN/fonts/SVGs, compare profiles/social previews/screenshots in CI, add a presentation workflow/context, or skip re-recording the CLI.

Acceptance checks:

- Match exits 0, recording drift exits 1, invalid flag use and missing required arguments exit 2. Optional drift artifacts contain only recording.json. Full local check/render modes still work; profiles and images are locally checked and committed.

Baseline expectation:

- A rendering-dependent check may fail for image drift while missing whether the CLI demo is current.

Evidence sources:

- CLI/Action tests, exit codes, diff output and preserved committed files.

Owner notes:

- Repository names and paths are synthetic case inputs.
