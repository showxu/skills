# Reference Matching

Use this method when the owner wants an icon to match the look of an existing
app icon: its line weight and spacing, how lines meet the rim, or its
proportions. Measure the reference and fit the parameters of original
artwork to it. Eyeballing parameters from a downscaled raster was off by
about 2x in practice; measured fitting is the default, not a refinement.

The reference informs numbers, never artwork. Do not trace, import, or ship
its shapes or pixels, and do not commit or redistribute the capture: keep it
in the task's ignored validation output and delete it with that output. The
idea, shapes, and composition stay the owner's. Apple icons remain references
only; a request to reproduce one is out of scope.

## 1. Capture the Displayed Rendition

Fit against the rendition the system actually displays. On macOS 26 and
later that is the Liquid Glass rendition, which
`NSWorkspace.shared.icon(forFile:)` returns. The bundle's `.icns` file is the
legacy macOS 11–15 tile rendition kept for earlier systems: its corner, edge,
and lack of a glass rim differ, and it may stop at 256 px. Draw the workspace
icon into a 1024 px bitmap:

```swift
import AppKit

// swift capture.swift APP OUTPUT.png
let arguments = CommandLine.arguments
let icon = NSWorkspace.shared.icon(forFile: arguments[1])
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
icon.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: arguments[2]))
```

The capture follows the current system icon appearance. Record it, with the
reference app and system versions, and compare with the same native
rendition: Default, Dark, Clear, or Tinted.

## 2. Map the Tile to the Canvas

macOS draws the tile at 100..923 px of a 1024 px icon, an 824 px square; both
renditions use that placement. Icon Composer exports and the artwork canvas
fill all 1024 px. Map a capture pixel to the canvas with
`canvas = (capture - 100) * 1024 / 824` on each axis, or place candidates
into the tile with the inverse.

Measured with Xcode 27.0 on macOS 27.0.1 (26A434): the mapped Liquid Glass
capture matched the mask of a native macOS export with alpha
intersection-over-union 0.9992; the `.icns` tile matched it at 0.9866,
because its outline is the legacy continuous corner.

## 3. Extract Line Art by Local Contrast

Glass shading, gradients, and the rim change the background luminance across
the icon, so a fixed luminance threshold picks up shading instead of lines.
Compute luminance, subtract a Gaussian-blurred copy, and use the residual as
the line-art map: positive for light lines, negative for dark ones. Choose a
blur several times wider than the lines. Apply the identical extraction to the
reference and every candidate.

## 4. Fit Parameters

1. Parameterize the original artwork: geometry such as line width,
   spacing, offset, angle, inset, and corner radius, and contrast such as
   opacity.
2. Render each candidate the way the reference is shown: a native export of
   the candidate `.icon` for the same platform, appearance, and design
   generation, mapped to the same canvas and extracted the same way.
3. Score geometry by zero-mean normalized cross-correlation of the two
   line-art maps inside a window free of foreground objects. Glyphs and panels
   change the local contrast around them and bias the fit.
4. Do not mask regions whose behavior matters. Where lines merge into the rim,
   keep that band inside the window; a fit that excludes it can match the
   interior and still end the lines wrongly at the edge.
5. Search coarse to fine: a grid over plausible values, then refinement
   around the best score.
6. Fit opacity and contrast last, with the geometry fixed. Correlation ignores
   amplitude: a map and any positive multiple of it score the same. Minimize
   the squared difference of the line-art maps over the same window instead.

Write the fitted values into the owner's artwork or generator and regenerate.
Keep the values and their scores in the task report; they belong to the
owner's design, not to this skill.

## 5. Verify

Accept a fit only after all three checks agree:

- **Overlay**: reference line art in red and the candidate in green on one
  image; matches turn yellow, and offsets show as colored fringes.
- **Junction crops**: 4–6x enlargements of the local-contrast map, with its
  contrast enhanced, where lines cross, end, or meet the rim.
- **Cross-sections**: raw luminance along a line across the line art in both
  images, comparing width, peak, and spacing. Raw profiles expose differences
  that the extraction can flatten.

Then inspect the regenerated icon on its contact sheet. The rim's width also
sets how close background line art may come to the outline; see
[glass color and rim](rendering.md#glass-color-and-rim).
