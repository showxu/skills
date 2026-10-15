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
supplies a `source` path relative to DESIGN.md and an optional display `name`.
SVG layers need `viewBox="0 0 1024 1024"`, with text converted to paths and no
external file dependencies. PNG layers are 1024 px square. Supply
transparency around the foreground; the renderer owns the background and
final mask.

Optional group fields mirror the native material controls:

- `name`: a descriptive group name, also used in lint findings.
- `shadow`: `{"kind": "neutral", "opacity": 0.5}`.
- `translucency`: `{"enabled": true, "value": 0.3}`.
- `blur-material`: a strength from 0 to 1.
- `refractivity`: `{"enabled": true, "strength": 0.5, "depth": 0}`.

These controls were inspected in Icon Composer 27. Native rendering must
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
