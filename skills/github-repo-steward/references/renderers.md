# Deterministic renderers

Use a repository-owned renderer when it implements the accepted standard.
Otherwise the helpers here provide portable rendering primitives. Run them
from the repository being served. Python 3 is required; social outlines need
`fonttools`. PNG conversion uses `rsvg-convert` and pixel verification uses
Pillow. Install dependencies in that repository's producer-owned ignored
location, not in the skill source or the owner's global environment.

## Project inputs

Resolve the project's actual DESIGN.md into a small JSON presentation recipe;
do not assume any particular token key paths. Set `design_source` to its path
and `design_sha256` to the reviewed file's digest. The helper rejects a stale
binding. Commit this mapping with the project's renderer inputs. If DESIGN is
absent, omit both fields and use or override the neutral defaults below.
Paths are relative to the recipe. Source paths, font choices, output paths and
all project colors are inputs. No fonts or project assets are bundled here.
If a font is bundled by the served project, include its redistribution license
and source/digest; the card recipe requires a license file for the chosen fonts.

Card recipe fields:

```json
{
  "owner": "example-owner",
  "title": "example-tool",
  "about": "Inspect your data before shipping it.",
  "icon": "assets/logo.svg",
  "font_title": "fonts/title.ttf",
  "font_body": "fonts/body.ttf",
  "font_license": "fonts/LICENSE.txt"
}
```

The literals above are example inputs only. Defaults: canvas 1280×640, padding
64, icon square 384, text start x=512, text width=704, owner 28 px, title range
72 down to 40 px in integer steps, title maximum two lines, About 32 px and at
most three lines with a 44 px line height. Default background is white, title
and owner black, summary dark gray. Override `background`, `ink`, `muted`,
`title_max`, `title_min`, `text_x`, `text_width`, `icon_size` and `padding`
with accepted DESIGN values. Canvas and About size remain the card contract.
Unbreakable overflow fails instead of clipping or silently reducing type.

```sh
python3 <skill>/scripts/render_social.py --spec <recipe.json> --output <card.svg>
rsvg-convert -w 1280 -h 640 <card.svg> -o <card.png>
python3 <skill>/scripts/render_social.py --spec <recipe.json> --output <card.svg> --check
```

The SVG uses glyph outlines. A sibling `.layout.json` records title/About
lines, actual font size, dimensions and input digests. `--check` compares both
outputs and fails on drift without writing. Inspect both output images.

## Terminal recording

Capture commands in a controlled directory with actual exit codes and stdout.
Retain stderr and failures in provenance where needed; do not fabricate output
or silently relabel a failed command as successful. A demonstration of an
expected error may be prepared by the repository's own renderer with an
explicitly reviewed error contract; this helper accepts successful sessions.
Normalize private paths explicitly before publication and preserve a private
receipt of what was normalized. Reject control sequences rather than rendering
unreadable escapes.

The recording has `title` and a nonempty `commands` list. Each command has
`command`, `stdout`, `exit_code` (zero). A separate provenance JSON records the
source revision, executable digest/version, input/dependency revisions and
digests, toolchain, original command exit codes and any normalization. Keep it
beside the recording or in private evidence, never in README prose.

Terminal recipe accepts `design_source`/`design_sha256`, `font_family`,
`font_size`, `line_height`, `padding`, `radius`, `title_height`, `min_width`,
and `light`/`dark` color objects. Color roles are `surface`, `bar`, `border`,
`prompt`, `command`, `output`, `dim`. Defaults are a portable monospace family,
14 px type/21 px lines, 20 px padding, 10 px radius, 34 px title bar and 560 px
minimum width with neutral grayscale themes. These are overridable defaults,
not a project's visual identity. Render width accounts for wide Unicode cells.

```sh
python3 <skill>/scripts/render_terminal.py --record <record.json> --spec <recipe.json> --output-dir <demo-dir>
python3 <skill>/scripts/render_terminal.py --record <record.json> --spec <recipe.json> --output-dir <demo-dir> --check
```

Outputs are `Demo-light.svg` and `Demo-dark.svg`. Commit recording, recipe and
exports together; use `--check` in the project's CI. Helpers never execute the
recorded commands and never upload. Build/test outputs stay in the producer's
ignored directory, reused across runs and removed after the task.
