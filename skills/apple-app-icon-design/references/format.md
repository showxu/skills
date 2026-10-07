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
      }]
    }
  }
}
```

## Fields

| Field | Contract |
| --- | --- |
| `background` | Required opaque `#RRGGBB` color. Also supplies the flat web background. |
| `gradient` | Optional boolean, default false. True uses Icon Composer's automatic native gradient from the background color. |
| `groups` | One to four material groups in back-to-front order. |
| `maskable_scale` | Foreground scale for the 512 px maskable web image. Default and maximum 0.56, fitting a square inside the central 80%-diameter safe circle. |

Every group has a nonempty `layers` list in back-to-front order. The generator
converts both group and layer order to Icon Composer's front-to-back format;
the web renderer retains the input's painting order. Each layer supplies a `source` path
relative to DESIGN.md and an optional display `name`. SVG layers need
`viewBox="0 0 1024 1024"`, with text converted to paths and no external file
dependencies. PNG layers are 1024 px square. Supply transparency around the
foreground; the renderer owns the background and final mask.

Optional group fields mirror the native material controls:

- `name`: a descriptive group name.
- `shadow`: `{"kind": "neutral", "opacity": 0.5}`.
- `translucency`: `{"enabled": true, "value": 0.3}`.
- `blur-material`: a strength from 0 to 1.
- `refractivity`: `{"enabled": true, "strength": 0.5, "depth": 0}`.

These controls were inspected in Icon Composer 27. Native rendering must
validate them for the selected tool version; a JSON document alone is not
proof of material behavior. Start with defaults and inspect appearance
exports before adding blur or refraction.

Native foreground layers receive glass effects through their group. Static
web assets deliberately flatten the original art over the base color; they
do not reproduce native lighting or material controls. The 1024 avatar is
the native iOS Default export.

Source filenames never become dependencies outside the generated `.icon`:
the generator copies the artwork into `Assets/` and gives it ordered names.
The generated document contains no source filesystem paths.
