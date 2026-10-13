# Scripts

| Script | Purpose | Exit codes |
| --- | --- | --- |
| `design_icons.py DESIGN.md --list \| --out DIR \| --check NAME=FILE... \| --tints \| --sheet FILE` | Reads the `## Iconography` JSON block and lists, renders, verifies, or previews icons. | 0; 1 on drift or missing names with `--check`; errors exit non-zero with a message |
| `design_icons.py DESIGN.md --lint` | Checks each slab entry's resolved palette for a face-to-band seam, a dark face over light bands, or pastel colors, as a tab-separated report. | 0 when clean; 1 on any finding |
| `design_icons.py --fidelity REFDIR` | Compares each style's silhouette, ramp lightness and chroma, and slab side contrast with reference PNGs `icon-<name>.png` in `REFDIR`, as a tab-separated report. | 0 when every style has a measurement; non-zero for missing, invalid, or unusable references |
| `stack_logo.py --spec JSON --out FILE` | The generator: the three styles, palette and tile ramps, geometry including the continuous corner (`continuous_square`, `tile_path`), glyph library, textures, standing objects, and panels. Renders one icon from a JSON spec. | 0 |

Run `python3 -B scripts/test_design_icons.py` from this skill directory for
palette regression checks, including seam/pastel rejection, the explicit rose
ramp and bounded chroma preservation.

The generators use only the Python standard library. `--png`, previews, and
`--fidelity` need `rsvg-convert` (librsvg).

```bash
python3 scripts/design_icons.py DESIGN.md --tints
python3 scripts/design_icons.py DESIGN.md --out /tmp/icons --name swift-example --png
python3 scripts/design_icons.py DESIGN.md --sheet /tmp/sheet.svg && rsvg-convert -w 1600 /tmp/sheet.svg -o /tmp/sheet.png
python3 scripts/design_icons.py DESIGN.md --check swift-example=Documentation/Assets/Logo.svg
python3 scripts/design_icons.py DESIGN.md --lint
python3 scripts/stack_logo.py --spec '{"hue": 205, "glyph": "braces", "glyph_rotation": -45}' --out /tmp/try.svg
python3 scripts/stack_logo.py --spec '{"style": "volumetric", "hue": 196, "glyph": "chevrons", "texture": "grid"}' --out /tmp/tile.svg
python3 scripts/design_icons.py --fidelity /tmp/reference-icons
```

Output is deterministic: the same entry always produces the same bytes, which
is what `--check` relies on.

Fidelity references must be 256 px square, non-interlaced RGB or RGBA PNGs
with 8- or 16-bit channels. A report needs at least one measurable reference
per style. An empty directory or skipped images cannot establish fidelity.
