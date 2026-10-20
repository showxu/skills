import assert from "node:assert/strict";
import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import { readCatalog } from "../src/catalog.ts";
import { parseDesign, readDesign } from "../src/design.ts";
import { iconSVG, attributeURLs } from "../src/social-preview/icon.ts";
import { pngChunk, decodeRaster, rasterURI, rgbaPNG } from "../src/social-preview/raster.ts";
import { cardContent, fitTitle, renderSocial, socialSVG, wrapAbout } from "../src/social-preview/render.ts";
import { catalogPath, cli, designPath, fixture, fonts, temporary } from "./helpers.ts";

const catalog = await readCatalog(catalogPath);
const design = await readDesign(designPath);
const icon = join(fixture, "social-preview/icon.png");
const rawIcon = await readFile(icon);
const measure = (text: string, size: number) => [...text].length * size;
const svg = (content: string) => `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 100">${content}</svg>`;
const embeddedSVG = (image: string) => Buffer.from(image.match(/data:image\/svg\+xml;base64,([^"]+)/)![1], "base64").toString();
const uri = (bytes: Buffer, mime = "image/png") => `data:${mime};base64,${bytes.toString("base64")}`;

test("social PNG golden is deterministic 1280×640 8-bit RGBA without text or time chunks", async () => {
  const png = await renderSocial(catalog, "example-cli", design, fonts, icon);
  assert.deepEqual(png, await readFile(join(fixture, "social-preview/social-preview.png")));
  assert.deepEqual(await renderSocial(catalog, "example-cli", design, fonts, icon), png);
  assert.equal(png.readUInt32BE(16), 1280); assert.equal(png.readUInt32BE(20), 640);
  assert.equal(png[24], 8); assert.equal(png[25], 6);
  const chunks: string[] = [];
  for (let offset = 8; offset < png.length; offset += png.readUInt32BE(offset) + 12) chunks.push(png.toString("ascii", offset + 4, offset + 8));
  assert.deepEqual([...new Set(chunks)], ["IHDR", "IDAT", "IEND"]);
  const internal = await socialSVG(catalog, "example-cli", design, fonts, icon);
  assert.doesNotMatch(internal, /<text|font-family|font-face/);
  assert.match(internal, /x="64" y="128" width="384" height="384"/);
  assert.match(internal, /fill="#F5F4FF"/);
});

test("title fits on one line before balanced separator wrapping and never truncates", () => {
  const single = fitTitle("sample-appstoreconnect", (text, size) => measure(text, size) * .55, 704, 72);
  assert.deepEqual(single.lines, ["sample-appstoreconnect"]); assert.ok(single.size < 72 && single.size >= 40);
  assert.deepEqual(fitTitle("sample-/appstoreconnect", measure, 90, 10, 5).lines, ["sample", "appstoreconnect"]);
  assert.deepEqual(fitTitle("alpha-beta-gamma-delta", measure, 60, 8, 5).lines, ["alpha-beta", "gamma-delta"]);
  assert.throws(() => fitTitle("unbreakable", measure, 20, 20, 10), /cannot fit/);
  assert.throws(() => fitTitle("name", measure, 20, 39), /bounds/);
  assert.deepEqual(wrapAbout("Read each complete result before publishing.", text => text.length * 10, 180),
    ["Read each complete", "result before", "publishing."]);
  assert.throws(() => wrapAbout("unbreakable", text => text.length, 2), /unbreakable/);
  assert.throws(() => wrapAbout("one two three four", text => text.length, 5), /at most three/);
});

test("catalog selects complete repository content and the organization's own card", () => {
  assert.deepEqual(cardContent(catalog, "EXAMPLE-CLI"), { owner: "example-team", title: "example-cli", about: "Inspect local inputs." });
  assert.deepEqual(cardContent(catalog, ".github"), { owner: "example-team", title: "Example Team", about: catalog.organization.about });
  assert.throws(() => cardContent(catalog, "missing"), /unknown repository missing/);
});

test("overflow, missing glyphs and missing tokens fail with the input or token identified", async () => {
  const source = await readFile(designPath, "utf8");
  for (const [field, value, error] of [
    ["title", "W".repeat(100), /Title cannot fit/],
    ["about", "W".repeat(100), /unbreakable/],
    ["about", "one two three four ".repeat(30), /at most three/],
    ["title", "\u{10ffff}", /missing glyph.*U\+10FFFF/],
  ] as const) {
    const c = structuredClone(catalog);
    c.groups[0].repositories[1][field] = value;
    await assert.rejects(renderSocial(c, "example-cli", design, fonts, icon), error);
  }
  const c = structuredClone(catalog); c.organization.login = "long".repeat(40);
  await assert.rejects(renderSocial(c, "example-cli", design, fonts, icon), /Owner label/);
  for (const [before, after, error] of [
    ["social-preview-icon: 384px", "social-preview-icon: 700px", /composition/],
    ["social-preview-padding: 64px", "social-preview-padding: 2rem", /social-preview.padding.*px/],
    ["social-preview-stack: 24px", "social-preview-stack: 220px", /Text block/],
    ["fontSize: 72px", "fontSize: 30px", /bounds/],
  ] as const) await assert.rejects(renderSocial(catalog, "example-cli", parseDesign(source.replace(before, after)), fonts, icon), error);
  const d = await readDesign(designPath); d.components.light.delete("social-preview-gap");
  await assert.rejects(renderSocial(catalog, "example-cli", d, fonts, icon), /social-preview-gap.width/);
});

test("every social typography token requires explicit fontVariation", async t => {
  const source = await readFile(designPath, "utf8");
  for (const role of ["title", "owner", "body"]) await t.test(role, async () => {
    const token = `social-preview-${role}`;
    const changed = source.replace(new RegExp(`(  ${token}:\\n(?:    .*\\n)*?)    fontVariation:.*\\n`), "$1");
    assert.notEqual(changed, source);
    await assert.rejects(renderSocial(catalog, "example-cli", parseDesign(changed), fonts, icon),
      error => error instanceof Error && error.message.includes(`typography.${token}.fontVariation`));
  });
});

function solidPNG(width: number, height: number): Buffer {
  const pixels = new Uint8Array(width * height * 4);
  for (let offset = 0; offset < pixels.length; offset += 4) pixels.set([36, 104, 172, 128], offset);
  return rgbaPNG(width, height, pixels);
}

const rasterFixtures = Object.fromEntries(await Promise.all(["png", "jpeg", "webp"].map(async format =>
  [format, await readFile(join(fixture, `social-preview/icon.${format}`))]))) as Record<string, Buffer>;

test("still raster formats fully decode in WASM, render and enforce dimensions", async t => {
  const root = await temporary(t);
  for (const [format, bytes] of Object.entries(rasterFixtures)) {
    const path = join(root, `icon.${format}`);
    await writeFile(path, bytes);
    const decoded = await decodeRaster(bytes, path);
    assert.equal(decoded.mime, `image/${format}`);
    assert.equal(decoded.width, 384); assert.equal(decoded.height, 384);
    assert.equal(decoded.data.length, 384 * 384 * 4);
    const image = await iconSVG(path, 64, 128, 384);
    assert.match(image, /x="64" y="128" width="384" height="384"/);
    const payload = Buffer.from(image.match(/base64,([^"]+)/)![1], "base64");
    if (format !== "webp") assert.deepEqual(payload, bytes);
    else {
      assert.deepEqual(payload, Buffer.from(rasterURI(bytes, decoded).split(",")[1], "base64"));
      assert.deepEqual((await decodeRaster(payload, path)).data, decoded.data);
    }
    const card = await renderSocial(catalog, "example-cli", design, fonts, path);
    const pixels = (await decodeRaster(card, "card.png")).data;
    const offset = (200 * 1280 + 100) * 4;
    assert.notDeepEqual([...pixels.subarray(offset, offset + 4)], [245, 244, 255, 255], `${format} icon was omitted`);
  }
  for (const [width, height, size, error] of [[384, 512, 384, /square/], [256, 256, 256.5, /at least/], [256, 256, 384, /at least/]] as const) {
    const path = join(root, "size.png");
    await writeFile(path, solidPNG(width, height));
    await assert.rejects(iconSVG(path, 0, 0, size), error);
  }
  await writeFile(join(root, "size.png"), solidPNG(256, 256));
  await iconSVG(join(root, "size.png"), 0, 0, 256);
  for (const bytes of [Buffer.from("not an image"), rawIcon.subarray(0, 50),
    Buffer.from("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7", "base64")]) {
    await assert.rejects(decodeRaster(bytes, "invalid-icon"), /invalid-icon:.*valid PNG, JPEG or WebP/);
  }
});

test("raster validation rejects corrupt pixels and truncated containers, including SVG embeddings", async t => {
  const root = await temporary(t), path = join(root, "icon.svg");
  const header = rawIcon.subarray(16, 29), signature = rawIcon.subarray(0, 8);
  const badPNG = Buffer.concat([signature, pngChunk("IHDR", header), pngChunk("IDAT", Buffer.from("invalid compressed pixels")), pngChunk("IEND", Buffer.alloc(0))]);
  const jpeg = rasterFixtures.jpeg, webp = rasterFixtures.webp;
  const badWebP = Buffer.from(webp); badWebP.fill(0, 20);
  for (const [bytes, mime] of [[badPNG, "image/png"], [jpeg.subarray(0, -2), "image/jpeg"],
    [Buffer.from([0xff, 0xd8, 0xff, 0xd9]), "image/jpeg"], [badWebP, "image/webp"], [webp.subarray(0, -1), "image/webp"]] as const) {
    await assert.rejects(decodeRaster(bytes, "corrupt-icon"), /corrupt-icon:.*valid PNG, JPEG or WebP/);
    for (const attribute of ["href", "xlink:href"]) {
      await writeFile(path, svg(`<svg><image ${attribute}="${uri(bytes, mime)}"/></svg>`));
      await assert.rejects(iconSVG(path, 0, 0, 384), error => error instanceof Error && error.message.includes(path) && /valid PNG, JPEG or WebP/.test(error.message));
    }
  }
});

test("damaged image streams fail even when their containers and end markers are intact", async t => {
  const root = await temporary(t);
  const jpeg = rasterFixtures.jpeg;
  const truncatedJPEG = Buffer.concat([jpeg.subarray(0, 400), jpeg.subarray(-2)]);
  const idatLength = rawIcon.readUInt32BE(33);
  const truncatedPNG = Buffer.concat([rawIcon.subarray(0, 33),
    pngChunk("IDAT", rawIcon.subarray(41, 41 + Math.floor(idatLength / 2))), rawIcon.subarray(-12)]);
  const truncatedWebP = Buffer.from(rasterFixtures.webp.subarray(0, -100));
  truncatedWebP.writeUInt32LE(truncatedWebP.length - 8, 4);
  truncatedWebP.writeUInt32LE(truncatedWebP.length - 56, 52);
  for (const [format, bytes] of [["jpeg", truncatedJPEG], ["png", truncatedPNG], ["webp", truncatedWebP]] as const) {
    await t.test(format, async () => {
      const path = join(root, `damaged.${format}`), embedded = join(root, `embedded-${format}.svg`);
      await writeFile(path, bytes);
      await writeFile(embedded, svg(`<image href="${uri(bytes, `image/${format}`)}"/>`));
      for (const input of [path, embedded]) {
        await assert.rejects(iconSVG(input, 0, 0, 384), error => error instanceof Error && error.message.includes(input));
        const out = join(root, "card.png");
        const result = cli("social-preview", "render", "--design", designPath, "--fonts", fonts, "--catalog", catalogPath,
          "--repository", "example-cli", "--icon", input, "--out", out);
        assert.equal(result.status, 1); assert.ok(result.stderr.includes(input));
        await assert.rejects(readFile(out), { code: "ENOENT" });
      }
      const [damaged, valid] = await Promise.allSettled([
        decodeRaster(bytes, path), decodeRaster(rasterFixtures[format], `valid.${format}`),
      ]);
      assert.equal(damaged.status, "rejected"); assert.equal(valid.status, "fulfilled");
      assert.equal((await decodeRaster(rasterFixtures[format], `valid.${format}`)).width, 384);
    });
  }
});

function animatedPNG(): Buffer {
  const animation = Buffer.alloc(8); animation.writeUInt32BE(2);
  const control = (sequence: number) => {
    const bytes = Buffer.alloc(26); bytes.writeUInt32BE(sequence); bytes.writeUInt32BE(384, 4); bytes.writeUInt32BE(384, 8); return bytes;
  };
  const idat = rawIcon.subarray(33, rawIcon.length - 12);
  return Buffer.concat([rawIcon.subarray(0, 33), pngChunk("acTL", animation), pngChunk("fcTL", control(0)),
    idat, pngChunk("fcTL", control(1)), pngChunk("fdAT", Buffer.concat([Buffer.from([0, 0, 0, 2]), idat.subarray(8, -4)])),
    pngChunk("IEND", Buffer.alloc(0))]);
}

function animatedWebP(): Buffer {
  const chunk = (name: string, bytes: Buffer) => {
    const header = Buffer.alloc(8); header.write(name); header.writeUInt32LE(bytes.length, 4);
    return Buffer.concat([header, bytes, Buffer.alloc(bytes.length % 2)]);
  };
  const extended = Buffer.alloc(10); extended[0] = 0x12;
  extended.writeUIntLE(383, 4, 3); extended.writeUIntLE(383, 7, 3);
  const control = Buffer.alloc(16); control.writeUIntLE(383, 6, 3); control.writeUIntLE(383, 9, 3); control.writeUIntLE(100, 12, 3);
  const imageChunks: Buffer[] = [], source = rasterFixtures.webp;
  for (let offset = 12; offset + 8 <= source.length;) {
    const length = source.readUInt32LE(offset + 4), end = offset + 8 + length + length % 2;
    if (["ALPH", "VP8 ", "VP8L"].includes(source.toString("ascii", offset, offset + 4))) imageChunks.push(source.subarray(offset, end));
    offset = end;
  }
  const frame = chunk("ANMF", Buffer.concat([control, ...imageChunks]));
  const payload = Buffer.concat([Buffer.from("WEBP"), chunk("VP8X", extended), chunk("ANIM", Buffer.alloc(6)), frame, frame]);
  const header = Buffer.alloc(8); header.write("RIFF"); header.writeUInt32LE(payload.length, 4);
  return Buffer.concat([header, payload]);
}

test("APNG and animated WebP fail as standalone and embedded icons, naming the file", async t => {
  const root = await temporary(t);
  for (const [bytes, format, message] of [[animatedPNG(), "png", /Animated PNG/], [animatedWebP(), "webp", /Animated WebP/]] as const) {
    const path = join(root, `animated.${format}`);
    await writeFile(path, bytes);
    await assert.rejects(iconSVG(path, 0, 0, 384), error => error instanceof Error && error.message.includes(path) && message.test(error.message));
    for (const attribute of ["href", "xlink:href"]) {
      const embedded = join(root, "embedded.svg");
      await writeFile(embedded, svg(`<image ${attribute}="${uri(bytes, `image/${format}`)}"/>`));
      await assert.rejects(iconSVG(embedded, 0, 0, 384), error => error instanceof Error && error.message.includes(embedded) && message.test(error.message));
    }
    const out = join(root, "card.png");
    const result = cli("social-preview", "render", "--design", designPath, "--fonts", fonts, "--catalog", catalogPath,
      "--repository", "example-cli", "--icon", path, "--out", out);
    assert.equal(result.status, 1);
    assert.ok(result.stderr.includes(path)); assert.match(result.stderr, message);
    await assert.rejects(readFile(out), { code: "ENOENT" });
  }
});

test("PNG metadata changes do not affect generated pixels", async t => {
  const root = await temporary(t), path = join(root, "metadata.png");
  await writeFile(path, Buffer.concat([rawIcon.subarray(0, -12),
    pngChunk("tEXt", Buffer.from("Comment\0fixture metadata")), rawIcon.subarray(-12)]));
  assert.deepEqual(await renderSocial(catalog, "example-cli", design, fonts, path),
    await renderSocial(catalog, "example-cli", design, fonts, icon));
});

test("SVG accepts namespaced composition, fragments, embedded rasters and strips metadata", async t => {
  const root = await temporary(t), path = join(root, "icon.svg");
  await writeFile(path, svg(`<title>Outlined &amp; logo &#35;1</title><defs><linearGradient id="paint">
    <stop offset="0" stop-color="rgb(30, 100, 200)"/><stop offset="1" stop-color="blue"/></linearGradient>
    <path id="shape" d="M0 0h100v100z"/><filter id="effect"><feGaussianBlur stdDeviation="1"/>
    <feOffset dx="1" dy="2"/><feBlend in="SourceGraphic" in2="offset" mode="normal"/>
    <feColorMatrix type="saturate" values="0.8"/><feComposite in2="SourceAlpha" operator="in"/>
    <feFlood flood-color="blue"/><feMerge><feMergeNode in="SourceGraphic"/></feMerge>
    <feMorphology operator="dilate" radius="1"/><feDropShadow dx="1" dy="1"/>
    <feComponentTransfer><feFuncR type="gamma"/><feFuncG type="linear"/><feFuncB type="table"/><feFuncA type="identity"/></feComponentTransfer>
    </filter></defs><g class="logo" fill="url(#paint)"><use href="#shape" filter="url('#effect')"/></g>
    <metadata id="receipt">private text<iframe xmlns="http://www.w3.org/1999/xhtml" srcdoc="active"/></metadata>`));
  const embedded = embeddedSVG(await iconSVG(path, 0, 0, 384));
  assert.match(embedded, /feComponentTransfer/); assert.match(embedded, /href="#shape"/);
  assert.doesNotMatch(embedded, /iframe|private text|srcdoc/);
  for (const format of ["png", "jpeg", "webp"] as const) for (const attribute of ["href", "xlink:href"]) {
    const bytes = format === "png" ? solidPNG(16, 8) : rasterFixtures[format];
    await writeFile(path, svg(`<image ${attribute}="${uri(bytes, `image/${format}`)}" width="100" height="100"/>`));
    assert.match(embeddedSVG(await iconSVG(path, 0, 0, 384)), /data:image\/(?:png|jpeg);base64/);
  }
  for (const value of ["url(#paint)", "url('#paint')", String.raw`u\72l(\23 filter)`, "translate(10 20) scale(2)"]) attributeURLs(value);
});

test("SVG rejects active content, foreign namespaces, unlisted elements and attributes at every depth", async t => {
  const root = await temporary(t), path = join(root, "icon.svg");
  const cases = [
    ...["script", "foreignObject", "text", "style", "set", "animate", "unknown", "feImage", "feTurbulence", "a", "iframe", "img"].map(tag => `<${tag}/>`),
    ...['onload="alert(1)"', 'onerror="alert(1)"', 'style="fill:red"', 'unknown="x"', 'srcdoc="active"', 'srcset="image.png 1x"',
      'xml:base="https://example.test/"', 'src="image.png"', 'xmlns:custom="urn:custom" custom:fill="red"', 'xmlns:custom="urn:custom" custom:href="#local"'].map(attribute => `<path ${attribute}/>`),
    ...["http://www.w3.org/1999/xhtml", "http://www.w3.org/1998/Math/MathML", "urn:unknown", ""].map(namespace => `<path xmlns="${namespace}"/>`),
    '<style><![CDATA[@import "theme.css";]]></style>',
    '<path href="#local"/>', '<linearGradient xlink:href="#base"/>', '<image href="#local"/>',
    '<use href="other.svg#local"/>', `<use href="${uri(rawIcon)}"/>`,
  ];
  for (const content of cases) for (const wrapper of [(text: string) => text, (text: string) => `<svg><defs><g>${text}</g></defs></svg>`]) {
    await writeFile(path, svg(wrapper(content)));
    await assert.rejects(iconSVG(path, 0, 0, 384), /self-contained/, content);
  }
  for (const attribute of ["fill", "stroke", "filter", "clip-path", "mask", "marker", "marker-start", "marker-mid", "marker-end", "cursor"]) {
    await writeFile(path, svg(`<svg><path ${attribute}="url(https://example.test/a.svg#part)"/></svg>`));
    await assert.rejects(iconSVG(path, 0, 0, 384), /self-contained/);
  }
  for (const value of [
    String.raw`u\72l(\68ttps://example.test/icon.svg#paint)`, 'URL("https://example.test/icon.svg")',
    "url(#local) url(../paint.svg)", 'url("https://example.test/icon.svg")', "url(not a URL)",
    '"url(https://example.test/icon.svg)"', 'image-set("https://example.test/icon.png" 1x)', "unknown(#local)",
    `url(${uri(rawIcon)})`,
  ]) assert.throws(() => attributeURLs(value), /self-contained/, value);
});

test("SVG image references require correct validated raster base64 and reject every other source", async t => {
  const root = await temporary(t), path = join(root, "icon.svg");
  for (const value of ["https://example.test/icon.png", "file:///tmp/icon.png", "icon.png", "//example.test/icon.png",
    "data:image/svg+xml;base64,PHN2Zy8+", "data:image/gif;base64,R0lGODlh", "data:text/plain;base64,YQ==", "data:image/png,%89PNG",
    "data:image/png;base64,not!base64", "data:image/png;base64,PHN2Zy8+", uri(rawIcon, "image/jpeg")]) {
    for (const attribute of ["href", "xlink:href"]) {
      await writeFile(path, svg(`<image ${attribute}="${value}"/>`));
      await assert.rejects(iconSVG(path, 0, 0, 384), /self-contained|base64|valid PNG|match its data URI/);
    }
  }
});

test("SVG rejects declarations and processing instructions in UTF-8 and UTF-16, even in metadata", async t => {
  const root = await temporary(t), path = join(root, "icon.svg");
  const cases = [
    "<!DOCTYPE svg>" + svg(""), '<!DOCTYPE svg [<!ENTITY payload "expanded">]>' + svg("<title>&payload;</title>"),
    '<!DOCTYPE svg SYSTEM "https://example.test/external.dtd">' + svg(""),
    '<?xml-stylesheet href="https://example.test/theme.css"?>' + svg(""), svg("<metadata><?instruction ignored?></metadata>"),
  ];
  for (const source of cases) for (const encoding of ["utf8", "utf16le"] as const) {
    await writeFile(path, Buffer.from(source, encoding));
    await assert.rejects(iconSVG(path, 0, 0, 384), /DOCTYPE|entity|processing instruction/);
  }
  await writeFile(path, '<?xml version="1.0"?>' + svg("<title>Icon &amp; logo &#35;1</title>"));
  assert.match(embeddedSVG(await iconSVG(path, 0, 0, 384)), /Icon &amp; logo #1/);
});

test("real app and framework icon assets still produce a card", async () => {
  for (const asset of ["apple-app-icon-design/assets/icon-large.png", "apple-framework-icon-design/assets/icon-large.svg"]) {
    const path = join(fixture, "../../../../", asset);
    const png = await renderSocial(catalog, "example-cli", design, fonts, path);
    assert.equal(png.readUInt32BE(16), 1280);
  }
});

test("social CLI render/check detects pixel drift without writing and returns regenerated PNG", async t => {
  const root = await temporary(t), out = join(root, "social-preview.png"), artifact = join(root, "artifact");
  const args = ["--design", designPath, "--fonts", fonts, "--catalog", catalogPath, "--repository", "example-cli", "--icon", icon];
  assert.equal(cli("social-preview", "check", ...args, "--assets", root).status, 1);
  await assert.rejects(readFile(out), { code: "ENOENT" });
  const generated = cli("social-preview", "render", ...args, "--out", out);
  assert.equal(generated.status, 0, generated.stderr);
  assert.equal(cli("social-preview", "check", ...args, "--assets", root).status, 0);
  const original = await readFile(out); await writeFile(out, "drift");
  const checked = cli("social-preview", "check", ...args, "--assets", root, "--artifact-dir", artifact);
  assert.equal(checked.status, 1, checked.stderr); assert.match(checked.stdout, /social-preview render/);
  assert.equal(await readFile(out, "utf8"), "drift");
  assert.deepEqual(await readFile(join(artifact, "social-preview.png")), original);
  assert.equal(cli("social-preview", "render", ...args).status, 2);
});
