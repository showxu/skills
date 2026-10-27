"""Usage windows, host-specific count units and content-free reports."""

from __future__ import annotations

import json
import os
import unittest

from helpers import HelperTestCase


SINCE = "2026-10-01T00:00:00Z"
UNTIL = "2026-10-03T00:00:00Z"


def codex_meta(cwd, when=SINCE):
    return {"timestamp": when, "type": "session_meta", "payload": {"cwd": str(cwd)}}


def codex_call(skill="alpha", when=SINCE, custom=False):
    return {"timestamp": when, "type": "response_item", "payload": {
        "type": "custom_tool_call" if custom else "function_call",
        "input" if custom else "arguments": f"read /collection/{skill}/SKILL.md",
    }}


def claude_call(skill="alpha", when=SINCE, cwd=None):
    event = {"timestamp": when, "type": "assistant", "message": {"content": [
        {"type": "tool_use", "name": "Skill", "input": {"skill": skill}},
    ]}}
    if cwd is not None:
        event["cwd"] = str(cwd)
    return event


class UsageCountsTests(HelperTestCase):
    def setUp(self):
        super().setUp()
        self.repository = self.root / "repository"
        (self.repository / ".git").mkdir(parents=True)
        self.skills = self.repository / "collection" / "skills"
        for folder, name in (("different-folder", "alpha"), ("beta", "beta"), ("unused", "unused")):
            path = self.skills / folder / "SKILL.md"
            path.parent.mkdir(parents=True)
            path.write_text(f"---\nname: '{name}'\ndescription: fixture\n---\n", encoding="utf-8")

    def count(self, *arguments, env=None):
        return self.run_helper("usage_counts.py", "--skills-root", self.skills,
                               "--since", "2026-10-01", "--until", "2026-10-03", *arguments, env=env)

    def add_worktree(self, path, relative=False):
        metadata = self.repository / ".git" / "worktrees" / path.name
        metadata.mkdir(parents=True)
        path.mkdir(parents=True)
        target = os.path.relpath(metadata, path) if relative else str(metadata)
        (path / ".git").write_text(f"gitdir: {target}\n", encoding="utf-8")
        return path

    def worktree_skills(self, worktree):
        self.skills = worktree / "skills"
        skill = self.skills / "alpha" / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("---\nname: alpha\n---\n", encoding="utf-8")

    def test_counts_codex_sessions_and_claude_calls_in_window(self):
        self.jsonl(self.codex_home / "sessions" / "current.jsonl", [
            codex_call(), codex_call(), codex_call("beta", custom=True),
            codex_call("unused", when="2026-09-30T23:59:59Z"), codex_call("unused", when=UNTIL),
        ])
        self.jsonl(self.codex_home / "archived_sessions" / "old.jsonl", [
            codex_call(), codex_call(when="2026-10-02T12:00:00+08:00"),
        ])
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(), claude_call(), claude_call("beta"),
            claude_call("unused", when="2026-09-30T23:59:59Z"), claude_call("unused", when=UNTIL),
        ])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["counts"], {
            "alpha": {"codex": {"uses": 2, "maintenance": 0}, "claude-code": {"uses": 2, "maintenance": 0}},
            "beta": {"codex": {"uses": 1, "maintenance": 0}, "claude-code": {"uses": 1, "maintenance": 0}},
            "unused": {"codex": {"uses": 0, "maintenance": 0}, "claude-code": {"uses": 0, "maintenance": 0}},
        })
        self.assertEqual(report["totals"], {
            "codex": {"uses": 3, "maintenance": 0}, "claude-code": {"uses": 3, "maintenance": 0},
        })
        self.assertEqual(report["files_read"], {"codex": 2, "claude-code": 1})
        self.assertEqual(report["parse_errors"], [])
        self.assertEqual(report["window"], {"since": "2026-10-01T00:00:00+00:00", "until": "2026-10-03T00:00:00+00:00"})

    def test_plugin_names_and_subagents_are_included(self):
        self.jsonl(self.claude_projects / "project" / "parent.jsonl", [claude_call("plugin:alpha")])
        self.jsonl(self.claude_projects / "project" / "parent" / "subagents" / "child.jsonl", [
            claude_call("other-plugin:beta"), claude_call("unknown"), claude_call("alpha"),
        ])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["totals"]["claude-code"], {"uses": 3, "maintenance": 0})
        self.assertEqual(report["counts"]["alpha"]["claude-code"], {"uses": 2, "maintenance": 0})
        self.assertEqual(report["files_read"]["claude-code"], 2)

    def test_corrupt_lines_are_reported_without_exposing_content(self):
        secret = "PRIVATE_TRANSCRIPT_SENTINEL"
        path = self.jsonl(self.codex_home / "sessions" / "corrupt.jsonl", [codex_call()])
        with path.open("ab") as stream:
            stream.write((secret + "{bad json\n").encode())
            stream.write(b"\xff\xfe\n")
            stream.write(b"null\n")
            stream.write((json.dumps(codex_call("beta", when="invalid " + secret)) + "\n").encode())
            stream.write((json.dumps(codex_call("beta", when=123)) + "\n").encode())
            stream.write((json.dumps(codex_call("beta", custom=True)) + "\n").encode())
        event = claude_call()
        event["message"]["content"].insert(0, {"type": "text", "text": secret})
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [event])
        for arguments in (("--json",), ()):
            with self.subTest(arguments=arguments):
                result = self.count(*arguments)
                self.assertNotIn(secret, result.stdout + result.stderr)
                self.assertNotIn("read /collection", result.stdout + result.stderr)
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["parse_errors"], [{"host": "codex", "file": str(path), "invalid_lines": 5}])
        self.assertEqual(report["counts"]["beta"]["codex"], {"uses": 1, "maintenance": 0})

    def test_only_matching_tool_calls_count(self):
        events = [
            {"timestamp": SINCE, "type": "response_item", "payload": {"type": "message", "arguments": "/collection/alpha/SKILL.md"}},
            {"timestamp": SINCE, "type": "event_msg", "payload": {"type": "function_call", "arguments": "/collection/alpha/SKILL.md"}},
            codex_call("alpha/SKILL.md.backup"),
        ]
        escaped = codex_call("beta")
        escaped["payload"]["arguments"] = json.dumps({"path": "/collection/beta/SKILL.md"}).replace("/", "\\/")
        events.append(escaped)
        self.jsonl(self.codex_home / "sessions" / "session.jsonl", events)
        message = claude_call()
        message["message"]["content"][0]["name"] = "Read"
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [message])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["totals"], {
            "codex": {"uses": 1, "maintenance": 0}, "claude-code": {"uses": 0, "maintenance": 0},
        })
        self.assertEqual(report["counts"]["alpha"]["codex"], {"uses": 0, "maintenance": 0})

    def test_explicit_stores_override_isolated_defaults(self):
        self.jsonl(self.codex_home / "sessions" / "default.jsonl", [codex_call()])
        self.jsonl(self.claude_projects / "project" / "default.jsonl", [claude_call()])
        alternate = self.root / "alternate"
        self.jsonl(alternate / "sessions" / "session.jsonl", [codex_call("beta")])
        report = json.loads(self.count("--json", "--codex-home", alternate,
                                       "--claude-projects", self.root / "missing").stdout)
        self.assertEqual(report["counts"]["alpha"], {
            "codex": {"uses": 0, "maintenance": 0}, "claude-code": {"uses": 0, "maintenance": 0},
        })
        self.assertEqual(report["counts"]["beta"]["codex"], {"uses": 1, "maintenance": 0})

    def test_codex_default_uses_home_when_environment_override_is_absent(self):
        self.jsonl(self.codex_home / "sessions" / "session.jsonl", [codex_call()])
        env = dict(self.env)
        del env["CODEX_HOME"]
        self.assertEqual(json.loads(self.count("--json", env=env).stdout)["totals"]["codex"],
                         {"uses": 1, "maintenance": 0})

    def test_unbounded_window_and_timezone_boundaries(self):
        self.jsonl(self.codex_home / "sessions" / "first.jsonl", [codex_call(when="2026-10-01T01:00:00+01:00")])
        self.jsonl(self.codex_home / "sessions" / "second.jsonl", [codex_call(when="2026-09-30T23:59:59+00:00")])
        self.jsonl(self.codex_home / "sessions" / "third.jsonl", [codex_call(when="2026-11-01T00:00:00Z")])
        report = json.loads(self.run_helper("usage_counts.py", "--skills-root", self.skills,
                                             "--since", "2026-10-01", "--json").stdout)
        self.assertEqual(report["totals"]["codex"], {"uses": 2, "maintenance": 0})
        self.assertIsNone(report["window"]["until"])

    def test_codex_classifies_repository_worktree_and_outside_sessions(self):
        worktree = self.add_worktree(self.repository / ".claude" / "worktrees" / "task")
        outside = self.root / "repository-other"
        for name, cwd in (("main", self.repository), ("task", worktree), ("outside", outside)):
            other_cwd = self.repository if name == "outside" else outside
            call = codex_call()
            call["cwd"] = str(other_cwd)
            self.jsonl(self.codex_home / "sessions" / f"{name}.jsonl", [
                codex_meta(cwd, when="2026-09-01T00:00:00Z"),
                codex_meta(other_cwd), call, codex_call(custom=True),
            ])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["counts"]["alpha"]["codex"], {"uses": 1, "maintenance": 2})
        self.assertEqual(report["totals"]["codex"], {"uses": 1, "maintenance": 2})
        self.assertEqual(report["files_read"]["codex"], 3)

    def test_skills_in_a_worktree_include_all_checkouts_of_the_same_repository(self):
        task = self.add_worktree(self.repository / ".claude" / "worktrees" / "task", relative=True)
        sibling = self.add_worktree(self.repository / ".claude" / "worktrees" / "sibling")
        external = self.add_worktree(self.root / "external-worktrees" / "external", relative=True)
        self.worktree_skills(task)
        locations = (("main", self.repository), ("task", task), ("sibling", sibling / "nested"),
                     ("external", external / "nested"), ("outside", self.root / "outside"))
        for name, cwd in locations:
            self.jsonl(self.codex_home / "sessions" / f"{name}.jsonl", [
                codex_meta(cwd), codex_call(), codex_call(custom=True),
            ])
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(cwd=cwd) for _, cwd in locations
        ])
        report = json.loads(self.count("--json").stdout)
        for host in ("codex", "claude-code"):
            self.assertEqual(report["counts"]["alpha"][host], {"uses": 1, "maintenance": 4})
            self.assertEqual(report["totals"][host], {"uses": 1, "maintenance": 4})

    def test_deleted_worktrees_outside_the_main_checkout_count_as_uses(self):
        task = self.add_worktree(self.repository / ".claude" / "worktrees" / "task")
        self.worktree_skills(task)
        deleted = [self.add_worktree(self.root / "external-worktrees" / "external-deleted"),
                   self.add_worktree(self.repository / ".claude" / "worktrees" / "internal-deleted")]
        for index, worktree in enumerate(deleted):
            (worktree / ".git").unlink()
            worktree.rmdir()
            self.jsonl(self.codex_home / "sessions" / f"session-{index}.jsonl", [
                codex_meta(worktree), codex_call(),
            ])
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(cwd=worktree) for worktree in deleted
        ])
        report = json.loads(self.count("--json").stdout)
        for host in ("codex", "claude-code"):
            self.assertEqual(report["counts"]["alpha"][host], {"uses": 1, "maintenance": 1})

    def test_other_repositories_and_their_worktrees_count_as_uses(self):
        task = self.add_worktree(self.repository / ".claude" / "worktrees" / "task")
        self.worktree_skills(task)
        other = self.root / "other-repository"
        metadata = other / ".git" / "worktrees" / "task"
        metadata.mkdir(parents=True)
        other_task = self.root / "other-worktrees" / "task"
        other_task.mkdir(parents=True)
        (other_task / ".git").write_text(f"gitdir: {metadata}\n", encoding="utf-8")
        for index, cwd in enumerate((other, other_task)):
            self.jsonl(self.codex_home / "sessions" / f"session-{index}.jsonl", [
                codex_meta(cwd), codex_call(),
            ])
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(cwd=cwd) for cwd in (other, other_task)
        ])
        report = json.loads(self.count("--json").stdout)
        for host in ("codex", "claude-code"):
            self.assertEqual(report["counts"]["alpha"][host], {"uses": 2, "maintenance": 0})

    def test_gitfile_can_point_directly_to_the_common_directory(self):
        checkout = self.root / "linked-checkout"
        checkout.mkdir()
        target = os.path.relpath(self.repository / ".git", checkout)
        (checkout / ".git").write_text(f"gitdir: {target}\n", encoding="utf-8")
        self.worktree_skills(checkout)
        for index, cwd in enumerate((self.repository, checkout)):
            self.jsonl(self.codex_home / "sessions" / f"session-{index}.jsonl", [
                codex_meta(cwd), codex_call(),
            ])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["counts"]["alpha"]["codex"], {"uses": 0, "maintenance": 2})

    def test_claude_classifies_each_calls_own_cwd(self):
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(cwd=self.repository),
            claude_call(cwd=self.root / "outside"),
            claude_call("plugin:alpha", cwd=self.repository / ".claude" / "worktrees" / "task"),
            claude_call("beta", when=UNTIL, cwd=self.repository),
        ])
        self.jsonl(self.claude_projects / "project" / "session" / "subagents" / "child.jsonl", [
            claude_call("beta", cwd=self.repository),
        ])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["counts"]["alpha"]["claude-code"], {"uses": 1, "maintenance": 2})
        self.assertEqual(report["counts"]["beta"]["claude-code"], {"uses": 0, "maintenance": 1})
        self.assertEqual(report["totals"]["claude-code"], {"uses": 1, "maintenance": 3})

    def test_without_git_uses_the_skills_roots_parent(self):
        self.skills = self.root / "unversioned" / "skills"
        skill = self.skills / "alpha" / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("---\nname: alpha\n---\n", encoding="utf-8")
        for name, cwd in (("inside", self.skills.parent), ("outside", self.root / "unversioned-other")):
            self.jsonl(self.codex_home / "sessions" / f"{name}.jsonl", [codex_meta(cwd), codex_call()])
        report = json.loads(self.count("--json").stdout)
        self.assertEqual(report["counts"]["alpha"]["codex"], {"uses": 1, "maintenance": 1})

    def test_missing_or_unusable_cwd_counts_as_uses(self):
        for index, cwd in enumerate((None, "", "relative/path", [], "invalid\x00cwd")):
            meta = codex_meta(self.repository)
            meta["payload"]["cwd"] = cwd
            self.jsonl(self.codex_home / "sessions" / f"session-{index}.jsonl", [
                meta, codex_meta(self.repository), codex_call(),
            ])
            event = claude_call()
            event["cwd"] = cwd
            self.jsonl(self.claude_projects / "project" / f"session-{index}.jsonl", [event])
        report = json.loads(self.count("--json").stdout)
        for host in ("codex", "claude-code"):
            self.assertEqual(report["counts"]["alpha"][host], {"uses": 5, "maintenance": 0})

    def test_method_describes_host_count_units_and_limits(self):
        method = json.loads(self.count("--json").stdout)["method"]
        self.assertEqual(set(method), {"codex", "claude-code"})
        self.assertIn("session", method["codex"]["count"])
        self.assertIn("reads, writes or searches", method["codex"]["count"])
        self.assertIn("/<name>/SKILL.md", method["codex"]["count"])
        self.assertIn("relative SKILL.md read", " ".join(method["codex"]["limits"]))
        self.assertIn("first session_meta payload.cwd", method["codex"]["maintenance"])
        self.assertIn("Skill tool call", method["claude-code"]["count"])
        self.assertIn("event's own cwd", method["claude-code"]["maintenance"])
        for host in method.values():
            self.assertIn("Missing or unusable cwd", " ".join(host["limits"]))
            self.assertIn("common Git directory", host["maintenance"])
            self.assertIn("main checkout", host["maintenance"])
            self.assertIn("Deleted worktrees outside the main checkout count as uses", " ".join(host["limits"]))

    def test_markdown_shows_uses_and_maintenance_for_both_hosts(self):
        self.jsonl(self.codex_home / "sessions" / "session.jsonl", [
            codex_meta(self.repository), codex_call(),
        ])
        self.jsonl(self.claude_projects / "project" / "session.jsonl", [
            claude_call(cwd=self.root / "outside"),
        ])
        text = self.count().stdout
        self.assertIn("| Skill | Codex uses | Codex maintenance | Claude Code uses | Claude Code maintenance |", text)
        self.assertIn("| alpha | 0 | 1 | 1 | 0 |", text)
        self.assertIn("codex: 0 uses; 1 maintenance; 1 files read", text)
        self.assertIn("claude-code: 1 uses; 0 maintenance; 1 files read", text)

    def test_invalid_window_is_rejected(self):
        for until in ("invalid", "2026-09-01", "2026-10-01"):
            with self.subTest(until=until):
                self.run_helper("usage_counts.py", "--skills-root", self.skills, "--since", "2026-10-01",
                                "--until", until, expected=1)


if __name__ == "__main__":
    unittest.main()
