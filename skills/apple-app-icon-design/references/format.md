# Design Entry

The owner's `DESIGN.md` holds one JSON block under `## Iconography`. App icon
entries live under `app_icons`; other consumers may use other keys in that
block. Each entry's key is its output name.

```json
{
  "app_icons": {
    "example-studio": {
      "background": "#3565CA",
      "gradient": true,
      "groups": [{
        "layers": [{"source": "layers/foreground.svg", "name": "Foreground"}],
        "shadow": {"kind": "neutral", "opacity": 0.5},
        "translucency": {"enabled": true, "value": 0.3}
      }],
      "styles": {
        "liquid-glass": {"design_generation": 26},
        "flat": {},
        "mac-tile": {"unclipped": [1]},
        "gloss": {"groups": [{"layers": [{"source": "layers/gloss-foreground.png"}]}]}
      }
    }
  }
}
```

## Fields

| Field | Contract |
| --- | --- |
| `background` | Required opaque `#RRGGBB` color. Also supplies the background of style renderings and web icons. |
| `gradient` | Optional boolean, default false. Liquid Glass uses Icon Composer's automatic gradient from the background color; style renderings blend from 20% white at the top to the background color at the bottom. |
| `groups` | One to four material groups in back-to-front order, shared by every style. |
| `maskable_scale` | Foreground scale for the 512 px maskable web image. Default and maximum 0.56, fitting a square inside the central 80%-diameter safe circle. |
| `styles` | Optional object of styles to render: `liquid-glass`, `flat`, `mac-tile`, `gloss`. Default `{"liquid-glass": {}}`. |

Every group has a nonempty `layers` list in back-to-front order. The generator
converts both group and layer order to Icon Composer's front-to-back format;
style renderings and web icons retain the input's painting order. Each layer
supplies a `source` path relative to DESIGN.md and an optional display `name`,
plus the optional native materials described below.
SVG layers need `viewBox="0 0 1024 1024"`, with text converted to paths and no
external file dependencies. PNG layers are 1024 px square. Supply
transparency around the foreground; the renderer owns the background and
final mask.

Optional group fields mirror the native material controls:

- `name`: a descriptive group name, also used in lint findings.
- `blend-mode`: `normal`, `plus-lighter`, `plus-darker`, `overlay`, `multiply`,
  `soft-light`, `hard-light`, `darken`, `lighten`, or `screen`.
- `specular`: boolean, enabling or disabling native specular highlights.
- `opacity`: a number from 0 to 1.
- `shadow`: `{"kind": "neutral", "opacity": 0.5}`. Kind is `neutral`,
  `layer-color` (chromatic), or `none`; opacity is 0–1.
- `translucency`: `{"enabled": true, "value": 0.3}`.
- `blur-material`: a strength from 0 to 1.
- `refractivity`: `{"enabled": true, "strength": 0.5, "depth": 0}`.

Optional layer materials:

- `fill`: exactly one of `{"automatic-gradient": "#RRGGBB"}` or
  `{"solid": "#RRGGBB"}`. Both accept six-digit RGB or eight-digit RGBA hex,
  converted to native sRGB components. Alpha is independent of layer opacity.
- `opacity`: a number from 0 to 1.
- `fill-specializations`: a nonempty object mapping `default`, `dark`, and/or
  `tinted` to fills of the same shape. `fill` supplies the inherited fill;
  without it, native artwork behavior supplies the fallback. `default`
  overrides only Default, `dark` only Dark, and `tinted` both Tinted and Clear
  appearances. These are native appearance families, not platform overrides.

For example, an original layer can use a gradient normally and a dimmer solid
fill in Dark:

```json
{
  "source": "layers/foreground.svg",
  "fill": {"automatic-gradient": "#B38AFF"},
  "opacity": 0.85,
  "fill-specializations": {
    "dark": {"solid": "#7155AA"},
    "tinted": {"solid": "#CCCCCC"}
  }
}
```

Unknown fields, fill kinds, appearance names, and enum values are errors;
booleans are not numbers. Material fields are serialized only into the native
`.icon`. They do not recolor or fade the source artwork in other styles, their
web icons, sheets, or drift checks. Liquid Glass masked web PNGs continue to
come from the native iOS Default export; its SVG favicon and full-bleed web
images retain their existing artwork composition.

These controls were rendered with Icon Composer 27.0 (129), with appearance
specializations checked in design generations 26 and 27. See the
[probe results](rendering.md#native-material-schema). Native rendering must
validate them for the selected tool version; a JSON document alone is not
proof of material behavior. Start with defaults and inspect appearance
exports before adding blur or refraction. Style renderings ignore material
controls.

## Styles

Each style object accepts only its own fields; unknown styles and fields are
errors.

| Style | Fields |
| --- | --- |
| `liquid-glass` | `design_generation`: 26 or 27, passed to Icon Composer. Omitted, the renderer chooses; record it for assets that must stay fixed. `groups`. |
| `flat` | `groups`. |
| `mac-tile` | `unclipped`: distinct 1-based positions of this style's groups, back to front. Those groups are not clipped to the tile; their artwork may extend past the 1024 box up to the canvas edge. `groups`. |
| `gloss` | `groups`. |

`groups` in a style replaces the shared groups for that style only, for
example with raster texture art that a skeuomorphic style needs. Positions in
`unclipped` refer to the style's own groups.

Source filenames never become dependencies outside the generated `.icon`:
the generator copies the artwork into `Assets/` and gives it ordered names.
The generated document contains no source filesystem paths.
