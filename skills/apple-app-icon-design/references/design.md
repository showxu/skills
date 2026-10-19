# Design Guidance

Quoted guidance comes from Apple's
[Human Interface Guidelines for app icons](https://developer.apple.com/design/human-interface-guidelines/app-icons).
Lint thresholds are this skill's heuristics, named as such in
[rendering](rendering.md#lint).

## Concept

- Find the one idea that captures what the product does and make it the
  icon's core. Apple advises expressing it "with a minimal number of shapes."
- Prefer an illustration to a photo, and do not reproduce interface
  components, screenshots, or Apple hardware.
- Include text only when it is essential to the brand. A single letter can
  serve as a mnemonic; words such as "New" or "Play" do not belong.
- Keep the design consistent across every platform and style it ships in.

For each concept, write a short brief: the idea, the silhouette people should
recognize at 32 px, two or three colors, and the layer plan.

## Composition

- Keep primary content centered so masks and corner changes never truncate
  it. Platform masks differ: rounded squares for iOS, iPadOS, and macOS,
  circles for watchOS and visionOS.
- A simple background works best: a solid color or a gradient from the
  entry's `background`. The canvas does not need to be filled.
- Leave breathing room. For the maskable web icon, essential content must
  fit the central safe circle at `maskable_scale`.

## Layers

- The background color is not a layer. Foreground groups stack back to
  front; Icon Composer accepts up to four.
- Depth comes from overlap: Apple suggests "filled, overlapping shapes",
  especially with transparency and blur, to give an icon depth. Shapes that
  never overlap read as flat in every style.
- In Liquid Glass, depth reads where a colored element lies under a glass
  element. The color shows through only where the glass layer's fill alpha
  (`#RRGGBBAA`) or opacity is below 1; translucency alone barely tints it, and
  refraction needs `design_generation` 27. See
  [glass color and rim](rendering.md#glass-color-and-rim).
- Give each foreground shape clearly defined edges. Avoid soft or feathered
  edges, which spoil system highlights and shadows.
- Avoid extremely thin lines and sharp corners; they lose detail at small
  sizes.
- Vary opacity in Icon Composer rather than in the artwork, so translucency
  can be previewed against system effects.
- Do not paint specular highlights, drop shadows, bevels, blurs, or glows.
  Liquid Glass adds them dynamically, and style renderings add their own.
- Group layers that should share one material.

## Color and Appearances

- Prefer the owner's brand tokens. Pick a background that lets the
  foreground stand out.
- iOS, iPadOS, and macOS show default, dark, clear, and tinted appearances.
  Keep the core features identical in each. Clear and tinted appearances
  remove most color, so each group needs a lightness difference from the
  background and from groups it overlaps.
- Base dark variants on the light design with complementary, less bright
  colors. Avoid a black background on watchOS.
- Use native fill and opacity specializations when automatic appearance
  treatment loses the intended contrast. Tune group materials per appearance
  where needed, and compare every rendition to confirm the change stays in
  its intended family. Clear and Tinted share one specialization family;
  their light and dark renditions still need separate visual inspection.

## Drafting Layers

When the skill drafts artwork:

- Write one SVG per layer with `viewBox="0 0 1024 1024"`, filled paths, no
  text elements, no external references, and no clip to the icon shape.
- Use the layer plan's back-to-front order, and keep each group's shapes in
  that group's file or files.
- Choose artwork colors for the SVG style renderings. Give Liquid Glass layers
  native `automatic-gradient` fills where color should respond to material
  shading, or `solid` fills where a uniform color is intentional. Layer opacity
  and group blend modes control native overlap: Multiply darkens, Screen and
  Plus Lighter brighten, and Soft/Hard Light alter contrast. Use restrained
  translucency and refraction for glass, then verify the result at small sizes
  and across appearances. See the [Apple icon material study](rendering.md#apple-icon-material-study).
  These native controls leave the SVG artwork and other styles unchanged.
- Draw continuous-corner rectangles with `--continuous-rect`. Corners joined
  by hand draw a stray segment wherever their departures exceed the edge; see
  [continuous rectangles](rendering.md#continuous-rectangles).
- Keep background line art about 20 px inside the outline on the 1024
  canvas, or taper it deliberately into the rim: the Liquid Glass rim is
  wider and softer than the macOS 11–15 tile edge.
- For `mac-tile`, artwork may extend beyond the 1024 box only in a group
  listed in `unclipped`; every other style crops it at the art boundary.
- Mark drafted art as original and keep it with the owner's assets.

## Grid Backdrop

A design grid behind the foreground suits developer and design tools. It is a
generic motif, not a copy of any app's icon; the idea and foreground stay
original. `--grid-backdrop` prints the layer with the defaults below, and
`KEY=VALUE` arguments override `lines`, `width`, `inset`, `radius`, `turn`,
and `opacity`.

- Three vertical and three horizontal lines at 25%, 50%, and 75% of the
  canvas, 10 px wide, in solid white.
- Only the four corner cells carry an outer edge. The middle lines run into
  the rim, and the outer lines begin where the corner edges turn into them.
  A full inner border, or cell edges along the rim, doubles the white edge,
  because the glass rim already is the edge.
- Each corner edge is a continuous corner of radius 189 inset 25 px from the
  canvas edge, cut where it meets the outer lines and turned into them within
  30 px. Against the Liquid Glass outline its gap tapers from about 22 px at
  the turn to about 3 px on the diagonal, so the edge seems to peel out of the
  rim. A constant gap looks stiff; a gap that closes too early fuses the whole
  edge into the rim.
- A corner cell spans 231 px, yet radius 189 departs 289 px along each edge;
  a plain rounded rectangle would draw a stray segment, so the helper builds
  the cells from [continuous rectangles](rendering.md#continuous-rectangles).
- Give the grid its own group with specular off and no shadow, and fade the
  layer natively. With specular on, design generation 27 renders the lines as
  embossed glass tubes.

```json
{
  "name": "Grid",
  "specular": false,
  "shadow": {"kind": "none", "opacity": 0},
  "layers": [{"source": "layers/grid.svg", "opacity": 0.2}]
}
```

Style renderings ignore native opacity. When `flat`, `mac-tile`, or `gloss`
ships too, give that style a `groups` override whose grid layer comes from
`--grid-backdrop opacity=0.2`. Lint measures the solid artwork, so it reports
the lines as narrower than 1 px at 32 px, the corner edges as crossing the
outline on the diagonal, and a light foreground over the grid as too close in
lightness. The texture is meant to fade at small sizes and to meet the rim;
record these findings as owner decisions rather than thickening the lines.

## Families

When several products share a family, keep one style, one corner geometry,
and one layering approach, and give each member a distinct hue and
silhouette. Render the family together with `--sheet` and check that no two
members are confused at 32 px.
