import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { readDesign } from "../src/design.ts";
import { parseRecording } from "../src/terminal/record.ts";
import { render, THEMES } from "../src/terminal/render.ts";

// The test runner discovers files in test/; only the explicit golden command writes.
if (process.argv.includes("--write")) {
  const root = new URL("./fixtures/", import.meta.url);
  const recording = parseRecording(await readFile(new URL("recording.json", root), "utf8"));
  const result = await render(recording, await readDesign(fileURLToPath(new URL("DESIGN.md", root))),
    fileURLToPath(new URL("fonts/", root)));
  for (const theme of THEMES) {
    await writeFile(new URL(`terminal-${theme}.svg`, root), result[theme], "utf8");
  }
}
