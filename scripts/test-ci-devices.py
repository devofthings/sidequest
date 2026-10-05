#!/usr/bin/env python3
"""Offline recovery and actual shell-signal regressions; never invoke simctl."""

import json
from contextlib import nullcontext
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

import ci_devices as devices
import native_tests


class RecoveryTests(unittest.TestCase):
    owner = {"run_id": "123", "attempt": "1", "commit": "a" * 40}
    environment = {"GITHUB_RUN_ID": "123", "GITHUB_RUN_ATTEMPT": "1", "SIDEQUEST_EXPECTED_HEAD": "a" * 40}
    identifiers = ["00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002"]

    def prepare(self, root, count=2):
        registry = devices.Registry(root, self.environment)
        for index in range(count):
            registry.created(self.identifiers[index], f"Sidequest CI 123-1 {index + 1}")
        return registry

    def live(self, registry):
        return {"devices": {native_tests.RUNTIME: [
            {"udid": item["udid"], "name": item["name"], "deviceTypeIdentifier": item["device_type"], "state": "Booted"}
            for item in registry.record["devices"]]}}

    def test_recovery_is_durable_exact_and_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = self.prepare(root)
            live = self.live(registry)
            unrelated = {"udid": "00000000-0000-0000-0000-000000000009", "name": "personal", "state": "Booted"}
            live["devices"][native_tests.RUNTIME].append(unrelated)
            calls = []

            def run(label, command):
                calls.append(command)
                if label == "devices":
                    return json.dumps(live)
                if command[2] == "delete":
                    live["devices"][native_tests.RUNTIME] = [item for item in live["devices"][native_tests.RUNTIME] if item["udid"] != command[3]]
                return ""

            del registry  # Recovery reads disk, not the dead driver's memory.
            self.assertEqual(devices.recover(root, self.owner, run), self.identifiers)
            self.assertEqual([command[2:] for command in calls[1:]],
                             [[operation, identifier] for identifier in self.identifiers for operation in ("shutdown", "delete")])
            self.assertEqual(live["devices"][native_tests.RUNTIME], [unrelated])
            calls.clear()
            devices.recover(root, self.owner, run)
            self.assertEqual(len(calls), 1)

    def test_wrong_owner_or_live_identity_is_rejected_before_deletion(self):
        for mismatch in ("commit", "attempt", "run_id", "name", "runtime", "device_type", "duplicate", "uuid"):
            with self.subTest(mismatch=mismatch), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                registry = self.prepare(root)
                live = self.live(registry)
                if mismatch in self.owner:
                    registry.record[mismatch] = "different"
                elif mismatch == "uuid":
                    registry.record["devices"][1]["udid"] = "bad"
                elif mismatch == "duplicate":
                    registry.record["devices"][1]["udid"] = self.identifiers[0]
                elif mismatch == "runtime":
                    live["devices"]["unrelated-runtime"] = live["devices"].pop(native_tests.RUNTIME)
                else:
                    field = "deviceTypeIdentifier" if mismatch == "device_type" else "name"
                    live["devices"][native_tests.RUNTIME][1][field] = "unrelated"
                devices.write_atomic(registry.path, registry.record)
                calls = []

                def run(label, command):
                    calls.append(command)
                    return json.dumps(live)

                with self.assertRaises((ValueError, AttributeError)):
                    devices.recover(root, self.owner, run)
                self.assertTrue(all(command[2] == "list" for command in calls))

    def test_failed_cleanup_attempts_remaining_owned_operations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            registry = self.prepare(root)
            calls = []

            def run(label, command):
                calls.append(command)
                if label == "devices":
                    return json.dumps(self.live(registry))
                if command[2] == "shutdown":
                    raise RuntimeError("owned shutdown failure")
                return ""

            with self.assertRaisesRegex(RuntimeError, "shutdown-1, shutdown-2"):
                devices.recover(root, self.owner, run)
            self.assertEqual(len(calls), 5)
            self.assertEqual(json.loads(registry.path.read_text()), registry.record)

    def test_registration_precedes_boot_and_write_failure_still_cleans_returned_uuid(self):
        for failure in (False, True):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                registry = devices.Registry(root, self.environment)
                calls = []

                def run(label, command):
                    calls.append(command[2])
                    if command[2] == "create":
                        return self.identifiers[0]
                    if command[2] == "boot":
                        self.assertEqual(json.loads(registry.path.read_text())["devices"][0]["udid"], self.identifiers[0])
                    return ""

                with patch.object(devices, "write_atomic", side_effect=OSError("disk full")) if failure else patch.object(devices, "write_atomic", wraps=devices.write_atomic):
                    if failure:
                        with self.assertRaises(OSError):
                            with native_tests.devices(run, "Sidequest CI 123-1", 1, created=registry.created):
                                self.fail("failed persistence cannot boot")
                    else:
                        with native_tests.devices(run, "Sidequest CI 123-1", 1, created=registry.created):
                            pass
                self.assertEqual(calls[-2:], ["shutdown", "delete"])
                self.assertEqual("boot" in calls, not failure)

    def test_force_killed_creator_leaves_recoverable_owned_record(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            code = ("import ci_devices, pathlib, sys, time; "
                    f"registry=ci_devices.Registry(pathlib.Path(sys.argv[1]), {self.environment!r}); "
                    f"registry.created({self.identifiers[0]!r}, 'Sidequest CI 123-1 1'); "
                    "print('registered', flush=True); time.sleep(60)")
            child = subprocess.Popen([sys.executable, "-c", code, str(root)], stdout=subprocess.PIPE,
                                     cwd=Path(__file__).parent, text=True)
            try:
                deadline = time.monotonic() + 5
                while not (root / "owned-devices.json").exists() or not json.loads((root / "owned-devices.json").read_text())["devices"]:
                    self.assertLess(time.monotonic(), deadline)
                    time.sleep(0.01)
                child.kill()
                child.wait(timeout=5)
                live = {"devices": {native_tests.RUNTIME: [{"udid": self.identifiers[0], "name": "Sidequest CI 123-1 1", "deviceTypeIdentifier": native_tests.DEVICE_TYPE, "state": "Booted"}]}}
                calls = []

                def run(label, command):
                    calls.append(command)
                    return json.dumps(live) if label == "devices" else ""

                devices.recover(root, self.owner, run)
                self.assertEqual([command[2] for command in calls], ["list", "shutdown", "delete"])
            finally:
                if child.poll() is None:
                    child.kill()
                    child.wait()
                child.stdout.close()

    def test_finalizer_repeated_signals_and_manifest_failure_boundaries(self):
        for outcome, failed in (("success", False), ("cancelled", False), ("failure", False), ("success", True)):
            with self.subTest(outcome=outcome, failed=failed), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.prepare(root, 1)
                manifest = root / "verification.json"
                manifest.write_text("passing manifest")

                def recover(*args):
                    signal.raise_signal(signal.SIGINT)
                    signal.raise_signal(signal.SIGTERM)
                    if failed:
                        raise RuntimeError("owned cleanup failed")
                    return self.identifiers[:1]

                environment = {**self.environment, "SIDEQUEST_VERIFICATION_OUTCOME": outcome}
                with patch.dict(os.environ, environment), patch.object(devices, "directory", return_value=root), \
                     patch.object(devices.native_tests, "owned_execution", side_effect=nullcontext), \
                     patch.object(devices, "recover", side_effect=recover):
                    if failed:
                        with self.assertRaises(RuntimeError):
                            devices.main()
                    else:
                        devices.main()
                self.assertEqual(manifest.exists(), outcome == "success" and not failed)
                self.assertEqual(json.loads((root / "device-recovery.json").read_text()),
                                 {**self.owner, "verification_outcome": outcome, "cleanup_completed": not failed})

    def test_finalizer_cli_uses_only_recorded_ids_after_driver_death(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            diagnostics = root / "sidequest-diagnostics/123-1"
            diagnostics.mkdir(parents=True)
            registry = self.prepare(diagnostics, 1)
            state = self.live(registry)
            unrelated = {"udid": self.identifiers[1], "name": "personal", "state": "Booted"}
            state["devices"][native_tests.RUNTIME].append(unrelated)
            (root / "state.json").write_text(json.dumps(state))
            (diagnostics / "verification.json").write_text("must not survive cancellation")
            binary = root / "bin"
            binary.mkdir()
            fake = binary / "xcrun"
            fake.write_text(f"#!{sys.executable}\n" +
                            "import json,os,pathlib,sys,time\n" +
                            "root=pathlib.Path(os.environ['FIXTURE_ROOT']); path=root/'state.json'; state=json.loads(path.read_text())\n" +
                            "with (root/'calls').open('a') as out: out.write(json.dumps(sys.argv[1:])+'\\n')\n" +
                            "if sys.argv[2]=='list': print(json.dumps(state))\n" +
                            "elif sys.argv[2]=='shutdown': (root/'recovering').touch(); time.sleep(0.2)\n" +
                            "elif sys.argv[2]=='delete':\n    for key in state['devices']: state['devices'][key]=[item for item in state['devices'][key] if item['udid']!=sys.argv[3]]\n    path.write_text(json.dumps(state))\n")
            fake.chmod(0o700)
            environment = {**os.environ, **self.environment, "RUNNER_TEMP": str(root / "_temp"),
                           "SIDEQUEST_VERIFICATION_OUTCOME": "cancelled", "FIXTURE_ROOT": str(root),
                           "PATH": str(binary) + os.pathsep + os.environ["PATH"]}
            child = subprocess.Popen([sys.executable, str(Path(devices.__file__).resolve())], env=environment,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                deadline = time.monotonic() + 5
                while not (root / "recovering").exists():
                    self.assertLess(time.monotonic(), deadline)
                    time.sleep(0.01)
                child.send_signal(signal.SIGINT)
                child.send_signal(signal.SIGTERM)
                output, error = child.communicate(timeout=5)
                self.assertEqual(child.returncode, 0, error)
                self.assertFalse((diagnostics / "verification.json").exists())
                self.assertTrue(json.loads((diagnostics / "device-recovery.json").read_text())["cleanup_completed"])
                self.assertEqual(json.loads((root / "state.json").read_text())["devices"][native_tests.RUNTIME], [unrelated])
                calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
                self.assertEqual(calls, [["simctl", "list", "devices", "--json"],
                                         ["simctl", "shutdown", self.identifiers[0]], ["simctl", "delete", self.identifiers[0]]])
            finally:
                if child.poll() is None:
                    child.kill()
                    child.communicate()

    def test_actual_exec_shell_delivers_repeated_runner_signals_to_python(self):
        # Use the exact workflow entry command, substituting only the fixture driver.
        source = Path(__file__).resolve().parent.parent
        for name in ("verification.yml", "releases.yml"):
            workflow = (source / ".github/workflows" / name).read_text()
            self.assertIn("run: exec python3 scripts/ci-verify.py", workflow)
            self.assertIn("if: always()", workflow)
            self.assertIn("SIDEQUEST_VERIFICATION_OUTCOME: ${{ steps.verify.outcome }}", workflow)
            self.assertIn("run: exec python3 scripts/ci_devices.py", workflow)
        for signum in (signal.SIGINT, signal.SIGTERM):
            with self.subTest(signal=signum), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / "scripts").mkdir()
                driver = root / "scripts/ci-verify.py"
                driver.write_text(f"import sys; sys.path.insert(0, {str(source / 'scripts')!r})\n" +
                                  "import importlib.util, pathlib, signal, time, os\n" +
                                  f"spec=importlib.util.spec_from_file_location('ci', {str(source / 'scripts/ci-verify.py')!r}); ci=importlib.util.module_from_spec(spec); spec.loader.exec_module(ci)\n" +
                                  "try:\n    with ci.OwnedCommands(grace_seconds=0.15) as commands:\n        pathlib.Path('ready').write_text(str(os.getpid()))\n        commands.run([sys.executable, '-c', \"import pathlib,time; pathlib.Path('child-ready').touch(); time.sleep(60)\"], sys.stdout)\n" +
                                  "except ci.VerificationCanceled as error:\n    time.sleep(0.2)\n    pathlib.Path('cleaned').write_text(str(error.signum))\n    raise SystemExit(128+error.signum)\n")
                child = subprocess.Popen(["bash", "--noprofile", "--norc", "-e", "-c", "exec python3 scripts/ci-verify.py"], cwd=root)
                try:
                    deadline = time.monotonic() + 5
                    while not (root / "child-ready").exists():
                        self.assertLess(time.monotonic(), deadline)
                        time.sleep(0.01)
                    self.assertEqual(int((root / "ready").read_text()), child.pid)
                    child.send_signal(signum)
                    time.sleep(0.03)
                    child.send_signal(signal.SIGTERM)
                    self.assertEqual(child.wait(timeout=5), 128 + signum)
                    self.assertEqual((root / "cleaned").read_text(), str(int(signum)))
                finally:
                    if child.poll() is None:
                        child.kill()
                        child.wait()


if __name__ == "__main__":
    unittest.main()
