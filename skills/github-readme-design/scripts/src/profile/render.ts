import { catalogURL, MAINTENANCE, NAVIGATION, query, quoteURL, revision } from "../catalog.ts";
import type { Catalog, Icon, Member } from "../catalog.ts";
import { px } from "../design.ts";
import type { Design } from "../design.ts";

function html(value: string): string {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#x27;");
}

function anchor(url: string, label: string): string {
  return `<a href="${html(url)}">${html(label)}</a>`;
}

function imageTag(value: Icon, label: string, size: number, resolve: (url: string) => string): string {
  const img = (url: string) => `<img src="${html(resolve(url))}" width="${size}" height="${size}" alt="${html(label)}">`;
  return typeof value === "string" ? img(value)
    : `<picture><source media="(prefers-color-scheme: dark)" srcset="${html(resolve(value.dark))}">${img(value.light)}</picture>`;
}

function badge(url: string, imageURL: string, label: string): string {
  return `<a href="${html(url)}"><img src="${html(imageURL)}" alt="${html(label)}"></a>`;
}

function size(design: Design, component: string): number {
  const value = px(design.components.light.get(component)?.get("size"), `components.${component}.size`);
  if (!Number.isInteger(value) || value <= 0) throw new Error(`components.${component}.size: expected positive integer pixels`);
  return value;
}

export function renderProfile(catalog: Catalog, design: Design, member?: Member, catalogRevision?: string): string {
  if (member) revision(catalogRevision);
  else if (catalogRevision !== undefined) throw new Error("catalog-revision: only allowed in member mode");
  const sizes = {
    header: size(design, "profile-header"), memberHeader: size(design, "profile-member-header"),
    row: size(design, "profile-row"), memberRow: size(design, "profile-member-row"),
  };
  const resolve = (url: string) => catalogURL(url, catalog, catalogRevision);
  const resolveImage = (url: string) => catalogURL(url, catalog, catalogRevision, true);
  const { login: owner, name } = catalog.organization;
  const title = member ? `${name} maintainer dashboard` : catalog.promise;
  const header = imageTag(catalog.mark, `${name} mark`, member ? sizes.memberHeader : sizes.header, resolveImage);
  const output = [`<p align="center">${header}</p>`, "", `<h1 align="center">${html(title)}</h1>`, ""];
  if (!member) {
    output.push(`<p align="center">${html(catalog.secondary)}</p>`, "");
    const links = NAVIGATION.flatMap(role => {
      const item = catalog.navigation[role];
      return item ? [anchor(resolve(item.url), item.label)] : [];
    });
    if (links.length) output.push(`<p align="center">${links.join(" · ")}</p>`, "");
    if (catalog.quickstart) output.push(`<h2>${html(catalog.quickstart.title)}</h2>`, "", "```sh", ...catalog.quickstart.commands, "```", "");
  } else {
    const url = catalog.website ? resolve(catalog.website) : `https://github.com/${owner}`;
    output.push(`<p align="center">${anchor(url, catalog.website ? "Public website" : "Public profile")}</p>`, "",
      "<h2>Maintenance</h2>", "", "<p>" + MAINTENANCE.map(role =>
        anchor(member.maintenance[role].url, member.maintenance[role].label)).join(" · ") + "</p>", "", "<h2>Repositories</h2>", "");
  }
  for (const group of catalog.groups) {
    const heading = member ? "h3" : "h2";
    output.push(`<${heading}>${html(group.title)}</${heading}>`, "", "<table>");
    if (member) output.push("<tr><th></th><th>Repository</th><th>CI</th><th>Release</th></tr>");
    for (const repo of group.repositories) {
      const url = `https://github.com/${owner}/${repo.name}`;
      const mark = imageTag(repo.icon, `${repo.name} icon`, member ? sizes.memberRow : sizes.row, resolveImage);
      const label = `<strong>${anchor(url, repo.name)}</strong>`;
      if (!member) output.push(`<tr><td>${mark}</td><td>${label}<br>${html(repo.outcome)}</td></tr>`);
      else {
        const facts = member.repositories[repo.name];
        let ci = anchor(`${url}/actions`, "Actions");
        if (facts.workflow !== null) {
          const workflow = quoteURL(facts.workflow);
          ci = badge(`${url}/actions/workflows/${workflow}?${query({ query: `branch:${facts.default_branch}` })}`,
            `https://img.shields.io/github/actions/workflow/status/${owner}/${repo.name}/${workflow}?${query({ branch: facts.default_branch, style: "flat", label: "CI" })}`, `${repo.name} CI`);
        }
        let release = "—";
        if (facts.releases === "published") release = badge(`${url}/releases`,
          `https://img.shields.io/github/v/release/${owner}/${repo.name}?${query({ style: "flat", sort: "date", include_prereleases: "true" })}`, `${repo.name} latest release`);
        else if (facts.releases === "channel") release = anchor(`${url}/releases`, "Releases");
        output.push(`<tr><td>${mark}</td><td>${label}</td><td>${ci}</td><td>${release}</td></tr>`);
      }
    }
    output.push("</table>", "");
  }
  if (member) {
    output.push("<h2>Needs attention</h2>", "", "<ul>");
    for (const [label, search, type] of [
      ["Open pull requests", "is:pr is:open", "pullrequests"],
      ["Open issues", "is:issue is:open", "issues"],
      ["Dependabot pull requests", "is:pr is:open author:app/dependabot", "pullrequests"],
    ]) output.push(`<li>${anchor(`https://github.com/search?${query({ q: `org:${owner} ${search}`, type })}`, label)}</li>`);
    output.push("</ul>", "");
  } else if (catalog.maintainer) output.push(`<p>${anchor(resolve(catalog.maintainer.url), catalog.maintainer.label)}</p>`, "");
  return output.join("\n");
}
