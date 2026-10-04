#!/usr/bin/env python3
"""Exercise queued-main/PR verification and private runner storage without networking."""

from contextlib import nullcontext
import importlib.util
import json
import os
from pathlib import Path
import shlex
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
        for event, inherited in [("push", False), ("workflow_dispatch", False), ("push", True), ("workflow_dispatch", True)]:
            with self.subTest(event=event, inherited=inherited), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                environment = {"SIDEQUEST_EXPECTED_HEAD": "a" * 40, "SIDEQUEST_BASE_REF": "main",
                               "GITHUB_RUN_ID": "100", "GITHUB_RUN_ATTEMPT": "2", "GITHUB_RUN_NUMBER": "24",
                               "GITHUB_EVENT_NAME": event, "GITHUB_REF": "refs/heads/main",
                               "RUNNER_TEMP": str(root / "_temp"), "RUNNER_NAME": "Sidequest-Mac-foreground",
                               "GITHUB_OUTPUT": str(root / "output"), "GITHUB_STEP_SUMMARY": str(root / "summary")}

                def controlled(command, stdout=None, **kwargs):
                    output = ""
                    if command == ["git", "rev-parse", "HEAD"]:
                        output = "a" * 40
                    elif "launch" in command and "--terminate-running-process" in command:
                        output = "dev.devofthings.sidequest: 123"
                    elif "launchctl" in command:
                        output = "123 0 UIKitApplication:dev.devofthings.sidequest[fixture]"
                    elif command[:3] == ["xcrun", "simctl", "create"]:
                        output = "owned"
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

                with patch.dict(os.environ, environment), patch.object(Path, "cwd", return_value=root), \
                     patch.object(subprocess, "run", side_effect=controlled), \
                     patch.object(ci, "inherited_tests", return_value={"mode": "inherited", "original_head": "b" * 40, "inventory": ["original/test/case"]} if inherited else None), \
                     patch.object(ci.native_tests, "owned_execution", side_effect=nullcontext), \
                     patch.object(ci.native_tests, "selection", return_value=["SidequestTests"]), \
                     patch.object(ci.native_tests, "execute", return_value=({"mode": "full", "selected": ["SidequestTests"]}, root / "cache")) as execute:
                    (root / "scripts").mkdir()
                    (root / "scripts/native-test-inventory.json").write_text("{}")
                    ci.main()
                manifest = json.loads((root / "sidequest-diagnostics/100-2/verification.json").read_text())
                self.assertEqual(manifest["event"], event)
                self.assertEqual(manifest["run_number"], "24")
                self.assertEqual(manifest["run_id"], "100")
                self.assertEqual(manifest["attempt"], "2")
                self.assertTrue(manifest["all_checks_passed"])
                self.assertEqual(manifest["schema"], 2)
                self.assertEqual(manifest["tests"]["mode"], "inherited" if inherited else "full")
                self.assertEqual(execute.call_count, 0 if inherited else 1)
                commands = json.loads((root / "sidequest-diagnostics/100-2/commands.json").read_text())
                labels = [item["label"] for item in commands]
                self.assertIn("smoke-install", labels)
                self.assertIn("release-build", labels)
                if inherited:
                    self.assertIn("build-for-testing", labels)
                    self.assertNotIn("tests-1", labels)
                self.assertTrue(manifest["main_smoke_passed"])
                self.assertIn("100-2", (root / "output").read_text())

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
