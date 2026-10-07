"""Scripted stdio peer used only by isolated adapter tests."""

import json
from pathlib import Path
import sys
import time


scenario = json.loads(Path(sys.argv[1]).read_text())
log = Path(sys.argv[2])

for line in sys.stdin:
    message = json.loads(line)
    with log.open("a") as file:
        file.write(json.dumps(message) + "\n")
    if "id" not in message:
        continue
    step = scenario.pop(0)
    if message.get("method") != step["method"]:
        raise SystemExit(f"Unexpected method: {message.get('method')}")
    if "params" in step and message.get("params") != step["params"]:
        raise SystemExit("Unexpected parameters")
    if step.get("disconnect"):
        raise SystemExit(0)
    if step.get("delay"):
        time.sleep(step["delay"])
    if step.get("serverRequest"):
        print(json.dumps({"id": "server-request", "method": "item/commandExecution/requestApproval", "params": {}}), flush=True)
        # Record the client's explicit unsupported response before exiting.
        response = sys.stdin.readline()
        with log.open("a") as file:
            file.write(response)
        raise SystemExit(0)
    print(json.dumps({"method": "fixture/notification", "params": {}}), flush=True)
    response = {"id": message["id"]}
    if "error" in step:
        response["error"] = step["error"]
    else:
        response["result"] = step.get("result", {})
    print(json.dumps(response), flush=True)
