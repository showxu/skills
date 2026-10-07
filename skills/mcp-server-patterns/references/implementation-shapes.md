# MCP Implementation Shapes

Verify the current MCP specification and SDK README before coding. SDK APIs
change; these shapes are design anchors, not a substitute for current docs.

Primary sources to check:

- `https://modelcontextprotocol.io/llms-full.txt`
- `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md`
- `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`

## Language Selection

Choose the implementation language from the project host and maintenance
boundary.

| Host boundary | Preferred shape | Why |
|---|---|---|
| Swift package, Xcode workflow, macOS app, Apple local tooling, or this workspace's Swift library ecosystem | Swift | Keeps the backend in the owning package/toolchain and makes build/test/review follow local Swift rules. |
| Remote service, npm/MCPB distribution, broad MCP host compatibility, web deployment, or no local language owner | TypeScript | Strong public SDK examples, static typing, npm packaging, and broad agent-generated-code support. |
| Scripted local automation, data tooling, Python-first API client, notebooks, or quick internal harness | Python | Fast iteration and mature API/data libraries. |

Do not read an upstream TypeScript recommendation as a local absolute. It is a
good default for generic/public MCP servers; it is not stronger than a clear
Swift or Python host boundary.

## Swift Shape

Use Swift when the MCP server is part of a Swift package, Xcode workflow,
macOS app, local Apple automation, or another Swift-owned workspace surface.

Expected package shape:

```text
<service>-mcp-server/
├── Package.swift
├── Sources/
│   ├── <ServiceMCPServer>/
│   │   ├── main.swift
│   │   ├── Tools/
│   │   ├── Schemas/
│   │   └── Services/
│   └── <ServiceClient>/
└── Tests/
```

Rules:

- Keep the MCP protocol adapter thin; put service logic in normal Swift types.
- Use Swift's type system for request/response models before exposing tool
  schemas.
- Keep tool names service-prefixed and action-oriented just like other
  languages.
- Run from SwiftPM/Xcode using the owning package's normal build and test
  commands.
- If using a Swift MCP SDK or bridge package, verify its current README/API
  before coding; do not infer API details from TypeScript or Python examples.

Validation:

```bash
swift build
swift test
timeout 5s swift run <executable>
```

## TypeScript Shape

Use TypeScript when public host compatibility, npm distribution, MCPB/web
packaging, static types, and current official SDK examples matter.

Expected project shape:

```text
<service>-mcp-server/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts
│   ├── schemas/
│   ├── services/
│   ├── tools/
│   └── constants.ts
└── dist/
```

Current source-verified shape:

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import * as z from "zod/v4";

const server = new McpServer({
  name: "service-mcp-server",
  version: "1.0.0",
});

server.registerTool(
  "service_search_items",
  {
    title: "Search Service Items",
    description: "Search service items without modifying them.",
    inputSchema: {
      query: z.string().min(1).max(200),
      limit: z.number().int().min(1).max(100).default(20),
    },
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true,
    },
  },
  async ({ query, limit }) => {
    const result = { query, limit, items: [] };
    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
      structuredContent: result,
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

Rules:

- Prefer `server.registerTool`, `server.registerResource`, and
  `server.registerPrompt` over deprecated manual registration APIs.
- Use Zod schemas and strict TypeScript settings.
- Type tool parameters and return values explicitly.
- Put API clients and pagination helpers outside individual tool handlers.
- Add `outputSchema` and `structuredContent` when current SDK support and host
  compatibility justify it.

Validation:

```bash
npm run build
npx @modelcontextprotocol/inspector
```

## Python Shape

Use Python when the surrounding ecosystem, existing API client, or local
automation stack is Python-first.

Current source-verified shape:

```python
from enum import Enum
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field

mcp = FastMCP("service_mcp")


class ResponseFormat(str, Enum):
    markdown = "markdown"
    json = "json"


class SearchInput(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    query: str = Field(..., min_length=1, max_length=200)
    limit: int = Field(default=20, ge=1, le=100)
    response_format: ResponseFormat = ResponseFormat.markdown


@mcp.tool(
    name="service_search_items",
    annotations={
        "readOnlyHint": True,
        "destructiveHint": False,
        "idempotentHint": True,
        "openWorldHint": True,
    },
)
async def service_search_items(params: SearchInput) -> str:
    """Search service items without modifying them."""
    return "{}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
```

Rules:

- Use Pydantic v2 patterns: `ConfigDict`, `field_validator`,
  `model_dump()`.
- Use async I/O for network calls.
- Use `extra="forbid"` where extra model fields could hide mistakes.
- Keep logs off stdout for stdio servers.
- Keep auth in environment or host-managed configuration.

Validation:

```bash
python -m py_compile <server>.py
timeout 5s python <server>.py
```

## Shared Infrastructure

Create these before implementing many tools:

- API/auth client.
- Pagination helper.
- Response formatter for Markdown and JSON/structured output.
- Error mapper for auth, permission, not found, rate limit, timeout, and
  validation failures.
- Constants for API base URL, default limit, max limit, and output size limits.
- Logging that cannot corrupt the MCP transport.

## Failure Diagnosis

- Server hangs when run directly: expected for stdio; use timeout, inspector, or
  run in a separate session.
- Client cannot parse output: check stdout logging and structured response.
- Agent calls wrong tool: improve service prefix, description, and examples.
- Agent runs out of context: reduce default fields, add pagination, add concise
  response mode.
- Writes happen unexpectedly: audit annotations, host confirmations, and
  destructive operation descriptions.
