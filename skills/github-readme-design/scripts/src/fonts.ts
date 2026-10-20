import { open } from "fontkit";
import type { Font, Glyph } from "fontkit";
import type { ResolvedTypography } from "@google/design.md/linter";
import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { px } from "./design.ts";
import { plain } from "./validation.ts";

export function number(value: number): string {
  if (!Number.isFinite(value)) throw new Error("Non-finite SVG coordinate");
  return String(Math.round(value * 100) / 100 || 0);
}

export function variations(value: string | undefined, token: string): Record<string, number> {
  if (value === undefined) return {};
  const result: Record<string, number> = {};
  for (const setting of value.split(",")) {
    const match = /^\s*(['"])([\x20-\x7e]{4})\1\s+([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*$/.exec(setting);
    if (!match || !Number.isFinite(Number(match[3]))) throw new Error(`${token}: expected CSS font-variation-settings ('TAG' number)`);
    const tag = match[2];
    if (tag === "wght") throw new Error(`${token}: wght must come only from fontWeight`);
    if (Object.hasOwn(result, tag)) throw new Error(`${token}: duplicate axis ${tag}`);
    result[tag] = Number(match[3]);
  }
  return result;
}

export function matchesFont(font: Font, typography: ResolvedTypography, axes: Record<string, number>): boolean {
  const family = font.getName("preferredFamily", "en") ?? font.getName("fontFamily", "en");
  if (family !== typography.fontFamily) return false;
  if (!Object.keys(font.variationAxes).length) {
    return typography.fontVariation === undefined && font["OS/2"].usWeightClass === typography.fontWeight;
  }
  return Object.entries({ ...axes, wght: typography.fontWeight! }).every(([tag, value]) => {
    const axis = font.variationAxes[tag];
    return axis !== undefined && value >= axis.min && value <= axis.max;
  });
}

export interface Placement { glyph: Glyph; x: number }
export interface Run { placements: Placement[]; advance: number }
export interface Face {
  font: Font;
  scale: number;
  ascent: number;
  descent: number;
  capHeight: number;
  run(text: string, context: string): Run;
  outline(glyph: Glyph): string;
}

export async function resolveFont(directory: string, typography: ResolvedTypography, token = "typography.terminal"): Promise<Face> {
  if (!typography.fontFamily || !Number.isFinite(typography.fontWeight)) {
    throw new Error(`${token}: fontFamily and numeric fontWeight are required`);
  }
  const axes = variations(typography.fontVariation, `${token}.fontVariation`);
  const candidates: string[] = [];
  const matches: { path: string; font: Font }[] = [];
  for (const entry of (await readdir(directory, { withFileTypes: true })).sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0)) {
    if (!/\.(ttf|otf|woff2?|ttc|dfont)$/i.test(entry.name) || entry.isDirectory()) continue;
    const path = join(directory, entry.name);
    const opened = await open(path);
    const faces = "fonts" in opened ? opened.fonts : [opened];
    for (const font of faces) {
      candidates.push(`${entry.name} (${font.getName("preferredFamily", "en") ?? font.familyName}; ${font.subfamilyName})`);
      if (matchesFont(font, typography, axes)) matches.push({ path, font });
    }
  }
  if (matches.length !== 1) {
    throw new Error(`${token}: expected exactly one font matching ${typography.fontFamily}, weight ${typography.fontWeight}, variation ${typography.fontVariation ?? "(absent)"}; matched ${matches.length}: ${matches.map(match => match.path).join(", ") || "(none)"}; candidates: ${candidates.join(", ") || "(none)"}`);
  }
  const base = matches[0].font;
  const font = Object.keys(base.variationAxes).length ? base.getVariation({ ...axes, wght: typography.fontWeight }) : base;
  const scale = px(typography.fontSize, `${token}.fontSize`) / font.unitsPerEm;
  if (!(scale > 0) || !Number.isFinite(font.capHeight)) throw new Error(`${token}: fontSize must be positive and the font must have cap-height metrics`);
  const commands = { moveTo: "M", lineTo: "L", quadraticCurveTo: "Q", bezierCurveTo: "C", closePath: "Z" };
  return {
    font, scale, ascent: font.ascent * scale, descent: Math.abs(font.descent) * scale, capHeight: font.capHeight * scale,
    run(text, context) {
      plain(text, context);
      let advance = 0;
      const placements: Placement[] = [];
      for (const character of text) {
        const point = character.codePointAt(0)!;
        if (!font.hasGlyphForCodePoint(point)) {
          throw new Error(`${context}: missing glyph ${JSON.stringify(character)} (U+${point.toString(16).toUpperCase().padStart(4, "0")}) in ${matches[0].path}`);
        }
        const glyph = font.glyphForCodePoint(point);
        placements.push({ glyph, x: advance });
        advance += glyph.advanceWidth * scale;
      }
      return { placements, advance };
    },
    outline(glyph) {
      return glyph.path.commands.map(({ command, args }) =>
        commands[command] + args.map((value, index) => number(value * scale * (index % 2 ? -1 : 1))).join(" ")).join("");
    },
  };
}
