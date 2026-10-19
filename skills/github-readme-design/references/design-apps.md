# App design

Use for a product the visitor downloads and runs: a desktop, mobile or menu
bar app, open or closed source, in a public or private repository. Apply the
DESIGN tokens and composition; this file sets the information hierarchy where
DESIGN is silent. The values come from the supplied information set. Badges,
the social preview and review follow [design](design.md) as for every product
kind.

## Readers

Order the page for first-time visitors deciding whether to download, then for
current users looking for help, then for contributors when the source is open.

## Default layout

1. **Header:** the DESIGN header image, or the app icon with the name and the
   accepted sentence, in light and dark.
2. **Download:** the primary channel first (official store badge, direct
   download of the released build with its checksum, Homebrew cask, or beta),
   followed by one line of requirements: system version, chip and devices.
   Use official store badge artwork unchanged, in the reader's language where
   a localized badge exists.
3. **Screenshots:** one primary screenshot in light and dark, then three to
   five feature rows, each one screenshot and one sentence. Capture from the
   released build and reuse the store screenshot set when one exists. Text in
   a screenshot stays legible at README width.
4. **What you can do:** three to six points that start with the outcome.
5. **Getting started:** install, open, grant permissions, first success; each
   step has an observable result.
6. **Permissions and privacy:** each permission next to the feature that needs
   it, data handling consistent with any store privacy label, and a link to
   the privacy policy when one exists.
7. **Support and feedback:** where to report a problem and what to include:
   app version and build, system version, device and diagnostics output. Add
   FAQ or contact links where they exist.
8. **Release notes:** a link to the release notes or What's New; no roadmap.
9. **Source and terms:** open source adds building from source, Contributing
   and License. Closed source links its terms and has no build or
   contribution sections.
10. **Languages:** a switch at the top linking each `README.<language>.md`.

Omit a section whose information does not exist.

## Variants

- **Menu bar app:** the primary screenshot shows the open menu.
- **Bundled CLI or MCP server:** a short section with the install path and one
  command; its full information follows [design](design.md).
- **Plugin ecosystem:** link the plugin catalog instead of listing plugins.
- **Beta only:** the download block offers only the beta and states its status.

## Consistency and images

The README sentence, the store listing and the product website make the same
claim. Screenshots come from the same capture set as the store, and stated
requirements equal the released build. Report a difference instead of choosing
one side silently.

Header and screenshot images use `<picture>` with light and dark sources and
alt text that describes what the image shows. Commit sources with their
exports and review the exact files in light and dark before publication.
