---
version: alpha
name: example-org
description: Visual identity for example-org repository pages and icons.
colors:
  primary: "#2f6fde"
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
  org-icon-face:
    backgroundColor: "{colors.primary}"
  readme-logo:
    size: 160px
---

# example-org Design

## Overview

Repositories share an isometric stacked-slab icon style with one hue per
repository.

## Colors

- **Primary** is the organization icon's face color.
- **Ink** and **Surface** set text and background on generated cards.

## Typography

Generated cards use Inter Display converted to outlines.

## Shapes

Icons are rounded squares seen at an isometric angle.

## Components

- **README logo**: 160 px, centered above the repository name.

## Do's and Don'ts

- Do give each repository its own hue.
- Don't put text inside icons.

## Iconography

```json
{
  "icons": {
    "example-org": {"hue": 255, "mode": "glow", "bands": 3, "glyph": "tiles", "texture": "dots", "glyph_rotation": 0},
    "swift-example": {"hue": 150, "mode": "deepen", "bands": 3, "glyph": "braces", "texture": "lines", "glyph_rotation": -45},
    "example-cli": {"hue": 20, "mode": "deepen", "bands": 3, "glyph": "prompt", "texture": "grid", "glyph_rotation": -45}
  }
}
```
