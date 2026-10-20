import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { parseArgs } from "node:util";
import { check, CLI_PATH, quote, regeneration } from "./check.ts";
import { readDesign } from "./design.ts";
import { parseRecording, record, recordingJSON } from "./terminal/record.ts";
import { render, THEMES } from "./terminal/render.ts";
import { message } from "./validation.ts";

const usage = `Usage:
node src/cli.ts terminal record --script <script.yml> --executable <path> --out <recording.json>
node src/cli.ts terminal render --recording <recording.json> --design <DESIGN.md> --fonts <dir> --out-dir <dir>
node src/cli.ts terminal check --assets <dir> --design <DESIGN.md> --fonts <dir> --executable <path> [--artifact-dir <dir>]
node src/cli.ts design lint --design <DESIGN.md>`;

const contracts: Record<string, { required: string[]; optional?: string[] }> = {
  "terminal record": { required: ["script", "executable", "out"] },
  "terminal render": { required: ["recording", "design", "fonts", "out-dir"] },
  "terminal check": { required: ["assets", "design", "fonts", "executable"], optional: ["artifact-dir"] },
  "design lint": { required: ["design"] },
};

export async function main(args: string[]): Promise<number> {
  let values: Record<string, string>;
  const command = args.slice(0, 2).join(" ");
  try {
    const contract = contracts[command];
    if (!contract) throw new Error(`Unknown command: ${command}`);
    const options = Object.fromEntries([...contract.required, ...(contract.optional ?? [])].map(name => [name, { type: "string" as const }]));
    const parsed = parseArgs({ args: args.slice(2), options, strict: true, allowPositionals: false, tokens: true });
    const seen = new Set<string>();
    for (const token of parsed.tokens) {
      if (token.kind !== "option") continue;
      if (seen.has(token.name)) throw new Error(`Duplicate option --${token.name}`);
      seen.add(token.name);
    }
    values = parsed.values as Record<string, string>;
    for (const name of contract.required) {
      if (!values[name]?.trim()) throw new Error(`Missing --${name}`);
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
    } else {
      return await check({
        assets: values.assets, design: values.design, fonts: values.fonts,
        executable: values.executable, artifactDir: values["artifact-dir"],
      }) ? 0 : 1;
    }
    return 0;
  } catch (error) {
    const context = values.script ?? values.recording ?? values.assets ?? values.design;
    console.error(`${context}: ${message(error)}`);
    const rerun = command === "terminal check"
      ? regeneration({ assets: values.assets, design: values.design, fonts: values.fonts, executable: values.executable })
      : `node ${quote(CLI_PATH)} ${args.map(quote).join(" ")}`;
    console.error(`After correcting the input, run:\n${rerun}`);
    return 1;
  }
}

if (import.meta.main) process.exitCode = await main(process.argv.slice(2));
