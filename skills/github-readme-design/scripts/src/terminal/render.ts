import type { Design, Properties } from "../design.ts";
import { color, px } from "../design.ts";
import { number, resolveFont } from "../fonts.ts";
import type { Run } from "../fonts.ts";
import { parseRecording, recordingJSON } from "./record.ts";
import type { Recording } from "./record.ts";

export const MAX_WIDTH = 830;
export const THEMES = ["light", "dark"] as const;
type Theme = typeof THEMES[number];
interface ColoredRun { role: string; run: Run }
interface Row { runs: ColoredRun[]; continuation?: boolean }

function wrap(runs: ColoredRun[], width: number, scale: number, context: string): Row[] {
  // Accumulated floating-point roundoff must not wrap an exactly fitting glyph.
  const tolerance = Number.EPSILON * Math.max(1, width) * Math.max(1, runs.reduce((sum, item) => sum + item.run.placements.length, 0));
  const fits = (advance: number) => advance <= width + tolerance;
  if (fits(runs.reduce((sum, item) => sum + item.run.advance, 0))) return [{ runs }];
  const rows: Row[] = [{ runs: [] }];
  let row = rows[0];
  let advance = 0;
  for (const { role, run } of runs) {
    for (const { glyph } of run.placements) {
      const glyphAdvance = glyph.advanceWidth * scale;
      if (!fits(glyphAdvance)) throw new Error(`${context}: glyph ${glyph.id} advance exceeds terminal content width ${width}px`);
      if (!fits(advance + glyphAdvance)) {
        row = { runs: [], continuation: true };
        rows.push(row);
        advance = 0;
      }
      let segment = row.runs.at(-1);
      if (!segment || segment.role !== role) {
        segment = { role, run: { placements: [], advance: 0 } };
        row.runs.push(segment);
      }
      segment.run.placements.push({ glyph, x: segment.run.advance });
      segment.run.advance += glyphAdvance;
      advance += glyphAdvance;
    }
  }
  return rows;
}

function xml(value: string): string {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&apos;")
    .replace(/ +(?=\n|$)/g, spaces => "&#32;".repeat(spaces.length));
}

export function expandTabs(value: string, initialCell = 0): string {
  let cell = initialCell;
  let output = "";
  for (const character of value) {
    const count = character === "\t" ? 8 - cell % 8 : 1;
    output += character === "\t" ? " ".repeat(count) : character;
    cell += count;
  }
  return output;
}

function roundedRect(x: number, y: number, width: number, height: number, radius: number, topOnly = false): string {
  const n = number;
  const right = x + width;
  const bottom = y + height;
  const top = `M${n(x + radius)} ${n(y)}H${n(right - radius)}A${n(radius)} ${n(radius)} 0 0 1 ${n(right)} ${n(y + radius)}`;
  const lower = topOnly
    ? `V${n(bottom)}H${n(x)}`
    : `V${n(bottom - radius)}A${n(radius)} ${n(radius)} 0 0 1 ${n(right - radius)} ${n(bottom)}H${n(x + radius)}A${n(radius)} ${n(radius)} 0 0 1 ${n(x)} ${n(bottom - radius)}`;
  return `${top}${lower}V${n(y + radius)}A${n(radius)} ${n(radius)} 0 0 1 ${n(x + radius)} ${n(y)}Z`;
}

function component(design: Design, theme: Theme, name: string): Properties {
  const result = design.components[theme].get(name);
  if (!result) throw new Error(`components.${name}${theme === "dark" ? "-dark" : ""}: missing component`);
  return result;
}

function geometry(design: Design, theme: Theme) {
  const terminal = component(design, theme, "terminal");
  return {
    padding: px(terminal.get("padding"), "components.terminal.padding"),
    radius: px(terminal.get("rounded"), "components.terminal.rounded"),
    minWidth: px(terminal.get("width"), "components.terminal.width"),
    frame: px(component(design, theme, "terminal-frame").get("size"), "components.terminal-frame.size"),
    bar: px(component(design, theme, "terminal-title-bar").get("height"), "components.terminal-title-bar.height"),
    typography: terminal.get("typography"),
  };
}

