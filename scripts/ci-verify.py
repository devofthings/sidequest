#!/usr/bin/env python3
"""Run unsigned, deterministic Sidequest checks; retain diagnostics on this Mac."""

import json
import os
from pathlib import Path
import shlex
import signal
import subprocess
import threading
import sys
import time

import native_tests


class VerificationCanceled(BaseException):
    """Cancellation must unwind worker/device contexts without becoming success."""

    def __init__(self, signum):
        self.signum = signum
        super().__init__(f"Verification canceled by signal {signum}.")


class OwnedCommands:
    """Terminate only command groups created by this verification invocation."""

    def __init__(self, grace_seconds=3):
        self.grace_seconds = grace_seconds
        self.active = {}
        self.lock = threading.RLock()
        self.canceled = None
        self.previous = {}
        self.spawning = False
        self.tearing_down = False

    def __enter__(self):
        for signum in (signal.SIGINT, signal.SIGTERM):
            self.previous[signum] = signal.signal(signum, self.cancel)
        return self

    def __exit__(self, kind, value, traceback):
        self.tearing_down = True
        try:
            self.drain()
        finally:
            for signum, handler in self.previous.items():
                signal.signal(signum, handler)
        if self.canceled is not None and kind is None:
            raise VerificationCanceled(self.canceled)

    @staticmethod
    def group_is_inert(identifier):
        # macOS can report EPERM for groups containing only adopted zombies.
        # They cannot execute; never hide a permission failure for a live member.
        result = subprocess.run(["ps", "-axo", "pgid=,stat="], capture_output=True,
                                text=True, check=True)
        states = [fields[1] for line in result.stdout.splitlines()
                  if len(fields := line.split()) == 2 and fields[0] == str(identifier)]
        return not states or all(state.startswith("Z") for state in states)

    @classmethod
    def send(cls, process, signum):
        try:
            os.killpg(process.pid, signum)
        except ProcessLookupError:
            pass
        except PermissionError:
            if not cls.group_is_inert(process.pid):
                raise

    def drain(self, reap=True):
        with self.lock:
            processes = list(self.active.values())
            for process in processes:
                self.send(process, signal.SIGTERM)
            # Do not call Popen.wait inside a signal handler: the interrupted
            # main-thread wait may already own subprocess's non-reentrant lock.
            if processes:
                time.sleep(self.grace_seconds)
            for process in processes:
                self.send(process, signal.SIGKILL)
            if reap:
                for process in processes:
                    process.wait()
                self.active.clear()

    def cancel(self, signum, frame):
        if self.canceled is not None:
            return  # Repeated runner signals must not interrupt owned cleanup.
        self.canceled = signum
        # A main-thread signal during Popen must let registration finish before
        # raising. Unlike masking, this does not pass blocked signals to children.
        if self.spawning or self.tearing_down:
            return
        self.drain(reap=False)
        raise VerificationCanceled(signum)

    def run(self, command, output, cleanup=False):
        with self.lock:
            if self.canceled is not None and not cleanup:
                raise VerificationCanceled(self.canceled)
            self.spawning = True
            try:
                process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT,
                                           start_new_session=True)
                self.active[process.pid] = process
            finally:
                self.spawning = False
            if self.canceled is not None and not cleanup:
                self.drain()
                raise VerificationCanceled(self.canceled)
        try:
            status = process.wait()
            if self.canceled is not None and not cleanup:
                raise VerificationCanceled(self.canceled)
            return subprocess.CompletedProcess(command, status)
        finally:
            # The interrupted wait has unwound before this reap; workers also
            # finish their owned child before executor/device contexts exit.
            process.wait()
            with self.lock:
                # A command can exit while an owned descendant remains. Retain
                # its group until those descendants are stopped, even on success.
                try:
                    os.killpg(process.pid, 0)
                except ProcessLookupError:
                    pass
                except PermissionError:
                    if not self.group_is_inert(process.pid):
                        raise
                else:
                    self.send(process, signal.SIGTERM)
                    time.sleep(self.grace_seconds)
                    self.send(process, signal.SIGKILL)
                self.active.pop(process.pid, None)


def inherited_tests(root, expected, diagnostics_root):
    from verification_provenance import resolve_inherited_tests
    return resolve_inherited_tests(root, expected, diagnostics_root, diagnostic=lambda reason: print(
        f"::notice::Main test inheritance unavailable: {reason} Running the complete active gate.", flush=True))


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


def verify_clean_checkout(root, expected, run, phase):
    head = run(f"{phase}-head", ["git", "-C", str(root), "rev-parse", "HEAD"]).strip()
    if head != expected:
        raise RuntimeError("Checkout changed from the reviewed commit during verification.")
    status = run(f"{phase}-checkout", ["git", "-C", str(root), "status", "--porcelain=v1",
                                      "-z", "--untracked-files=all"])
    if status:
        raise RuntimeError("Verification requires a clean tracked and untracked checkout.")


