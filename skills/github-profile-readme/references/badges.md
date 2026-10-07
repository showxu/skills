# Badges

## Split Badges

A static shields.io badge with an empty label puts the logo on a gray block and
the text on a colored block:

```text
https://img.shields.io/badge/-<text>-<hex>?style=flat&logo=<slug>&logoColor=white&labelColor=555
```

- In `<text>`, write `--` for a dash, `__` for an underscore, and `_` or `%20`
  for a space. Percent-encode other reserved characters.
- Use the brand color of the logo, from Simple Icons, so each badge matches its
  icon. Several brands are near-black; check they still read on GitHub's dark
  background.
- Contact badges can drop the service name and show only the handle. The logo
  already names the service, and the row gets shorter.

## Corner Radius

The style fixes the radius: `flat-square` and `for-the-badge` are square, `flat`
and `plastic` are slightly rounded, and `social` matches GitHub buttons.
There is no radius parameter, and GitHub strips CSS. A different radius needs
self-drawn SVG badges, which lose live counts such as followers.

## Missing Logos

Simple Icons removes some brand logos. Pass a custom logo as a data URI:

```python
import base64, urllib.parse

svg = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="#fff" d="..."/></svg>'
logo = "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode()
param = urllib.parse.quote(logo, safe=":;,")
```

- Bake the fill color into the SVG. `logoColor` does not recolor custom logos.
- Strip any `<title>` from the SVG.
- Percent-encode the whole value; a raw `+` or `/` breaks the query string.

## Dynamic Badges

- Followers: `https://img.shields.io/github/followers/<login>?style=flat&logo=github&label=Followers&color=<hex>`
- Stars beside a project name:
  `https://img.shields.io/github/stars/<owner>/<repo>?style=social` with
  `align="absmiddle"` on the `<img>`.
- View counters count every load, including previews and checks. Point
  previews at a throwaway id. Check which parameters a counter supports before
  styling it; some accept only color, style, and label.

## Rows And Alignment

- A badge row wraps when it is wider than the column, stranding one badge on a
  second line. Measure the row in the preview at the profile column width.
- Badges inline with text sit on the baseline unless aligned. Use
  `align="absmiddle"`; GitHub strips `style`, so `vertical-align` is not
  available.

## Checking Badge URLs

- shields.io rejects Python urllib's default User-Agent with 403. Check URLs
  with `curl` or send a browser User-Agent.
- On github.com, external images load through GitHub's image proxy, which gives
  up on slow upstreams. A badge that fails once right after publishing can be
  transient; reload once before treating it as broken.
