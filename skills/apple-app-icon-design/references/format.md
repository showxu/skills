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
| `web_dark` | Optional boolean, default false. For `liquid-glass` exports, also writes five masked PNGs under `web/dark/` from the native iOS Dark rendition. Other styles and document-only output are unaffected. |
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
  `chromatic`, `layer-color`, or `none`; opacity is 0–1. `chromatic` names the
  chromatic shadow and is an alias for native `layer-color`. Both spellings
  serialize as `layer-color`, including appearance overrides.
- `translucency`: `{"enabled": true, "value": 0.3}`.
- `blur-material`: a strength from 0 to 1.
- `refractivity`: `{"enabled": true, "strength": 0.5, "depth": 0}`.

Optional layer materials:

- `fill`: exactly one of `{"automatic-gradient": "#RRGGBB"}` or
  `{"solid": "#RRGGBB"}`. Both accept six-digit RGB or eight-digit RGBA hex,
  converted to native sRGB components. Alpha is independent of layer opacity.
- `opacity`: a number from 0 to 1.

### Appearance overrides

Each group material above supports a corresponding `-specializations` field:
`blend-mode-specializations`, `specular-specializations`,
`opacity-specializations`, `shadow-specializations`,
`translucency-specializations`, `blur-material-specializations`, and
`refractivity-specializations`. Layers support `fill-specializations` and
`opacity-specializations`.

Each is a nonempty object mapping `default`, `dark`, and/or `tinted` to values
of exactly the same type and range as the base field. Structured values such
as shadows replace the whole value, so every required member must be supplied.
The base field supplies the inherited value; when omitted, Icon Composer's
native default applies (the artwork for a layer fill). `default` overrides
only Default, `dark` only Dark, and `tinted` both Tinted and Clear appearances.
These are native appearance families, not platform overrides. Clear has no
separate specialization key. Refraction requires design generation 27 for a
visible effect in the verified renderer; generation 26 ignores both its base
value and overrides.

For example, an original layer can use a gradient normally and a dimmer solid
fill in Dark:

```json
{
  "source": "layers/foreground.svg",
  "fill": {"automatic-gradient": "#B38AFF"},
  "opacity": 0.85,
  "opacity-specializations": {"dark": 1},
  "fill-specializations": {
    "dark": {"solid": "#7155AA"},
    "tinted": {"solid": "#CCCCCC"}
  }
}
```

The same pattern applies to a group's opacity and other materials, for example
`"opacity": 0.8, "opacity-specializations": {"dark": 1}` or
`"shadow-specializations": {"tinted": {"kind": "none", "opacity": 0}}`.

Unknown fields, fill kinds, appearance names, and enum values are errors;
booleans are not numbers. Material fields are serialized only into the native
`.icon`. They do not recolor or fade the source artwork in other styles, their
web icons, sheets, or drift checks. Liquid Glass masked web PNGs continue to
come from the native iOS Default export; its SVG favicon and full-bleed web
images retain their existing artwork composition. With `web_dark: true`, the
additional files are `web/dark/favicon-16.png`, `web/dark/favicon-32.png`,
`web/dark/icon-192.png`, `web/dark/icon-512.png`, and
`web/dark/avatar-1024.png`. These are resizes of iOS Dark, preserving its native
mask; they do not replace the default set or add dark full-bleed touch/maskable
images or an SVG approximation. The manifest lists the additional files.

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
