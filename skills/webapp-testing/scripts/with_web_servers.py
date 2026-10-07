#!/usr/bin/env python3
"""Run a command after starting one or more local web servers."""

from __future__ import annotations

import argparse
import os
import signal
import socket
import subprocess
import sys
import time


def port_ready(host: str, port: int, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, port), timeout=1):
                return True
        except OSError:
            time.sleep(0.25)
    return False


def terminate(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return

    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
    except Exception:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except Exception:
            process.kill()
        process.wait()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Start local web servers, wait for ports, run a QA command, then stop owned servers."
    )
    parser.add_argument(
        "--server",
        action="append",
        required=True,
        help="Server command to start. Repeat once per server.",
    )
    parser.add_argument(
        "--port",
        action="append",
        type=int,
        required=True,
        help="Port that must become reachable. Repeat once per server.",
    )
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Host used for port readiness checks. Default: 127.0.0.1.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30,
        help="Seconds to wait for each server port. Default: 30.",
    )
    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="Command to run after '--' once all servers are ready.",
    )

    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("missing command to run after servers are ready")

    if len(args.server) != len(args.port):
        parser.error("--server and --port counts must match")

    processes: list[subprocess.Popen[str]] = []
    try:
        for index, (server_cmd, port) in enumerate(zip(args.server, args.port), start=1):
            print(f"starting server {index}/{len(args.server)} on port {port}: {server_cmd}", flush=True)
            process = subprocess.Popen(
                server_cmd,
                shell=True,
                start_new_session=True,
                text=True,
            )
            processes.append(process)

            if not port_ready(args.host, port, args.timeout):
                raise RuntimeError(
                    f"server {index} did not become ready at {args.host}:{port} within {args.timeout:g}s"
                )
            print(f"server {index} ready at {args.host}:{port}", flush=True)

        print(f"running QA command: {' '.join(command)}", flush=True)
        return subprocess.run(command).returncode
    finally:
        for process in reversed(processes):
            terminate(process)


if __name__ == "__main__":
    sys.exit(main())
