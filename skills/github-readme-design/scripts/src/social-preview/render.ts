import { initWasm, Resvg } from "@resvg/resvg-wasm";
import type { ResolvedTypography } from "@google/design.md/linter";
import { readFile } from "node:fs/promises";
import type { Catalog } from "../catalog.ts";
import { color, px } from "../design.ts";
import type { Design } from "../design.ts";
import { number, resolveFont } from "../fonts.ts";
import type { Face } from "../fonts.ts";
import { iconSVG } from "./icon.ts";

export const WIDTH = 1280, HEIGHT = 640, TITLE_MINIMUM = 40;

export function fitTitle(title: string, measure: (text: string, size: number) => number, width: number,
  maximum: number, minimum = TITLE_MINIMUM): { lines: string[]; size: number } {
  if (!title || minimum <= 0 || maximum < minimum || width <= 0) throw new Error("Invalid title or title fitting bounds");
  const sizes: number[] = [];
  for (let size = maximum; size >= minimum; size--) sizes.push(size);
  if (sizes.at(-1) !== minimum) sizes.push(minimum);
  for (const size of sizes) if (measure(title, size) <= width) return { lines: [title], size };
  const candidates = [...title.matchAll(/[-/]+/g)].filter(match => match.index! > 0 && match.index! + match[0].length < title.length)
    .map(match => [title.slice(0, match.index), title.slice(match.index! + match[0].length)]);
  for (const size of sizes) {
    const fits = candidates.map(lines => ({ lines, widths: lines.map(line => measure(line, size)) }))
      .filter(item => Math.max(...item.widths) <= width);
    fits.sort((a, b) => Math.abs(a.widths[0] - a.widths[1]) - Math.abs(b.widths[0] - b.widths[1]) ||
      (a.lines[0] < b.lines[0] ? -1 : a.lines[0] > b.lines[0] ? 1 : 0));
    if (fits.length) return { lines: fits[0].lines, size };
  }
  throw new Error("Title cannot fit at its stated minimum; revise the composition");
}

export function wrapAbout(value: string, measure: (text: string) => number, width: number): string[] {
  const lines: string[] = [];
  let line = "";
  for (const word of value.split(/\s+/u).filter(Boolean)) {
    if (measure(word) > width) throw new Error("About contains an unbreakable word wider than the text area");
    const candidate = line ? `${line} ${word}` : word;
    if (line && measure(candidate) > width) { lines.push(line); line = word; }
    else line = candidate;
  }
  if (line) lines.push(line);
  if (!lines.length || lines.length > 3) throw new Error("Complete About must fit at its DESIGN font size in at most three lines");
  return lines;
}

export function cardContent(catalog: Catalog, repository: string): { owner: string; title: string; about: string } {
  const owner = catalog.organization.login;
  if (repository === ".github") return { owner, title: catalog.organization.name, about: catalog.organization.about };
  const entry = catalog.groups.flatMap(group => group.repositories).find(repo => repo.name.toLowerCase() === repository.toLowerCase());
  if (!entry) throw new Error(`catalog: unknown repository ${repository}`);
  return { owner, title: entry.title, about: entry.about };
}

function typography(design: Design, component: string, name: string): ResolvedTypography {
  const result = design.typography.get(name);
  if (!result || JSON.stringify(result) !== JSON.stringify(design.components.light.get(component)?.get("typography"))) {
    throw new Error(`components.${component}.typography: must reference typography.${name}`);
  }
  if (result.fontVariation === undefined) throw new Error(`typography.${name}.fontVariation: required for social preview variable fonts`);
  if (px(result.fontSize, `typography.${name}.fontSize`) <= 0 || px(result.lineHeight, `typography.${name}.lineHeight`) <= 0) {
    throw new Error(`typography.${name}: fontSize and lineHeight must be positive`);
  }
  return result;
}

