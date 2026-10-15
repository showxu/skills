# Example Studio Design

## Overview

A blue app icon with two original overlapping panels, representing a workspace.
The panels stay separate so native materials can express their depth, and
the entry renders in every Apple app icon style.

## Iconography

```json
{
  "app_icons": {
    "example-studio": {
      "background": "#3565CA",
      "gradient": true,
      "groups": [
        {
          "name": "Back panel",
          "layers": [{"source": "layers/back.svg", "name": "Back"}],
          "shadow": {"kind": "neutral", "opacity": 0.5},
          "translucency": {"enabled": true, "value": 0.2}
        },
        {
          "name": "Front panel",
          "layers": [{"source": "layers/front.svg", "name": "Front"}],
          "shadow": {"kind": "neutral", "opacity": 0.5},
          "translucency": {"enabled": true, "value": 0.3}
        }
      ],
      "styles": {
        "liquid-glass": {"design_generation": 26},
        "flat": {},
        "mac-tile": {},
        "gloss": {}
      }
    }
  }
}
```
