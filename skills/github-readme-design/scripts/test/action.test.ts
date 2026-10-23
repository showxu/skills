import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import { parse } from "yaml";
import { temporary } from "./helpers.ts";

test("Action passes social and profile inputs literally and enforces member mode", async t => {
  const action = parse(await readFile(new URL("../action.yml", import.meta.url), "utf8"));
  const step = action.runs.steps.find((step: { name: string }) => step.name === "Run presentation command");
  const root = await temporary(t);
  const bin = join(root, "bin");
  await mkdir(bin);
  await writeFile(join(bin, "node"), '#!/bin/bash\nprintf "%s\\0" "$@"\n', { mode: 0o755 });
  const inputs: Record<string, string> = {
    design: "path with spaces/DESIGN.md", catalog: "catalog $(exit 99).json",
    fonts: "fonts 'quoted'", repository: ".github", icon: "icon; exit 99",
    assets: "preview assets", "artifact-dir": "regenerated assets",
  };
  const run = (values: Record<string, string | undefined>) => {
    const env: NodeJS.ProcessEnv = { ...process.env, PATH: `${bin}:${process.env.PATH}`, GITHUB_ACTION_PATH: "action path" };
    for (const [key, expression] of Object.entries(step.env)) {
      const input = /^\$\{\{ inputs\.([a-z-]+) \}\}$/.exec(expression as string)?.[1];
      assert.ok(input, `Input must be passed through env: ${expression}`);
      env[key] = values[input] ?? action.inputs[input].default ?? "";
    }
    assert.doesNotMatch(step.run, /\$\{\{ inputs\./);
    const result = spawnSync("/bin/bash", ["-e", "-c", step.run], { env, encoding: "utf8" });
    return { ...result, args: result.stdout.split("\0").slice(0, -1) };
  };
  for (const command of ["render", "check"]) {
    const result = run({ ...inputs, asset: "social-preview", command });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(result.args, ["action path/src/cli.ts", "social-preview", command,
      "--design", inputs.design, "--fonts", inputs.fonts, "--catalog", inputs.catalog,
      "--repository", ".github", "--icon", inputs.icon, ...(command === "render"
        ? ["--out", "preview assets/social-preview.png"]
        : ["--assets", inputs.assets, "--artifact-dir", inputs["artifact-dir"]])]);
  }
  const output = "custom output/social.png";
  assert.equal(run({ ...inputs, asset: "social-preview", command: "render", output }).args.at(-1), output);
  assert.notEqual(action.inputs.design.required, true);
  const terminal = { asset: "terminal", assets: "terminal assets", executable: "built cli" };
  const recording = run({ ...terminal, "recording-only": "true" });
  assert.equal(recording.status, 0, recording.stderr);
  assert.deepEqual(recording.args, ["action path/src/cli.ts", "terminal", "check",
    "--assets", terminal.assets, "--executable", terminal.executable, "--recording-only"]);
  const full = run({ ...terminal, design: inputs.design, fonts: inputs.fonts });
  assert.equal(full.status, 0, full.stderr);
  assert.deepEqual(full.args, ["action path/src/cli.ts", "terminal", "check",
    "--assets", terminal.assets, "--executable", terminal.executable,
    "--design", inputs.design, "--fonts", inputs.fonts]);
  for (const values of [
    { ...terminal, "recording-only": "yes" },
    { ...terminal, command: "render", "recording-only": "true" },
    { asset: "profile", "recording-only": "true" },
    { asset: "social-preview", "recording-only": "true" },
    { asset: "design", command: "lint", "recording-only": "true" },
  ]) {
    const invalid = run(values);
    assert.equal(invalid.status, 2);
    assert.deepEqual(invalid.args, []);
  }
  for (const command of ["render", "check"]) {
    const base = { design: inputs.design, catalog: inputs.catalog, asset: "profile", command };
    const publicResult = run(base);
    assert.equal(publicResult.status, 0, publicResult.stderr);
    assert.deepEqual(publicResult.args, ["action path/src/cli.ts", "profile", command,
      "--design", inputs.design, "--catalog", inputs.catalog, "--out", "profile/README.md"]);
    const member = run({ ...base, mode: "member", member: "member input.json",
      "catalog-revision": "1".repeat(40), output: "member/README.md", "artifact-dir": "artifact" });
    assert.equal(member.status, 0, member.stderr);
    assert.deepEqual(member.args, ["action path/src/cli.ts", "profile", command,
      "--design", inputs.design, "--catalog", inputs.catalog, "--out", "member/README.md",
      "--member", "member input.json", "--catalog-revision", "1".repeat(40),
      ...(command === "check" ? ["--artifact-dir", "artifact"] : [])]);
    for (const extra of [{ mode: "other" }, { member: "member.json" }, { "catalog-revision": "1".repeat(40) }]) {
      const invalid = run({ ...base, ...extra });
      assert.equal(invalid.status, 2);
      assert.deepEqual(invalid.args, []);
    }
  }
});