def changed_paths(expected, base, event, run):
    revisions = [f"origin/{base}...{expected}"] if event == "pull_request" else [f"{expected}^", expected]
    # Report both owners of a rename, preserving paths with spaces or newlines.
    output = run("changed-paths", ["git", "diff", "--no-renames", "--name-only", "-z", *revisions])
    return [path for path in output.split("\0") if path]


def main():
    commands = OwnedCommands()
    try:
        with commands:
            verify(commands)
    finally:
        # This outer boundary also runs when cancellation interrupts command
        # diagnostics, summary output, or the signal-handler context teardown.
        if commands.canceled is not None and hasattr(commands, "diagnostics"):
            (commands.diagnostics / "verification.json").unlink(missing_ok=True)
            (commands.diagnostics / "cancellation.json").write_text(json.dumps({
                "signal": commands.canceled, "commit": commands.expected,
                "cleanup_completed": not commands.active,
            }, indent=2) + "\n")


def verify(commands):
    root = Path.cwd()
    expected = os.environ["SIDEQUEST_EXPECTED_HEAD"]
    base = os.environ["SIDEQUEST_BASE_REF"]
    run_id = os.environ["GITHUB_RUN_ID"]
    attempt = os.environ["GITHUB_RUN_ATTEMPT"]
    diagnostics = Path(os.environ["RUNNER_TEMP"]).parent / "sidequest-diagnostics" / f"{run_id}-{attempt}"
    diagnostics.mkdir(parents=True, exist_ok=False)
    commands.diagnostics = diagnostics
    commands.expected = expected
    summary = []
    timings = []

    def run(label, command):
        log = diagnostics / f"{label}.log"
        print(f"::group::{label}", flush=True)
        print(shlex.join(command), flush=True)
        started = time.monotonic()
        result = None
        try:
            with log.open("w") as output:
                cleanup = (label.startswith(("shutdown-", "delete-")) and
                           command[:3] in (["xcrun", "simctl", "shutdown"], ["xcrun", "simctl", "delete"]))
                result = commands.run(command, output, cleanup=cleanup)
        finally:
            timings.append({"label": label, "command": command,
                            "exit": result.returncode if result else None,
                            "canceled": commands.canceled is not None,
                            "seconds": time.monotonic() - started, "log": str(log)})
        lines = log.read_text(errors="replace").splitlines()
        print("\n".join(lines[-80:]), flush=True)
        print("::endgroup::", flush=True)
        summary.append(f"- {label}: {'PASS' if result.returncode == 0 else 'FAIL'} (exit {result.returncode}, {time.monotonic() - started:.3f} seconds)")
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
        changed = changed_paths(expected, base, event, run)
        selected = native_tests.selection(root, changed if event == "pull_request" else None)
        cache_root = diagnostics.parent.parent / "sidequest-debug-cache"
        # The approved pre-design smoke inventory uses one owned simulator.
        policy = native_tests.inventory(root)
        workers = policy.get("workers", 1)
        if workers not in (1, 2):
            raise RuntimeError("Unsupported native worker policy.")
        verify_clean_checkout(root, expected, run, "native-source")
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
                                                run, xcode, sdk, runtimes, gate=policy["active_gate"])
                if event != "pull_request":
                    # Also prove the freshly compiled fallback main can install and launch.
                    boundary, key = native_tests.cache_identity(root, xcode, sdk, runtimes)
                    with native_tests.owned_cache(cache_root, boundary, key) as derived:
                        smoke(destination, derived / "Build/Products/Debug-iphonesimulator/Sidequest.app", run)
            run("source-discovery", ["python3", "scripts/verify-source-discovery.py", "--destination", destination])
            release = native_tests.command(diagnostics / "DerivedData", destination)
            release[release.index("Debug")] = "Release"
            run("release-build", release + ["ARCHS=arm64", "build"])
        verify_clean_checkout(root, expected, run, "manifest-source")
        summary.append(f"- tests: {tests['mode']}; gate {tests['gate']}; {len(tests.get('inventory', []))} verified cases")
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
        if commands.canceled is not None:
            summary.append(f"- CANCELED by signal {commands.canceled}; no successful verification manifest.")
        (diagnostics / "commands.json").write_text(json.dumps(timings, indent=2) + "\n")
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as output:
            output.write(f"### Sidequest verification\n\nCommit: `{expected}`\n\n")
            output.write("\n".join(summary) + "\n\n")
            output.write(f"Diagnostics and XCTest results remain on the runner at `{diagnostics}`. No artifact/cache upload.\n")


if __name__ == "__main__":
    try:
        main()
    except VerificationCanceled as error:
        print(str(error), file=sys.stderr)
        sys.exit(128 + error.signum)
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"Verification failed: {error}", file=sys.stderr)
        sys.exit(1)