export async function socialSVG(catalog: Catalog, repository: string, design: Design, fonts: string, icon: string): Promise<string> {
  const content = cardContent(catalog, repository);
  const component = (name: string, property: string) => design.components.light.get(name)?.get(property);
  const padding = px(component("social-preview", "padding"), "components.social-preview.padding");
  const iconSize = px(component("social-preview", "size"), "components.social-preview.size");
  const gap = px(component("social-preview-gap", "width"), "components.social-preview-gap.width");
  const stack = px(component("social-preview-gap", "height"), "components.social-preview-gap.height");
  const x = padding + iconSize + gap, width = WIDTH - padding - x;
  if (padding < 0 || iconSize <= 0 || gap < 0 || stack < 0 || width <= 0 || iconSize > HEIGHT - 2 * padding) {
    throw new Error("components.social-preview: composition exceeds the canvas or overlaps its icon");
  }
  const titleType = typography(design, "social-preview", "social-preview-title");
  const ownerType = typography(design, "social-preview-owner", "social-preview-owner");
  const aboutType = typography(design, "social-preview-about", "social-preview-body");
  const [titleFace, ownerFace, aboutFace] = await Promise.all([
    resolveFont(fonts, titleType, "typography.social-preview-title"),
    resolveFont(fonts, ownerType, "typography.social-preview-owner"),
    resolveFont(fonts, aboutType, "typography.social-preview-body"),
  ]);
  const maximum = px(titleType.fontSize, "typography.social-preview-title.fontSize");
  const fitted = fitTitle(content.title, (text, size) => titleFace.run(text, "catalog title").advance * size / maximum, width, maximum);
  const fittedFace = fitted.size === maximum ? titleFace : await resolveFont(fonts,
    { ...titleType, fontSize: { type: "dimension", value: fitted.size, unit: "px" } }, "typography.social-preview-title");
  const about = wrapAbout(content.about, text => aboutFace.run(text, "catalog about").advance, width);
  if (ownerFace.run(content.owner, "catalog organization.login").advance > width) throw new Error("Owner label exceeds the text area");
  const ownerHeight = px(ownerType.lineHeight, "typography.social-preview-owner.lineHeight");
  const titleHeight = px(titleType.lineHeight, "typography.social-preview-title.lineHeight") * fitted.size / maximum;
  const aboutHeight = px(aboutType.lineHeight, "typography.social-preview-body.lineHeight");
  const height = ownerHeight + stack + fitted.lines.length * titleHeight + stack + about.length * aboutHeight;
  if (height > HEIGHT - 2 * padding) throw new Error("Text block exceeds the card height");
  const fill = (name: string, property = "textColor") => color(component(name, property), `components.${name}.${property}`);
  const definitions = new Map<string, string>();
  const draw = (face: Face, text: string, baseline: number, role: string, prefix: string): string => {
    const run = face.run(text, `catalog ${prefix}`);
    const uses = run.placements.map(({ glyph, x: offset }) => {
      const id = `${prefix}-${glyph.id}`;
      const path = face.outline(glyph);
      if (!path) return "";
      definitions.set(id, `<path id="${id}" d="${path}"/>`);
      return `<use href="#${id}" x="${number(x + offset)}" y="${number(baseline)}"/>`;
    });
    return `<g fill="${fill(role)}">${uses.join("")}</g>`;
  };
  let y = (HEIGHT - height) / 2 + ownerHeight;
  const body = [draw(ownerFace, content.owner, y, "social-preview-owner", "owner")];
  y += stack;
  for (const line of fitted.lines) { y += titleHeight; body.push(draw(fittedFace, line, y, "social-preview", "title")); }
  y += stack;
  for (const line of about) { y += aboutHeight; body.push(draw(aboutFace, line, y, "social-preview-about", "about")); }
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">`,
    "<defs>", ...definitions.values(), "</defs>",
    `<rect width="${WIDTH}" height="${HEIGHT}" fill="${fill("social-preview", "backgroundColor")}"/>`,
    await iconSVG(icon, padding, (HEIGHT - iconSize) / 2, iconSize), ...body, "</svg>", "",
  ].join("\n");
}

let ready: Promise<void> | undefined;
export async function renderSocial(catalog: Catalog, repository: string, design: Design, fonts: string, icon: string): Promise<Buffer> {
  const svg = await socialSVG(catalog, repository, design, fonts, icon);
  ready ??= initWasm(readFile(new URL(import.meta.resolve("@resvg/resvg-wasm/index_bg.wasm"))));
  await ready;
  const renderer = new Resvg(svg, { font: { loadSystemFonts: false }, imageRendering: 0 });
  try {
    const result = renderer.render();
    try { return Buffer.from(result.asPng()); }
    finally { result.free(); }
  } finally { renderer.free(); }
}
