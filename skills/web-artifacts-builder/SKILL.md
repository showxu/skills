---
name: web-artifacts-builder
description: Build shareable single-file HTML web artifacts from a temporary React/Tailwind/shadcn workspace. Use for complex review artifacts, prototypes, demos, or interactive HTML deliverables that need state management, routing, or shadcn/ui components. Uses an Anthropic-compatible artifact tooling baseline with local quality and host adaptations. Do not use for production frontend architecture or to invent product behavior.
---

# Web Artifacts Builder

## Maintenance Model

This `SKILL.md` is the single active workflow. It integrates the
Anthropic-compatible artifact-builder baseline with local quality and host
adaptations, following the same maintenance pattern as `skill-creator`:

- `references/anthropic-baseline.md` preserves the upstream baseline for
  refresh comparison.
- `references/anthropic-patch-manifest.md` records local differences from the
  upstream-derived baseline.
- `references/host-compatibility.md` records host assumptions and non-claims.

The output is a shareable artifact such as `bundle.html`. It is not production
frontend architecture, and it is not a product source of truth. If the artifact
is generated from product artifacts, preserve the supplied requirements and
interaction behavior; report missing behavior instead of inventing it.

## Artifact Quality Rules

When the artifact uses React state, routing, or component composition, keep the
implementation clear enough to inspect and modify as a temporary artifact. When
using the bundled shadcn component set, respect the project `components.json`,
semantic tokens, composition patterns, and component docs instead of hardcoding
a visually similar replacement.

Use React guidance only as artifact hygiene: simple state boundaries, clear
component composition, predictable client-side transitions, and avoidance of
obvious render bugs in the temporary artifact. Do not import full Next.js,
server/data-fetching, bundle-optimization, or production architecture guidance
into this skill.

Use shadcn guidance only when the artifact stack actually uses the bundled
shadcn component set or an existing shadcn project context. Prefer the bundled
components and semantic tokens; do not run registry, preset, or project
migration workflows unless the user is explicitly promoting the artifact into a
real frontend project.

Keep artifact code scoped to review or demo use unless the user explicitly asks
to promote it into a project frontend. If promotion is requested, hand
implementation ownership to `webapp-builder` so the work follows the project's
normal frontend architecture and validation expectations.

To build powerful frontend HTML artifacts, follow these steps:
1. Initialize the frontend repo using `scripts/init-artifact.sh`
2. Develop your artifact by editing the generated code
3. Bundle all code into a single HTML file using `scripts/bundle-artifact.sh`
4. Present or reference the artifact for review
5. (Optional) Test the artifact

**Stack**: React 18 + TypeScript + Vite + Parcel (bundling) + Tailwind CSS + shadcn/ui

## Design & Style Guidelines

VERY IMPORTANT: To avoid what is often referred to as "AI slop", avoid using excessive centered layouts, purple gradients, uniform rounded corners, and Inter font.

## Quick Start

### Step 1: Initialize Project

Run the initialization script to create a new React project:
```bash
bash scripts/init-artifact.sh <project-name>
cd <project-name>
```

This creates a fully configured project with:
- ✅ React + TypeScript (via Vite)
- ✅ Tailwind CSS 3.4.1 with shadcn/ui theming system
- ✅ Path aliases (`@/`) configured
- ✅ 40+ shadcn/ui components pre-installed
- ✅ All Radix UI dependencies included
- ✅ Parcel configured for bundling (via .parcelrc)
- ✅ Node 18+ compatibility (auto-detects and pins Vite version)

### Step 2: Develop Your Artifact

To build the artifact, edit the generated files. See **Common Development Tasks** below for guidance.

### Step 3: Bundle to Single HTML File

To bundle the React app into a single HTML artifact:
```bash
bash scripts/bundle-artifact.sh
```

This creates `bundle.html` - a self-contained artifact with all JavaScript,
CSS, and dependencies inlined. This file can be directly shared or reviewed as
a web artifact.

**Requirements**: Your project must have an `index.html` in the root directory.

**What the script does**:
- Installs bundling dependencies (parcel, @parcel/config-default, parcel-resolver-tspaths, html-inline)
- Creates `.parcelrc` config with path alias support
- Builds with Parcel (no source maps)
- Inlines all assets into single HTML using html-inline

### Step 4: Share Artifact with User

Finally, make the bundled HTML file available for review in the current host.

### Step 5: Testing/Visualizing the Artifact (Optional)

Note: This is a completely optional step. Only perform if necessary or requested.

To test/visualize the artifact, use available tools (including other Skills or built-in tools like Playwright or Puppeteer). In general, avoid testing the artifact upfront as it adds latency between the request and when the finished artifact can be seen. Test later, after presenting the artifact, if requested or if issues arise.

## Reference

- **shadcn/ui components**: https://ui.shadcn.com/docs/components
