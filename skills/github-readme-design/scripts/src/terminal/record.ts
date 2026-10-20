import { spawn } from "node:child_process";
import { cp, lstat, mkdir, mkdtemp, readFile, readdir, realpath, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { parseDocument } from "yaml";
import { keys, list, message, object, plain, string } from "../validation.ts";

export interface Recording {
  title: string;
  steps: { command: string; output: string }[];
}

interface RunStep { run: string; cwd: string; show: boolean }
interface WriteStep { write: string; content: string }
interface Script {
  title: string;
  executable: string;
  env: Record<string, string>;
  files: Record<string, string>;
  copy: { from: string; to: string }[];
  steps: (RunStep | WriteStep)[];
  expect: { file: string; contains?: string; equals?: string }[];
}

export function environment(home: string): Record<string, string> {
  return {
    HOME: home,
    PATH: `${join(home, "bin")}:/usr/bin:/bin:/usr/sbin:/sbin`,
    TMPDIR: join(home, "tmp"),
    LC_ALL: "C",
    TERM: "dumb",
    NO_COLOR: "1",
    GIT_CONFIG_NOSYSTEM: "1",
    GIT_CONFIG_GLOBAL: "/dev/null",
    GIT_TERMINAL_PROMPT: "0",
    GIT_ALLOW_PROTOCOL: "file",
    GIT_AUTHOR_NAME: "Demo",
    GIT_AUTHOR_EMAIL: "demo@example.invalid",
    GIT_COMMITTER_NAME: "Demo",
    GIT_COMMITTER_EMAIL: "demo@example.invalid",
    GIT_AUTHOR_DATE: "2026-01-01T00:00:00Z",
    GIT_COMMITTER_DATE: "2026-01-01T00:00:00Z",
  };
}

function strings(value: unknown, path: string): Record<string, string> {
  return Object.fromEntries(Object.entries(object(value, path)).map(([key, item]) =>
    [key, string(item, `${path}.${key}`, true)]));
}

export function parseScript(text: string, file = "script.yml"): Script {
  const document = parseDocument(text, { uniqueKeys: true });
  if (document.errors.length || document.warnings.length) {
    throw new Error(`${file}: ${[...document.errors, ...document.warnings].map(message).join("\n")}`);
  }
  const value = object(document.toJS({ maxAliasCount: 0 }), file);
  keys(value, ["title", "executable", "env", "files", "copy", "steps", "expect"], file);
  const title = string(value.title, `${file}.title`);
  plain(title, `${file}.title`);
  const executable = string(value.executable, `${file}.executable`);
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(executable)) {
    throw new Error(`${file}.executable: expected a bare executable name`);
  }
  const env = strings(value.env ?? {}, `${file}.env`);
  for (const key of Object.keys(env)) {
    if (Object.hasOwn(environment(""), key)) throw new Error(`${file}.env.${key}: fixed environment key cannot be overridden`);
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key) || env[key].includes("\0")) {
      throw new Error(`${file}.env.${key}: invalid environment entry`);
    }
  }
  const steps = list(value.steps, `${file}.steps`).map((item, index) => {
    const path = `${file} step ${index + 1}`;
    const step = object(item, path);
    if ("run" in step) {
      keys(step, ["run", "cwd", "show"], path);
      if (step.show !== undefined && typeof step.show !== "boolean") throw new Error(`${path}.show: expected a boolean`);
      const run = string(step.run, `${path}.run`);
      plain(run, `${path}.run`, step.show === false);
      return { run, cwd: string(step.cwd ?? "~/project", `${path}.cwd`), show: step.show !== false };
    }
    keys(step, ["write", "content"], path);
    return { write: string(step.write, `${path}.write`), content: string(step.content, `${path}.content`, true) };
  });
  if (!steps.some(step => "run" in step && step.show)) throw new Error(`${file}.steps: needs at least one shown run step`);
  const copy = list(value.copy ?? [], `${file}.copy`).map((item, index) => {
    const path = `${file}.copy[${index}]`;
    const entry = object(item, path);
    keys(entry, ["from", "to"], path);
    return { from: string(entry.from, `${path}.from`), to: string(entry.to, `${path}.to`) };
  });
  const expect = list(value.expect ?? [], `${file}.expect`).map((item, index) => {
    const path = `${file}.expect[${index}]`;
    const entry = object(item, path);
    keys(entry, ["file", "contains", "equals"], path);
    if (("contains" in entry) === ("equals" in entry)) throw new Error(`${path}: requires exactly one of contains or equals`);
    const target = string(entry.file, `${path}.file`);
    return "contains" in entry
      ? { file: target, contains: string(entry.contains, `${path}.contains`, true) }
      : { file: target, equals: string(entry.equals, `${path}.equals`, true) };
  });
  return { title, executable, env, files: strings(value.files ?? {}, `${file}.files`), copy, steps, expect };
}