export async function render(recording: Recording, design: Design, fonts: string): Promise<Record<Theme, string>> {
  parseRecording(recordingJSON(recording));
  const light = geometry(design, "light");
  const dark = geometry(design, "dark");
  if (JSON.stringify(light) !== JSON.stringify(dark)) throw new Error("components.terminal-dark: light and dark geometry and typography must be identical");
  const { padding: p, radius: r, minWidth, frame: s, bar } = light;
  const typography = design.typography.get("terminal");
  if (!typography || JSON.stringify(typography) !== JSON.stringify(light.typography)) {
    throw new Error("components.terminal.typography: must reference typography.terminal");
  }
  const lineHeight = px(typography.lineHeight, "typography.terminal.lineHeight");
  if (p < 0 || s <= 0 || r < s || minWidth <= 2 * r || bar <= r + s || lineHeight <= 0) {
    throw new Error("components.terminal: invalid padding, frame size, radius, width, title-bar height or typography.terminal.lineHeight");
  }
  const face = await resolveFont(fonts, typography);
  const titleText = expandTabs(recording.title);
  const title = face.run(titleText, "recording.json title");
  const lines: { text: string; context: string; runs: ColoredRun[] }[] = [];
  for (const [index, step] of recording.steps.entries()) {
    const context = `recording.json step ${index + 1} (${step.command})`;
    if (index) lines.push({ text: "", context, runs: [] });
    const command = expandTabs(step.command, 2);
    lines.push({ text: `$ ${command}`, context, runs: [
      { role: "terminal-prompt", run: face.run("$ ", context) },
      { role: "terminal-command", run: face.run(command, context) },
    ] });
    if (step.output !== "") {
      for (const line of step.output.split("\n")) {
        const text = expandTabs(line);
        lines.push({ text, context, runs: [{ role: "terminal", run: face.run(text, context) }] });
      }
    }
  }
  const widestAdvance = lines.reduce((previous, line) => {
    const advance = line.runs.reduce((sum, item) => sum + item.run.advance, 0);
    return Math.max(previous, advance);
  }, title.advance);
  const titleWidth = Math.ceil(Math.max(minWidth, title.advance + 2 * p));
  if (titleWidth > MAX_WIDTH) {
    throw new Error(`recording.json title: widest line ${JSON.stringify(titleText)} requires canvas ${titleWidth}px (components.terminal.width=${minWidth}px); maximum ${MAX_WIDTH}px; shorten the title or reduce components.terminal.width`);
  }
  const width = Math.min(MAX_WIDTH, Math.ceil(Math.max(minWidth, widestAdvance + 2 * p)));
  const rows = lines.flatMap(line => wrap(line.runs, width - 2 * p, face.scale, line.context));
  const markerSize = Math.min(6, (p - s) / 2, lineHeight / 3);
  if (rows.some(row => row.continuation) && Number(number(markerSize / 6)) <= 0) {
    throw new Error("components.terminal.padding and typography.terminal.lineHeight: must leave room for a visible continuation marker inside the frame");
  }
  const height = Math.ceil(bar + 2 * p + rows.length * lineHeight);
  const paths = new Map<number, string>();
  for (const run of [title, ...lines.flatMap(line => line.runs.map(item => item.run))]) {
    for (const { glyph } of run.placements) {
      if (!paths.has(glyph.id)) {
        const path = face.outline(glyph);
        if (path) paths.set(glyph.id, path);
      }
    }
  }
  const definitions = [...paths].sort(([a], [b]) => a - b).map(([id, path]) => `<path id="g${id}" d="${path}"/>`);
  const output = {} as Record<Theme, string>;
  for (const theme of THEMES) {
    const fill = (role: string, property = "textColor") => color(component(design, theme, role).get(property), `components.${role}${theme === "dark" ? "-dark" : ""}.${property}`);
    const drawRun = (run: Run, x: number, baseline: number, role: string) =>
      `<g fill="${fill(role)}">${run.placements.filter(({ glyph }) => paths.has(glyph.id))
        .map(({ glyph, x: offset }) => `<use href="#g${glyph.id}" x="${number(x + offset)}" y="${number(baseline)}"/>`).join("")}</g>`;
    const svg = [
      `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">`,
      `<title id="title">${xml(recording.title)}</title>`,
      `<desc id="desc">${xml(lines.map(line => line.text).join("\n"))}</desc>`,
      "<defs>", ...definitions, "</defs>",
      `<path d="${roundedRect(0, 0, width, height, r)}" fill="${fill("terminal-frame", "backgroundColor")}"/>`,
      `<path d="${roundedRect(s, s, width - 2 * s, height - 2 * s, r - s)}" fill="${fill("terminal", "backgroundColor")}"/>`,
      `<path d="${roundedRect(s, s, width - 2 * s, bar - 2 * s, r - s, true)}" fill="${fill("terminal-title-bar", "backgroundColor")}"/>`,
      `<rect x="${number(s)}" y="${number(bar - s)}" width="${number(width - 2 * s)}" height="${number(s)}" fill="${fill("terminal-frame", "backgroundColor")}"/>`,
      drawRun(title, (width - title.advance) / 2, (bar + face.capHeight) / 2, "terminal-title-bar"),
    ];
    rows.forEach((line, index) => {
      const baseline = bar + p + index * lineHeight + (lineHeight - (face.ascent + face.descent)) / 2 + face.ascent;
      if (line.continuation) {
        const size = markerSize;
        const centerX = (p + s) / 2;
        const centerY = baseline - face.capHeight / 2;
        svg.push(`<path d="M${number(centerX - size / 2)} ${number(centerY - size / 2)}L${number(centerX + size / 2)} ${number(centerY)}L${number(centerX - size / 2)} ${number(centerY + size / 2)}" fill="none" stroke="${fill("terminal")}" stroke-width="${number(size / 6)}" opacity="0.5" aria-hidden="true"/>`);
      }
      let x = p;
      for (const { run, role } of line.runs) {
        svg.push(drawRun(run, x, baseline, role));
        x += run.advance;
      }
    });
    output[theme] = svg.join("\n") + "\n</svg>\n";
  }
  return output;
}
