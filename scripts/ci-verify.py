#!/usr/bin/env python3
"""Run unsigned, deterministic Sidequest checks; retain diagnostics on this Mac."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time

import native_tests


def inherited_tests(root, expected, diagnostics_root):
    from verification_provenance import resolve_inherited_tests
    return resolve_inherited_tests(root, expected, diagnostics_root)


def smoke(destination, app, run):
    identifier = destination.split("id=", 1)[1]
    run("smoke-install", ["xcrun", "simctl", "install", identifier, str(app)])
    launch = run("smoke-launch", ["xcrun", "simctl", "launch", "--terminate-running-process",
                                  identifier, "dev.devofthings.sidequest"])
    pid = launch.strip().rsplit(":", 1)[-1].strip()
    if not pid.isdecimal() or int(pid) <= 0:
        raise RuntimeError("Main smoke launch did not return a process identity.")
    processes = run("smoke-process", ["xcrun", "simctl", "spawn", identifier, "launchctl", "list"])
    if not any(line.split()[0] == pid and "dev.devofthings.sidequest" in line
               for line in processes.splitlines() if line.split()):
        raise RuntimeError("Main smoke app process did not remain running.")
    run("smoke-terminate", ["xcrun", "simctl", "terminate", identifier, "dev.devofthings.sidequest"])


def verify_revision(expected, base, event, ref, run):
    head = run("head", ["git", "rev-parse", "HEAD"]).strip()
    if head != expected:
        raise RuntimeError("Checkout does not match the reviewed commit.")
    if event == "pull_request":
        run("base-ancestry", ["git", "merge-base", "--is-ancestor", f"origin/{base}", head])
        run("whitespace", ["git", "diff", "--check", f"origin/{base}...{head}"])
    elif event in ("push", "workflow_dispatch") and ref == "refs/heads/main":
        # A newer main may exist by the time this queued event gets the runner.
        # Verify this event's own change; PR review already validated its ancestry.
        run("whitespace", ["git", "diff", "--check", f"{head}^", head])
    else:
        raise RuntimeError("Only same-repository PR or main push/manual verification is supported.")


def main():
    root = Path.cwd()
    expected = os.environ["SIDEQUEST_EXPECTED_HEAD"]
    base = os.environ["SIDEQUEST_BASE_REF"]
    run_id = os.environ["GITHUB_RUN_ID"]
    attempt = os.environ["GITHUB_RUN_ATTEMPT"]
    diagnostics = Path(os.environ["RUNNER_TEMP"]).parent / "sidequest-diagnostics" / f"{run_id}-{attempt}"
    diagnostics.mkdir(parents=True, exist_ok=False)
    summary = []
    timings = []

    def run(label, command):
        log = diagnostics / f"{label}.log"
        print(f"::group::{label}", flush=True)
        print(shlex.join(command), flush=True)
        started = time.monotonic()
        with log.open("w") as output:
            result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT)
        timings.append({"label": label, "command": command, "exit": result.returncode,
                        "seconds": time.monotonic() - started, "log": str(log)})
        lines = log.read_text(errors="replace").splitlines()
        print("\n".join(lines[-80:]), flush=True)
        print("::endgroup::", flush=True)
        summary.append(f"- {label}: {'PASS' if result.returncode == 0 else 'FAIL'} (exit {result.returncode})")
        if result.returncode:
            raise RuntimeError(f"{label} failed; local diagnostics: {log}")
        return log.read_text(errors="replace")

    try:
        verify_revision(expected, base, os.environ["GITHUB_EVENT_NAME"],
                        os.environ["GITHUB_REF"], run)
        if (root / "Sidequest.xcodeproj/LocalSigning.xcconfig").exists() or (root / ".local-news").exists():
            raise RuntimeError("CI checkout contains local signing or personal news inputs.")
        xcode = run("xcode", ["xcodebuild", "-version"])
        if xcode.strip() != "Xcode 27.0\nBuild version 27A266a":
            raise RuntimeError("CI requires the verified Xcode 27.0 (27A266a) toolchain.")
        run("swift", ["xcrun", "swift", "-version"])
        run("documentation", ["python3", "scripts/check-documentation.py"])
        run("documentation-tests", ["python3", "scripts/test-documentation.py"])
        run("ci-tests", ["python3", "scripts/test-ci.py"])
        if Path("scripts/test-release.py").is_file():
            run("release-tests", ["python3", "scripts/test-release.py"])
        run("format", ["xcrun", "swift-format", "lint", "--strict", "--recursive",
                       "--configuration", ".swift-format", "Sidequest", "SidequestTests", "SidequestUITests"])
        for script in ("test-native-tests.py", "test-verification-provenance.py", "test-git-hooks.py", "test-agent-preflight.py", "test-review-gate.py"):
            run(script.removesuffix(".py"), ["python3", f"scripts/{script}"])
        sdk = run("sdk", ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-build-version"])
        sdk += run("sdk-path", ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"])
        sdk += run("developer-path", ["xcode-select", "-p"])
        runtime = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"
        runtimes = json.loads(run("runtimes", ["xcrun", "simctl", "list", "runtimes", "--json"]))
        installed = [item for item in runtimes["runtimes"] if item["identifier"] == runtime]
        if len(installed) != 1 or not installed[0]["isAvailable"] or installed[0]["buildversion"] != "24A434":
            raise RuntimeError("CI requires the verified iOS 27.0 (24A434) simulator runtime.")
        event = os.environ["GITHUB_EVENT_NAME"]
        evidence = inherited_tests(root, expected, diagnostics.parent) if event != "pull_request" else None
        changed = run("changed-paths", ["git", "diff", "--name-only", "-z",
                      f"origin/{base}...{expected}" if event == "pull_request" else f"{expected}^", expected]).split("\0")
        selected = native_tests.selection(root, changed if event == "pull_request" else None)
        cache_root = diagnostics.parent.parent / "sidequest-debug-cache"
        # Selected only from the recorded comparable benchmark; serial is the safe default.
        workers = json.loads((root / "scripts/native-test-inventory.json").read_text()).get("workers", 1)
        if workers not in (1, 2):
            raise RuntimeError("Unsupported native worker policy.")
        with native_tests.owned_execution(), native_tests.devices(run, f"Sidequest CI {run_id}-{attempt}", 1 if evidence else workers) as destinations:
            destination = destinations[0]
            if evidence:
                boundary, key = native_tests.cache_identity(root, xcode, sdk, runtimes)
                with native_tests.owned_cache(cache_root, boundary, key) as derived:
                    run("build-for-testing", native_tests.command(derived, destination) + ["build-for-testing"])
                    smoke(destination, derived / "Build/Products/Debug-iphonesimulator/Sidequest.app", run)
                tests = evidence
            else:
                tests, _ = native_tests.execute(root, diagnostics, cache_root, destinations, selected,
                                                run, xcode, sdk, runtimes)
                if event != "pull_request":
                    # Also prove the freshly compiled fallback main can install and launch.
                    boundary, key = native_tests.cache_identity(root, xcode, sdk, runtimes)
                    with native_tests.owned_cache(cache_root, boundary, key) as derived:
                        smoke(destination, derived / "Build/Products/Debug-iphonesimulator/Sidequest.app", run)
            run("source-discovery", ["python3", "scripts/verify-source-discovery.py", "--destination", destination])
            release = native_tests.command(diagnostics / "DerivedData", destination)
            release[release.index("Debug")] = "Release"
            run("release-build", release + ["ARCHS=arm64", "build"])
        manifest = {
            "schema": 2, "commit": expected, "run_id": run_id, "attempt": attempt,
            "run_number": os.environ["GITHUB_RUN_NUMBER"],
            "event": os.environ["GITHUB_EVENT_NAME"], "ref": os.environ["GITHUB_REF"],
            "runner_name": os.environ["RUNNER_NAME"], "xcode": xcode.strip(),
            "runtime": f"iOS {installed[0]['version']} ({installed[0]['buildversion']})",
            "all_checks_passed": True, "tests": tests,
            "main_smoke_passed": event != "pull_request",
            "release_app": str(diagnostics / "DerivedData/Build/Products/Release-iphonesimulator/Sidequest.app"),
        }
        (diagnostics / "verification.json").write_text(json.dumps(manifest, indent=2) + "\n")
        with Path(os.environ["GITHUB_OUTPUT"]).open("a") as output:
            output.write(f"verification_directory={diagnostics}\n")
    finally:
        (diagnostics / "commands.json").write_text(json.dumps(timings, indent=2) + "\n")
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