function inside(root: string, path: string, label: string): string {
  const result = resolve(root, path);
  const rel = relative(root, result);
  if (rel === ".." || rel.startsWith(`..${sep}`) || isAbsolute(rel)) {
    throw new Error(`${label}: path escapes ${root}`);
  }
  return result;
}

function homePath(home: string, path: string): string {
  if (isAbsolute(path) || (path.startsWith("~") && path !== "~" && !path.startsWith("~/"))) {
    throw new Error(`${path}: use a relative path or ~/ inside the sandbox home`);
  }
  return inside(home, path === "~" ? "." : path.replace(/^~\//, ""), path);
}

async function safeDestination(home: string, path: string): Promise<string> {
  const target = homePath(home, path);
  const canonicalHome = await realpath(home);
  let existing = home;
  for (const part of relative(home, target).split(sep).filter(Boolean)) {
    existing = join(existing, part);
    try {
      await lstat(existing);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      break;
    }
    inside(canonicalHome, await realpath(existing), path);
  }
  return target;
}

async function validateCopy(path: string, root: string, ancestors = new Set<string>()): Promise<void> {
  const canonical = await realpath(path);
  inside(root, canonical, path);
  if (ancestors.has(canonical)) throw new Error(`${path}: fixture symlink cycle`);
  const stat = await lstat(canonical);
  if (stat.isDirectory()) {
    const next = new Set([...ancestors, canonical]);
    for (const name of await readdir(canonical)) await validateCopy(join(canonical, name), root, next);
  } else if (!stat.isFile()) {
    throw new Error(`${path}: fixture must contain ordinary files and directories`);
  }
}

export function normalizeOutput(output: string, home: string, canonicalHome: string): string {
  for (const path of [...new Set([home, canonicalHome])].sort((a, b) => b.length - a.length)) {
    output = output.replaceAll(path, "~");
  }
  return output.endsWith("\n") ? output.slice(0, -1) : output;
}

async function run(step: RunStep, cwd: string, env: Record<string, string>, label: string, timeout: number): Promise<string> {
  return new Promise((resolveRun, reject) => {
    const child = spawn("/bin/sh", ["-c", step.run], { cwd, env, detached: true, stdio: ["ignore", "pipe", "pipe"] });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];
    let failure: string | undefined;
    const kill = (reason: string) => {
      failure = reason;
      if (child.pid) {
        try { process.kill(-child.pid, "SIGKILL"); }
        catch (error) { if ((error as NodeJS.ErrnoException).code !== "ESRCH") failure += `; ${message(error)}`; }
      }
    };
    const interrupt = () => kill("interrupted");
    process.once("SIGINT", interrupt);
    process.once("SIGTERM", interrupt);
    const timer = setTimeout(() => kill(`timed out after ${timeout / 1000} s`), timeout);
    child.stdout.on("data", chunk => stdout.push(chunk));
    child.stderr.on("data", chunk => stderr.push(chunk));
    child.once("error", error => { failure = message(error); });
    child.once("close", (code, signal) => {
      clearTimeout(timer);
      process.removeListener("SIGINT", interrupt);
      process.removeListener("SIGTERM", interrupt);
      try {
        const err = new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(stderr));
        if (failure || code !== 0 || err.length) {
          throw new Error(`${label} (${step.run}): ${failure ?? "command failed"}; exit ${code ?? signal}; stderr: ${err || "(empty)"}`);
        }
        resolveRun(new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(stdout)));
      } catch (error) { reject(new Error(`${label}: ${message(error)}`)); }
    });
  });
}

