---
version: alpha
name: example-studio
description: Visual identity for example-studio repository pages and icons.
colors:
  primary: "#2a7fd6"
  ink: "#1d1d1f"
  surface: "#fbfbfd"
typography:
  card-title:
    fontFamily: Inter Display
    fontSize: 76px
    fontWeight: 700
rounded:
  none: 0px
components:
  social-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.card-title}"
    rounded: "{rounded.none}"
  readme-logo:
    size: 160px
---

# example-studio Design

## Overview

Repositories share front-facing tile icons with one hue per repository.
Tools use flat tiles; libraries with physical ideas use volumetric tiles.

## Colors

- **Primary** is the studio icon's tile color.
- **Ink** and **Surface** set text and background on generated cards.

## Typography

Generated cards use Inter Display converted to outlines.

## Shapes

Icons are tiles with continuous corners.

## Components

- **README logo**: 160 px, centered above the repository name.

## Do's and Don'ts

- Do give each repository its own hue.
- Don't put text inside icons.

## Iconography

```json
{
  "icons": {
    "example-studio": {"style": "flat", "hue": 232, "glyph": "tiles", "glyph_scale": 0.30},
    "example-cli": {"style": "flat", "hue": 150, "glyph": "prompt"},
    "example-layout": {"style": "volumetric", "hue": 196, "glyph": "chevrons", "texture": "grid", "glyph_scale": 0.28},
    "example-intents": {"style": "volumetric", "hue": 300, "face": "light",
                        "objects": [{"x": -0.16, "y": 0.10, "w": 0.34, "h": 0.42, "color": 10},
                                    {"x": 0.0, "y": -0.02, "w": 0.34, "h": 0.42, "color": 275},
                                    {"x": 0.16, "y": -0.14, "w": 0.34, "h": 0.42, "color": 190, "opacity": 0.8}]}
  }
}
```
