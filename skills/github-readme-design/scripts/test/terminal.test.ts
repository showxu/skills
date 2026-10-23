import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFile, cp, mkdir, mkdtemp, readFile, readdir, rm, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import type { TestContext } from "node:test";
import type { Font } from "fontkit";
import { open } from "fontkit";
import { stringify } from "yaml";
import { changedSteps, check, regeneration } from "../src/check.ts";
import { parseDesign, readDesign } from "../src/design.ts";
import { matchesFont, number, resolveFont, variations } from "../src/fonts.ts";
import { environment, normalizeOutput, parseRecording, parseScript, record, recordingJSON } from "../src/terminal/record.ts";
import { expandTabs, render, THEMES } from "../src/terminal/render.ts";

const fixture = fileURLToPath(new URL("./fixtures/", import.meta.url));
const fonts = join(fixture, "fonts");
const designPath = join(fixture, "DESIGN.md");
const designText = await readFile(designPath, "utf8");
const golden = parseRecording(await readFile(join(fixture, "recording.json"), "utf8"));
const executable = join(fixture, "executable.sh");
const scriptText = await readFile(join(fixture, "session/script.yml"), "utf8");
const outputRoot = fileURLToPath(new URL("../../../../.build/presentation-toolchain/tests/", import.meta.url));

