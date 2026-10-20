import { readFile } from "node:fs/promises";
import { AsyncLocalStorage } from "node:async_hooks";
import { crc32, deflateSync } from "node:zlib";
import decodePNG, { init as initPNG } from "@jsquash/png/decode.js";
import decodeJPEG, { init as initJPEG } from "@jsquash/jpeg/decode.js";
import decodeWebP, { init as initWebP } from "@jsquash/webp/decode.js";

const PNG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
export function pngChunk(type: string, data: Uint8Array): Buffer {
  const bytes = Buffer.alloc(data.length + 12);
  bytes.writeUInt32BE(data.length);
  bytes.write(type, 4, 4, "ascii");
  bytes.set(data, 8);
  bytes.writeUInt32BE(crc32(bytes.subarray(4, -4)), bytes.length - 4);
  return bytes;
}

export function rgbaPNG(width: number, height: number, pixels: Uint8Array | Uint8ClampedArray): Buffer {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 6;
  const scanlines = Buffer.alloc(height * (width * 4 + 1));
  for (let y = 0; y < height; y++) scanlines.set(pixels.subarray(y * width * 4, (y + 1) * width * 4), y * (width * 4 + 1) + 1);
  return Buffer.concat([PNG, pngChunk("IHDR", header), pngChunk("IDAT", deflateSync(scanlines)), pngChunk("IEND", Buffer.alloc(0))]);
}

function validatePNG(data: Buffer): void {
  let offset = 8;
  let header = false;
  while (offset + 12 <= data.length) {
    const length = data.readUInt32BE(offset);
    if (length > data.length - offset - 12) throw new Error("Truncated PNG chunk");
    const chunk = data.subarray(offset, offset + length + 12);
    const type = chunk.toString("ascii", 4, 8);
    if (crc32(chunk.subarray(4, -4)) !== chunk.readUInt32BE(chunk.length - 4)) throw new Error(`Invalid PNG ${type} checksum`);
    if (type === "IHDR") {
      if (offset !== 8 || length !== 13) throw new Error("Invalid PNG header");
      header = true;
    }
    if (!header) throw new Error("Missing PNG header");
    if (["acTL", "fcTL", "fdAT"].includes(type)) throw new Error("Animated PNG (APNG) is not supported; provide a single still image");
    offset += length + 12;
    if (type === "IEND") {
      if (length || offset !== data.length) throw new Error("Invalid PNG end");
      return;
    }
  }
  throw new Error("Missing PNG end");
}

function validateWebP(data: Buffer): void {
  if (data.readUInt32LE(4) + 8 !== data.length) throw new Error("Invalid WebP container size");
  let offset = 12;
  while (offset + 8 <= data.length) {
    const length = data.readUInt32LE(offset + 4);
    const type = data.toString("ascii", offset, offset + 4);
    if (length + length % 2 > data.length - offset - 8) throw new Error("Truncated WebP chunk");
    if (type === "ANIM" || type === "ANMF" || type === "VP8X" && length && (data[offset + 8] & 2)) {
      throw new Error("Animated WebP is not supported; provide a single still image");
    }
    offset += 8 + length + length % 2;
  }
  if (offset !== data.length) throw new Error("Truncated WebP container");
}

export interface Raster {
  mime: "image/png" | "image/jpeg" | "image/webp";
  width: number;
  height: number;
  data: Uint8ClampedArray;
}

let pngReady: Promise<unknown> | undefined;
let jpegReady: Promise<void> | undefined;
let webpReady: Promise<void> | undefined;
const diagnostics = new AsyncLocalStorage<string[]>();
function decoderMessage(message: string): void {
  diagnostics.getStore()!.push(message);
}
async function moduleOptions(path: string) {
  return { noInitialRun: true, wasmBinary: await readFile(new URL(import.meta.resolve(path))), print: decoderMessage, printErr: decoderMessage };
}

export async function decodeRaster(data: Buffer, file: string): Promise<Raster> {
  // Diagnostics belong to this input even when multiple renders share a codec.
  return diagnostics.run([], async () => {
    try {
      let mime: Raster["mime"];
      let decoded: ImageData;
      const buffer = Uint8Array.from(data).buffer;
      if (data.subarray(0, 8).equals(PNG)) {
        validatePNG(data);
        pngReady ??= readFile(new URL(import.meta.resolve("@jsquash/png/codec/pkg/squoosh_png_bg.wasm"))).then(bytes => initPNG(bytes));
        await pngReady;
        mime = "image/png";
        decoded = await decodePNG(buffer);
      } else if (data[0] === 0xff && data[1] === 0xd8) {
        if (data.at(-2) !== 0xff || data.at(-1) !== 0xd9) throw new Error("Missing JPEG end marker");
        jpegReady ??= moduleOptions("@jsquash/jpeg/codec/dec/mozjpeg_dec.wasm").then(options => initJPEG(options));
        await jpegReady;
        mime = "image/jpeg";
        decoded = await decodeJPEG(buffer);
      } else if (data.toString("ascii", 0, 4) === "RIFF" && data.toString("ascii", 8, 12) === "WEBP") {
        validateWebP(data);
        webpReady ??= moduleOptions("@jsquash/webp/codec/dec/webp_dec.wasm").then(options => initWebP(options));
        await webpReady;
        mime = "image/webp";
        decoded = await decodeWebP(buffer);
      } else throw new Error("Unsupported raster format");
      const messages = diagnostics.getStore()!;
      if (messages.length) throw new Error(messages.join("; "));
      if (!decoded.width || !decoded.height || decoded.data.length !== decoded.width * decoded.height * 4) {
        throw new Error("Incomplete decoded pixels");
      }
      return { mime, width: decoded.width, height: decoded.height, data: decoded.data };
    } catch (error) {
      throw new Error(`${file}: Raster icon must be a valid PNG, JPEG or WebP still image: ${error instanceof Error ? error.message : String(error)}`, { cause: error });
    }
  });
}

// resvg 2.6.2 does not decode WebP. Embed the fully decoded still as a lossless
// PNG; PNG and JPEG inputs retain their original encoded bytes.
export function rasterURI(data: Buffer, raster: Raster): string {
  return raster.mime === "image/webp"
    ? `data:image/png;base64,${rgbaPNG(raster.width, raster.height, raster.data).toString("base64")}`
    : `data:${raster.mime};base64,${data.toString("base64")}`;
}
