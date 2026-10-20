import { DOMParser, XMLSerializer } from "@xmldom/xmldom";
import type { Element, Node } from "@xmldom/xmldom";
import { ident, parse, walk } from "css-tree";
import { readFile } from "node:fs/promises";
import { number } from "../fonts.ts";
import { SVG_ATTRIBUTES, SVG_ELEMENTS, SVG_VALUE_FUNCTIONS } from "./allowlist.ts";
import { decodeRaster, rasterURI } from "./raster.ts";

const SVG = "http://www.w3.org/2000/svg";
const XLINK = "http://www.w3.org/1999/xlink";
const XMLNS = "http://www.w3.org/2000/xmlns/";

function fragment(value: string): void {
  if (!value.startsWith("#")) throw new Error("Icon must be self-contained SVG; only fragment URLs are allowed");
}

export function attributeURLs(value: string): void {
  try {
    const tree = parse(value, { context: "value", onParseError: error => { throw error; } });
    walk(tree, node => {
      if (node.type === "Url") fragment(node.value);
      else if (node.type === "Function") {
        const name = ident.decode(node.name).toLowerCase();
        if (name === "url") {
          const args = node.children.toArray();
          const arg = args[0];
          if (args.length !== 1 || !arg) throw new Error("url() needs a literal fragment");
          if (arg.type === "String") fragment(arg.value);
          else if (arg.type === "Identifier") fragment(ident.decode(arg.name));
          else if (arg.type === "Hash") fragment("#" + ident.decode(arg.value));
          else throw new Error("url() needs a literal fragment");
        } else if (!SVG_VALUE_FUNCTIONS.has(name)) throw new Error(`function ${node.name} is not allowed`);
      } else if (node.type === "String") attributeURLs(node.value);
      else if (!["Value", "Identifier", "Hash", "Number", "Percentage", "Dimension", "Operator"].includes(node.type)) {
        throw new Error("invalid attribute value");
      }
    });
  } catch (error) {
    throw new Error(`Icon must be self-contained SVG with valid attribute values: ${String(error)}`);
  }
}

function text(data: Buffer): string {
  const big = data[0] === 0xfe && data[1] === 0xff || data[0] === 0 && data[1] === 0x3c;
  const little = data[0] === 0xff && data[1] === 0xfe || data[0] === 0x3c && data[1] === 0;
  return new TextDecoder(big ? "utf-16be" : little ? "utf-16le" : "utf-8", { fatal: true }).decode(data);
}

function declarations(node: Node, document: Node): void {
  if (node.nodeType === 10) throw new Error("SVG icons must not contain DOCTYPE or entity declarations");
  if (node.nodeType === 7 && !(node.nodeName === "xml" && node === document.firstChild)) {
    throw new Error("SVG icons must not contain processing instructions");
  }
  for (let child = node.firstChild; child; child = child.nextSibling) declarations(child, document);
}

async function validateSVG(node: Element, file: string): Promise<void> {
  if (node.namespaceURI !== SVG) throw new Error("Icon must be self-contained SVG; elements must use the SVG namespace");
  const tag = node.localName!;
  if (!SVG_ELEMENTS.has(tag)) throw new Error(`Icon must be self-contained static SVG with outlined lettering; element ${tag} is not allowed`);
  for (let index = 0; index < node.attributes.length; index++) {
    const attribute = node.attributes.item(index)!;
    const { name, value, namespaceURI: namespace } = attribute;
    if (namespace === XMLNS) continue;
    if (name === "href" && !namespace || attribute.localName === "href" && namespace === XLINK) {
      if (tag === "use") fragment(value);
      else if (tag === "image") {
        const match = /^data:(image\/(?:png|jpeg|webp));base64,(.+)$/.exec(value);
        if (!match) throw new Error("Icon must be self-contained SVG; image links need raster base64 data URIs");
        if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(match[2])) {
          throw new Error("Embedded raster image needs valid base64 data");
        }
        const data = Buffer.from(match[2], "base64");
        const info = await decodeRaster(data, file);
        if (info.mime !== match[1]) throw new Error("Embedded raster image format must match its data URI");
        attribute.value = rasterURI(data, info);
      } else throw new Error("Icon must be self-contained SVG; links are allowed only on use and image");
    } else if (!namespace && SVG_ATTRIBUTES.has(name)) attributeURLs(value);
    else throw new Error(`Icon must be self-contained SVG; attribute ${name} is not allowed`);
  }
  if (tag === "metadata") {
    while (node.firstChild) node.removeChild(node.firstChild);
  } else {
    for (let child = node.firstChild; child; child = child.nextSibling) {
      if (child.nodeType === 1) await validateSVG(child as Element, file);
    }
  }
}

export async function iconSVG(file: string, x: number, y: number, size: number): Promise<string> {
  const data = await readFile(file);
  const raster = data.subarray(0, 4).equals(Buffer.from([137, 80, 78, 71])) ||
    data[0] === 0xff && data[1] === 0xd8 || data.toString("ascii", 0, 4) === "RIFF";
  if (raster) {
    const raster = await decodeRaster(data, file);
    const { width, height } = raster;
    if (width !== height) throw new Error(`Raster icon must be square; got ${width}x${height} pixels`);
    if (width < size) throw new Error(`Raster icon must be at least ${size}x${size} pixels; got ${width}x${height}`);
    return `<image x="${number(x)}" y="${number(y)}" width="${number(size)}" height="${number(size)}" href="${rasterURI(data, raster)}"/>`;
  }
  let source: string;
  try { source = text(data); }
  catch { throw new Error("Icon must be self-contained SVG or a valid PNG, JPEG or WebP image"); }
  const document = new DOMParser({ onError: (_level, message) => { throw new Error(message); } }).parseFromString(source, "image/svg+xml");
  declarations(document, document);
  const root = document.documentElement;
  if (!root || root.namespaceURI !== SVG || root.localName !== "svg") {
    throw new Error("Icon must be self-contained SVG with a root svg element in the SVG namespace");
  }
  await validateSVG(root, file);
  if (!root.hasAttribute("viewBox")) throw new Error("Icon needs a viewBox");
  root.setAttribute("x", "0"); root.setAttribute("y", "0");
  root.setAttribute("width", number(size)); root.setAttribute("height", number(size));
  // A separate SVG image document scopes the icon's fragment IDs; they cannot
  // collide with the card's glyph definitions or accessibility IDs.
  const uri = "data:image/svg+xml;base64," + Buffer.from(new XMLSerializer().serializeToString(root)).toString("base64");
  return `<image x="${number(x)}" y="${number(y)}" width="${number(size)}" height="${number(size)}" href="${uri}"/>`;
}
