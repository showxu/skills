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

## Drafting Layers

When the skill drafts artwork:

- Write one SVG per layer with `viewBox="0 0 1024 1024"`, filled paths, no
  text elements, no external references, and no clip to the icon shape.
- Use the layer plan's back-to-front order, and keep each group's shapes in
  that group's file or files.
- Use flat fills. A gradient belongs to the background color, or to Icon
  Composer for Liquid Glass.
- For `mac-tile`, artwork may extend beyond the 1024 box only in a group
  listed in `unclipped`; every other style crops it at the art boundary.
- Mark drafted art as original and keep it with the owner's assets.

## Families

When several products share a family, keep one style, one corner geometry,
and one layering approach, and give each member a distinct hue and
silhouette. Render the family together with `--sheet` and check that no two
members are confused at 32 px.