async function temporary(t: TestContext): Promise<string> {
  await mkdir(outputRoot, { recursive: true });
  const root = await mkdtemp(join(outputRoot, "case-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  return root;
}

async function session(t: TestContext): Promise<string> {
  const root = await temporary(t);
  await cp(join(fixture, "session"), root, { recursive: true });
  return root;
}

function cli(...args: string[]) {
  return spawnSync(process.execPath, [fileURLToPath(new URL("../src/cli.ts", import.meta.url)), ...args], { encoding: "utf8" });
}

function decodeXMLText(value: string): string {
  const entities: Record<string, string> = {
    "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&apos;": "'", "&#32;": " ",
  };
  return value.replace(/&(?:amp|lt|gt|quot|apos|#32);/g, entity => entities[entity]);
}

test("official DESIGN parser resolves tokens and merges only listed dark properties", async () => {
  const design = await readDesign(designPath);
  assert.equal(design.components.light.get("terminal")!.get("width"), design.components.dark.get("terminal")!.get("width"));
  assert.notDeepEqual(design.components.light.get("terminal")!.get("textColor"), design.components.dark.get("terminal")!.get("textColor"));
  assert.equal(design.typography.get("terminal")!.fontVariation, "'MONO' 1");
  assert.throws(() => parseDesign(designText.replace("{colors.ink}", "{colors.absent}"), "broken.md"), /broken\.md:.*broken-ref/);
  assert.throws(() => parseDesign(designText.replace('primary: "#3B35D1"', 'primary: "#FBFBFE"'), "contrast.md"), /contrast\.md:.*contrast.*warning/);
});

test("golden outlined SVGs are deterministic and share geometry", async () => {
  const design = await readDesign(designPath);
  const result = await render(golden, design, fonts);
  assert.deepEqual(await render(golden, design, fonts), result);
  for (const theme of THEMES) {
    assert.equal(result[theme], await readFile(join(fixture, `terminal-${theme}.svg`), "utf8"));
    assert.match(result[theme], /width="560" height="284"/);
    assert.match(result[theme], /aria-labelledby="title desc"/);
    assert.match(result[theme], /<desc id="desc">\$ demo inspect\nWorkspace: ~\/project/);
    assert.doesNotMatch(result[theme], /<text|<style|transform=|xlink:|\r/);
    assert.ok(result[theme].endsWith("</svg>\n"));
    const ids = [...result[theme].matchAll(/<path id="g(\d+)"/g)].map(match => Number(match[1]));
    assert.deepEqual(ids, [...new Set(ids)].sort((a, b) => a - b));
    assert.doesNotMatch(result[theme], /(?:="|[MLQC ])-0(?:[ "A-Z])/);
  }
  assert.equal(result.light.replaceAll(/#[A-F0-9]{6}/g, "#COLOR"), result.dark.replaceAll(/#[A-F0-9]{6}/g, "#COLOR"));
  assert.match(result.light, /<g fill="#67657F"><use[^>]+y="22.01"/);
  assert.match(result.light, /<g fill="#3B35D1"><use[^>]+x="20" y="69.26"/);
});

test("tabs use eight-cell stops, empty outputs add no line, transcript is escaped", async () => {
  assert.equal(expandTabs("a\tb"), "a       b");
  assert.equal(expandTabs("x\ty", 2), "x     y");
  const result = await render({ title: "A & B", steps: [{ command: "x\ty", output: "<a>\t&" }] }, await readDesign(designPath), fonts);
  assert.match(result.light, /height="116"/);
  assert.match(result.light, /<title id="title">A &amp; B/);
  assert.match(result.light, /\$ x {5}y\n&lt;a&gt; {5}&amp;/);
});

test("SVG descriptions encode trailing spaces and preserve transcript text", async () => {
  const recording = { title: "Whitespace", steps: [{
    command: "demo  diff  ",
    output: " \n   \n  <a> & \"b\" 'c' &#32;  \n  leading  and interior\nlast  ",
  }] };
  const transcript = `$ ${recording.steps[0].command}\n${recording.steps[0].output}`;
  const encoded = [
    "$ demo  diff&#32;&#32;",
    "&#32;",
    "&#32;&#32;&#32;",
    "  &lt;a&gt; &amp; &quot;b&quot; &apos;c&apos; &amp;#32;&#32;&#32;",
    "  leading  and interior",
    "last&#32;&#32;",
  ].join("\n");
  const result = await render(recording, await readDesign(designPath), fonts);
  for (const theme of THEMES) {
    assert.doesNotMatch(result[theme], /[ \t]+$/m, theme);
    const description = result[theme].match(/<desc id="desc">([\s\S]*?)<\/desc>/);
    assert.ok(description, theme);
    assert.equal(description[1], encoded, theme);
    assert.equal(decodeXMLText(description[1]), transcript, theme);
  }
});

test("SVG titles encode trailing spaces and preserve title text", async () => {
  const title = `  A & <B> "C" 'D' &#32; `;
  const result = await render({ title, steps: [{ command: "demo", output: "" }] }, await readDesign(designPath), fonts);
  for (const theme of THEMES) {
    assert.doesNotMatch(result[theme], /[ \t]+$/m, theme);
    const element = result[theme].match(/<title id="title">([\s\S]*?)<\/title>/);
    assert.ok(element, theme);
    assert.equal(element[1], "  A &amp; &lt;B&gt; &quot;C&quot; &apos;D&apos; &amp;#32;&#32;", theme);
    assert.equal(decodeXMLText(element[1]), title, theme);
  }
});

test("font selection uses variation cmap advances without shaping", async () => {
  const typography = (await readDesign(designPath)).typography.get("terminal")!;
  const face = await resolveFont(fonts, typography);
  const run = face.run("fi ->", "step 1");
  assert.equal(run.placements.length, 5);
  assert.equal(run.advance, [..."fi ->"].reduce((sum, char) => sum + face.font.glyphForCodePoint(char.codePointAt(0)!).advanceWidth * face.scale, 0));
  assert.equal(face.ascent, face.font.hhea.ascent * face.scale);
  assert.equal(face.descent, Math.abs(face.font.hhea.descent) * face.scale);
  assert.equal(number(-0.001), "0");
  assert.equal(number(2.5), "2.5");
  assert.deepEqual(variations("'MONO' 1", "variation"), { MONO: 1 });
  assert.throws(() => variations("'wght' 400", "typography.terminal.fontVariation"), /fontWeight/);
  for (const bad of ["MONO 1", "'MONO' 1,", "'MONO' 1, 'MONO' 0", "'MONO' NaN"]) {
    assert.throws(() => variations(bad, "variation"), /variation/);
  }
  const font = await open(join(fonts, "GoogleSansCode[MONO,wght].ttf")) as Font;
  assert.ok(matchesFont(font, typography, { MONO: 1 }));
  assert.equal(matchesFont(font, { ...typography, fontWeight: 900 }, { MONO: 1 }), false);
  assert.equal(matchesFont(font, typography, { MONO: 2 }), false);
  assert.equal(matchesFont(font, typography, { FAKE: 1 }), false);
  const staticFont = {
    getName: (key: string) => key === "preferredFamily" ? "Google Sans Code" : "Legacy Family",
    variationAxes: {}, "OS/2": { usWeightClass: 400 },
  } as unknown as Font;
  assert.equal(matchesFont(staticFont, typography, { MONO: 1 }), false);
  assert.ok(matchesFont(staticFont, { ...typography, fontVariation: undefined }, {}));
  assert.equal(matchesFont(staticFont, { ...typography, fontVariation: undefined, fontWeight: 500 }, {}), false);
});

test("ambiguous or absent font selection names candidates", async t => {
  const root = await temporary(t);
  const source = join(fonts, "GoogleSansCode[MONO,wght].ttf");
  await copyFile(source, join(root, "one.ttf"));
  await copyFile(source, join(root, "two.ttf"));
  const typography = (await readDesign(designPath)).typography.get("terminal")!;
  await assert.rejects(resolveFont(root, typography), /matched 2:.*one.ttf.*two.ttf/);
  await assert.rejects(resolveFont(root, { ...typography, fontFamily: "Absent" }), /matched 0:.*candidates:.*one.ttf.*two.ttf/);
});

test("fontVariation accepts CSS numbers with signs, fractions and exponents", async () => {
  for (const [text, expected] of [
    ["1e0", 1], ["+1", 1], [".5", 0.5], ["-.5", -0.5],
    ["+1.25E-2", 0.0125], ["-2e+1", -20], ["5E-1", 0.5], ["0", 0],
  ] as const) {
    assert.deepEqual(variations(`'MONO' ${text}`, "fontVariation"), { MONO: expected });
  }
  assert.deepEqual(variations(`"MONO" +.5e0, 'slnt' -1e1`, "fontVariation"), { MONO: 0.5, slnt: -10 });
  const typography = (await readDesign(designPath)).typography.get("terminal")!;
  const scientific = await resolveFont(fonts, { ...typography, fontVariation: "'MONO' 1e0" });
  const ordinary = await resolveFont(fonts, typography);
  assert.equal(scientific.run("mono", "test").advance, ordinary.run("mono", "test").advance);
});

test("fontVariation rejects malformed numbers and keeps weight in fontWeight", () => {
  for (const value of ["1.", ".", "+", "1e", "1e+", "1e--2", "1 e0", "+ 1", "1e2px", "0x1", "NaN", "Infinity", "1e999"]) {
    assert.throws(() => variations(`'MONO' ${value}`, "fontVariation"), /fontVariation: expected CSS/);
  }
  for (const value of ["400", "+400", "4e2"]) {
    assert.throws(() => variations(`'wght' ${value}`, "fontVariation"), /wght must come only from fontWeight/);
  }
});

test("width, missing glyphs, control characters, units and geometry overrides fail explicitly", async () => {
  const design = await readDesign(designPath);
  await assert.rejects(render({ title: "Demo", steps: [{ command: "demo wide", output: "W".repeat(120) }] }, design, fonts), /step 1 \(demo wide\).*maximum 830px/);
  await assert.rejects(render({ title: "Demo", steps: [{ command: "demo glyph", output: "\u{10ffff}" }] }, design, fonts), /step 1.*missing glyph.*U\+10FFFF/);
  await assert.rejects(render({ title: "Demo", steps: [{ command: "demo escape", output: "\x1b[31m" }] }, design, fonts), /step 1.*U\+001B/);
  await assert.rejects(render(golden, parseDesign(designText.replace("terminal-padding: 20px", "terminal-padding: 2rem")), fonts), /terminal.padding.*px/);
  await assert.rejects(render(golden, parseDesign(designText.replace("fontSize: 14px", "fontSize: 1rem")), fonts), /terminal.fontSize.*px/);
  const dark = parseDesign(designText.replace("  terminal-dark:\n", "  terminal-dark:\n    padding: 21px\n"));
  await assert.rejects(render(golden, dark, fonts), /geometry and typography must be identical/);
});

test("record executes hidden setup, writes, copies, expectations and fixed environment", async t => {
  const root = await session(t);
  const result = await record(join(root, "script.yml"), executable, { tempRoot: root });
  assert.deepEqual(result, golden);
  assert.equal(recordingJSON(result), await readFile(join(fixture, "recording.json"), "utf8"));
  assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
  assert.equal(normalizeOutput("/private/var/demo/a\n/var/demo/b\n\n", "/var/demo", "/private/var/demo"), "~/a\n~/b\n");
  assert.equal(normalizeOutput("x\r\n", "/sandbox", "/sandbox"), "x\r");
  assert.equal(environment("/sandbox").GIT_COMMITTER_DATE, "2026-01-01T00:00:00Z");
});

test("unknown schema keys, fixed environment keys and malformed expectations fail", () => {
  for (const key of Object.keys(environment("/sandbox"))) {
    assert.throws(() => parseScript(scriptText.replace("  EXAMPLE: fixture", `  ${key}: forbidden`)), new RegExp(`env\\.${key}: fixed`));
  }
  for (const source of [
    scriptText + "unknown: true\n",
    scriptText.replace("  - run: demo inspect", "  - run: demo inspect\n    typo: true"),
    scriptText.replace("    contains: Copied", "    contains: Copied\n    equals: Copied"),
    scriptText.replace("    contains: Copied\n", ""),
    scriptText.replace("    show: false", "    show: 'false'"),
    scriptText.replace("executable: demo", "executable: ../demo"),
    scriptText + "title: duplicate\n",
  ]) assert.throws(() => parseScript(source));
});

test("failed commands, stderr, assertions and timeout clean the sandbox", async t => {
  const root = await temporary(t);
  for (const [run, expected] of [
    ["demo failure", /step 1.*exit 3; stderr: failed/],
    ["demo stderr", /step 1.*exit 0; stderr: warning/],
    ["demo sleep", /step 1.*timed out/],
  ] as const) {
    const script = join(root, "script.yml");
    await writeFile(script, stringify({ title: "Failure", executable: "demo", steps: [{ run }] }));
    await assert.rejects(record(script, executable, { timeoutMs: 100, tempRoot: root }), expected);
    assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
  }
  await writeFile(join(root, "script.yml"), stringify({ title: "Expect", executable: "demo", files: { result: "actual\n" }, steps: [{ run: "demo empty" }], expect: [{ file: "~/result", equals: "actual" }] }));
  await assert.rejects(record(join(root, "script.yml"), executable, { tempRoot: root }), /expect ~\/result: equals/);
  assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
});

test("recorder file operations stay inside the sandbox and fixture", async t => {
  const root = await temporary(t);
  const script = join(root, "script.yml");
  for (const path of ["../escape", "/absolute/escape", "~someone/file"]) {
    await writeFile(script, stringify({ title: "Paths", executable: "demo", files: { [path]: "x" }, steps: [{ run: "demo empty" }] }));
    await assert.rejects(record(script, executable, { tempRoot: root }), /escape|inside the sandbox/);
  }
  await mkdir(join(root, "fixture"));
  await symlink(executable, join(root, "fixture", "outside.sh"));
  await writeFile(script, stringify({ title: "Paths", executable: "demo", copy: [{ from: "fixture", to: "copied" }], steps: [{ run: "demo empty" }] }));
  await assert.rejects(record(script, executable, { tempRoot: root }), /path escapes/);
  await writeFile(script, stringify({ title: "Paths", executable: "demo", steps: [
    { run: "ln -s / project-link", cwd: "~", show: false }, { write: "~/project-link/escape", content: "x" }, { run: "demo empty" },
  ] }));
  await assert.rejects(record(script, executable, { tempRoot: root }), /step 2:.*symlink.*project-link/);
});

test("check passes, detects changed output and preserves committed bytes while copying complete artifacts", async t => {
  const root = await session(t);
  for (const name of ["recording.json", "terminal-light.svg", "terminal-dark.svg"]) await copyFile(join(fixture, name), join(root, name));
  const options = { assets: root, executable, design: designPath, fonts, artifactDir: join(await temporary(t), "artifact") };
  assert.equal(await check(options, () => {}), true);
  const changed = structuredClone(golden);
  changed.steps[0].output = "unexpected output";
  const changedBytes = recordingJSON(changed);
  await writeFile(join(root, "recording.json"), changedBytes);
  const messages: string[] = [];
  assert.equal(await check(options, line => messages.push(line)), false);
  assert.match(messages.join("\n"), /changed step 1: demo inspect/);
  assert.match(messages.join("\n"), /--- .*recording.json\n\+\+\+ regenerated/);
  assert.match(messages.join("\n"), /terminal record.*--script/);
  assert.equal(await readFile(join(root, "recording.json"), "utf8"), changedBytes);
  assert.equal(await readFile(join(options.artifactDir, "recording.json"), "utf8"), recordingJSON(golden));
  assert.equal(await readFile(join(options.artifactDir, "script.yml"), "utf8"), scriptText);
  assert.equal(await readFile(join(options.artifactDir, "fixture/note.txt"), "utf8"), "Copied fixture ready.\n");
  assert.deepEqual((await readdir(options.artifactDir)).sort(), ["fixture", "recording.json", "script.yml", "terminal-dark.svg", "terminal-light.svg"]);
  await copyFile(join(fixture, "recording.json"), join(root, "recording.json"));
  await writeFile(join(root, "terminal-dark.svg"), "stale\n");
  messages.length = 0;
  assert.equal(await check(options, line => messages.push(line)), false);
  assert.match(messages.join("\n"), /terminal-dark.svg: differs; recording matches; DESIGN or the renderer changed/);
});

test("changed steps report replacements, additions and removals by index", () => {
  assert.match(changedSteps(golden, { ...golden, steps: golden.steps.slice(0, 1) }).join("\n"), /removed step 2: demo empty/);
  assert.match(changedSteps({ ...golden, steps: [] }, golden).join("\n"), /added step 1: demo inspect/);
  assert.match(changedSteps(golden, { ...golden, steps: [{ command: "new", output: "" }] }).join("\n"), /demo inspect -> new/);
});

test("recording-only check ignores SVGs and rendering inputs and reports recording drift", async t => {
  const root = await session(t);
  const recording = join(root, "recording.json");
  await copyFile(join(fixture, "recording.json"), recording);
  await writeFile(join(root, "terminal-light.svg"), "stale SVG\n");
  const options = { assets: root, executable, recordingOnly: true,
    design: join(root, "absent.md"), fonts: join(root, "absent-fonts"),
    artifactDir: join(await temporary(t), "artifact") };
  const messages: string[] = [];
  assert.equal(await check(options, line => messages.push(line)), true);
  assert.match(messages.join("\n"), /recording.json matches/);
  const changed = recordingJSON({ ...golden, steps: [{ command: "demo inspect", output: "drift" }] });
  await writeFile(recording, changed);
  messages.length = 0;
  assert.equal(await check(options, line => messages.push(line)), false);
  assert.match(messages.join("\n"), /changed step 1: demo inspect/);
  assert.match(messages.join("\n"), /added step 2/);
  assert.match(messages.join("\n"), /--- .*recording.json\n\+\+\+ regenerated/);
  assert.doesNotMatch(messages.join("\n"), /terminal render|terminal-.*svg/);
  assert.equal(await readFile(recording, "utf8"), changed);
  assert.equal(await readFile(join(root, "terminal-light.svg"), "utf8"), "stale SVG\n");
  assert.deepEqual(await readdir(options.artifactDir), ["recording.json"]);
  assert.equal(await readFile(join(options.artifactDir, "recording.json"), "utf8"), recordingJSON(golden));
  const result = spawnSync("/bin/sh", ["-c", regeneration({ assets: root, executable, recordingOnly: true })], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(await check({ assets: root, executable, recordingOnly: true }, () => {}), true);
});

test("recording-only CLI needs assets and an executable and rejects invalid flag usage", async t => {
  const root = await session(t);
  const args = ["terminal", "check", "--assets", root, "--executable", executable];
  const missing = cli(...args, "--recording-only");
  assert.equal(missing.status, 1);
  assert.match(missing.stdout, /missing committed recording/);
  await copyFile(join(fixture, "recording.json"), join(root, "recording.json"));
  assert.equal(cli(...args, "--recording-only").status, 0);
  for (const invalid of [
    args, [...args, "--design", designPath], [...args, "--fonts", fonts],
    ["terminal", "check", "--recording-only", "--assets", root],
    ["terminal", "check", "--recording-only", "--executable", executable],
    [...args, "--recording-only=false"], [...args, "--recording-only", "false"],
    [...args, "--recording-only", "--recording-only"],
    ["terminal", "render", "--recording-only"], ["profile", "check", "--recording-only"],
  ]) assert.equal(cli(...invalid).status, 2, invalid.join(" "));
  const failed = cli("terminal", "check", "--recording-only", "--assets", root, "--executable", join(root, "missing"));
  assert.equal(failed.status, 1);
  assert.match(failed.stderr, /terminal record/);
  assert.doesNotMatch(failed.stderr, /terminal render|TypeError/);
});

test("recording-only artifacts cannot overwrite inputs through overlapping or aliased directories", async t => {
  const root = await session(t);
  const input = join(root, "fixture", "data");
  await mkdir(input);
  await writeFile(join(input, "recording.json"), "fixture input\n");
  const output = await temporary(t);
  const alias = join(output, "alias");
  await symlink(input, alias);
  for (const artifactDir of [root, input, join(root, "new"), join(root, ".."), alias]) {
    await assert.rejects(check({ assets: root, executable, recordingOnly: true, artifactDir }, () => {}),
      /artifact directory must be separate from assets/);
  }
  assert.equal(await readFile(join(input, "recording.json"), "utf8"), "fixture input\n");
});

test("regeneration commands work outside the package and quote paths", async t => {
  const root = await temporary(t);
  const assets = join(root, "demo's assets");
  await cp(join(fixture, "session"), assets, { recursive: true });
  const options = { assets, design: designPath, fonts, executable };
  const result = spawnSync("/bin/sh", ["-c", regeneration(options)], { cwd: root, encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(await check(options, () => {}), true);
});

test("CLI exit codes distinguish success, drift, validation and usage", async t => {
  const root = await session(t);
  assert.equal(cli("design", "lint", "--design", designPath).status, 0);
  assert.equal(cli("terminal", "unknown").status, 2);
  assert.equal(cli("terminal", "record", "--script", join(root, "script.yml")).status, 2);
  assert.equal(cli("design", "lint", "--design", designPath, "--unknown", "x").status, 2);
  const recording = join(root, "recording.json");
  assert.equal(cli("terminal", "record", "--script", join(root, "script.yml"), "--executable", executable, "--out", recording).status, 0);
  assert.equal(cli("terminal", "render", "--recording", recording, "--design", designPath, "--fonts", fonts, "--out-dir", root).status, 0);
  const checkArgs = ["terminal", "check", "--assets", root, "--design", designPath, "--fonts", fonts, "--executable", executable];
  assert.equal(cli(...checkArgs).status, 0);
  await writeFile(recording, recordingJSON({ ...golden, steps: [{ command: "demo inspect", output: "drift" }] }));
  const failed = cli(...checkArgs, "--artifact-dir", join(await temporary(t), "artifact"));
  assert.equal(failed.status, 1);
  assert.match(failed.stdout, /changed step 1: demo inspect/);
  const invalid = join(root, "invalid.md");
  await writeFile(invalid, designText.replace("{colors.ink}", "{colors.absent}"));
  const lint = cli("design", "lint", "--design", invalid);
  assert.equal(lint.status, 1);
  assert.match(lint.stderr, /broken-ref/);
});
