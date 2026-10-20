import assert from "node:assert/strict";
import { link as hardLink, mkdir, readFile, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import { catalogURL, json, link, parseCatalog, parseMember, readCatalog } from "../src/catalog.ts";
import { checkFile } from "../src/check.ts";
import { readDesign, parseDesign } from "../src/design.ts";
import { renderProfile } from "../src/profile/render.ts";
import { catalogPath, cli, commit, designPath, fixture, memberPath, temporary } from "./helpers.ts";

const catalog = await readCatalog(catalogPath);
const memberSource = JSON.parse(await readFile(memberPath, "utf8"));
const design = await readDesign(designPath);
const member = () => parseMember(structuredClone(memberSource), catalog);

test("public and member profile bytes equal the original goldens", async () => {
  assert.equal(renderProfile(catalog, design), await readFile(join(fixture, "profile/public.md"), "utf8"));
  assert.equal(renderProfile(catalog, design, member(), commit), await readFile(join(fixture, "profile/member.md"), "utf8"));
});

test("catalog validates required fields, unknown keys, kinds, duplicate names and control characters", () => {
  for (const change of [
    (c: any) => { delete c.organization.about; },
    (c: any) => { delete c.groups[0].repositories[0].title; },
    (c: any) => { c.groups[0].repositories[0].kind = "unknown"; },
    (c: any) => { c.groups[0].repositories[0].extra = true; },
    (c: any) => { c.groups[0].repositories.push({ ...c.groups[0].repositories[0], name: "EXAMPLE-LIBRARY" }); },
    (c: any) => { c.groups[0].repositories[0].name = ".github"; },
    (c: any) => { c.groups[0].repositories = []; },
    (c: any) => { c.organization.login = "bad_owner"; },
    (c: any) => { c.promise = "text\nother"; },
    (c: any) => { c.secondary = "text\tother"; },
    (c: any) => { c.description = " "; },
    (c: any) => { c.description = "one\u0085two"; },
    (c: any) => { c.quickstart.commands = []; },
    (c: any) => { c.quickstart.commands = ["run\nother"]; },
    (c: any) => { c.quickstart.commands = ["echo ```"]; },
    (c: any) => { c.quickstart.note = "extra"; },
  ]) {
    const changed = structuredClone(catalog);
    change(changed);
    assert.throws(() => parseCatalog(changed));
  }
  for (const kind of ["tool", "library", "app", "distribution", "website"]) {
    const changed = structuredClone(catalog);
    (changed.groups[0].repositories[0] as any).kind = kind;
    assert.equal(parseCatalog(changed).groups[0].repositories[0].kind, kind);
  }
  assert.throws(() => json('{"repositories":{"tool":{},"tool":{}}}', "input.json"), /unique|duplicate/i);
  assert.throws(() => json('{"name":1,"na\\u006de":2}', "input.json"), /unique|duplicate/i);
  assert.throws(() => json("name: YAML", "input.json"));
});

test("profile links reject unsafe schemes, disguised absolutes, credentials and escaping paths", () => {
  for (const value of [
    "http://example.test", "javascript:alert(1)", "data:image/png;base64,a", "file:///etc/passwd",
    "//example.test/a", "\\\\example.test/a", "https://user:password@example.test/a", "https:",
    "https://example.test/\nx", "https://example.test:bad/icon.svg", "https://example.test:99999/icon.svg",
    "java%73cript:alert(1)", "%2f%2fexample.test/a", "/root/path", "../../../outside",
    "%2e%2e/%2e%2e/outside", "%252e%252e/%252e%252e/outside",
  ]) assert.throws(() => link(value), value);
  const c = structuredClone(catalog);
  c.mark = "../assets/family%20mark.svg";
  assert.match(renderProfile(parseCatalog(c), design, member(), commit), /\/assets\/family%20mark\.svg/);
  assert.equal(catalogURL("#section", catalog, commit), `https://github.com/example-team/.github/blob/${commit}/profile/README.md#section`);
});

test("hostile text is escaped in both layouts and icon attributes", () => {
  const c = structuredClone(catalog);
  const hostile = '<script>alert("x")</script> & [link](javascript:evil) **strong**';
  c.organization.name = c.promise = c.secondary = c.groups[0].title = c.groups[0].repositories[0].outcome = hostile;
  c.mark = 'https://example.test/mark.svg?title="onerror=evil"&x=1';
  for (const m of [undefined, member()]) {
    const value = renderProfile(parseCatalog(c), design, m, m ? commit : undefined);
    assert.doesNotMatch(value, /<script|<img [^>]* onerror=/);
    assert.match(value, /&lt;script&gt;/);
    assert.match(value, /&quot;onerror=evil&quot;/);
  }
});

test("member membership is exact while group order and icons remain catalog owned", () => {
  for (const name of ["example-library", "extra"]) {
    const m = member();
    if (name === "extra") m.repositories[name] = m.repositories["example-library"];
    else delete m.repositories[name];
    assert.throws(() => parseMember(m, catalog), /membership mismatch/);
  }
  const m = member();
  m.repositories = Object.fromEntries(Object.entries(m.repositories).reverse());
  assert.equal(renderProfile(catalog, design, m, commit), renderProfile(catalog, design, member(), commit));
  assert.throws(() => parseMember({ ...m, groups: [] }, catalog), /unknown key/);
  assert.throws(() => parseMember({ ...m, catalog: { revision: commit } }, catalog), /unknown key/);
  (m.repositories["example-library"] as any).status = "green";
  assert.throws(() => parseMember(m, catalog), /unknown key/);
});

test("member operations require a branch, validate workflow/release facts and keep encoded branches", () => {
  for (const branch of [null, "", " ", "trunk\nother"]) {
    const m = member(); (m.repositories["example-distribution"] as any).default_branch = branch;
    assert.throws(() => parseMember(m, catalog));
  }
  for (const field of ["default_branch", "workflow", "releases"]) {
    const m = member(); delete (m.repositories["example-library"] as any)[field];
    assert.throws(() => parseMember(m, catalog), /missing field/);
  }
  for (const [field, value] of [["workflow", "../ci.yml"], ["workflow", "file.txt"], ["releases", "green"]]) {
    const m = member(); (m.repositories["example-library"] as any)[field] = value;
    assert.throws(() => parseMember(m, catalog));
  }
  for (const branch of ["trunk", "stable/next", "release/候选&channel=beta", "release!'()*~"]) {
    const m = member(); m.repositories["example-library"].default_branch = branch;
    const output = renderProfile(catalog, design, parseMember(m, catalog), commit);
    const raw = output.match(/https:\/\/img.shields.io\/github\/actions\/workflow\/status\/example-team\/example-library\/[^"]+/)![0].replaceAll("&amp;", "&");
    assert.equal(new URL(raw).searchParams.get("branch"), branch);
    assert.match(output, /style=flat/);
  }
});

test("public-only content, operational fallbacks and search result types preserve their roles", () => {
  const c = structuredClone(catalog); delete c.website;
  const publicOutput = renderProfile(c, design), dashboard = renderProfile(c, design, member(), commit);
  assert.match(publicOutput, /<h2>Get started<\/h2>\n\n```sh/);
  assert.doesNotMatch(dashboard, /Get started|Maintained by/);
  assert.match(dashboard, /https:\/\/github.com\/example-team">Public profile/);
  assert.match(dashboard, /example-distribution\/actions">Actions/);
  assert.match(dashboard, /example-cli\/releases">Releases/);
  assert.match(dashboard, /<td>—<\/td>/);
  assert.match(dashboard, /author%3Aapp%2Fdependabot&amp;type=pullrequests/);
  assert.match(dashboard, /is%3Aissue\+is%3Aopen&amp;type=issues/);
  for (const value of [publicOutput, dashboard]) assert.ok(!value.includes(c.description!));
});

test("DESIGN owns all four sizes; missing or malformed dimensions fail with token names", async () => {
  const source = await readFile(designPath, "utf8");
  const changed = parseDesign(source.replace("profile-header-icon: 128px", "profile-header-icon: 120px")
    .replace("profile-member-header-icon: 64px", "profile-member-header-icon: 60px")
    .replace("profile-row-icon: 40px", "profile-row-icon: 36px")
    .replace("profile-member-row-icon: 24px", "profile-member-row-icon: 20px"));
  assert.match(renderProfile(catalog, changed), /width="120"/);
  assert.match(renderProfile(catalog, changed), /width="36"/);
  assert.match(renderProfile(catalog, changed, member(), commit), /width="60"/);
  assert.match(renderProfile(catalog, changed, member(), commit), /width="20"/);
  for (const value of ["0px", "1.5px", "2rem"]) {
    assert.throws(() => renderProfile(catalog, parseDesign(source.replace("profile-row-icon: 40px", `profile-row-icon: ${value}`))), /profile-row/);
  }
});

test("profile CLI renders, byte-checks, detects CRLF and supplies safe failure artifacts", async t => {
  const root = await temporary(t), out = join(root, "profile/README.md"), artifact = join(root, "artifact");
  for (const m of [false, true]) {
    const args = ["--design", designPath, "--catalog", catalogPath, "--out", out,
      ...(m ? ["--member", memberPath, "--catalog-revision", commit] : [])];
    assert.equal(cli("profile", "render", ...args).status, 0);
    const original = await readFile(out);
    assert.equal(cli("profile", "check", ...args).status, 0);
    for (const drift of ["handwritten", original.toString().replaceAll("\n", "\r\n")]) {
      await writeFile(out, drift);
      const result = cli("profile", "check", ...args, "--artifact-dir", artifact);
      assert.equal(result.status, 1, result.stderr);
      assert.match(result.stdout, /differs from its inputs|--- /);
      assert.match(result.stdout, /profile render/);
      assert.equal(await readFile(out, "utf8"), drift);
      assert.deepEqual(await readFile(join(artifact, "README.md")), original);
    }
    assert.equal(cli("profile", "check", ...args, "--artifact-dir", join(root, "profile")).status, 1);
    assert.equal(await readFile(out, "utf8"), original.toString().replaceAll("\n", "\r\n"));
  }
  const alias = join(root, "alias");
  await symlink(join(root, "profile"), alias);
  assert.equal(cli("profile", "check", "--design", designPath, "--catalog", catalogPath, "--out", out, "--artifact-dir", alias).status, 1);
  const args = ["--design", designPath, "--catalog", catalogPath, "--out", out];
  assert.equal(cli("profile", "render", ...args, "--member", memberPath).status, 2);
  assert.equal(cli("profile", "render", ...args, "--catalog-revision", commit).status, 2);
  assert.equal(cli("profile", "render", ...args, "--member", memberPath, "--catalog-revision", "main").status, 2);
  assert.equal(cli("profile", "render", ...args, "--out", out).status, 2);
  const missing = join(root, "absent.md");
  assert.equal(cli("profile", "check", "--design", designPath, "--catalog", catalogPath, "--out", missing).status, 1);
  await assert.rejects(readFile(missing), { code: "ENOENT" });
});

test("drift artifacts replace hard links without modifying their source", async t => {
  const root = await temporary(t), file = join(root, "README.md"), artifactDir = join(root, "artifact");
  await writeFile(file, "committed");
  await mkdir(artifactDir);
  await hardLink(file, join(artifactDir, "README.md"));
  assert.equal(await checkFile({ file, artifactDir, bytes: Buffer.from("regenerated"), regenerate: "example command" }, () => {}), false);
  assert.equal(await readFile(file, "utf8"), "committed");
  assert.equal(await readFile(join(artifactDir, "README.md"), "utf8"), "regenerated");
  await writeFile(join(artifactDir, "unrelated"), "preserve");
  await assert.rejects(checkFile({ file, artifactDir, bytes: Buffer.from("next"), regenerate: "example command" }, () => {}), /unrelated entry/);
  assert.equal(await readFile(join(artifactDir, "README.md"), "utf8"), "regenerated");
});
