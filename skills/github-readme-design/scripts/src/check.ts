import { cp, mkdir, mkdtemp, readFile, readdir, realpath, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { readDesign } from "./design.ts";
import { parseRecording, record, recordingJSON } from "./terminal/record.ts";
import type { Recording } from "./terminal/record.ts";
import { render, THEMES } from "./terminal/render.ts";
import { message } from "./validation.ts";

export function changedSteps(before: Recording, after: Recording): string[] {
  const changes: string[] = [];
  if (before.title !== after.title) changes.push("recording.json: title changed");
  for (let index = 0; index < Math.max(before.steps.length, after.steps.length); index++) {
    const old = before.steps[index];
    const next = after.steps[index];
    if (!old) changes.push(`recording.json: added step ${index + 1}: ${next.command}`);
    else if (!next) changes.push(`recording.json: removed step ${index + 1}: ${old.command}`);
    else if (old.command !== next.command || old.output !== next.output) {
      changes.push(`recording.json: changed step ${index + 1}: ${old.command}${old.command !== next.command ? ` -> ${next.command}` : ""}`);
    }
  }
  return changes;
}

function unifiedDiff(before: string, after: string, file: string): string {
  const a = before.endsWith("\n") ? before.slice(0, -1).split("\n") : before.split("\n");
  const b = after.endsWith("\n") ? after.slice(0, -1).split("\n") : after.split("\n");
  return [`--- ${file}`, `+++ regenerated/${file}`, `@@ -1,${a.length} +1,${b.length} @@`,
    ...a.map(line => `-${line}`), ...b.map(line => `+${line}`)].join("\n");
}

export function quote(value: string): string {
  return "'" + value.replaceAll("'", "'\\''") + "'";
}

export const CLI_PATH = fileURLToPath(new URL("./cli.ts", import.meta.url));

export function regeneration(options: CheckOptions): string {
  const { assets, design, fonts, executable } = options;
  const recording = join(assets, "recording.json");
  return [
    `node ${quote(CLI_PATH)} terminal record --script ${quote(join(assets, "script.yml"))} --executable ${quote(executable)} --out ${quote(recording)}`,
    ...(options.recordingOnly ? [] : [
      `node ${quote(CLI_PATH)} terminal render --recording ${quote(recording)} --design ${quote(design!)} --fonts ${quote(fonts!)} --out-dir ${quote(assets)}`,
    ]),
  ].join("\n");
}

async function optionalRead(file: string): Promise<Buffer | undefined> {
  try { return await readFile(file); }
  catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
    throw error;
  }
}

export interface CheckOptions {
  assets: string;
  design?: string;
  fonts?: string;
  executable: string;
  artifactDir?: string;
  recordingOnly?: boolean;
}

async function separateArtifact(source: string, target: string): Promise<void> {
  const canonical = async (path: string): Promise<string> => {
    try { return await realpath(path); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      return join(await canonical(dirname(path)), basename(path));
    }
  };
  const contains = (a: string, b: string) => {
    const path = relative(resolve(a), resolve(b));
    return path === "" || (path !== ".." && !path.startsWith(`..${sep}`) && !path.startsWith(sep));
  };
  const realSource = await canonical(resolve(source));
  const realTarget = await canonical(resolve(target));
  if (contains(realSource, realTarget) || contains(realTarget, realSource)) throw new Error(`${target}: artifact directory must be separate from assets ${source}`);
}

async function copyArtifact(source: string, generated: string, target: string): Promise<void> {
  await separateArtifact(source, target);
  await mkdir(target, { recursive: true });
  const names = ["script.yml", "fixture", "recording.json", "terminal-light.svg", "terminal-dark.svg"];
  for (const name of await readdir(target)) {
    if (!names.includes(name)) throw new Error(`${target}: artifact directory contains unrelated entry ${name}`);
  }
  await cp(join(source, "script.yml"), join(target, "script.yml"));
  await rm(join(target, "fixture"), { recursive: true, force: true });
  try { await cp(join(source, "fixture"), join(target, "fixture"), { recursive: true, verbatimSymlinks: true }); }
  catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
  for (const name of names.slice(2)) await cp(join(generated, name), join(target, name));
}

