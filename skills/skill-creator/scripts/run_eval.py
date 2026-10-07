#!/usr/bin/env python3
"""Run trigger evaluation for a skill description.

Tests whether a skill's description should trigger for a set of queries.
The Anthropic source path uses `claude -p`; this Codex-adapted version uses
`codex exec` by default and keeps `--runner claude` for compatibility.
"""

import argparse
import json
import os
import re
import select
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
if str(SKILL_ROOT) not in sys.path:
    sys.path.insert(0, str(SKILL_ROOT))

from scripts.utils import parse_skill_md

PROMPT_INPUT_NON_CLAIM = (
    "codex debug prompt-input proves rendered prompt/registry visibility only; "
    "it does not prove runtime skill consultation or native auto-trigger success."
)


def find_project_root() -> Path:
    """Find the project root by walking up from cwd looking for host config.

    Claude uses `.claude/commands`; Codex often has `.codex/` at the project
    root. Fall back to cwd when no host-local config exists.
    """
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".codex").is_dir() or (parent / ".claude").is_dir():
            return parent
    return current


def resolve_runner(runner: str) -> str:
    if runner != "auto":
        return runner
    if shutil.which("codex"):
        return "codex"
    return "claude"


def parse_trigger_response(text: str) -> bool:
    stripped = text.strip()
    if "```" in stripped:
        stripped = stripped.replace("```json", "```")
        parts = stripped.split("```")
        if len(parts) >= 3:
            stripped = parts[1].strip()
    try:
        data = json.loads(stripped)
        return bool(data.get("triggered"))
    except json.JSONDecodeError:
        upper = stripped.upper()
        if "NO_TRIGGER" in upper:
            return False
        if "TRIGGER" in upper:
            return True
        return False


def write_candidate_skill(skill_dir: Path, skill_name: str, skill_description: str) -> Path:
    skill_dir.mkdir(parents=True, exist_ok=True)
    skill_path = skill_dir / "SKILL.md"
    description_lines = skill_description.splitlines() or [""]
    indented_description = "\n  ".join(description_lines)
    skill_path.write_text(
        (
            "---\n"
            f"name: {json.dumps(skill_name)}\n"
            "description: |\n"
            f"  {indented_description}\n"
            "---\n\n"
            f"# {skill_name}\n\n"
            "Temporary Codex trigger-eval candidate.\n"
        ),
        encoding="utf-8",
    )
    return skill_path


def prompt_input_contains_candidate(
    prompt_text: str,
    skill_name: str,
    skill_description: str,
    skill_path: Path,
) -> bool:
    """Identify the candidate's registry entry even when descriptions are shortened."""
    try:
        rendered = json.loads(prompt_text)
    except json.JSONDecodeError:
        rendered = prompt_text

    def instruction_texts(value):
        if isinstance(value, str):
            yield value
        elif isinstance(value, list):
            for item in value:
                yield from instruction_texts(item)
        elif isinstance(value, dict):
            # A task can mention a path without the host discovering that skill.
            if value.get("role") not in (None, "system", "developer"):
                return
            for item in value.values():
                yield from instruction_texts(item)

    expected_path = skill_path.resolve()
    for text in instruction_texts(rendered):
        blocks = re.findall(r"<skills_instructions>(.*?)</skills_instructions>", text, re.DOTALL)
        for block in blocks or [text]:
            roots = dict(re.findall(r"^- `([^`]+)` = `([^`]+)`\s*$", block, re.MULTILINE))
            _, marker, entries = block.partition("### Available skills")
            if not marker:
                continue
            for line in entries.splitlines():
                if line.startswith("#") or line.startswith("</"):
                    break
                if not line.startswith(f"- {skill_name}:"):
                    continue
                location = re.search(r"\(file:\s*([^)]+)\)", line)
                if not location:
                    continue
                candidate = Path(location.group(1).strip())
                if not candidate.is_absolute():
                    alias, separator, relative = str(candidate).partition("/")
                    if not separator or alias not in roots:
                        continue
                    candidate = Path(roots[alias]) / relative
                if candidate.resolve() == expected_path:
                    return True
    return False


