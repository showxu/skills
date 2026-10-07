# MCP Server Evaluation

Evaluate whether an agent can solve realistic tasks using only the MCP server's
tools and the host context. Do not treat endpoint coverage as proof of quality.

## Eval Question Rules

Create about 10 questions. Each question should be:

- read-only, non-destructive, and idempotent
- independent from every other question
- realistic for a human assisted by an agent
- complex enough to require multiple tool calls
- answerable with one stable, directly comparable answer
- insulated from changing live state by using fixed time windows or closed data

Avoid:

- counts that change over time
- answers requiring long prose or unordered lists
- questions solvable by one obvious keyword search
- write operations or setup mutations

## Eval Process

1. Inspect service/API docs.
2. Inspect MCP tool list and input schemas without calling tools.
3. Explore content with read-only calls only.
4. Use small limits while exploring.
5. Create questions and solve them yourself.
6. Store expected answers as exact strings.
7. Run the eval through an agent loop and capture:
   - final answer
   - tool calls
   - duration
   - failure reason
   - tool feedback

## XML Shape

```xml
<evaluation>
  <qa_pair>
    <question>Find the project closed in Q2 2024 whose owner later archived the related repository. What is the project name?</question>
    <answer>Website Redesign</answer>
  </qa_pair>
</evaluation>
```

## What The Harness Should Measure

- Accuracy by exact answer comparison.
- Tool-call count and repeated-call loops.
- Whether tool descriptions led the agent to the right tool.
- Whether result payloads were too large.
- Whether pagination was discoverable.
- Whether errors were actionable.
- Whether the server exposed enough stable identifiers.

## Two Protocol Layers

An MCP eval has two distinct layers:

1. **MCP server protocol layer**
   - Connect to the server over stdio, streamable HTTP, or legacy SSE.
   - Read the tool list and schemas with `list_tools`.
   - Execute tool calls with `call_tool`.
   - Preserve MCP result/error shape for scoring and diagnosis.

2. **Model runner protocol layer**
   - Translate MCP tools into the model/agent runner's tool format.
   - Let the model choose a tool call.
   - Bridge the model's tool call into MCP `call_tool`.
   - Return MCP output to the model in the runner's expected result format.
   - Handle approval, auth, logging, and provider-specific message state.

This distinction matters. Claude API, OpenAI Responses API, OpenAI Agents SDK,
and Codex SDK can all expose MCP-backed tools to a model/agent, but their
runner protocols differ. Do not store those provider-specific loops in this
skill.

## Harness Receipt

The upstream `mcp-builder` sources include an Anthropic-specific evaluation
script that connects to stdio, SSE, or streamable HTTP servers, lists tools,
runs XML QA pairs through a Claude tool-use loop, and writes a Markdown report.

This local skill preserves the MCP-side harness mechanics but does not copy the
Claude runner script:

- MCP-side ownership here: stdio/SSE/streamable HTTP connection shape,
  `list_tools`, `call_tool`, XML QA pairs, exact answer comparison,
  per-tool metrics, tool feedback, and report sections.
- Claude API runner ownership belongs to `claude-api`: Anthropic SDK, Messages
  API, model IDs, `tool_use` / `tool_result` blocks, auth, and
  Claude-specific message formatting. The upstream script is this shape; it is
  not a Claude Code SDK runner.
- OpenAI model runner ownership belongs to the OpenAI API skill owner:
  Responses API function/MCP tool-call format, `function_call_output` or
  `mcp_call` result bridging, model selection, auth, and approval handling.
- Codex agent runner ownership belongs to the Codex SDK/automation owner:
  controlling local Codex agents, Codex threads/runs, Codex CLI-as-MCP, and
  workspace-local app-server behavior.
- Future executable evaluator should have a shared MCP eval core plus runner
  adapters. This skill owns the core contract and adapter boundary, not the
  provider-specific runner logic.

## Review Outcomes

Use eval failures to improve the server:

- Wrong tool chosen: rename or rewrite descriptions.
- Too many calls: add workflow tool or better filters.
- Context blowup: trim default output and paginate.
- Wrong answer despite tool access: improve schemas, stable IDs, or output
  format.
- Unsafe path: split mutating tools, add annotations, and strengthen host/user
  confirmation.
