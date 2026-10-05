"""Durable, run-specific simulator ownership for CI cancellation recovery."""

import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import uuid

import native_tests


def identity(environment):
    run = environment["GITHUB_RUN_ID"]
    attempt = environment["GITHUB_RUN_ATTEMPT"]
    commit = environment["SIDEQUEST_EXPECTED_HEAD"]
    if not re.fullmatch(r"[1-9][0-9]*", run) or not re.fullmatch(r"[1-9][0-9]*", attempt):
        raise ValueError("Invalid CI run identity.")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Invalid CI source identity.")
    return {"run_id": run, "attempt": attempt, "commit": commit}


def directory(environment):
    owner = identity(environment)
    return Path(environment["RUNNER_TEMP"]).parent / "sidequest-diagnostics" / f"{owner['run_id']}-{owner['attempt']}"


def write_atomic(path, value):
    temporary = path.with_suffix(".tmp")
    with temporary.open("w") as output:
        json.dump(value, output, indent=2)
        output.write("\n")
        output.flush()
        os.fsync(output.fileno())
    os.replace(temporary, path)


class Registry:
    """Record returned UUIDs before boot; never infer ownership from a name scan."""

    def __init__(self, diagnostics, environment):
        self.path = diagnostics / "owned-devices.json"
        self.record = {"schema": 1, **identity(environment), "devices": []}
        write_atomic(self.path, self.record)

    def created(self, identifier, name):
        if str(uuid.UUID(identifier)).upper() != identifier.upper():
            raise ValueError("Simulator creation returned an invalid UUID.")
        self.record["devices"].append({
            "udid": identifier, "name": name, "runtime": native_tests.RUNTIME,
            "device_type": native_tests.DEVICE_TYPE,
        })
        write_atomic(self.path, self.record)


def owned_inventory(diagnostics, expected):
    """Validate ownership before changing devices or an existing success manifest."""
    path = diagnostics / "owned-devices.json"
    if not path.exists():
        return []  # Verification may have failed before establishing ownership.
    record = json.loads(path.read_text())
    if record.get("schema") != 1 or any(record.get(key) != value for key, value in expected.items()):
        raise ValueError("Simulator ownership belongs to a different run/source.")
    devices = record["devices"]
    if not isinstance(devices, list) or len(devices) > 2:
        raise ValueError("Invalid owned simulator inventory.")
    seen = set()
    for item in devices:
        identifier = str(uuid.UUID(item["udid"])).upper()
        if identifier in seen or item["runtime"] != native_tests.RUNTIME or item["device_type"] != native_tests.DEVICE_TYPE:
            raise ValueError("Invalid owned simulator identity.")
        if item["name"] != f"Sidequest CI {expected['run_id']}-{expected['attempt']} {len(seen) + 1}":
            raise ValueError("Invalid owned simulator name.")
        seen.add(identifier)
    return devices


def recover(diagnostics, expected, run):
    """Delete only recorded UUIDs with matching live identity; retain every diagnostic."""
    devices = owned_inventory(diagnostics, expected)
    if not devices:
        return []
    seen = {item["udid"].upper() for item in devices}
    live = json.loads(run("devices", ["xcrun", "simctl", "list", "devices", "--json"]))
    found = {}
    for runtime, entries in live["devices"].items():
        for item in entries:
            if item["udid"].upper() in seen:
                identifier = item["udid"].upper()
                if identifier in found:
                    raise ValueError("Duplicate live simulator identity.")
                found[identifier] = (runtime, item)
    # Validate the entire inventory before any destructive operation.
    for item in devices:
        current = found.get(item["udid"].upper())
        if current and (current[0] != item["runtime"] or current[1]["name"] != item["name"] or
                        current[1].get("deviceTypeIdentifier") != item["device_type"]):
            raise ValueError("Live simulator differs from its ownership record.")
    failures = []
    for index, item in enumerate(devices, 1):
        current = found.get(item["udid"].upper())
        if current is None:
            continue  # Already deleted by normal cleanup or a prior recovery.
        for operation in ("shutdown", "delete"):
            if operation == "shutdown" and current[1]["state"] == "Shutdown":
                continue
            try:
                run(f"{operation}-{index}", ["xcrun", "simctl", operation, item["udid"]])
            except (RuntimeError, OSError, subprocess.SubprocessError):
                failures.append(f"{operation}-{index}")
    if failures:
        raise RuntimeError("Owned simulator recovery failed: " + ", ".join(failures))
    return [item["udid"] for item in devices]


def main():
    expected = identity(os.environ)
    diagnostics = directory(os.environ)
    if not diagnostics.is_dir():
        return  # Checkout/verification may not have started.
    owned_inventory(diagnostics, expected)
    # Recovery is a bounded finalizer after the verification process has exited.
    # Repeated cancellation signals must not interrupt its owned cleanup.
    previous = {signum: signal.signal(signum, signal.SIG_IGN)
                for signum in (signal.SIGINT, signal.SIGTERM)}
    outcome = os.environ["SIDEQUEST_VERIFICATION_OUTCOME"]
    succeeded = False
    try:
        if outcome != "success":
            (diagnostics / "verification.json").unlink(missing_ok=True)

        def run(label, command):
            with (diagnostics / f"recovery-{label}.log").open("a+") as output:
                start = output.tell()
                subprocess.run(command, stdout=output, stderr=subprocess.STDOUT,
                               timeout=30, check=True)
                # Retain earlier diagnostics without decoding them as this result.
                output.seek(start)
                return output.read()

        with native_tests.owned_execution():
            recover(diagnostics, expected, run)
        succeeded = True
    finally:
        if not succeeded:
            (diagnostics / "verification.json").unlink(missing_ok=True)
        write_atomic(diagnostics / "device-recovery.json", {
            **expected, "verification_outcome": outcome, "cleanup_completed": succeeded,
        })
        for signum, handler in previous.items():
            signal.signal(signum, handler)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"Owned simulator recovery failed: {error}", file=sys.stderr)
        sys.exit(1)
