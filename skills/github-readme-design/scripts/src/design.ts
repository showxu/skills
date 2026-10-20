import { lint } from "@google/design.md/linter";
import type { ResolvedTypography, ResolvedValue } from "@google/design.md/linter";
import { readFile } from "node:fs/promises";

export type Properties = Map<string, ResolvedValue>;
export interface Design {
  components: { light: Map<string, Properties>; dark: Map<string, Properties> };
  typography: Map<string, ResolvedTypography>;
}

export function parseDesign(text: string, file = "DESIGN.md"): Design {
  const report = lint(text);
  const failures = report.findings.filter(finding => finding.severity !== "info");
  if (failures.length) {
    throw new Error(failures.map(finding =>
      `${file}: ${finding.path ?? "(document)"} [${finding.rule ?? "parse"}] ${finding.severity}: ${finding.message}`).join("\n"));
  }
  const light = new Map<string, Properties>();
  const dark = new Map<string, Properties>();
  for (const [name, component] of report.designSystem.components) {
    if (name.endsWith("-dark")) continue;
    light.set(name, new Map(component.properties));
    dark.set(name, new Map([...component.properties,
      ...(report.designSystem.components.get(`${name}-dark`)?.properties ?? [])]));
  }
  return { components: { light, dark }, typography: report.designSystem.typography };
}

export async function readDesign(file: string): Promise<Design> {
  return parseDesign(await readFile(file, "utf8"), file);
}

export function px(value: ResolvedValue | undefined, token: string): number {
  if (typeof value !== "object" || value.type !== "dimension" || value.unit !== "px" || !Number.isFinite(value.value)) {
    throw new Error(`${token}: expected a dimension in px`);
  }
  return value.value;
}

export function color(value: ResolvedValue | undefined, token: string): string {
  if (typeof value !== "object" || value.type !== "color" || (value.a !== undefined && value.a !== 1) ||
      !/^#[0-9a-f]{6}$/i.test(value.hex)) {
    throw new Error(`${token}: expected an opaque six-digit hex color`);
  }
  return value.hex.toUpperCase();
}
