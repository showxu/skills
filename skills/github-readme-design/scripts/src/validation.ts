export function object(value: unknown, path: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${path}: expected an object`);
  }
  return value as Record<string, unknown>;
}

export function keys(value: Record<string, unknown>, allowed: string[], path: string): void {
  for (const key of Object.keys(value)) {
    if (!allowed.includes(key)) throw new Error(`${path}.${key}: unknown key`);
  }
}

export function string(value: unknown, path: string, empty = false): string {
  if (typeof value !== "string" || (!empty && !value.trim())) {
    throw new Error(`${path}: expected ${empty ? "a string" : "a nonempty string"}`);
  }
  return value;
}

export function list(value: unknown, path: string): unknown[] {
  if (!Array.isArray(value)) throw new Error(`${path}: expected an array`);
  return value;
}

export function plain(value: string, path: string, multiline = false): void {
  for (const character of value) {
    const point = character.codePointAt(0)!;
    if (character === "\t" || (multiline && character === "\n")) continue;
    if (point < 32 || (point >= 127 && point <= 159) ||
        (point >= 0xd800 && point <= 0xdfff) || point === 0xfffe || point === 0xffff) {
      throw new Error(`${path}: unsupported control character U+${point.toString(16).toUpperCase().padStart(4, "0")}`);
    }
  }
}

export function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
