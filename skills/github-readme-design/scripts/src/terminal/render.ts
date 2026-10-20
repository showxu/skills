import type { Design, Properties } from "../design.ts";
import { color, px } from "../design.ts";
import { number, resolveFont } from "../fonts.ts";
import type { Run } from "../fonts.ts";
import { parseRecording, recordingJSON } from "./record.ts";
import type { Recording } from "./record.ts";

export const MAX_WIDTH = 830;
export const THEMES = ["light", "dark"] as const;
type Theme = typeof THEMES[number];

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
  const lines: { text: string; context: string; runs: { role: string; run: Run }[] }[] = [];
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
  const widest = lines.reduce((previous, line) => {
    const advance = line.runs.reduce((sum, item) => sum + item.run.advance, 0);
    return advance > previous.advance ? { advance, text: line.text, context: line.context } : previous;
  }, { advance: title.advance, text: titleText, context: "recording.json title" });
  const width = Math.ceil(Math.max(minWidth, widest.advance + 2 * p));
  if (width > MAX_WIDTH) {
    throw new Error(`${widest.context}: widest line ${JSON.stringify(widest.text)} requires canvas ${width}px (components.terminal.width=${minWidth}px); maximum ${MAX_WIDTH}px; shorten the script line or title`);
  }
  const height = Math.ceil(bar + 2 * p + lines.length * lineHeight);
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
    lines.forEach((line, index) => {
      const baseline = bar + p + index * lineHeight + (lineHeight - (face.ascent + face.descent)) / 2 + face.ascent;
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
