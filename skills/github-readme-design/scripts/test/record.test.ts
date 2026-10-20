import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { chmod, copyFile, lstat, mkdir, mkdtemp, readFile, readdir, rm, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import type { TestContext } from "node:test";
import { setTimeout as delay } from "node:timers/promises";
import { stringify } from "yaml";
import { record } from "../src/terminal/record.ts";

const executable = fileURLToPath(new URL("./fixtures/executable.sh", import.meta.url));
const cli = new URL("../src/cli.ts", import.meta.url).href;
const outputRoot = fileURLToPath(new URL("../../../../.build/presentation-toolchain/tests/", import.meta.url));

async function removeTestDirectory(root: string): Promise<void> {
  await chmod(root, 0o700);
  for (const entry of await readdir(root, { withFileTypes: true })) {
    if (entry.isDirectory()) await removeTestDirectory(join(root, entry.name));
  }
  await rm(root, { recursive: true, force: true });
}

async function temporary(t: TestContext): Promise<string> {
  await mkdir(outputRoot, { recursive: true });
  const root = await mkdtemp(join(outputRoot, "record-"));
  t.after(() => removeTestDirectory(root));
  return root;
}

async function script(root: string, fields: Record<string, unknown> = {}): Promise<string> {
  const path = join(root, "script.yml");
  await writeFile(path, stringify({
    title: "Recorder", executable: "demo", steps: [{ run: "printf ready" }], ...fields,
  }));
  return path;
}

test("directory executable cannot redirect a recursive fixture copy outside home", async t => {
  const root = await temporary(t);
  const outside = join(root, "outside");
  await mkdir(outside);
  await mkdir(join(root, "fixture/bin/demo"), { recursive: true });
  await writeFile(join(root, "fixture/bin/demo/payload.txt"), "payload");
  const file = await script(root, { copy: [{ from: "fixture/bin", to: "bin" }] });
  await assert.rejects(record(file, outside, { tempRoot: root }), error => {
    assert.match(String(error), /outside.*regular executable file/);
    return true;
  });
  assert.deepEqual(await readdir(outside), []);
  assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
});

test("executable validation resolves links and precedes sandbox creation", async t => {
  const root = await temporary(t);
  const file = await script(root);
  const nonExecutable = join(root, "non-executable");
  await copyFile(executable, nonExecutable);
  await chmod(nonExecutable, 0o644);
  await symlink(root, join(root, "directory-link"));
  await symlink(join(root, "missing"), join(root, "dangling"));
  for (const name of ["non-executable", "directory-link", "missing", "dangling"]) {
    await assert.rejects(record(file, join(root, name), { tempRoot: join(root, "absent-temp-root") }), error => {
      assert.ok(String(error).includes(join(root, name)), String(error));
      assert.match(String(error), /regular executable file/);
      return true;
    });
  }
  await symlink(executable, join(root, "executable-link"));
  assert.equal((await record(file, join(root, "executable-link"), { tempRoot: root })).steps[0].output, "ready");
});

test("copies require fresh destinations, including existing bin and executable links", async t => {
  const root = await temporary(t);
  await mkdir(join(root, "fixture/nested"), { recursive: true });
  await writeFile(join(root, "fixture/nested/payload.txt"), "payload");
  for (const to of ["existing", "bin", "bin/demo", "bin/demo/child"]) {
    const file = await script(root, {
      files: { "existing/nested/keep.txt": "keep" },
      copy: [{ from: "fixture", to }],
    });
    await assert.rejects(record(file, executable, { tempRoot: root }), error => {
      assert.ok(String(error).includes(to === "bin/demo/child" ? "bin/demo" : to), String(error));
      assert.match(String(error), /fresh|symlink/);
      return true;
    });
  }
});

test("managed writes refuse both leaf and ancestor symlinks even when targets are inside home", async t => {
  const root = await temporary(t);
  for (const path of ["~/linked", "~/directory-link/payload.txt", "~/bin/demo"]) {
    const file = await script(root, { steps: [
      { run: "mkdir target-dir; printf original > target; ln -s target linked; ln -s target-dir directory-link", cwd: "~", show: false },
      { write: path, content: "changed" },
      { run: "printf ready" },
    ] });
    await assert.rejects(record(file, executable, { tempRoot: root }), error => {
      assert.match(String(error), /step 2:.*symlink/);
      assert.ok(String(error).includes(path.replace("~/", "").split("/")[0]), String(error));
      return true;
    });
  }
});

test("nested fixture links cannot leave fixture, while contained links copy ordinary files", async t => {
  const root = await temporary(t);
  await mkdir(join(root, "fixture/nested"), { recursive: true });
  await writeFile(join(root, "outside.txt"), "outside");
  await symlink("../../outside.txt", join(root, "fixture/nested/link"));
  const file = await script(root, { copy: [{ from: "fixture", to: "copied" }] });
  await assert.rejects(record(file, executable, { tempRoot: root }), /fixture\/nested\/link: path escapes/);
  await rm(join(root, "fixture/nested/link"));
  await writeFile(join(root, "fixture/source.txt"), "inside");
  await symlink("../source.txt", join(root, "fixture/nested/link"));
  await script(root, {
    copy: [{ from: "fixture", to: "copied" }],
    expect: [{ file: "~/copied/nested/link", equals: "inside" }],
  });
  assert.equal((await record(file, executable, { tempRoot: root })).steps[0].output, "ready");
});

for (const operation of ["expect", "write"] as const) {
  for (const [kind, setup] of [
    ["FIFO", "mkfifo special"],
    ["directory", "mkdir special"],
    ["symlink", "printf ready > ordinary; ln -s ordinary special"],
  ]) {
    test(`${operation} rejects a ${kind} target before opening it`, async t => {
      const root = await temporary(t);
      const file = await script(root, {
        steps: [{ run: setup }, ...(operation === "write" ? [{ write: "~/project/special", content: "ready" }] : [])],
        ...(operation === "expect" ? { expect: [{ file: "~/project/special", equals: "ready" }] } : {}),
      });
      const result = spawnSync(process.execPath, [fileURLToPath(cli), "terminal", "record",
        "--script", file, "--executable", executable, "--out", join(root, "recording.json")], {
        env: { ...process.env, TMPDIR: root }, encoding: "utf8", timeout: 3_000, killSignal: "SIGKILL",
      });
      assert.equal(result.error, undefined, `recorder blocked on ${kind}: ${result.error}`);
      assert.equal(result.status, 1, result.stderr);
      assert.match(result.stderr, /special.*(?:regular file|ordinary file|symlink)/);
      assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
    });
  }
}

for (const source of ["step", "fixture"] as const) {
  for (const fail of [false, true]) {
    test(`cleanup removes non-writable directories from a ${source} after ${fail ? "failure" : "success"}`, async t => {
      const root = await temporary(t);
      const outside = join(root, "outside");
      await mkdir(outside);
      await writeFile(join(outside, "keep.txt"), "keep");
      await chmod(outside, 0o500);
      await mkdir(join(root, "fixture/locked/nested"), { recursive: true });
      await writeFile(join(root, "fixture/locked/nested/payload"), "payload");
      await chmod(join(root, "fixture/locked/nested"), 0o500);
      await chmod(join(root, "fixture/locked"), 0o500);
      const file = await script(root, {
        env: { OUTSIDE: outside },
        ...(source === "fixture" ? { copy: [{ from: "fixture", to: "copied" }] } : {}),
        steps: [
          { run: source === "step"
            ? 'mkdir -p locked/nested; printf payload > locked/nested/payload; ln -s "$OUTSIDE" locked/outside; chmod 500 locked/nested locked "$HOME"'
            : 'ln -s "$OUTSIDE" copied/locked-link', cwd: "~", show: false },
          { run: fail ? "exit 7" : "printf ready" },
        ],
      });
      if (fail) await assert.rejects(record(file, executable, { tempRoot: root }), /exit 7/);
      else assert.equal((await record(file, executable, { tempRoot: root })).steps[0].output, "ready");
      assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
      assert.equal((await lstat(outside)).mode & 0o777, 0o500);
      assert.equal(await readFile(join(outside, "keep.txt"), "utf8"), "keep");
    });
  }
}

test("cleanup reports the offending path and exits nonzero if removal still fails", async t => {
  const root = await temporary(t);
  const file = await script(root);
  const runner = join(root, "removal-failure.mjs");
  await writeFile(runner, `
    import fs from "node:fs/promises";
    import { syncBuiltinESMExports } from "node:module";
    const original = fs.rm;
    fs.rm = async (path, ...args) => {
      if (String(path).includes("presentation-home-")) {
        throw Object.assign(new Error("removal denied"), {code: "EACCES", path: path + "/stuck"});
      }
      return original(path, ...args);
    };
    syncBuiltinESMExports();
    const { main } = await import(${JSON.stringify(cli)});
    process.exitCode = await main(process.argv.slice(2));
  `);
  const result = spawnSync(process.execPath, [runner, "terminal", "record", "--script", file,
    "--executable", executable, "--out", join(root, "recording.json")], {
    env: { ...process.env, TMPDIR: root }, encoding: "utf8",
  });
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /presentation-home-[^\n]+\/stuck.*removal denied/);
  assert.equal((await readdir(root)).filter(name => name.startsWith("presentation-home-")).length, 1);
  await assert.rejects(readFile(join(root, "recording.json")), { code: "ENOENT" });
});

