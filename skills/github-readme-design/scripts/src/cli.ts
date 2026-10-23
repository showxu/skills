import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { parseArgs } from "node:util";
import { check, checkFile, CLI_PATH, quote, regeneration } from "./check.ts";
import { json, parseMember, readCatalog, revision } from "./catalog.ts";
import { readDesign } from "./design.ts";
import { renderProfile } from "./profile/render.ts";
import { renderSocial } from "./social-preview/render.ts";
import { parseRecording, record, recordingJSON, RecordingInterrupted } from "./terminal/record.ts";
import { render, THEMES } from "./terminal/render.ts";
import { message } from "./validation.ts";

const usage = `Usage:
node src/cli.ts terminal record --script <script.yml> --executable <path> --out <recording.json>
node src/cli.ts terminal render --recording <recording.json> --design <DESIGN.md> --fonts <dir> --out-dir <dir>
node src/cli.ts terminal check --assets <dir> --design <DESIGN.md> --fonts <dir> --executable <path> [--artifact-dir <dir>]
node src/cli.ts terminal check --recording-only --assets <dir> --executable <path> [--artifact-dir <dir>]
node src/cli.ts design lint --design <DESIGN.md>
node src/cli.ts social-preview render --design <DESIGN.md> --fonts <dir> --catalog <catalog.json> --repository <name|.github> --icon <path> --out <social-preview.png>
node src/cli.ts social-preview check --design <DESIGN.md> --fonts <dir> --catalog <catalog.json> --repository <name|.github> --icon <path> --assets <dir> [--artifact-dir <dir>]
node src/cli.ts profile render --design <DESIGN.md> --catalog <catalog.json> [--member <member.json> --catalog-revision <40-hex-sha>] --out <README.md>
node src/cli.ts profile check --design <DESIGN.md> --catalog <catalog.json> [--member <member.json> --catalog-revision <40-hex-sha>] --out <README.md> [--artifact-dir <dir>]`;

const contracts: Record<string, { required: string[]; optional?: string[] }> = {
  "terminal record": { required: ["script", "executable", "out"] },
  "terminal render": { required: ["recording", "design", "fonts", "out-dir"] },
  "terminal check": { required: ["assets", "executable"], optional: ["design", "fonts", "artifact-dir"] },
  "design lint": { required: ["design"] },
  "social-preview render": { required: ["design", "fonts", "catalog", "repository", "icon", "out"] },
  "social-preview check": { required: ["design", "fonts", "catalog", "repository", "icon", "assets"], optional: ["artifact-dir"] },
  "profile render": { required: ["design", "catalog", "out"], optional: ["member", "catalog-revision"] },
  "profile check": { required: ["design", "catalog", "out"], optional: ["member", "catalog-revision", "artifact-dir"] },
};

function renderCommand(command: string, values: Record<string, string>): string {
  const asset = command.split(" ")[0];
  const options = asset === "social-preview"
    ? { design: values.design, fonts: values.fonts, catalog: values.catalog, repository: values.repository,
      icon: values.icon, out: values.out ?? join(values.assets, "social-preview.png") }
    : { design: values.design, catalog: values.catalog, ...(values.member
      ? { member: values.member, "catalog-revision": values["catalog-revision"] } : {}), out: values.out };
  return `node ${quote(CLI_PATH)} ${asset} render ` + Object.entries(options).map(([key, value]) => `--${key} ${quote(value)}`).join(" ");
}

