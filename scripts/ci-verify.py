#!/usr/bin/env python3
"""Run unsigned, deterministic Sidequest checks; retain diagnostics on this Mac."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


def main():
    root = Path.cwd()
    expected = os.environ["SIDEQUEST_EXPECTED_HEAD"]
    base = os.environ["SIDEQUEST_BASE_REF"]
    run_id = os.environ["GITHUB_RUN_ID"]
    attempt = os.environ["GITHUB_RUN_ATTEMPT"]
    diagnostics = Path(os.environ["RUNNER_TEMP"]).parent / "sidequest-diagnostics" / f"{run_id}-{attempt}"
    diagnostics.mkdir(parents=True, exist_ok=False)
    summary = []

    def run(label, command):
        log = diagnostics / f"{label}.log"
        print(f"::group::{label}", flush=True)
        print(shlex.join(command), flush=True)
        with log.open("w") as output:
            result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT)
        lines = log.read_text(errors="replace").splitlines()
        print("\n".join(lines[-80:]), flush=True)
        print("::endgroup::", flush=True)
        summary.append(f"- {label}: {'PASS' if result.returncode == 0 else 'FAIL'} (exit {result.returncode})")
        if result.returncode:
            raise RuntimeError(f"{label} failed; local diagnostics: {log}")
        return log.read_text(errors="replace")

    try:
        head = run("head", ["git", "rev-parse", "HEAD"]).strip()
        if head != expected:
            raise RuntimeError("Checkout does not match the reviewed commit.")
        run("base-ancestry", ["git", "merge-base", "--is-ancestor", f"origin/{base}", head])
        run("whitespace", ["git", "diff", "--check", f"origin/{base}...{head}"])
        if (root / "Sidequest.xcodeproj/LocalSigning.xcconfig").exists() or (root / ".local-news").exists():
            raise RuntimeError("CI checkout contains local signing or personal news inputs.")
        xcode = run("xcode", ["xcodebuild", "-version"])
        if xcode.strip() != "Xcode 27.0\nBuild version 27A266a":
            raise RuntimeError("CI requires the verified Xcode 27.0 (27A266a) toolchain.")
        run("swift", ["xcrun", "swift", "-version"])
        run("documentation", ["python3", "scripts/check-documentation.py"])
        run("documentation-tests", ["python3", "scripts/test-documentation.py"])
        run("format", ["xcrun", "swift-format", "lint", "--strict", "--recursive",
                       "--configuration", ".swift-format", "Sidequest", "SidequestTests", "SidequestUITests"])
        for script in ("test-git-hooks.py", "test-agent-preflight.py", "test-review-gate.py"):
            run(script.removesuffix(".py"), ["python3", f"scripts/{script}"])
        devices = json.loads(run("devices", ["xcrun", "simctl", "list", "devices", "available", "--json"]))
        runtime = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"
        matching = [device for device in devices["devices"].get(runtime, [])
                    if device["name"] == "Sidequest CI iPhone"]
        if len(matching) > 1:
            raise RuntimeError("More than one CI simulator exists; reconcile without deleting user devices.")
        if not matching:
            run("create-device", ["xcrun", "simctl", "create", "Sidequest CI iPhone",
                                  "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro", runtime])
        destination = "platform=iOS Simulator,name=Sidequest CI iPhone,OS=27.0"
        command = ["xcodebuild", "-project", "Sidequest.xcodeproj", "-scheme", "Sidequest",
                   "-configuration", "Debug", "-destination", destination,
                   "-derivedDataPath", str(diagnostics / "DerivedData"), "CODE_SIGNING_ALLOWED=NO"]
        run("build", command + ["build"])
        run("tests", command + ["-parallel-testing-enabled", "NO", "-resultBundlePath",
                                str(diagnostics / "Tests.xcresult"), "test"])
        run("source-discovery", ["python3", "scripts/verify-source-discovery.py", "--destination", destination])
        release = command.copy()
        release[release.index("Debug")] = "Release"
        run("release-build", release + ["build"])
    finally:
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as output:
            output.write(f"### Sidequest verification\n\nCommit: `{expected}`\n\n")
            output.write("\n".join(summary) + "\n\n")
            output.write(f"Diagnostics and XCTest results remain on the runner at `{diagnostics}`. No artifact/cache upload.\n")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        sys.exit(1)
