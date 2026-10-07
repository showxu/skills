# Banner SVG

Commit the banner to the profile repository as two files,
`assets/banner-light.svg` and `assets/banner-dark.svg`, and switch them with
`<picture>`. A committed file cannot break the way a third-party banner
generator can.

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./assets/banner-dark.svg">
  <img alt="Name, role line." src="./assets/banner-light.svg" width="100%">
</picture>
```

Ship two files rather than one with an inner media query. Inside an SVG loaded
as an image, `prefers-color-scheme` follows the viewer's operating system, not
their GitHub theme.

## What Works Inside The Image

GitHub shows the SVG as an image, so:

- Works: shapes, gradients, `<text>`, and a `<style>` block with CSS
  `@keyframes` animations and media queries.
- Does not load: web fonts, external images, scripts, and links.

## Fonts

- Use system font stacks, such as
  `-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif`
  and `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`.
- Text width differs by platform. Leave at least 10% slack inside any box that
  holds text, and avoid effects that depend on exact text width.
- Outlining a font into paths makes rendering identical everywhere, but check
  the font license first. Apple's SF fonts are licensed for Apple-platform
  mockups, not for artwork like this.

## Size

The image is scaled to the column width. Rendered text size is:

```text
rendered px = font size x displayed width / viewBox width
```

Check both ends. With a 1200-wide viewBox, the desktop profile column of about
846 px scales by 0.7. A phone column of about 308 px scales by 0.26, so text
under 47 units renders below 12 px on phones. Keep the banner to a few large
elements rather than many small ones.

## Animation

- Run entrance animations once with `animation-fill-mode: forwards`, and keep
  them short.
- For a typing effect, put each character in its own `<tspan>` and stagger
  opacity. Do not clip by measured width; widths differ by font.
- Start a blinking cursor only after typing ends: one animation delays
  visibility, a second one blinks.
- Add `@media (prefers-reduced-motion: reduce)` that shows the final state with
  no animation.

## Source Hygiene

- Keep the file ASCII. Write symbols as numeric character references, such as
  `&#x276F;` for a prompt chevron and `&#x2588;` for a block cursor. Some
  editing tools corrupt multibyte characters, and a parse error shows as a
  broken image with no message.
- Validate with `xmllint --noout assets/banner-light.svg` after every edit.
- Check text contrast against each background, aiming for 4.5:1 for small text.

## Measuring

To check that text fits its box, load the SVG inline in a local page, then
compare `getBBox()` of each text element with its container. Do this at the
platform fonts you can reach, and report other platforms as unverified.
