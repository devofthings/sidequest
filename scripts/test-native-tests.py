#!/usr/bin/env python3
"""Offline regression checks for cache ownership, coverage, and native failure boundaries."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import native_tests as native


class NativeTests(unittest.TestCase):
    def test_owned_devices_are_deleted_without_touching_unrelated_devices_or_diagnostics(self):
        for failure in (None, "body", "create-2", "boot-1", "bootstatus-1"):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                retained = [root / name for name in ("Tests.xcresult", "tests.log", "cache", "Release.app")]
                for path in retained:
                    path.write_bytes(b"retained evidence")
                state = {"user-device": "Booted"}
                calls = []

                def run(label, command):
                    calls.append((label, command))
                    if label == failure:
                        raise RuntimeError(failure)
                    operation = command[2]
                    identifier = f"owned-{label.split('-')[-1]}" if operation == "create" else command[3]
                    if operation == "create":
                        state[identifier] = "Shutdown"
                        return identifier
                    if operation in ("boot", "shutdown"):
                        state[identifier] = "Booted" if operation == "boot" else "Shutdown"
                    elif operation == "delete":
                        del state[identifier]
                    return ""

                def execute():
                    with native.devices(run, "isolated fixture", 2) as destinations:
                        self.assertEqual(destinations, ["platform=iOS Simulator,id=owned-1",
                                                        "platform=iOS Simulator,id=owned-2"])
                        self.assertIn("owned-1", state)
                        if failure == "body":
                            raise RuntimeError("body")

                if failure:
                    with self.assertRaisesRegex(RuntimeError, failure):
                        execute()
                else:
                    execute()
                self.assertEqual(state, {"user-device": "Booted"})
                cleanup = [(label, command) for label, command in calls if command[2] in ("shutdown", "delete")]
                expected_count = 1 if failure in ("create-2", "boot-1", "bootstatus-1") else 2
                self.assertEqual([label for label, _ in cleanup],
                                 [f"{operation}-{index}" for index in range(1, expected_count + 1)
                                  for operation in ("shutdown", "delete")])
                self.assertTrue(all(command[3].startswith("owned-") for _, command in cleanup))
                self.assertEqual([path.read_bytes() for path in retained], [b"retained evidence"] * 4)

    def test_cleanup_failures_attempt_all_operations_and_report_owned_leftovers(self):
        calls = []
        state = {"user-device": "Booted"}

        def run(label, command):
            calls.append(label)
            if label in ("shutdown-1", "delete-2"):
                raise RuntimeError("simctl failed")
            if command[2] == "create":
                identifier = "owned-" + label.split("-")[-1]
                state[identifier] = "Shutdown"
                return identifier
            if command[2] == "delete":
                del state[command[3]]
            return ""

        with self.assertRaisesRegex(RuntimeError, r"shutdown-1 \(owned-1\), delete-2 \(owned-2\)"):
            with native.devices(run, "isolated fixture", 2):
                pass
        self.assertEqual(calls[-4:], ["shutdown-1", "delete-1", "shutdown-2", "delete-2"])
        self.assertEqual(state, {"user-device": "Booted", "owned-2": "Shutdown"})

    def test_cache_boundaries_and_exclusive_ownership(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            boundary, key = native.cache_identity(root, "Xcode A", "SDK A", {"runtime": "A"})
            for changed in [(root / "other", "Xcode A", "SDK A", {"runtime": "A"}),
                            (root, "Xcode B", "SDK A", {"runtime": "A"}),
                            (root, "Xcode A", "SDK B", {"runtime": "A"}),
                            (root, "Xcode A", "SDK A", {"runtime": "B"})]:
                self.assertNotEqual(native.cache_identity(*changed)[1], key)
            with patch.object(native, "SETTINGS", ["CODE_SIGNING_ALLOWED=YES"]):
                self.assertNotEqual(native.cache_identity(root, "Xcode A", "SDK A", {"runtime": "A"})[1], key)
            runtime = {"runtimes": [{"identifier": native.RUNTIME, "version": "27.0", "buildversion": "A",
                                    "isAvailable": True, "lastUsage": {"arm64": "old"}}]}
            before = native.cache_identity(root, "xcode", "sdk", runtime)[1]
            runtime["runtimes"][0]["lastUsage"]["arm64"] = "new"
            self.assertEqual(native.cache_identity(root, "xcode", "sdk", runtime)[1], before)
            runtime["runtimes"][0]["buildversion"] = "B"
            self.assertNotEqual(native.cache_identity(root, "xcode", "sdk", runtime)[1], before)
            with native.owned_cache(root / "cache", boundary, key) as derived:
                self.assertIn(key, str(derived))
                with self.assertRaisesRegex(RuntimeError, "owned"):
                    with native.owned_cache(root / "cache", boundary, key):
                        self.fail("Concurrent cache ownership was admitted.")
            with native.owned_cache(root / "cache", boundary, key):
                pass
            (root / "cache" / key / "identity.json").write_text("{}")
            with self.assertRaisesRegex(RuntimeError, "boundary"):
                with native.owned_cache(root / "cache", boundary, key):
                    pass

    def test_failed_current_build_never_tests_cached_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            calls = []
            def run(label, command):
                calls.append(command)
                raise RuntimeError("current build failed")
            with self.assertRaisesRegex(RuntimeError, "current build failed"):
                native.execute(root, root, root / "cache", ["platform=iOS Simulator,id=owned"],
                               ["SidequestTests"], run, "xcode", "sdk", "runtime")
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0][-1], "build-for-testing")
            self.assertFalse((root / "native-tests.json").exists())

    def test_successful_runs_recompile_current_checkout_and_record_actual_inventory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "SidequestUITests").mkdir()
            (root / "SidequestUITests/Flow.swift").write_text("final class Flow: XCTestCase { func testFlow() {} }")
            case = "SidequestUITests/Flow/testFlow"
            (root / "scripts/native-test-inventory.json").write_text(json.dumps({"required": [case], "extended": {}}))
            tree = {"devices": [{"deviceId": "owned"}], "testNodes": [{"nodeType": "Test Case", "result": "Passed",
                                                                             "nodeIdentifierURL": "test://suite/" + case}]}
            summary = {"result": "Passed", "passedTests": 1, "failedTests": 0, "skippedTests": 0,
                       "expectedFailures": 0, "startTime": 1, "finishTime": 3}
            calls = []
            def run(label, command):
                calls.append((label, command))
                return json.dumps(tree if label.startswith("test-tree") else summary) if label.startswith(("test-tree", "test-summary")) else ""
            fingerprints = []
            for index in range(2):
                output = root / f"run-{index}"
                output.mkdir()
                record, _ = native.execute(root, output, root / "cache", ["platform=iOS Simulator,id=owned"],
                                           [case], run, "xcode", "sdk", "runtime")
                self.assertEqual(record["inventory"], [case])
                self.assertEqual(record["worker_inventory"][0]["passed"], 1)
                fingerprints.append(record["source_fingerprint"])
                (root / "SidequestUITests/Flow.swift").write_text("final class Flow: XCTestCase { func testFlow() {} } // changed\n")
            self.assertNotEqual(*fingerprints)
            self.assertEqual([label for label, _ in calls].count("build-for-testing"), 2)
            test_commands = [command for label, command in calls if label == "tests-1"]
            self.assertTrue(all(command[-1] == "test-without-building" for command in test_commands))
            self.assertNotEqual(test_commands[0][test_commands[0].index("-resultBundlePath") + 1],
                                test_commands[1][test_commands[1].index("-resultBundlePath") + 1])

    def test_inventory_selection_and_new_case_fail_closed(self):
        root = Path(__file__).resolve().parent.parent
        policy = native.inventory(root)
        required = native.selection(root, [])
        self.assertEqual(set(required), {"SidequestTests", *policy["pre_design_smoke"]})
        self.assertEqual(native.selection(root), required)
        full = native.selection(root, extended=True)
        self.assertTrue(set(required) < set(full))
        self.assertEqual(set(full), {"SidequestTests", *policy["required"], *policy["extended"]})
        relevant = native.selection(root, ["Sidequest/Games/Chess/Presentation/ChessController.swift"])
        self.assertEqual(relevant, required, "Ownership paths cannot restore deferred UI gates.")
        self.assertEqual(native.selection(root, ["Sidequest/", "SidequestUITests/"]), required)
        for groups in [native.shards(full, policy, 1), native.shards(full, policy, 2)]:
            flattened = [case for group in groups for case in group]
            self.assertEqual(len(flattened), len(set(flattened)))
            self.assertEqual(set(flattened), set(full))
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            (fixture / "scripts").mkdir()
            (fixture / "SidequestUITests").mkdir()
            (fixture / "scripts/native-test-inventory.json").write_text(json.dumps({"required": [], "extended": {}}))
            (fixture / "SidequestUITests/New.swift").write_text("final class New: XCTestCase { func testNew() {} }")
            with self.assertRaisesRegex(RuntimeError, "inventory"):
                native.inventory(fixture)

    def test_actual_platform_inventory_counts_failures_and_device(self):
        case = "SidequestUITests/Flow/testFlow"
        tree = {"devices": [{"deviceId": "owned"}], "testNodes": [{"children": [{
            "nodeType": "Test Case", "result": "Passed", "nodeIdentifierURL": "test://suite/" + case}]}]}
        summary = {"result": "Passed", "passedTests": 1, "failedTests": 0, "skippedTests": 0,
                   "expectedFailures": 0, "startTime": 1, "finishTime": 3}
        self.assertEqual(native.result_evidence(tree, summary, "platform=iOS Simulator,id=owned", [case])["passed"], 1)
        for key, value in [("failedTests", 1), ("skippedTests", 1), ("expectedFailures", 1), ("passedTests", 0)]:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                native.result_evidence(tree, {**summary, key: value}, "platform=iOS Simulator,id=owned", [case])
        with self.assertRaisesRegex(RuntimeError, "inventory"):
            native.result_evidence(tree, summary, "platform=iOS Simulator,id=owned", ["missing"])
        with self.assertRaisesRegex(RuntimeError, "simulator"):
            native.result_evidence(tree, summary, "platform=iOS Simulator,id=other", [case])
        tree["testNodes"][0]["children"][0]["result"] = "Skipped"
        with self.assertRaisesRegex(RuntimeError, "failure, skip"):
            native.result_evidence(tree, summary, "platform=iOS Simulator,id=owned", [case])


if __name__ == "__main__":
    unittest.main()
