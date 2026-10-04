#!/usr/bin/env python3
"""Offline inherited-test regressions using real disposable Git histories."""

import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from verification_provenance import resolve_inherited_tests

spec = importlib.util.spec_from_file_location("gate", Path(__file__).with_name("review-gate.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class ProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git("init", "-q")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        (self.root / "source").write_text("base")
        self.git("add", "source")
        self.git("commit", "-qm", "base")
        self.base = self.git("rev-parse", "HEAD")
        (self.root / "source").write_text("reviewed")
        self.git("commit", "-qam", "feature")
        self.original = self.git("rev-parse", "HEAD")
        self.git("reset", "--soft", self.base)
        self.git("commit", "-qm", "squashed main")
        self.head = self.git("rev-parse", "HEAD")
        self.prefix = "repos/devofthings/sidequest"
        self.url = "https://github.com/devofthings/sidequest/actions/runs/100/job/200"
        self.comment_url = "https://github.com/devofthings/sidequest/pull/90#issuecomment-300"
        self.receipt = {
            "schema": 1, "pr": 90, "issue": 90, "head": self.original, "base": self.base,
            "reviewer": "fresh-reviewer", "contributors": ["author"], "findings": [],
            "round": 1, "resolutions": [], "authorization": {
                "source": "Owner instruction", "decision": "Fix testing first",
                "approved_scope": "Testing", "confirmed_by": "owner", "changed_paths": ["source"]},
            "verification": {"head": self.original, "base": self.base, "mode": "ci",
                             "run_url": self.url, "unavailable_checks": [],
                             "commands": [{"command": "ci-verify", "result": "Passed", "exit_code": 0}]}}
        self.data = {
            f"{self.prefix}/commits/{self.head}/pulls": [{
                "number": 90, "state": "closed", "merged_at": "2026-10-04T00:00:00Z",
                "merge_commit_sha": self.head, "head": {"sha": self.original,
                "repo": {"full_name": "devofthings/sidequest"}},
                "base": {"ref": "main", "sha": self.head}}],
            f"{self.prefix}/commits/{self.original}/statuses": [{"id": 1,
                "context": "Sidequest / independent review", "state": "success",
                "target_url": self.comment_url}],
            f"{self.prefix}/issues/comments/300": {
                "issue_url": f"https://api.github.com/{self.prefix}/issues/90",
                "html_url": self.comment_url, "body": gate.audit_body(self.receipt)},
            f"{self.prefix}/commits/{self.original}/check-runs": {"check_runs": [{
                "id": 200, "name": "Sidequest / verification", "head_sha": self.original,
                "app": {"slug": "github-actions"}, "status": "completed",
                "conclusion": "success", "details_url": self.url}]},
            f"{self.prefix}/actions/runs/100": {
                "id": 100, "run_attempt": 1, "run_number": 7, "event": "pull_request",
                "path": ".github/workflows/verification.yml", "head_sha": self.original,
                "status": "completed", "conclusion": "success",
                "repository": {"full_name": "devofthings/sidequest"},
                "head_repository": {"full_name": "devofthings/sidequest"}},
            f"{self.prefix}/actions/jobs/200": {
                "id": 200, "run_id": 100, "run_attempt": 1,
                "name": "Sidequest / verification", "head_sha": self.original,
                "status": "completed", "conclusion": "success",
                "runner_name": "Sidequest-Mac-foreground", "html_url": self.url,
                "check_run_url": f"https://api.github.com/{self.prefix}/check-runs/200"}}
        inventory = ["SidequestTests/Rules/testRules", "SidequestUITests/Feed/testTap"]
        selected = ["SidequestTests", inventory[1]]
        self.manifest = {
            "schema": 2, "commit": self.original, "run_id": "100", "attempt": "1",
            "run_number": "7", "event": "pull_request", "ref": "refs/pull/90/merge",
            "runner_name": "Sidequest-Mac-foreground", "all_checks_passed": True,
            "tests": {"mode": "full", "inventory": inventory, "selected": selected,
                "workers": 1, "worker_inventory": [{"destination": "platform=iOS Simulator,id=fixture",
                    "inventory": inventory, "tests": selected, "exit_code": 0, "passed": 2,
                    "failed": 0, "skipped": 0, "result_bundle": "/tmp/fixture.xcresult",
                    "test_seconds": 1.5}]}}

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, text=True,
                              capture_output=True, check=True).stdout.strip()

    def resolve(self):
        folder = self.root / "diagnostics" / "100-1"
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "verification.json").write_text(json.dumps(self.manifest))
        return resolve_inherited_tests(self.root, self.head, self.root / "diagnostics",
                                       read_api=lambda path: copy.deepcopy(self.data[path.split("?")[0]]))

    def test_valid_squash_uses_historical_base_and_original_inventory(self):
        evidence = self.resolve()
        self.assertEqual(evidence["reviewed_base"], self.base)
        self.assertEqual(evidence["original_head"], self.original)
        self.assertEqual(evidence["inventory"], self.manifest["tests"]["inventory"])
        self.assertEqual(evidence["run_url"], self.url)

    def test_evidence_mutations_require_full_verification(self):
        mutations = [
            ("receipt checksum", lambda: self.data[f"{self.prefix}/issues/comments/300"].update(body=gate.audit_body(self.receipt) + "\n")),
            ("reviewer independence", lambda: self.receipt.update(reviewer="author")),
            ("wrong historical base", lambda: self.receipt.update(base=self.head)),
            ("new pending review", lambda: self.data[f"{self.prefix}/commits/{self.original}/statuses"].append({"id": 2, "context": "Sidequest / independent review", "state": "pending"})),
            ("ambiguous PR", lambda: self.data[f"{self.prefix}/commits/{self.head}/pulls"].append(copy.deepcopy(self.data[f"{self.prefix}/commits/{self.head}/pulls"][0]))),
            ("failed latest check", lambda: self.data[f"{self.prefix}/commits/{self.original}/check-runs"]["check_runs"][0].update(conclusion="failure")),
            ("rerun stale", lambda: self.data[f"{self.prefix}/actions/runs/100"].update(run_attempt=2)),
            ("wrong workflow", lambda: self.data[f"{self.prefix}/actions/runs/100"].update(path=".github/workflows/other.yml")),
            ("wrong runner", lambda: self.data[f"{self.prefix}/actions/jobs/200"].update(runner_name="other")),
            ("wrong head", lambda: self.data[f"{self.prefix}/actions/jobs/200"].update(head_sha=self.head)),
            ("legacy manifest", lambda: self.manifest.update(schema=1)),
            ("transitive inheritance", lambda: self.manifest["tests"].update(mode="inherited")),
            ("missing selected case", lambda: self.manifest["tests"]["selected"].append("SidequestUITests/Feed/testMissing")),
            ("duplicate inventory", lambda: self.manifest["tests"]["inventory"].append(self.manifest["tests"]["inventory"][0])),
            ("worker failures", lambda: self.manifest["tests"]["worker_inventory"][0].update(failed=1)),
            ("worker count mismatch", lambda: self.manifest["tests"].update(workers=2)),
            ("false pass", lambda: self.manifest.update(all_checks_passed=False)),
            ("API unavailable", lambda: self.data.clear())]
        baseline = copy.deepcopy((self.data, self.receipt, self.manifest))
        for name, mutate in mutations:
            with self.subTest(name=name):
                self.data, self.receipt, self.manifest = copy.deepcopy(baseline)
                mutate()
                if name in ("reviewer independence", "wrong historical base"):
                    self.data[f"{self.prefix}/issues/comments/300"]["body"] = gate.audit_body(self.receipt)
                self.assertIsNone(self.resolve())

    def test_two_disjoint_workers_preserve_original_cases(self):
        tests = self.manifest["tests"]
        first = tests["worker_inventory"][0]
        second = copy.deepcopy(first)
        first.update(tests=["SidequestTests"], inventory=[tests["inventory"][0]], passed=1)
        second.update(destination="platform=iOS Simulator,id=second",
                      tests=[tests["selected"][1]], inventory=[tests["inventory"][1]], passed=1)
        tests.update(workers=2, worker_inventory=[first, second])
        self.assertEqual(self.resolve()["original_workers"], 2)
        second.update(inventory=first["inventory"])
        self.assertIsNone(self.resolve())

    def test_job_and_check_have_independent_linked_identities(self):
        self.data[f"{self.prefix}/commits/{self.original}/check-runs"]["check_runs"][0]["id"] = 250
        self.data[f"{self.prefix}/actions/jobs/200"]["check_run_url"] = f"https://api.github.com/{self.prefix}/check-runs/250"
        self.assertIsNotNone(self.resolve())
        self.data[f"{self.prefix}/actions/jobs/200"]["check_run_url"] = f"https://api.github.com/{self.prefix}/check-runs/251"
        self.assertIsNone(self.resolve())

    def test_injected_api_failure_uses_full_fallback(self):
        def unavailable(path):
            raise RuntimeError("Read API unavailable")
        self.assertIsNone(resolve_inherited_tests(self.root, self.head, self.root / "diagnostics",
                                                 read_api=unavailable))

    def test_equal_tree_with_wrong_parent_requires_full_verification(self):
        self.git("commit", "--allow-empty", "-qm", "extra main parent")
        new_head = self.git("rev-parse", "HEAD")
        self.data[f"{self.prefix}/commits/{new_head}/pulls"] = self.data.pop(f"{self.prefix}/commits/{self.head}/pulls")
        self.head = new_head
        self.data[f"{self.prefix}/commits/{self.head}/pulls"][0]["merge_commit_sha"] = self.head
        self.assertIsNone(self.resolve())

    def test_changed_main_tree_requires_full_verification(self):
        (self.root / "source").write_text("unreviewed")
        self.git("commit", "-qam", "different main")
        self.git("reset", "--soft", self.base)
        self.git("commit", "-qm", "different squash tree")
        new_head = self.git("rev-parse", "HEAD")
        self.data[f"{self.prefix}/commits/{new_head}/pulls"] = self.data.pop(f"{self.prefix}/commits/{self.head}/pulls")
        self.head = new_head
        self.data[f"{self.prefix}/commits/{self.head}/pulls"][0]["merge_commit_sha"] = self.head
        self.assertIsNone(self.resolve())

    def test_dirty_checkout_head_or_missing_objects_requires_full_verification(self):
        self.git("checkout", "-q", self.base)
        self.assertIsNone(self.resolve())


if __name__ == "__main__":
    unittest.main()
