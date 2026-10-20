import { readFile } from "node:fs/promises";
import { posix } from "node:path";
import { parseDocument } from "yaml";
import { keys, list, object, plain, string } from "./validation.ts";

export const NAVIGATION = ["documentation", "contributing", "security", "support"] as const;
export const MAINTENANCE = ["maintenance", "versioning", "settings", "design"] as const;
export const KINDS = ["tool", "library", "app", "distribution", "website"] as const;
export type Icon = string | { light: string; dark: string };
export interface Link { label: string; url: string }
export interface Repository {
  name: string; outcome: string; icon: Icon;
  kind: typeof KINDS[number]; title: string; about: string;
}
export interface Catalog {
  organization: { login: string; name: string; about: string };
  promise: string; secondary: string; mark: Icon;
  navigation: Partial<Record<typeof NAVIGATION[number], Link>>;
  groups: { title: string; repositories: Repository[] }[];
  website?: string; maintainer?: Link; description?: string;
  quickstart?: { title: string; commands: string[] };
}
export interface Operations {
  default_branch: string; workflow: string | null; releases: "published" | "channel" | "none";
}
export interface Member {
  maintenance: Record<typeof MAINTENANCE[number], Link>;
  repositories: Record<string, Operations>;
}

export function json(text: string, file: string): unknown {
  const value: unknown = JSON.parse(text);
  // JSON.parse accepts duplicate keys; the YAML parser also understands JSON
  // and checks key uniqueness before any schema validation loses that evidence.
  const document = parseDocument(text, { uniqueKeys: true });
  if (document.errors.length) throw new Error(`${file}: ${document.errors.map(error => error.message).join("\n")}`);
  return value;
}

export function fields(value: unknown, required: string[], optional: string[], path: string): Record<string, unknown> {
  const result = object(value, path);
  keys(result, [...required, ...optional], path);
  for (const key of required) {
    if (!Object.hasOwn(result, key)) throw new Error(`${path}.${key}: missing field`);
  }
  return result;
}

export function text(value: unknown, path: string): string {
  const result = string(value, path);
  plain(result, path);
  if (result.includes("\t")) throw new Error(`${path}: unsupported control character U+0009`);
  return result;
}

export function identifier(value: unknown, kind: "organization" | "repository", path: string): string {
  const result = text(value, path);
  const pattern = kind === "organization" ? /^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$/ : /^[A-Za-z0-9_.-]+$/;
  if (!pattern.test(result) || result === "." || result === "..") throw new Error(`${path}: invalid ${kind} identifier`);
  return result;
}

