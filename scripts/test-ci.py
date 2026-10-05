#!/usr/bin/env python3
"""Exercise queued-main/PR verification and private runner storage without networking."""

from contextlib import nullcontext
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import signal
import time
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ci = load("ci-verify")
installer = load("configure-ci-runner")


class CIBoundaryTests(unittest.TestCase):
    def test_owned_command_status_and_logs_are_preserved(self):
        with tempfile.TemporaryDirectory() as directory, ci.OwnedCommands() as commands:
            log = Path(directory) / "command.log"
            for status in (0, 7):
                with log.open("w") as output:
                    result = commands.run([sys.executable, "-c",
                                           f"print('diagnostic'); raise SystemExit({status})"], output)
                self.assertEqual(result.returncode, status)
                self.assertEqual(log.read_text(), "diagnostic\n")
                self.assertEqual(commands.active, {})

    def test_successful_leader_cannot_leave_owned_descendant(self):
        with tempfile.TemporaryDirectory() as directory, ci.OwnedCommands(grace_seconds=0.1) as commands:
            pid_file = Path(directory) / "child.pid"
            child = ("import os, pathlib, signal, time; "
                     "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                     f"pathlib.Path({str(pid_file)!r}).write_text(str(os.getpid())); time.sleep(60)")
            parent = ("import pathlib, subprocess, sys, time; "
                      "subprocess.Popen([sys.executable, '-c', sys.argv[1]]); "
                      f"path = pathlib.Path({str(pid_file)!r}); "
                      "\nwhile not path.exists(): time.sleep(0.01)\n")
            with (Path(directory) / "log").open("w") as output:
                result = commands.run([sys.executable, "-c", parent, child], output)
            self.assertEqual(result.returncode, 0)
            pid = int(pid_file.read_text())
            state = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)],
                                   capture_output=True, text=True).stdout.strip()
            self.assertTrue(not state or state.startswith("Z"), f"owned child {pid} survived success")
            self.assertEqual(commands.active, {})

    def test_interrupt_drains_owned_tree_and_preserves_unrelated_process(self):
        # Real isolated groups, a TERM-resistant descendant, both runner signals,
        # and a simultaneous worker exercise the defect rather than mocking kill.
        source = str(Path(ci.__file__).resolve())
        for signum in (signal.SIGINT, signal.SIGTERM):
            with self.subTest(signal=signum), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                driver = root / "driver.py"
                driver.write_text("\n".join([
                    "import importlib.util, json, pathlib, signal, sys, threading",
                    f"sys.path.insert(0, {str(Path(source).parent)!r})",
                    f"spec = importlib.util.spec_from_file_location('driver_ci', {source!r})",
                    "ci = importlib.util.module_from_spec(spec); spec.loader.exec_module(ci)",
                    "root = pathlib.Path(sys.argv[1])",
                    "child = \"import os, pathlib, signal, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); pathlib.Path(os.environ['CHILD_PID']).write_text(str(os.getpid())); time.sleep(60)\"",
                    "parent = \"import os, pathlib, subprocess, sys, time; pathlib.Path(os.environ['PARENT_PID']).write_text(str(os.getpid())); subprocess.Popen([sys.executable, '-c', sys.argv[1]]); time.sleep(60)\"",
                    "import os",
                    "os.environ['PARENT_PID'] = str(root / 'parent.pid')",
                    "os.environ['CHILD_PID'] = str(root / 'child.pid')",
                    "try:",
                    "    with ci.OwnedCommands(grace_seconds=0.15) as commands:",
                    "        def worker():",
                    "            with (root / 'worker.log').open('w') as output:",
                    "                commands.run([sys.executable, '-c', 'import time; time.sleep(60)'], output)",
                    "        thread = threading.Thread(target=worker); thread.start()",
                    "        try:",
                    "            with (root / 'tree.log').open('w') as output:",
                    "                commands.run([sys.executable, '-c', parent, child], output)",
                    "        finally:",
                    "            thread.join(timeout=2)",
                    "except ci.VerificationCanceled as error:",
                    "    try:",
                    "        commands.run([sys.executable, '-c', 'raise SystemExit(99)'], sys.stdout)",
                    "    except ci.VerificationCanceled:",
                    "        pass",
                    "    else:",
                    "        raise AssertionError('ordinary command launched after cancellation')",
                    "    commands.run([sys.executable, '-c', \"print('owned cleanup')\"], sys.stdout, cleanup=True)",
                    "    (root / 'canceled.json').write_text(json.dumps({'signal': error.signum, 'active': list(commands.active)}))",
                    "    raise SystemExit(128 + error.signum)",
                ]) + "\n")
                unrelated = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"],
                                             start_new_session=True)
                invocation = subprocess.Popen([sys.executable, str(driver), str(root)],
                                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                              text=True, start_new_session=True)
                try:
                    deadline = time.monotonic() + 5
                    while not (root / "child.pid").exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertTrue((root / "child.pid").exists())
                    pids = [int((root / name).read_text()) for name in ("parent.pid", "child.pid")]
                    invocation.send_signal(signum)
                    time.sleep(0.03)
                    invocation.send_signal(signum)  # Runner escalation during bounded drain.
                    output, error = invocation.communicate(timeout=5)
                    self.assertEqual(invocation.returncode, 128 + signum, error)
                    self.assertIn("owned cleanup", output)
                    self.assertEqual(json.loads((root / "canceled.json").read_text()),
                                     {"signal": signum, "active": []})
                    self.assertIsNone(unrelated.poll())
                    for pid in pids:
                        deadline = time.monotonic() + 2
                        while time.monotonic() < deadline:
                            state = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)],
                                                   capture_output=True, text=True).stdout.strip()
                            if not state or state.startswith("Z"):
                                break
                            time.sleep(0.01)
                        self.assertTrue(not state or state.startswith("Z"), f"owned PID {pid} survived")
                finally:
                    if invocation.poll() is None:
                        # The driver file proves this group belongs to this fixture.
                        os.killpg(invocation.pid, signal.SIGKILL)
                        invocation.wait()
                    if (root / "parent.pid").exists():
                        try:
                            os.killpg(int((root / "parent.pid").read_text()), signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        except PermissionError:
                            if not ci.OwnedCommands.group_is_inert(int((root / "parent.pid").read_text())):
                                raise
                    unrelated.terminate()
                    unrelated.wait()

    def test_routine_workflow_is_pr_only_and_release_jobs_require_manual_main(self):
        directory = Path(__file__).resolve().parent.parent / ".github/workflows"
        expected = {"verification.yml": {"pull_request"}, "releases.yml": {"workflow_dispatch"}}
        for name, events in expected.items():
            source = (directory / name).read_text()
            block = re.search(r"^on:\n((?:[ \t]+[^\n]*\n)+)", source, re.MULTILINE)
            self.assertIsNotNone(block)
            self.assertEqual(set(re.findall(r"^  ([\w-]+):", block[1], re.MULTILINE)), events)
        pr = (directory / "verification.yml").read_text()
        activities = re.search(r"^    types: \[([^\]]+)\]$", pr, re.MULTILINE)
        self.assertIsNotNone(activities)
        self.assertEqual([value.strip() for value in activities[1].split(",")],
                         ["opened", "synchronize", "reopened"])
        # Draft opening and commit changes run; an unchanged ready transition reuses its check.
        self.assertEqual(re.findall(r"^    if: (.+)$", pr, re.MULTILINE), [
            "github.event_name == 'pull_request' && github.event.pull_request.head.repo.full_name == github.repository"])
        self.assertIn("ref: ${{ github.event.pull_request.head.sha || github.sha }}", pr)
        release = (directory / "releases.yml").read_text()
        guards = re.findall(r"^    if: (.+)$", release, re.MULTILINE)
        self.assertEqual(guards, ["github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'"] * 2)
        self.assertIn("needs: verification", release)

    def test_checkout_pins_preserve_exact_revision_history_and_ephemeral_credentials(self):
        directory = Path(__file__).resolve().parent.parent / ".github/workflows"
        expected_pin = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"
        expected_refs = {
            "verification.yml": ["${{ github.event.pull_request.head.sha || github.sha }}"],
            "releases.yml": ["${{ github.sha }}", "${{ github.sha }}"],
        }
        for name, refs in expected_refs.items():
            source = (directory / name).read_text()
            checkouts = re.findall(r"^        uses: (actions/checkout@[^ \n]+).*\n"
                                   r"        with:\n((?:          [^\n]+\n)+)", source, re.MULTILINE)
            self.assertEqual(len(checkouts), len(refs))
            for (pin, inputs), ref in zip(checkouts, refs):
                self.assertEqual(pin, expected_pin)
                values = dict(re.findall(r"^          ([\w-]+): (.+)$", inputs, re.MULTILINE))
                self.assertEqual(values, {"ref": ref, "fetch-depth": "0",
                                          "persist-credentials": "false", "clean": "true"})

    def test_main_workflow_grants_exact_read_only_provenance_permissions(self):
        workflow = Path(__file__).resolve().parent.parent / ".github/workflows/releases.yml"
        source = workflow.read_text()
        required_reads = {"actions": "read", "checks": "read", "pull-requests": "read", "statuses": "read"}
        # Job-specific permissions replace workflow permissions, so check both callers.
        for indent, contents in ((0, "read"), (4, "write")):
            match = re.search(r"^" + " " * indent + r"permissions:\n((?:" +
                              " " * (indent + 2) + r"[^\n]+\n)+)", source, re.MULTILINE)
            self.assertIsNotNone(match)
            permissions = dict(re.findall(r"^\s+([\w-]+): (read|write|none)$", match[1], re.MULTILINE))
            self.assertEqual(permissions, {"contents": contents, **required_reads})
        self.assertEqual(source.count("GH_TOKEN: ${{ github.token }}"), 2)

    def test_changed_paths_uses_real_pr_range_and_main_parent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)

            def git(*args):
                return subprocess.run(["git", *args], cwd=root, text=True,
                                      capture_output=True, check=True).stdout.strip()

            git("init", "-q")
            git("config", "core.hooksPath", "/dev/null")
            git("config", "user.name", "CI fixture")
            git("config", "user.email", "fixture@example.invalid")
            for name in ("deleted.swift", "old.swift", "changed.swift"):
                (root / name).write_text("base\n")
            git("add", ".")
            git("commit", "-qm", "base")
            base = git("rev-parse", "HEAD")
            git("update-ref", "refs/remotes/origin/main", base)
            (root / "deleted.swift").unlink()
            (root / "old.swift").rename(root / "renamed\nfile.swift")
            (root / "changed.swift").write_text("changed\n")
            git("add", "-A")
            git("commit", "-qm", "feature changes")
            (root / "new.swift").write_text("new\n")
            git("add", ".")
            git("commit", "-qm", "second feature commit")
            head = git("rev-parse", "HEAD")
            commands = []

            def run(label, command):
                commands.append(command)
                return subprocess.run(command, cwd=root, text=True,
                                      capture_output=True, check=True).stdout

            self.assertEqual(set(ci.changed_paths(head, "main", "pull_request", run)),
                             {"deleted.swift", "old.swift", "renamed\nfile.swift",
                              "changed.swift", "new.swift"})
            for event in ("push", "workflow_dispatch"):
                with self.subTest(event=event):
                    self.assertEqual(ci.changed_paths(head, "main", event, run), ["new.swift"])
            self.assertEqual(commands[0][-1], f"origin/main...{head}")
            self.assertEqual(commands[1][-2:], [f"{head}^", head])

    def test_successful_main_manifest_retains_workflow_run_number(self):
        scenarios = [("push", False, False, False), ("workflow_dispatch", False, False, False),
                     ("push", True, False, False), ("workflow_dispatch", True, False, False),
                     ("push", False, True, False), ("push", False, False, "summary"), ("push", False, False, "teardown")]
        for event, inherited, cleanup_failure, late_cancellation in scenarios:
            with self.subTest(event=event, inherited=inherited, cleanup_failure=cleanup_failure), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                environment = {"SIDEQUEST_EXPECTED_HEAD": "a" * 40, "SIDEQUEST_BASE_REF": "main",
                               "GITHUB_RUN_ID": "100", "GITHUB_RUN_ATTEMPT": "2", "GITHUB_RUN_NUMBER": "24",
                               "GITHUB_EVENT_NAME": event, "GITHUB_REF": "refs/heads/main",
                               "RUNNER_TEMP": str(root / "_temp"), "RUNNER_NAME": "Sidequest-Mac-foreground",
                               "GITHUB_OUTPUT": str(root / "output"), "GITHUB_STEP_SUMMARY": str(root / "summary")}

                def controlled(command, stdout=None, **kwargs):
                    output = ""
                    if cleanup_failure and command[:3] == ["xcrun", "simctl", "delete"]:
                        stdout.write("fixture deletion failed")
                        return subprocess.CompletedProcess(command, 1)
                    if command[-2:] == ["rev-parse", "HEAD"]:
                        output = "a" * 40
                    elif "launch" in command and "--terminate-running-process" in command:
                        output = "dev.devofthings.sidequest: 123"
                    elif "launchctl" in command:
                        output = "123 0 UIKitApplication:dev.devofthings.sidequest[fixture]"
                    elif command[:3] == ["xcrun", "simctl", "create"]:
                        output = "00000000-0000-0000-0000-000000000001"
                    elif command == ["xcodebuild", "-version"]:
                        output = "Xcode 27.0\nBuild version 27A266a"
                    elif command == ["xcrun", "simctl", "list", "devices", "available", "--json"]:
                        output = json.dumps({"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
                            {"name": "Sidequest CI iPhone"}]}})
                    elif command == ["xcrun", "simctl", "list", "runtimes", "--json"]:
                        output = json.dumps({"runtimes": [{"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
                                             "version": "27.0", "buildversion": "24A434", "isAvailable": True}]})
                    if stdout is not None:
                        stdout.write(output)
                    return subprocess.CompletedProcess(command, 0)

                original_open = Path.open

                def summary_open(path, mode="r", *args, **kwargs):
                    if late_cancellation == "summary" and path == root / "summary" and mode == "a":
                        # Interrupt after successful native/device cleanup and
                        # manifest writing, before final summary output completes.
                        self.assertTrue((root / "sidequest-diagnostics/100-2/verification.json").exists())
                        signal.raise_signal(signal.SIGTERM)
                    return original_open(path, mode, *args, **kwargs)

                original_signal = signal.signal

                def restore_signal(signum, handler):
                    if (late_cancellation == "teardown" and signum == signal.SIGTERM and
                            not callable(handler) and
                            (root / "sidequest-diagnostics/100-2/verification.json").exists()):
                        signal.raise_signal(signal.SIGTERM)
                    return original_signal(signum, handler)

                with patch.dict(os.environ, environment), patch.object(Path, "cwd", return_value=root), \
                     patch.object(signal, "signal", restore_signal), \
                     patch.object(Path, "open", summary_open), \
                     patch.object(ci.OwnedCommands, "run", side_effect=lambda command, output, cleanup=False: controlled(command, stdout=output)), \
                     patch.object(ci, "inherited_tests", return_value={"mode": "inherited", "gate": "pre_design_smoke", "original_head": "b" * 40, "inventory": ["original/test/case"]} if inherited else None), \
                     patch.object(ci.native_tests, "owned_execution", side_effect=nullcontext), \
                     patch.object(ci.native_tests, "selection", return_value=["SidequestTests"]), \
                     patch.object(ci.native_tests, "inventory", return_value={"active_gate": "pre_design_smoke", "workers": 1}), \
                     patch.object(ci.native_tests, "execute", return_value=({"mode": "full", "gate": "pre_design_smoke", "selected": ["SidequestTests"]}, root / "cache")) as execute:
                    (root / "scripts").mkdir()
                    (root / "scripts/native-test-inventory.json").write_text("{}")
                    if late_cancellation:
                        with self.assertRaises(ci.VerificationCanceled):
                            ci.main()
                    elif cleanup_failure:
                        with self.assertRaisesRegex(RuntimeError, "Owned simulator cleanup failed: delete-1"):
                            ci.main()
                    else:
                        ci.main()
                diagnostics = root / "sidequest-diagnostics/100-2"
                if late_cancellation:
                    self.assertFalse((diagnostics / "verification.json").exists())
                    self.assertEqual(json.loads((diagnostics / "cancellation.json").read_text()),
                                     {"signal": signal.SIGTERM, "commit": "a" * 40, "cleanup_completed": True})
                    self.assertTrue((diagnostics / "commands.json").exists())
                    self.assertEqual(json.loads((diagnostics / "commands.json").read_text())[-1]["exit"], 0)
                    continue
                if cleanup_failure:
                    self.assertFalse((diagnostics / "verification.json").exists())
                    commands = json.loads((diagnostics / "commands.json").read_text())
                    self.assertEqual(commands[-1]["label"], "delete-1")
                    self.assertEqual(commands[-1]["exit"], 1)
                    self.assertEqual((diagnostics / "delete-1.log").read_text(), "fixture deletion failed")
                    continue
                manifest = json.loads((root / "sidequest-diagnostics/100-2/verification.json").read_text())
                self.assertEqual(manifest["event"], event)
                self.assertEqual(manifest["run_number"], "24")
                self.assertEqual(manifest["run_id"], "100")
                self.assertEqual(manifest["attempt"], "2")
                self.assertTrue(manifest["all_checks_passed"])
                self.assertEqual(manifest["schema"], 2)
                self.assertEqual(manifest["tests"]["mode"], "inherited" if inherited else "full")
                self.assertEqual(execute.call_count, 0 if inherited else 1)
                self.assertEqual(manifest["tests"]["gate"], "pre_design_smoke")
                if not inherited:
                    self.assertEqual(execute.call_args.kwargs["gate"], "pre_design_smoke")
                commands = json.loads((root / "sidequest-diagnostics/100-2/commands.json").read_text())
                labels = [item["label"] for item in commands]
                self.assertIn("smoke-install", labels)
                self.assertIn("release-build", labels)
                if inherited:
                    self.assertIn("build-for-testing", labels)
                    self.assertNotIn("tests-1", labels)
                self.assertTrue(manifest["main_smoke_passed"])
                self.assertIn("100-2", (root / "output").read_text())
                self.assertLess(labels.index("native-source-checkout"), labels.index("create-1"))
                self.assertLess(labels.index("release-build"), labels.index("manifest-source-checkout"))
                self.assertLess(labels.index("shutdown-1"), labels.index("delete-1"))
                self.assertLess(labels.index("delete-1"), labels.index("manifest-source-checkout"))

    def test_clean_checkout_rejects_real_tracked_and_untracked_native_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()
            git("init", "-q")
            git("config", "core.hooksPath", "/dev/null")
            git("config", "user.name", "CI fixture")
            git("config", "user.email", "fixture@example.com")
            (root / "Sidequest").mkdir()
            tracked = root / "Sidequest/App.swift"
            tracked.write_text("let fixture = 1\n")
            git("add", ".")
            git("commit", "-qm", "reviewed source")
            expected = git("rev-parse", "HEAD")
            def run(label, command):
                return subprocess.check_output(command, text=True)
            for phase in ("native-source", "manifest-source"):
                ci.verify_clean_checkout(root, expected, run, phase)
                tracked.write_text("let fixture = 2\n")
                with self.assertRaisesRegex(RuntimeError, "clean tracked and untracked"):
                    ci.verify_clean_checkout(root, expected, run, phase)
                git("checkout", "--", "Sidequest/App.swift")
                extra = root / "Sidequest/Unreviewed.swift"
                extra.write_text("let unreviewed = 3\n")
                with self.assertRaisesRegex(RuntimeError, "clean tracked and untracked"):
                    ci.verify_clean_checkout(root, expected, run, phase)
                extra.unlink()
            git("commit", "--allow-empty", "-qm", "unreviewed head")
            with self.assertRaisesRegex(RuntimeError, "changed from the reviewed commit"):
                ci.verify_clean_checkout(root, expected, run, "manifest-source")

    def test_main_smoke_requires_actual_launch_and_running_process(self):
        calls = []
        def run(label, command):
            calls.append(label)
            return "dev.devofthings.sidequest: 123" if label == "smoke-launch" else ""
        with self.assertRaisesRegex(RuntimeError, "remain running"):
            ci.smoke("platform=iOS Simulator,id=owned", Path("/owned/app"), run)
        self.assertNotIn("smoke-terminate", calls)
        def invalid(label, command):
            return "launch did not start" if label == "smoke-launch" else ""
        with self.assertRaisesRegex(RuntimeError, "process identity"):
            ci.smoke("platform=iOS Simulator,id=owned", Path("/owned/app"), invalid)

    def test_older_queued_main_and_stale_pr(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)

            def git(*args):
                return subprocess.check_output(["git", *args], cwd=root,
                                               stderr=subprocess.STDOUT, text=True).strip()

            git("init", "-q")
            git("config", "user.name", "CI fixture")
            git("config", "user.email", "fixture@example.com")
            git("config", "core.hooksPath", "/dev/null")
            (root / "fixture").write_text("base\n")
            git("add", ".")
            git("commit", "-qm", "base")
            (root / "fixture").write_text("older main\n")
            git("commit", "-qam", "older main")
            older = git("rev-parse", "HEAD")
            (root / "fixture").write_text("newer main\n")
            git("commit", "-qam", "newer main")
            newer = git("rev-parse", "HEAD")
            git("update-ref", "refs/remotes/origin/main", newer)
            git("checkout", "-q", older)

            def run(label, command):
                result = subprocess.run(command, cwd=root, capture_output=True, text=True)
                if result.returncode:
                    raise RuntimeError(label)
                return result.stdout

            # The remote advanced before this queued event starts. Main must pass.
            ci.verify_revision(older, "main", "push", "refs/heads/main", run)
            ci.verify_revision(older, "main", "workflow_dispatch", "refs/heads/main", run)
            with self.assertRaisesRegex(RuntimeError, "base-ancestry"):
                ci.verify_revision(older, "main", "pull_request", "refs/pull/1/merge", run)
            with self.assertRaisesRegex(RuntimeError, "does not match"):
                ci.verify_revision(newer, "main", "push", "refs/heads/main", run)
            with self.assertRaisesRegex(RuntimeError, "Only"):
                ci.verify_revision(older, "main", "push", "refs/heads/other", run)
            with self.assertRaisesRegex(RuntimeError, "Only"):
                ci.verify_revision(older, "main", "workflow_dispatch", "refs/heads/other", run)
            git("checkout", "-q", newer)
            ci.verify_revision(newer, "main", "pull_request", "refs/pull/1/merge", run)

    def test_runner_storage_rejected_before_network_and_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / "repo"
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            (repo / "nested").mkdir()
            destination = repo / "nested" / "runner"
            with patch.object(sys, "argv", ["configure-ci-runner.py", "--directory", str(destination)]), \
                 patch.object(installer, "github", side_effect=AssertionError("No network allowed")):
                with self.assertRaisesRegex(RuntimeError, "outside every Git"):
                    installer.main()
            self.assertFalse(destination.exists())
            symlink = root / "linked-repo"
            symlink.symlink_to(repo, target_is_directory=True)
            with self.assertRaisesRegex(RuntimeError, "outside every Git"):
                installer.validate_directory((symlink / "runner").resolve())
            hooks = root / "fixture-hooks"
            hooks.mkdir()
            marker = root / "post-checkout-ran"
            hook = hooks / "post-checkout"
            hook.write_text("#!/bin/sh\n: > " + shlex.quote(str(marker)) + "\nexit 71\n")
            hook.chmod(0o755)
            subprocess.run(["git", "-C", str(repo), "config", "core.hooksPath", str(hooks)],
                           check=True)
            subprocess.run(["git", "-C", str(repo), "-c", "core.hooksPath=/dev/null",
                            "-c", "user.name=CI fixture", "-c", "user.email=fixture@example.com",
                            "commit", "--allow-empty", "-qm", "fixture"], check=True)
            worktree = root / "worktree"
            # Worktree creation runs post-checkout, even in a disposable fixture.
            subprocess.run(["git", "-C", str(repo), "-c", "core.hooksPath=/dev/null",
                            "worktree", "add", "--detach", "-q", str(worktree)],
                           check=True)
            self.assertFalse(marker.exists(), "Disposable fixtures must not execute inherited hooks.")
            with self.assertRaisesRegex(RuntimeError, "outside every Git"):
                installer.validate_directory(worktree / "runner")
            installer.validate_directory(root / "safe-runner")
            self.assertFalse((root / "safe-runner").exists())

    def test_existing_private_configuration_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "runner"
            destination.mkdir()
            credential = destination / ".credentials"
            credential.write_text("fictional private configuration")
            with patch.object(sys, "argv", ["configure-ci-runner.py", "--directory", str(destination)]), \
                 patch.object(installer, "github", side_effect=AssertionError("No network allowed")):
                with self.assertRaisesRegex(RuntimeError, "already exists"):
                    installer.main()
            self.assertEqual(credential.read_text(), "fictional private configuration")


if __name__ == "__main__":
    unittest.main()