def run_codex_prompt_input_preflight(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
) -> dict:
    """Verify Codex renders the candidate skill before proxy trigger scoring."""
    with tempfile.TemporaryDirectory(prefix="skill-trigger-codex-home-") as tmp:
        codex_home = Path(tmp).resolve()
        candidate_path = write_candidate_skill(
            codex_home / "skills" / "candidate-skill",
            skill_name,
            skill_description,
        )
        cmd = ["codex", "debug", "prompt-input"]
        if model:
            cmd.extend(["-c", f"model={json.dumps(model)}"])
        cmd.append(query)
        env = {**os.environ, "CODEX_HOME": str(codex_home)}

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=project_root,
            env=env,
        )
        if result.returncode != 0:
            raise RuntimeError(
                "codex debug prompt-input exited "
                f"{result.returncode}\nstderr: {result.stderr}"
            )

        prompt_text = result.stdout
        try:
            prompt_text = json.dumps(json.loads(result.stdout), ensure_ascii=False)
        except json.JSONDecodeError:
            pass

        visible = prompt_input_contains_candidate(prompt_text, skill_name, skill_description, candidate_path)
        evidence = {
            "status": "passed" if visible else "failed",
            "checked_query": query,
            "candidate_skill_name": skill_name,
            "candidate_skill_description": skill_description,
            "candidate_skill_path": str(candidate_path),
            "visible": visible,
            "non_claim": PROMPT_INPUT_NON_CLAIM,
        }
        if not visible:
            raise RuntimeError(
                "codex debug prompt-input did not expose the candidate skill; "
                "this is eval setup failure, not description-trigger evidence."
            )
        return evidence


def build_setup_evidence(
    selected_runner: str,
    eval_set: list[dict],
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: Path,
    model: str | None,
) -> dict:
    checked_query = eval_set[0]["query"] if eval_set else ""
    prompt_input = {
        "status": "not_applicable",
        "checked_query": checked_query,
        "candidate_skill_name": skill_name,
        "candidate_skill_description": skill_description,
        "visible": None,
        "non_claim": PROMPT_INPUT_NON_CLAIM,
    }
    if selected_runner == "codex" and checked_query:
        prompt_input = run_codex_prompt_input_preflight(
            checked_query,
            skill_name,
            skill_description,
            timeout,
            str(project_root),
            model,
        )
    elif selected_runner == "codex":
        prompt_input["status"] = "skipped_no_queries"
    return {
        "runner": selected_runner,
        "prompt_input": prompt_input,
    }