export async function check(options: CheckOptions, log: (line: string) => void = console.log): Promise<boolean> {
  if (!options.recordingOnly && (!options.design || !options.fonts)) {
    throw new Error("Terminal rendering requires design and fonts");
  }
  const temporary = await mkdtemp(join(tmpdir(), "presentation-check-"));
  try {
    const recording = await record(join(options.assets, "script.yml"), options.executable);
    const json = recordingJSON(recording);
    const outputs: Record<string, string> = { "recording.json": json };
    if (!options.recordingOnly) {
      const svg = await render(recording, await readDesign(options.design!), options.fonts!);
      for (const theme of THEMES) outputs[`terminal-${theme}.svg`] = svg[theme];
    }
    let different = false;
    let recordingChanged = false;
    for (const [name, bytes] of Object.entries(outputs)) {
      await writeFile(join(temporary, name), bytes, "utf8");
      const file = join(options.assets, name);
      const before = await optionalRead(file);
      if (before?.equals(Buffer.from(bytes, "utf8"))) continue;
      different = true;
      if (name === "recording.json") {
        recordingChanged = true;
        if (before !== undefined) {
          try {
            for (const line of changedSteps(parseRecording(before.toString("utf8"), file), recording)) log(line);
          } catch (error) { log(`${file}: ${message(error)}`); }
        } else log(`${file}: missing committed recording`);
        log(unifiedDiff(before?.toString("utf8") ?? "", bytes, file));
      } else {
        log(`${file}: ${before === undefined ? "missing" : "differs"}; ${recordingChanged ? "recording or DESIGN or the renderer changed" : "recording matches; DESIGN or the renderer changed"}`);
      }
    }
    if (different) {
      if (options.artifactDir) {
        if (options.recordingOnly) {
          await separateArtifact(options.assets, options.artifactDir);
          await checkFile({ file: join(options.assets, "recording.json"), bytes: Buffer.from(json),
            regenerate: regeneration(options), artifactDir: options.artifactDir }, () => {});
          log(`Regenerated recording: ${join(options.artifactDir, "recording.json")}`);
        } else {
          await copyArtifact(options.assets, temporary, options.artifactDir);
          log(`Regenerated asset directory: ${options.artifactDir}`);
        }
      }
      log(`Regenerate from the current directory:\n${regeneration(options)}`);
    } else log(`${options.assets}: ${options.recordingOnly ? "recording.json matches" : "recording.json and both terminal SVGs match"}`);
    return !different;
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
}

export async function checkFile(options: {
  file: string; bytes: Buffer; regenerate: string; artifactDir?: string; text?: boolean;
}, log: (line: string) => void = console.log): Promise<boolean> {
  const before = await optionalRead(options.file);
  if (before?.equals(options.bytes)) {
    log(`${options.file}: matches its inputs`);
    return true;
  }
  log(`${options.file}: ${before === undefined ? "missing" : "differs from its inputs"}`);
  if (options.text) log(unifiedDiff(before?.toString("utf8") ?? "", options.bytes.toString("utf8"), options.file));
  if (options.artifactDir) {
    const canonical = async (path: string): Promise<string> => {
      try { return await realpath(path); }
      catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
        return join(await canonical(dirname(path)), basename(path));
      }
    };
    const name = basename(options.file);
    const target = join(options.artifactDir, name);
    if (await canonical(resolve(target)) === await canonical(resolve(options.file))) {
      throw new Error(`${options.artifactDir}: artifact must be separate from the checked output ${options.file}`);
    }
    await mkdir(options.artifactDir, { recursive: true });
    for (const entry of await readdir(options.artifactDir)) {
      if (entry !== name) throw new Error(`${options.artifactDir}: artifact directory contains unrelated entry ${entry}`);
    }
    // Replace the artifact's directory entry so an old hard link cannot
    // overwrite the checked output or another input through its inode.
    await rm(target, { force: true });
    await writeFile(target, options.bytes, { flag: "wx" });
    log(`Regenerated output: ${target}`);
  }
  log(`Regenerate from the current directory:\n${options.regenerate}`);
  return false;
}
