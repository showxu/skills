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
    fontSize: 72px
    lineHeight: 82.8px
    fontWeight: 700
    fontVariation: "'MONO' 0"
  social-preview-owner:
    fontFamily: Google Sans Code
    fontSize: 28px
    lineHeight: 28px
    fontWeight: 500
    fontVariation: "'MONO' 0"
  social-preview-body:
    fontFamily: Google Sans Code
    fontSize: 32px
    lineHeight: 44px
    fontWeight: 400
    fontVariation: "'MONO' 0"
rounded:
  terminal: 10px
spacing:
  social-preview-padding: 64px
  social-preview-gap: 64px
  social-preview-stack: 24px
  social-preview-icon: 384px
  profile-header-icon: 128px
  profile-member-header-icon: 64px
  profile-row-icon: 40px
  profile-member-row-icon: 24px
  terminal-padding: 20px
  terminal-title-bar: 34px
  terminal-min-width: 560px
  hairline: 1px
components:
  social-preview-gap:
    width: "{spacing.social-preview-gap}"
    height: "{spacing.social-preview-stack}"
  profile-header:
    size: "{spacing.profile-header-icon}"
  profile-member-header:
    size: "{spacing.profile-member-header-icon}"
  profile-row:
    size: "{spacing.profile-row-icon}"
  profile-member-row:
    size: "{spacing.profile-member-row-icon}"
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
    padding: "{spacing.social-preview-padding}"
    size: "{spacing.social-preview-icon}"
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

Presentation rendering fixture for the agents-tools visual identity.