def run_codex_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
) -> bool:
    """Ask Codex's model to make the trigger decision for one query.

    This is a description-trigger proxy. The prompt-input preflight in
    `run_eval` confirms rendered prompt visibility before this scorer runs, but
    Codex still does not expose a stream event proving runtime skill
    consultation for this prompt.
    """
    schema = {
        "type": "object",
        "additionalProperties": False,
        "required": ["triggered", "reason"],
        "properties": {
            "triggered": {"type": "boolean"},
            "reason": {"type": "string"},
        },
    }
    prompt = f"""You are evaluating whether a Codex skill should trigger.

Skill name: {skill_name}
Skill description:
{skill_description}

User query:
{query}

Decide only whether the skill should be used for this query based on the skill
name and description. Do not solve the task. Return JSON only with:
- triggered: true if the skill should trigger
- reason: one short reason
"""

    with tempfile.TemporaryDirectory(prefix="skill-trigger-codex-") as tmp:
        tmp_path = Path(tmp)
        schema_path = tmp_path / "schema.json"
        output_path = tmp_path / "last_message.json"
        schema_path.write_text(json.dumps(schema), encoding="utf-8")

        cmd = [
            "codex",
            "exec",
            "--skip-git-repo-check",
            "--ephemeral",
            "--sandbox",
            "read-only",
            "--cd",
            project_root,
            "--output-schema",
            str(schema_path),
            "--output-last-message",
            str(output_path),
            "-",
        ]
        if model:
            cmd[2:2] = ["--model", model]

        result = subprocess.run(
            cmd,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        if result.returncode != 0:
            raise RuntimeError(f"codex exec exited {result.returncode}\nstderr: {result.stderr}")
        if output_path.exists():
            response_text = output_path.read_text(encoding="utf-8", errors="replace")
        else:
            response_text = result.stdout
        if not response_text.strip():
            raise RuntimeError("codex exec produced no final message")
        return parse_trigger_response(response_text)


def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
    runner: str = "auto",
) -> bool:
    """Run a single query and return whether the skill was triggered.

    The Codex runner is a proxy trigger decision from the skill name and
    description. The Claude runner creates a command file in .claude/commands/
    so it appears in Claude's available_skills list, then runs `claude -p` with
    the raw query and watches stream events.
    """
    selected_runner = resolve_runner(runner)
    if selected_runner == "codex":
        return run_codex_query(query, skill_name, skill_description, timeout, project_root, model)

    unique_id = uuid.uuid4().hex[:8]
    clean_name = f"{skill_name}-skill-{unique_id}"
    project_commands_dir = Path(project_root) / ".claude" / "commands"
    command_file = project_commands_dir / f"{clean_name}.md"

    try:
        project_commands_dir.mkdir(parents=True, exist_ok=True)
        # Use YAML block scalar to avoid breaking on quotes in description
        indented_desc = "\n  ".join(skill_description.split("\n"))
        command_content = (
            f"---\n"
            f"description: |\n"
            f"  {indented_desc}\n"
            f"---\n\n"
            f"# {skill_name}\n\n"
            f"This skill handles: {skill_description}\n"
        )
        command_file.write_text(command_content)

        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
            "--include-partial-messages",
        ]
        if model:
            cmd.extend(["--model", model])

        # Remove CLAUDECODE env var to allow nesting claude -p inside a
        # Claude Code session. The guard is for interactive terminal conflicts;
        # programmatic subprocess usage is safe.
        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            cwd=project_root,
            env=env,
        )

        triggered = False
        start_time = time.time()
        buffer = ""
        # Track state for stream event detection
        pending_tool_name = None
        accumulated_json = ""

        try:
            while time.time() - start_time < timeout:
                if process.poll() is not None:
                    remaining = process.stdout.read()
                    if remaining:
                        buffer += remaining.decode("utf-8", errors="replace")
                    break

                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue

                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    break
                buffer += chunk.decode("utf-8", errors="replace")

                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue

                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    # Early detection via stream events
                    if event.get("type") == "stream_event":
                        se = event.get("event", {})
                        se_type = se.get("type", "")

                        if se_type == "content_block_start":
                            cb = se.get("content_block", {})
                            if cb.get("type") == "tool_use":
                                tool_name = cb.get("name", "")
                                if tool_name in ("Skill", "Read"):
                                    pending_tool_name = tool_name
                                    accumulated_json = ""
                                else:
                                    return False

                        elif se_type == "content_block_delta" and pending_tool_name:
                            delta = se.get("delta", {})
                            if delta.get("type") == "input_json_delta":
                                accumulated_json += delta.get("partial_json", "")
                                if clean_name in accumulated_json:
                                    return True

                        elif se_type in ("content_block_stop", "message_stop"):
                            if pending_tool_name:
                                return clean_name in accumulated_json
                            if se_type == "message_stop":
                                return False

                    # Fallback: full assistant message
                    elif event.get("type") == "assistant":
                        message = event.get("message", {})
                        for content_item in message.get("content", []):
                            if content_item.get("type") != "tool_use":
                                continue
                            tool_name = content_item.get("name", "")
                            tool_input = content_item.get("input", {})
                            if tool_name == "Skill" and clean_name in tool_input.get("skill", ""):
                                triggered = True
                            elif tool_name == "Read" and clean_name in tool_input.get("file_path", ""):
                                triggered = True
                            return triggered

                    elif event.get("type") == "result":
                        return triggered
        finally:
            # Clean up process on any exit path (return, exception, timeout)
            if process.poll() is None:
                process.kill()
                process.wait()

        return triggered
    finally:
        if command_file.exists():
            command_file.unlink()