function parts(value: string): { path: string; suffix: string } {
  const offset = value.search(/[?#]/);
  return offset < 0 ? { path: value, suffix: "" } : { path: value.slice(0, offset), suffix: value.slice(offset) };
}

function relativePath(value: string): string {
  const path = posix.normalize(posix.join("profile", decodeURIComponent(parts(value).path) || "README.md"));
  if (path === ".." || path.startsWith("../")) throw new Error("Relative link escapes the profile repository");
  return path;
}

export function link(value: unknown, path = "link"): string {
  const result = text(value, path);
  const decoded = decodeURIComponent(result);
  if (/\s/u.test(result) || /[\x00-\x1f\x7f\\]/.test(decoded)) {
    throw new Error(`${path}: links must not contain whitespace, controls or backslashes`);
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(decoded)) {
    const url = new URL(decoded);
    if (!/^https:\/\//i.test(decoded) || url.protocol !== "https:" || !url.hostname || url.username || url.password) {
      throw new Error(`${path}: links must use https: or be repository-relative`);
    }
  } else {
    if (decoded.startsWith("/") || parts(decoded).path.split("/")[0].includes(":")) {
      throw new Error(`${path}: links must use https: or be repository-relative`);
    }
    relativePath(decoded);
  }
  return result;
}

export function icon(value: unknown, path: string): Icon {
  if (typeof value === "string") return link(value, path);
  const entry = fields(value, ["light", "dark"], [], path);
  return { light: link(entry.light, `${path}.light`), dark: link(entry.dark, `${path}.dark`) };
}

function navigation(value: unknown, roles: readonly string[], complete: boolean, path: string): Record<string, Link> {
  const entries = fields(value, complete ? [...roles] : [], complete ? [] : [...roles], path);
  return Object.fromEntries(Object.entries(entries).map(([role, item]) => {
    const entry = fields(item, ["label", "url"], [], `${path}.${role}`);
    return [role, { label: text(entry.label, `${path}.${role}.label`), url: link(entry.url, `${path}.${role}.url`) }];
  }));
}

export function parseCatalog(value: unknown, path = "catalog"): Catalog {
  const catalog = fields(value, ["organization", "promise", "secondary", "mark", "navigation", "groups"],
    ["website", "maintainer", "description", "quickstart"], path);
  const org = fields(catalog.organization, ["login", "name", "about"], [], `${path}.organization`);
  const seen = new Set<string>();
  const result: Catalog = {
    organization: {
      login: identifier(org.login, "organization", `${path}.organization.login`),
      name: text(org.name, `${path}.organization.name`), about: text(org.about, `${path}.organization.about`),
    },
    promise: text(catalog.promise, `${path}.promise`), secondary: text(catalog.secondary, `${path}.secondary`),
    mark: icon(catalog.mark, `${path}.mark`),
    navigation: navigation(catalog.navigation, NAVIGATION, false, `${path}.navigation`),
    groups: list(catalog.groups, `${path}.groups`).map((item, index) => {
      const context = `${path}.groups[${index}]`;
      const group = fields(item, ["title", "repositories"], [], context);
      const repositories = list(group.repositories, `${context}.repositories`);
      if (!repositories.length) throw new Error(`${context}.repositories: expected a nonempty array`);
      return {
        title: text(group.title, `${context}.title`),
        repositories: repositories.map((item, repoIndex): Repository => {
          const context = `${path}.groups[${index}].repositories[${repoIndex}]`;
          const repo = fields(item, ["name", "outcome", "icon", "kind", "title", "about"], [], context);
          const name = identifier(repo.name, "repository", `${context}.name`);
          const lower = name.toLowerCase();
          if (seen.has(lower)) throw new Error(`${context}: duplicate catalog repository: ${name}`);
          if ([".github", ".github-private"].includes(lower)) throw new Error(`${context}: ${name} is not a public catalog member`);
          seen.add(lower);
          if (!KINDS.includes(repo.kind as typeof KINDS[number])) throw new Error(`${context}.kind: expected ${KINDS.join(", ")}`);
          return {
            name, kind: repo.kind as Repository["kind"], outcome: text(repo.outcome, `${context}.outcome`),
            icon: icon(repo.icon, `${context}.icon`), title: text(repo.title, `${context}.title`), about: text(repo.about, `${context}.about`),
          };
        }),
      };
    }),
  };
  if ("website" in catalog) result.website = link(catalog.website, `${path}.website`);
  if ("description" in catalog) result.description = text(catalog.description, `${path}.description`);
  if ("maintainer" in catalog) {
    const entry = fields(catalog.maintainer, ["label", "url"], [], `${path}.maintainer`);
    result.maintainer = { label: text(entry.label, `${path}.maintainer.label`), url: link(entry.url, `${path}.maintainer.url`) };
  }
  if ("quickstart" in catalog) {
    const entry = fields(catalog.quickstart, ["title", "commands"], [], `${path}.quickstart`);
    const commands = list(entry.commands, `${path}.quickstart.commands`).map((command, index) => {
      const value = text(command, `${path}.quickstart.commands[${index}]`);
      if (value.includes("```")) throw new Error(`${path}.quickstart.commands[${index}]: code fences are not allowed`);
      return value;
    });
    if (!commands.length) throw new Error(`${path}.quickstart.commands: expected a nonempty array`);
    result.quickstart = { title: text(entry.title, `${path}.quickstart.title`), commands };
  }
  return result;
}

export async function readCatalog(file: string): Promise<Catalog> {
  return parseCatalog(json(await readFile(file, "utf8"), file), file);
}

export function parseMember(value: unknown, catalog: Catalog, path = "member"): Member {
  const member = fields(value, ["maintenance", "repositories"], [], path);
  const operations = object(member.repositories, `${path}.repositories`);
  const expected = catalog.groups.flatMap(group => group.repositories.map(repo => repo.name));
  const missing = expected.filter(name => !Object.hasOwn(operations, name));
  const extra = Object.keys(operations).filter(name => !expected.includes(name));
  if (missing.length || extra.length) throw new Error(`${path}: membership mismatch: missing ${JSON.stringify(missing)}, extra ${JSON.stringify(extra)}`);
  return {
    maintenance: navigation(member.maintenance, MAINTENANCE, true, `${path}.maintenance`) as Member["maintenance"],
    repositories: Object.fromEntries(Object.entries(operations).map(([name, value]) => {
      const context = `${path}.repositories.${name}`;
      const facts = fields(value, ["default_branch", "workflow", "releases"], [], context);
      if (facts.workflow !== null && (typeof facts.workflow !== "string" || !/^[A-Za-z0-9_.-]+\.ya?ml$/.test(facts.workflow))) {
        throw new Error(`${context}.workflow: expected a .yml or .yaml filename, or null`);
      }
      if (!["published", "channel", "none"].includes(facts.releases as string)) throw new Error(`${context}.releases: expected published, channel or none`);
      return [name, {
        default_branch: text(facts.default_branch, `${context}.default_branch`),
        workflow: facts.workflow as string | null, releases: facts.releases as Operations["releases"],
      }];
    })),
  };
}

export function revision(value: unknown): string {
  if (typeof value !== "string" || !/^[0-9a-fA-F]{40}$/.test(value)) throw new Error("catalog-revision: expected a full 40-hex commit SHA");
  return value;
}

// Match Python quote/quote_plus so existing profile links keep their bytes.
export function quoteURL(value: string): string {
  return encodeURIComponent(value).replace(/[!'()*]/g, char => `%${char.charCodeAt(0).toString(16).toUpperCase()}`);
}

export function query(value: Record<string, string>): string {
  return Object.entries(value).map(([key, value]) => `${quoteURL(key)}=${quoteURL(value).replaceAll("%20", "+")}`).join("&");
}

export function catalogURL(value: string, catalog: Catalog, commit?: string, image = false): string {
  link(value);
  if (commit === undefined || /^[a-z][a-z0-9+.-]*:/i.test(value)) return value;
  const path = relativePath(value).split("/").map(quoteURL).join("/");
  const owner = catalog.organization.login;
  const base = image ? `https://raw.githubusercontent.com/${owner}/.github/${quoteURL(commit)}`
    : `https://github.com/${owner}/.github/blob/${quoteURL(commit)}`;
  return `${base}/${path}${parts(value).suffix}`;
}
