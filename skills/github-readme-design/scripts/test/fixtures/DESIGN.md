---
version: alpha
name: agents-tools
description: Visual identity of the agents-tools organization and its repositories.
colors:
  primary: "#3B35D1"
  primary-dark: "#8F8AFF"
  ink: "#16143D"
  ink-dark: "#F1F0FF"
  terminal-surface: "#FBFBFE"
  terminal-surface-dark: "#0E0F24"
  terminal-bar: "#F0EFF8"
  terminal-bar-dark: "#16183A"
  terminal-border: "#DCDBEA"
  terminal-border-dark: "#2A2C55"
  terminal-output: "#3F3D5C"
  terminal-output-dark: "#C8C7E6"
  terminal-dim: "#67657F"
  terminal-dim-dark: "#8785AE"
  social-preview-background: "#F5F4FF"
  social-preview-muted: "#4F4C7A"
typography:
  terminal:
    fontFamily: Google Sans Code
    fontSize: 14px
    fontWeight: 400
    lineHeight: 21px
    fontVariation: "'MONO' 1"
  social-preview-title:
    fontFamily: Google Sans Code
    fontWeight: 700
    fontVariation: "'MONO' 0"
  social-preview-owner:
    fontFamily: Google Sans Code
    fontWeight: 500
    fontVariation: "'MONO' 0"
  social-preview-body:
    fontFamily: Google Sans Code
    fontWeight: 400
    fontVariation: "'MONO' 0"
rounded:
  terminal: 10px
spacing:
  terminal-padding: 20px
  terminal-title-bar: 34px
  terminal-min-width: 560px
  hairline: 1px
components:
  terminal:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.terminal-output}"
    typography: "{typography.terminal}"
    rounded: "{rounded.terminal}"
    padding: "{spacing.terminal-padding}"
    width: "{spacing.terminal-min-width}"
  terminal-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.terminal-output-dark}"
  terminal-frame:
    backgroundColor: "{colors.terminal-border}"
    size: "{spacing.hairline}"
  terminal-frame-dark:
    backgroundColor: "{colors.terminal-border-dark}"
  terminal-title-bar:
    backgroundColor: "{colors.terminal-bar}"
    textColor: "{colors.terminal-dim}"
    height: "{spacing.terminal-title-bar}"
  terminal-title-bar-dark:
    backgroundColor: "{colors.terminal-bar-dark}"
    textColor: "{colors.terminal-dim-dark}"
  terminal-prompt:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.primary}"
  terminal-prompt-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.primary-dark}"
  terminal-command:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.ink}"
  terminal-command-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.ink-dark}"
  social-preview:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.ink}"
    typography: "{typography.social-preview-title}"
  social-preview-owner:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.ink}"
    typography: "{typography.social-preview-owner}"
  social-preview-about:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.social-preview-muted}"
    typography: "{typography.social-preview-body}"
---

# agents-tools

## Overview

Terminal rendering fixture for the agents-tools visual identity.