def run_eval(
    eval_set: list[dict],
    skill_name: str,
    description: str,
    num_workers: int,
    timeout: int,
    project_root: Path,
    runs_per_query: int = 1,
    trigger_threshold: float = 0.5,
    model: str | None = None,
    runner: str = "auto",
) -> dict:
    """Run the full eval set and return results."""
    results = []
    selected_runner = resolve_runner(runner)
    try:
        setup_evidence = build_setup_evidence(
            selected_runner,
            eval_set,
            skill_name,
            description,
            timeout,
            project_root,
            model,
        )
    except Exception as e:
        if selected_runner == "codex":
            raise RuntimeError(
                "Codex prompt-input preflight failed; this is eval setup "
                "failure, not evidence that the description should not trigger."
            ) from e
        raise

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    skill_name,
                    description,
                    timeout,
                    str(project_root),
                    model,
                    selected_runner,
                )
                future_to_info[future] = (item, run_idx)

        query_triggers: dict[str, list[bool]] = {}
        query_items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            query = item["query"]
            query_items[query] = item
            if query not in query_triggers:
                query_triggers[query] = []
            try:
                query_triggers[query].append(future.result())
            except Exception as e:
                if selected_runner == "codex":
                    raise RuntimeError(
                        "Codex trigger proxy failed; this is runner/toolchain "
                        "failure, not evidence that the description should not trigger. "
                        f"Query: {query}"
                    ) from e
                print(f"Warning: query failed: {e}", file=sys.stderr)
                query_triggers[query].append(False)

    for query, triggers in query_triggers.items():
        item = query_items[query]
        trigger_rate = sum(triggers) / len(triggers)
        should_trigger = item["should_trigger"]
        if should_trigger:
            did_pass = trigger_rate >= trigger_threshold
        else:
            did_pass = trigger_rate < trigger_threshold
        results.append({
            "query": query,
            "should_trigger": should_trigger,
            "trigger_rate": trigger_rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": did_pass,
        })

    passed = sum(1 for r in results if r["pass"])
    total = len(results)

    return {
        "skill_name": skill_name,
        "description": description,
        "setup_evidence": setup_evidence,
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run trigger evaluation for a skill description")
    parser.add_argument("--eval-set", required=True, help="Path to eval set JSON file")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--description", default=None, help="Override description to test")
    parser.add_argument("--num-workers", type=int, default=10, help="Number of parallel workers")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per query in seconds")
    parser.add_argument("--runs-per-query", type=int, default=3, help="Number of runs per query")
    parser.add_argument("--trigger-threshold", type=float, default=0.5, help="Trigger rate threshold")
    parser.add_argument("--model", default=None, help="Model to use for the selected runner")
    parser.add_argument("--runner", choices=("auto", "codex", "claude"), default=os.environ.get("SKILL_CREATOR_RUNNER", "auto"), help="Execution runner for trigger evals")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)

    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, original_description, content = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root()

    if args.verbose:
        print(f"Evaluating with runner={resolve_runner(args.runner)}: {description}", file=sys.stderr)

    output = run_eval(
        eval_set=eval_set,
        skill_name=name,
        description=description,
        num_workers=args.num_workers,
        timeout=args.timeout,
        project_root=project_root,
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        model=args.model,
        runner=args.runner,
    )

    if args.verbose:
        summary = output["summary"]
        print(f"Results: {summary['passed']}/{summary['total']} passed", file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else "FAIL"
            rate_str = f"{r['triggers']}/{r['runs']}"
            print(f"  [{status}] rate={rate_str} expected={r['should_trigger']}: {r['query'][:70]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