export async function main(args: string[]): Promise<number> {
  let values: Record<string, string>;
  let recordingOnly = false;
  const command = args.slice(0, 2).join(" ");
  try {
    const contract = contracts[command];
    if (!contract) throw new Error(`Unknown command: ${command}`);
    const options: Record<string, { type: "string" | "boolean" }> = Object.fromEntries(
      [...contract.required, ...(contract.optional ?? [])].map(name => [name, { type: "string" as const }]));
    if (command === "terminal check") options["recording-only"] = { type: "boolean" };
    const parsed = parseArgs({ args: args.slice(2), options, strict: true, allowPositionals: false, tokens: true });
    const seen = new Set<string>();
    for (const token of parsed.tokens) {
      if (token.kind !== "option") continue;
      if (seen.has(token.name)) throw new Error(`Duplicate option --${token.name}`);
      seen.add(token.name);
    }
    recordingOnly = parsed.values["recording-only"] === true;
    values = Object.fromEntries(Object.entries(parsed.values).filter(([name]) => name !== "recording-only")) as Record<string, string>;
    const required = command === "terminal check" && !recordingOnly
      ? [...contract.required, "design", "fonts"] : contract.required;
    for (const name of required) {
      if (!values[name]?.trim()) throw new Error(`Missing --${name}`);
    }
    for (const [name, value] of Object.entries(values)) {
      if (!value.trim()) throw new Error(`Empty --${name}`);
    }
    if (command.startsWith("profile ")) {
      if (values.member) revision(values["catalog-revision"]);
      else if (values["catalog-revision"] !== undefined) throw new Error("--catalog-revision is only allowed in member mode");
    }
  } catch (error) {
    console.error(`${message(error)}\n${usage}`);
    return 2;
  }
  try {
    if (command === "design lint") {
      await readDesign(values.design);
      console.log(`${values.design}: zero errors and zero warnings`);
    } else if (command === "terminal record") {
      const result = await record(values.script, values.executable);
      await mkdir(dirname(values.out), { recursive: true });
      await writeFile(values.out, recordingJSON(result), "utf8");
      console.log(`Recorded ${values.out}`);
    } else if (command === "terminal render") {
      const recording = parseRecording(await readFile(values.recording, "utf8"), values.recording);
      const result = await render(recording, await readDesign(values.design), values.fonts);
      await mkdir(values["out-dir"], { recursive: true });
      for (const theme of THEMES) await writeFile(join(values["out-dir"], `terminal-${theme}.svg`), result[theme], "utf8");
      console.log(`Rendered ${values["out-dir"]}/terminal-{light,dark}.svg`);
    } else if (command === "terminal check") {
      return await check({
        assets: values.assets, design: values.design, fonts: values.fonts,
        executable: values.executable, artifactDir: values["artifact-dir"], recordingOnly,
      }) ? 0 : 1;
    } else {
      const catalog = await readCatalog(values.catalog);
      const design = await readDesign(values.design);
      const social = command.startsWith("social-preview ");
      const member = values.member ? parseMember(json(await readFile(values.member, "utf8"), values.member), catalog, values.member) : undefined;
      const bytes = social
        ? await renderSocial(catalog, values.repository, design, values.fonts, values.icon)
        : Buffer.from(renderProfile(catalog, design, member, values["catalog-revision"]), "utf8");
      const file = social && command.endsWith("check") ? join(values.assets, "social-preview.png") : values.out;
      if (command.endsWith("check")) return await checkFile({
        file, bytes, regenerate: renderCommand(command, values), artifactDir: values["artifact-dir"], text: !social,
      }) ? 0 : 1;
      await mkdir(dirname(file), { recursive: true });
      await writeFile(file, bytes);
      console.log(`Rendered ${file}`);
    }
    return 0;
  } catch (error) {
    if (error instanceof RecordingInterrupted) {
      console.error(error.message);
      return error.exitCode;
    }
    const context = values.script ?? values.recording ?? values.assets ?? values.design;
    console.error(`${context}: ${message(error)}`);
    const rerun = command === "terminal check"
      ? regeneration({ assets: values.assets, design: values.design, fonts: values.fonts, executable: values.executable, recordingOnly })
      : command.startsWith("profile ") || command.startsWith("social-preview ")
        ? renderCommand(command, values) : `node ${quote(CLI_PATH)} ${args.map(quote).join(" ")}`;
    console.error(`After correcting the input, run:\n${rerun}`);
    return 1;
  }
}

if (import.meta.main) process.exitCode = await main(process.argv.slice(2));
