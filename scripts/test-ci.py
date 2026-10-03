#!/usr/bin/env python3
"""Exercise queued-main/PR verification and private runner storage without networking."""

import importlib.util
import json
import os
from pathlib import Path
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
    def test_successful_main_manifest_retains_workflow_run_number(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            environment = {"SIDEQUEST_EXPECTED_HEAD": "a" * 40, "SIDEQUEST_BASE_REF": "main",
                           "GITHUB_RUN_ID": "100", "GITHUB_RUN_ATTEMPT": "2", "GITHUB_RUN_NUMBER": "24",
                           "GITHUB_EVENT_NAME": "push", "GITHUB_REF": "refs/heads/main",
                           "RUNNER_TEMP": str(root / "_temp"), "RUNNER_NAME": "Sidequest-Mac-foreground",
                           "GITHUB_OUTPUT": str(root / "output"), "GITHUB_STEP_SUMMARY": str(root / "summary")}

            def controlled(command, stdout, **kwargs):
                output = ""
                if command == ["git", "rev-parse", "HEAD"]:
                    output = "a" * 40
                elif command == ["xcodebuild", "-version"]:
                    output = "Xcode 27.0\nBuild version 27A266a"
                elif command == ["xcrun", "simctl", "list", "devices", "available", "--json"]:
                    output = json.dumps({"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
                        {"name": "Sidequest CI iPhone"}]}})
                elif command == ["xcrun", "simctl", "list", "runtimes", "--json"]:
                    output = json.dumps({"runtimes": [{"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
                                         "version": "27.0", "buildversion": "24A434", "isAvailable": True}]})
                stdout.write(output)
                return subprocess.CompletedProcess(command, 0)

            with patch.dict(os.environ, environment), patch.object(Path, "cwd", return_value=root), \
                 patch.object(subprocess, "run", side_effect=controlled):
                ci.main()
            manifest = json.loads((root / "sidequest-diagnostics/100-2/verification.json").read_text())
            self.assertEqual(manifest["run_number"], "24")
            self.assertEqual(manifest["run_id"], "100")
            self.assertEqual(manifest["attempt"], "2")
            self.assertTrue(manifest["all_checks_passed"])
            self.assertIn("100-2", (root / "output").read_text())

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
            with self.assertRaisesRegex(RuntimeError, "base-ancestry"):
                ci.verify_revision(older, "main", "pull_request", "refs/pull/1/merge", run)
            with self.assertRaisesRegex(RuntimeError, "does not match"):
                ci.verify_revision(newer, "main", "push", "refs/heads/main", run)
            with self.assertRaisesRegex(RuntimeError, "Only"):
                ci.verify_revision(older, "main", "push", "refs/heads/other", run)
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
            subprocess.run(["git", "-C", str(repo), "-c", "core.hooksPath=/dev/null",
                            "-c", "user.name=CI fixture", "-c", "user.email=fixture@example.com",
                            "commit", "--allow-empty", "-qm", "fixture"], check=True)
            worktree = root / "worktree"
            subprocess.run(["git", "-C", str(repo), "worktree", "add", "--detach", "-q", str(worktree)],
                           check=True)
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
