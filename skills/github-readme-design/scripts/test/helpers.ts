import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { join } from "node:path";
import type { TestContext } from "node:test";
import { fileURLToPath } from "node:url";

export const fixture = fileURLToPath(new URL("./fixtures/", import.meta.url));
export const designPath = join(fixture, "DESIGN.md");
export const fonts = join(fixture, "fonts");
export const catalogPath = join(fixture, "profile/catalog.json");
export const memberPath = join(fixture, "profile/member.json");
export const commit = "1".repeat(40);
const outputRoot = fileURLToPath(new URL("../../../../.build/presentation-toolchain/tests/", import.meta.url));

export async function temporary(t: TestContext): Promise<string> {
  await mkdir(outputRoot, { recursive: true });
  const root = await mkdtemp(join(outputRoot, "asset-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  return root;
}

export function cli(...args: string[]) {
  return spawnSync(process.execPath, [fileURLToPath(new URL("../src/cli.ts", import.meta.url)), ...args], { encoding: "utf8" });
}
