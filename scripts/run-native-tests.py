#!/usr/bin/env python3
"""Focused local tests or a comparable one/two-device required-suite benchmark."""
import argparse
import json
from pathlib import Path
import shlex
import subprocess
import sys
import time
import uuid

import native_tests


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cache", type=Path, default=Path("/private/tmp/sidequest-debug-cache"))
    parser.add_argument("--unit", action="store_true")
    parser.add_argument("--ui", action="append", default=[], help="UI class or class/method; repeatable")
    parser.add_argument("--required", action="store_true")
    parser.add_argument("--extended", action="store_true")
    parser.add_argument("--benchmark", action="store_true", help="Same required inventory, warm build boundary, one then two devices")
    args = parser.parse_args()
    root = Path.cwd().resolve()
    args.output.mkdir(parents=True, exist_ok=False)
    def runner(directory):
        def run(label, command):
            log = directory / f"{label}.log"
            print(f"{label}: {shlex.join(command)}", flush=True)
            start = time.monotonic()
            with log.open("w") as output:
                result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT)
            with (directory / "commands.jsonl").open("a") as output:
                output.write(json.dumps({"label": label, "command": command, "exit": result.returncode,
                                         "seconds": time.monotonic()-start, "log": str(log)})+"\n")
            if result.returncode:
                raise RuntimeError(f"{label} failed ({result.returncode}): {log}")
            return log.read_text(errors="replace")
        return run
    run = runner(args.output)
    xcode = run("xcode", ["xcodebuild", "-version"])
    sdk = run("sdk", ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-build-version"])
    sdk += run("sdk-path", ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"])
    sdk += run("developer-path", ["xcode-select", "-p"])
    runtime = run("runtime", ["xcrun", "simctl", "list", "runtimes", "--json"])
    selected = native_tests.selection(root, changed=[], extended=args.extended) if args.required or args.benchmark or args.extended else []
    if args.unit: selected.append("SidequestTests")
    selected += [f"SidequestUITests/{case}" for case in args.ui]
    if not selected:
        raise RuntimeError("Choose --unit, --ui, --required, --extended, or --benchmark.")
    selected = sorted(set(selected))
    gate = "focused"
    if args.extended:
        gate = "extended_ui"
    elif args.required or args.benchmark:
        gate = native_tests.inventory(root)["active_gate"]
    with native_tests.owned_execution(), native_tests.devices(run, "Sidequest 90 " + uuid.uuid4().hex[:8], 2 if args.benchmark else 1) as destinations:
        # Compile once to warm the same canonical cache before timing either policy.
        if args.benchmark:
            boundary, key = native_tests.cache_identity(root, xcode, sdk, runtime)
            with native_tests.owned_cache(args.cache, boundary, key) as derived:
                run("warm-build", native_tests.command(derived, destinations[0])+["build-for-testing"])
        for workers in ([1, 2] if args.benchmark else [1]):
            directory = args.output / f"workers-{workers}"
            directory.mkdir()
            measured = time.monotonic()
            worker_run = runner(directory)
            record, _ = native_tests.execute(root, directory, args.cache, destinations[:workers], selected,
                                             worker_run, xcode, sdk, runtime, gate=gate)
            if args.benchmark:
                # Measure the ordinary verification pipeline, not just XCTest wall time.
                for script in ("check-documentation.py", "test-documentation.py", "test-ci.py",
                               "test-release.py", "test-native-tests.py", "test-verification-provenance.py",
                               "test-git-hooks.py", "test-agent-preflight.py", "test-review-gate.py"):
                    worker_run(script.removesuffix(".py"), ["python3", f"scripts/{script}"])
                worker_run("format", ["xcrun", "swift-format", "lint", "--strict", "--recursive",
                                      "--configuration", ".swift-format", "Sidequest", "SidequestTests", "SidequestUITests"])
                worker_run("whitespace", ["git", "diff", "--check", "HEAD"])
                worker_run("source-discovery", ["python3", "scripts/verify-source-discovery.py",
                                               "--destination", destinations[0]])
                release = native_tests.command(directory / "ReleaseDerivedData", destinations[0])
                release[release.index("Debug")] = "Release"
                worker_run("release-build", release + ["ARCHS=arm64", "build"])
                record["ordinary_verification_seconds"] = time.monotonic() - measured
                record["comparison_boundary"] = "Same source/inventory; warm Debug products and booted owned devices; unique cold Release/discovery output. Device creation/toolchain inspection excluded and recorded separately."
                (directory / "native-tests.json").write_text(json.dumps(record, indent=2)+"\n")
            if not args.required and not args.extended and not args.benchmark:
                record["mode"] = "focused"
                (directory / "native-tests.json").write_text(json.dumps(record, indent=2)+"\n")
            print(json.dumps({key: record[key] for key in ("mode", "workers", "build_seconds", "test_seconds", "ordinary_verification_seconds") if key in record} | {"passed_cases": len(record["inventory"]), "record": str(directory / "native-tests.json")}), flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
