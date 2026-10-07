# Rendering and Validation

## Native Tool

Use Icon Composer's export-capable `ictool`. The compiler found by
`xcrun ictool` can be a different program and may reject `--export-image`.
The script locates the renderer in the active Xcode application's bundled
Icon Composer, or accepts an explicit `--ictool` path or `IC_TOOL` variable.
It checks the tool's advertised export command before invoking it.

The renderer owns platform geometry and material effects. Export Default,
Dark, ClearLight, ClearDark, TintedLight, and TintedDark for iOS, macOS, and
watchOS. The output canvas is 1024 px for iOS/macOS and 1088 px for watchOS.
Inspect the circular composition at small size. The same artwork and some
appearance labels may produce identical exports on a platform; preserve
the native result and do not invent differences.

Apple's design workflow uses flat foreground layers, with the background and
materials applied by Icon Composer. Do not pre-mask layers or paint native
specular effects into them. See [Apple's workflow](https://developer.apple.com/videos/play/wwdc2025/361/).

## Web Geometry

The flat SVG uses two mirrored cubic segments per continuous corner. In
fractions of a square's side, the edge departure and control values are
`0.396305, 0.230261, 0.152117, 0.076058`. The native `.icon` document does not
contain this outline; native masks always come from the renderer.

Validate these constants by rendering the SVG outline at 1024 px and
comparing its alpha with a full-bleed solid `.icon` exported for iOS and
macOS. Acceptance is alpha intersection-over-union at least 0.999 and
contour deviation at most 0.5 px. Use the installed tool and record the
version with the local results. Compare with Apple's App Icon Template as
an independent reference. If a platform's export uses an inset, preserve
and measure that placement; do not assume the canvas is fully occupied.

With Icon Composer 27 and design generations 26 and 27, the measured iOS
and macOS exports share the same mask. The outline achieves alpha IoU
0.999767 and bidirectional contour deviation 0.3491 px at 1024 px, measured
on the 50% alpha contour using marching squares and point-to-segment distance.

The favicon has the continuous outline. The apple-touch-icon has no baked-in
mask. The maskable image has an opaque full-bleed background and scales the
foreground square by at most 0.56, placing it within a circle of radius 0.4
times the canvas width. Inspect it with circular and rounded-square crops.

## Drift

`--check` regenerates the selected icon into a temporary candidate and
compares the entire directory without writing into the target. It reports
`same`, `drift`, `missing`, and `extra`. PNG comparison ignores ancillary
metadata but includes dimensions and decompressed image payload. SVG,
document, and manifest comparisons are exact.

Use the same renderer and explicit `--design-generation` when maintaining a
fixed appearance. A tool upgrade can legitimately change native rendering;
review the new sheet before replacing published assets. Never mark a
renderer failure, missing image, or unavailable native preview as verified.