// The child pauses at a completed filesystem operation until the parent releases
// it, making each signal land in the selected phase without production hooks.
for (const phase of ["creation", "copy", "copy-file", "write", "command", "expect", "removal"] as const) {
  for (const signal of ["SIGINT", "SIGTERM"] as const) {
    test(`${signal} during ${phase} removes the sandbox and returns its conventional status`, { timeout: 15_000 }, async t => {
      const root = await temporary(t);
      await mkdir(join(root, "fixture"));
      await writeFile(join(root, "fixture/payload.txt"), "payload");
      const marker = join(root, "first-command");
      const pidFile = join(root, "worker.pid");
      const file = await script(root, {
        env: { MARKER: marker, PID_FILE: pidFile },
        files: { managed: "ready" },
        copy: [{ from: "fixture", to: "copied" }],
        steps: [{ run: phase === "command"
          ? 'sleep 30 & worker=$!; printf "%s" "$worker" > "$PID_FILE"; printf ready; wait'
          : 'touch "$MARKER"; printf ready' }],
        expect: [{ file: "~/managed", equals: "ready" }],
      });
      const operation = { creation: "mkdtemp", copy: "readdir", "copy-file": "copyFile", write: "writeFile", command: "spawn", expect: "readFile", removal: "rm" }[phase];
      const match = phase === "creation" || phase === "removal"
        ? `String(args[0]).includes("presentation-home-")`
        : phase === "copy-file" ? `String(args[1]).includes("presentation-home-")`
        : phase === "copy"
          ? `String(args[0]).endsWith("/fixture")`
          : `String(args[0]).includes("presentation-home-") && String(args[0]).endsWith("/managed")`;
      const runner = join(root, "interrupt.mjs");
      await writeFile(runner, `
        import fs from "node:fs/promises";
        import cp from "node:child_process";
        import { syncBuiltinESMExports } from "node:module";
        ${phase === "command" ? `
        const original = cp.spawn;
        cp.spawn = (...args) => {
          const child = original(...args);
          child.stdout.once("data", () => process.send("ready"));
          child.once("close", () => process.disconnect());
          return child;
        };
        ` : `
        const original = fs[${JSON.stringify(operation)}];
        let paused = false;
        fs[${JSON.stringify(operation)}] = async (...args) => {
          const result = await original(...args);
          if (!paused && (${match})) {
            paused = true;
            await new Promise(resolve => {
              process.once("message", resolve);
              process.send("ready");
            });
            process.disconnect();
          }
          return result;
        };
        `}
        syncBuiltinESMExports();
        const { main } = await import(${JSON.stringify(cli)});
        process.exitCode = await main(process.argv.slice(2));
      `);
      const child = spawn(process.execPath, [runner, "terminal", "record", "--script", file,
        "--executable", executable, "--out", join(root, "recording.json")], {
        env: { ...process.env, TMPDIR: root }, stdio: ["ignore", "pipe", "pipe", "ipc"],
      });
      t.after(() => { if (child.exitCode === null && child.signalCode === null) child.kill("SIGKILL"); });
      let stderr = "";
      child.stderr!.on("data", chunk => { stderr += String(chunk); });
      const closed = new Promise<{ code: number | null; signal: NodeJS.Signals | null }>((resolve, reject) => {
        child.once("error", reject);
        child.once("close", (code, signal) => resolve({ code, signal }));
      });
      let ready = false;
      child.once("message", () => {
        ready = true;
        child.kill(signal);
        const release = setTimeout(() => {
          if (child.connected) child.send("continue", () => {});
        }, 100);
        release.unref();
      });
      const result = await closed;
      assert.ok(ready, stderr);
      assert.deepEqual(result, { code: signal === "SIGINT" ? 130 : 143, signal: null }, stderr);
      assert.equal((await readdir(root)).some(name => name.startsWith("presentation-home-")), false);
      if (["creation", "copy", "copy-file", "write"].includes(phase)) {
        await assert.rejects(readFile(marker), { code: "ENOENT" });
      }
      if (phase === "command") {
        const pid = Number(await readFile(pidFile, "utf8"));
        let running = true;
        for (let attempt = 0; attempt < 100 && running; attempt++) {
          try { process.kill(pid, 0); await delay(10); }
          catch (error) {
            assert.equal((error as NodeJS.ErrnoException).code, "ESRCH");
            running = false;
          }
        }
        assert.equal(running, false, `command descendant ${pid} survived ${signal}`);
      }
      await assert.rejects(readFile(join(root, "recording.json")), { code: "ENOENT" });
    });
  }
}