export async function record(scriptFile: string, executable: string, options: { timeoutMs?: number; tempRoot?: string } = {}): Promise<Recording> {
  const script = parseScript(await readFile(scriptFile, "utf8"), scriptFile);
  const product = await realpath(executable);
  const home = await mkdtemp(join(options.tempRoot ?? tmpdir(), "presentation-home-"));
  try {
    for (const name of ["project", "bin", "tmp"]) await mkdir(join(home, name));
    await symlink(product, join(home, "bin", script.executable));
    const canonicalHome = await realpath(home);
    const put = async (path: string, content: string) => {
      const target = await safeDestination(home, path);
      await mkdir(dirname(target), { recursive: true });
      await writeFile(target, content, "utf8");
    };
    for (const [path, content] of Object.entries(script.files)) await put(path, content);
    for (const entry of script.copy) {
      const fixture = await realpath(join(dirname(scriptFile), "fixture"));
      const source = inside(resolve(dirname(scriptFile), "fixture"), resolve(dirname(scriptFile), entry.from), entry.from);
      await validateCopy(source, fixture);
      const target = await safeDestination(home, entry.to);
      await mkdir(dirname(target), { recursive: true });
      await cp(source, target, { recursive: true, dereference: true });
    }
    const result: Recording = { title: script.title, steps: [] };
    for (const [index, step] of script.steps.entries()) {
      const label = `${scriptFile} step ${index + 1}`;
      try {
        if ("write" in step) {
          await put(step.write, step.content);
        } else {
          const output = await run(step, await safeDestination(home, step.cwd),
            { ...environment(home), ...script.env }, label, options.timeoutMs ?? 120_000);
          if (step.show) result.steps.push({ command: step.run, output: normalizeOutput(output, home, canonicalHome) });
        }
      } catch (error) { throw new Error(`${label}: ${message(error)}`); }
    }
    for (const expectation of script.expect) {
      const actual = await readFile(await safeDestination(home, expectation.file), "utf8");
      if (expectation.contains !== undefined ? !actual.includes(expectation.contains) : actual !== expectation.equals) {
        throw new Error(`${scriptFile} expect ${expectation.file}: ${expectation.contains !== undefined ? "contains" : "equals"} expectation failed`);
      }
    }
    return result;
  } finally {
    await rm(home, { recursive: true, force: true });
  }
}

export function recordingJSON(recording: Recording): string {
  return JSON.stringify({ title: recording.title, steps: recording.steps.map(({ command, output }) => ({ command, output })) }, null, 2) + "\n";
}

export function parseRecording(text: string, file = "recording.json"): Recording {
  const value = object(JSON.parse(text), file);
  keys(value, ["title", "steps"], file);
  const title = string(value.title, `${file}.title`);
  plain(title, `${file}.title`);
  const steps = list(value.steps, `${file}.steps`).map((item, index) => {
    const path = `${file} step ${index + 1}`;
    const step = object(item, path);
    keys(step, ["command", "output"], path);
    const command = string(step.command, `${path}.command`);
    const output = string(step.output, `${path}.output`, true);
    plain(command, `${path} (${command})`);
    plain(output, `${path} (${command})`, true);
    return { command, output };
  });
  if (!steps.length) throw new Error(`${file}.steps: needs a recorded command`);
  return { title, steps };
}
