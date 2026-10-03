#!/usr/bin/env python3
"""Deterministic merge-gate checks: temporary Git repos and fake GitHub only."""

import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("review_gate", Path(__file__).with_name("review-gate.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class FakeGitHub:
    def __init__(self, receipt):
        self.receipt = receipt
        self.calls = []
        self.comments = {}
        self.state = {
            "pr": {"state": "open", "draft": False, "mergeable": True,
                   "head": {"sha": receipt["head"], "ref": "codex/63-gates", "repo": {"full_name": gate.REPO}},
                   "base": {"sha": receipt["base"], "ref": "main", "repo": {"full_name": gate.REPO}},
                   "title": "Record a scoped decision", "body": "Closes #63"},
            "refs": {"head": receipt["head"], "base": receipt["base"]},
            "statuses": {}, "checks": [], "threads": [], "reviews": {}, "closing_issues": []}
        self.change_on_snapshot = None
        self.snapshot_count = 0

    def snapshot(self, number):
        self.snapshot_count += 1
        if self.change_on_snapshot == self.snapshot_count:
            self.state["refs"]["base"] = "f" * 40
        return copy.deepcopy(self.state)

    def issue(self, number):
        return {"state": "open"}

    def record(self, receipt):
        self.calls.append("record")
        url = f"https://github.com/{gate.REPO}/pull/63#issuecomment-123"
        self.comments[url] = {"body": gate.audit_body(receipt),
                              "issue_url": f"https://api.github.com/repos/{gate.REPO}/issues/63"}
        for context in (gate.REVIEW, gate.VERIFICATION):
            if context == gate.VERIFICATION and receipt["verification"]["mode"] == "ci":
                continue
            self.state["statuses"][context] = {"state": "success", "target_url": url}
        return url

    def audit(self, url):
        return self.comments[url]

    def merge(self, receipt):
        self.calls.append("merge")
        return "e" * 40


class GateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sidequest-gate-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        (self.root / "README.md").write_text("Before\n")
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        base = self.git("rev-parse", "HEAD")
        (self.root / "README.md").write_text("After\n")
        self.git("add", ".")
        self.git("commit", "-qm", "feature")
        head = self.git("rev-parse", "HEAD")
        self.receipt = {
            "schema": 1, "pr": 63, "issue": 63, "head": head, "base": base,
            "reviewer": "/root/fresh-reviewer", "contributors": ["/root/implementer"],
            "round": 1, "findings": [], "resolutions": [],
            "authorization": {"source": "User chat, October 3, 2026",
                              "decision": "User instructed: fix the gaps.",
                              "approved_scope": "Reproducible review-gate preparation only.",
                              "confirmed_by": "/root", "changed_paths": ["README.md"]},
            "verification": {"head": head, "base": base, "mode": "documentation",
                             "commands": [{"command": "git diff --check base...head",
                                           "exit_code": 0, "result": "No whitespace errors"}],
                             "unavailable_checks": ["No app target or CI exists."]}}
        self.github = FakeGitHub(self.receipt)

    def git(self, *args):
        return subprocess.run(["git", "-c", "core.hooksPath=/dev/null", *args], cwd=self.root, text=True,
                              capture_output=True, check=True).stdout.strip()

    def validate(self, **kwargs):
        return gate.validate(self.receipt, self.github, self.root, **kwargs)

    def blocked(self):
        calls_before = list(self.github.calls)
        with self.assertRaises(gate.GateError):
            self.validate()
        self.assertEqual(self.github.calls, calls_before)

    def test_default_is_read_only(self):
        result = gate.deliver(self.receipt, self.github, self.root)
        self.assertTrue(result["validated"])
        self.assertEqual(self.github.calls, [])

    def test_valid_record_then_merge(self):
        result = gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, ["record", "merge"])
        self.assertEqual(result["merged_commit"], "e" * 40)

    def test_changed_head_and_base(self):
        for target in ("head", "base"):
            with self.subTest(target=target):
                original = self.github.state["pr"][target]["sha"]
                self.github.state["pr"][target]["sha"] = "f" * 40
                self.blocked()
                self.github.state["pr"][target]["sha"] = original

    def test_live_refs_invalidate_unchanged_pr_metadata(self):
        for target in ("head", "base"):
            with self.subTest(target=target):
                original = self.github.state["refs"][target]
                self.github.state["refs"][target] = "f" * 40
                self.blocked()
                self.github.state["refs"][target] = original

    def test_race_before_record_leaves_no_mutation(self):
        self.github.change_on_snapshot = 2
        with self.assertRaises(gate.GateError):
            gate.deliver(self.receipt, self.github, self.root, record=True)
        self.assertEqual(self.github.calls, [])

    def test_race_after_record_prevents_merge(self):
        self.github.change_on_snapshot = 3
        with self.assertRaises(gate.GateError):
            gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, ["record"])

    def test_prohibited_pr_states_branches_and_conflicts(self):
        for field, value in (("state", "closed"), ("draft", True), ("mergeable", False), ("mergeable", None)):
            with self.subTest(field=field, value=value):
                old = self.github.state["pr"][field]
                self.github.state["pr"][field] = value
                self.blocked()
                self.github.state["pr"][field] = old
        for target, branch in (("head", "feature/foo"), ("head", "codex/99-wrong-issue"), ("base", "develop")):
            with self.subTest(branch=branch):
                old = self.github.state["pr"][target]["ref"]
                self.github.state["pr"][target]["ref"] = branch
                self.blocked()
                self.github.state["pr"][target]["ref"] = old

    def test_issue_association_required(self):
        self.github.state["pr"]["body"] = "Related #63"
        self.blocked()

    def test_valid_partial_issue_reference_is_read_only(self):
        self.receipt["issue_completion"] = "partial"
        for body in ("Refs #63", "Part of #63", "Related to #63",
                     f"Ref https://github.com/{gate.REPO}/issues/63",
                     "Refs devofthings/sidequest#63"):
            with self.subTest(body=body):
                self.github.state["pr"]["body"] = body
                result = gate.deliver(self.receipt, self.github, self.root)
                self.assertTrue(result["validated"])
                self.assertEqual(self.github.calls, [])

    def test_partial_issue_merge_records_partial_without_closing_parent(self):
        self.receipt["issue_completion"] = "partial"
        self.github.state["pr"]["body"] = "Refs #63; records a decision only."
        gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, ["record", "merge"])
        self.assertIn("Issue contribution: partial.", gate.audit_body(self.receipt))
        self.assertEqual(self.github.issue(63)["state"], "open")
        self.assertEqual(self.github.state["pr"]["body"], "Refs #63; records a decision only.")

    def test_invalid_partial_references_block_all_actions_before_writes(self):
        self.receipt["issue_completion"] = "partial"
        for body in ("", "Refs #64", "Refs #630", "Closes #63", "Refs #63. Closes #63",
                     f"Refs #63. Resolves https://github.com/{gate.REPO}/issues/63",
                     "Refs #63. Closes: #63", "Refs #63. CLOSES: #63",
                     "Refs #63. fixes devofthings/sidequest#63",
                     "Refs #63. RESOLVED:devofthings/sidequest#63"):
            for flags in ({}, {"record": True}, {"merge": True}, {"record": True, "merge": True}):
                with self.subTest(body=body, flags=flags):
                    self.github.state["pr"]["body"] = body
                    with self.assertRaises(gate.GateError):
                        gate.deliver(self.receipt, self.github, self.root, **flags)
                    self.assertEqual(self.github.calls, [])

    def test_partial_title_and_manual_closing_link_block_before_writes(self):
        self.receipt["issue_completion"] = "partial"
        self.github.state["pr"]["body"] = "Refs #63"
        for title, linked in (("Closes: #63", []), ("Record decision", [
                {"number": 63, "repository": {"nameWithOwner": gate.REPO}}])):
            for flags in ({}, {"record": True}, {"merge": True}, {"record": True, "merge": True}):
                with self.subTest(title=title, linked=linked, flags=flags):
                    self.github.state["pr"]["title"] = title
                    self.github.state["closing_issues"] = linked
                    with self.assertRaises(gate.GateError):
                        gate.deliver(self.receipt, self.github, self.root, **flags)
                    self.assertEqual(self.github.calls, [])

    def test_complete_supported_github_closing_syntax(self):
        for body in ("Closes: #63", "CLOSES: #63", "Fixed devofthings/sidequest#63",
                     "RESOLVED:devofthings/sidequest#63"):
            with self.subTest(body=body):
                self.github.state["pr"]["body"] = body
                self.validate()

    def test_invalid_completion_values_block_before_writes(self):
        for value in (None, True, 0, "", "Partial", "unknown", [], {}):
            with self.subTest(value=value):
                self.receipt["issue_completion"] = value
                with self.assertRaises(gate.GateError):
                    gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
                self.assertEqual(self.github.calls, [])

    def test_complete_and_legacy_receipts_require_closing_reference(self):
        for explicit in (False, True):
            with self.subTest(explicit=explicit):
                if explicit:
                    self.receipt["issue_completion"] = "complete"
                self.github.state["pr"]["body"] = "Refs #63"
                self.blocked()
                self.github.state["pr"]["body"] = "Closes #63"
                self.validate()
                self.assertIn("Issue contribution: complete.", gate.audit_body(self.receipt))

    def test_pending_or_failed_statuses_block(self):
        for state in ("pending", "failure", "error"):
            with self.subTest(state=state):
                self.github.state["statuses"]["Other gate"] = {"state": state}
                self.blocked()

    def test_pending_failed_skipped_checks_block(self):
        for status, conclusion in (("queued", None), ("in_progress", None), ("completed", "failure"), ("completed", "skipped")):
            with self.subTest(status=status, conclusion=conclusion):
                self.github.state["checks"] = [{"name": "Build", "status": status, "conclusion": conclusion}]
                self.blocked()

    def test_passing_other_checks_allowed(self):
        self.github.state["checks"] = [{"name": "Build", "status": "completed", "conclusion": "success"}]
        self.github.state["statuses"]["Other gate"] = {"state": "success"}
        self.validate()

    def test_review_threads_and_changes_requested_block(self):
        self.github.state["threads"] = [{"isResolved": False}]
        self.blocked()
        self.github.state["threads"] = []
        self.github.state["reviews"] = {"human": "CHANGES_REQUESTED"}
        self.blocked()

    def test_same_reviewer_or_findings_block(self):
        self.receipt["reviewer"] = self.receipt["contributors"][0]
        self.blocked()
        self.receipt["reviewer"] = "fresh"
        self.receipt["findings"] = ["Bug"]
        self.blocked()

    def test_malformed_receipt_and_failed_verification(self):
        cases = [("schema", True), ("schema", 2), ("pr", True), ("head", "abc"), ("contributors", []), ("round", 0)]
        for key, value in cases:
            with self.subTest(key=key):
                old = self.receipt[key]
                self.receipt[key] = value
                self.blocked()
                self.receipt[key] = old
        self.receipt["verification"]["commands"][0]["exit_code"] = 1
        self.blocked()
        self.receipt["verification"]["commands"][0]["exit_code"] = False
        self.blocked()

    def test_verification_target_mismatch(self):
        self.receipt["verification"]["base"] = "f" * 40
        self.blocked()

    def test_link_only_authorization_is_insufficient(self):
        self.receipt["authorization"]["decision"] = "https://github.com/devofthings/sidequest/issues/63"
        self.blocked()

    def test_complete_changed_paths_required(self):
        self.receipt["authorization"]["changed_paths"] = ["README.md", "unexpected.md"]
        self.blocked()

    def test_local_mode_explains_unavailable_checks(self):
        self.receipt["verification"]["unavailable_checks"] = []
        self.blocked()

    def test_missing_or_changed_published_audit_blocks_merge(self):
        with self.assertRaises(gate.GateError):
            gate.deliver(self.receipt, self.github, self.root, merge=True)
        url = self.github.record(self.receipt)
        self.github.comments[url]["body"] = "Different evidence"
        with self.assertRaises(gate.GateError):
            self.validate(recorded=True)
        self.assertNotIn("merge", self.github.calls)

    def test_ci_requires_matching_successful_run_and_head(self):
        verification = self.receipt["verification"]
        verification.update(mode="ci", run_url="https://github.com/example/run/1")
        self.blocked()
        check = {"name": gate.VERIFICATION, "status": "completed", "conclusion": "success",
                 "details_url": verification["run_url"], "head_sha": self.receipt["head"]}
        self.github.state["checks"] = [check]
        self.validate()
        self.github.record(self.receipt)
        self.assertNotIn(gate.VERIFICATION, self.github.state["statuses"])
        self.validate(recorded=True)
        check["head_sha"] = "f" * 40
        self.blocked()

    def test_documentation_mode_rejects_tooling_change(self):
        (self.root / "tool.py").write_text("pass\n")
        self.git("add", ".")
        self.git("commit", "-qm", "code")
        head = self.git("rev-parse", "HEAD")
        self.receipt["head"] = self.receipt["verification"]["head"] = head
        self.github.state["pr"]["head"]["sha"] = self.github.state["refs"]["head"] = head
        self.receipt["authorization"]["changed_paths"].append("tool.py")
        self.blocked()

    def application_fixture(self, path="Sidequest/App/Foundation.swift"):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("struct Foundation {}\n")
        self.git("add", ".")
        self.git("commit", "-qm", "app")
        head = self.git("rev-parse", "HEAD")
        self.receipt["head"] = self.receipt["verification"]["head"] = head
        self.github.state["pr"]["head"]["sha"] = self.github.state["refs"]["head"] = head
        self.receipt["authorization"]["changed_paths"].append(path)
        self.receipt["verification"].update(mode="application", environment={
            "xcode": "Xcode fixture", "project": "Sidequest.xcodeproj",
            "scheme": "Sidequest", "destination": "fixture simulator"})
        self.receipt["verification"]["commands"] = [
            {"check": check, "command": f"fixture {check}", "exit_code": 0, "result": "Observed pass"}
            for check in ("build", "tests", "format")]

    def test_local_application_records_and_merges_before_ci(self):
        self.application_fixture()
        result = gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, ["record", "merge"])
        self.assertEqual(result["merged_commit"], "e" * 40)

    def test_local_application_missing_or_failed_checks_do_not_write(self):
        self.application_fixture()
        original = copy.deepcopy(self.receipt["verification"]["commands"])
        for check in ("build", "tests", "format"):
            for failure in ("missing", "failed", "bad_exit"):
                with self.subTest(check=check, failure=failure):
                    commands = copy.deepcopy(original)
                    if failure == "missing":
                        commands = [item for item in commands if item["check"] != check]
                    else:
                        next(item for item in commands if item["check"] == check)["exit_code"] = 1 if failure == "failed" else False
                    self.receipt["verification"]["commands"] = commands
                    with self.assertRaises(gate.GateError):
                        gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
                    self.assertEqual(self.github.calls, [])

    def test_local_application_requires_environment_evidence(self):
        self.application_fixture()
        original = copy.deepcopy(self.receipt["verification"]["environment"])
        for field in ("xcode", "destination", "project", "scheme"):
            self.receipt["verification"]["environment"] = {k: v for k, v in original.items() if k != field}
            self.blocked()
        self.receipt["verification"]["environment"] = "invented"
        self.blocked()

    def test_local_application_rejects_unrelated_tooling(self):
        self.application_fixture("scripts/unrelated.py")
        with self.assertRaises(gate.GateError):
            gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, [])

    def test_local_application_cannot_bypass_workflow_verification(self):
        self.application_fixture(".github/workflows/ci.yml")
        with self.assertRaises(gate.GateError):
            gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, [])
        # Existing workflows also block application mode when the diff is ordinary app code.
        self.git("checkout", "--", ".github/workflows/ci.yml")
        base = self.receipt["head"]
        self.receipt["base"] = self.receipt["verification"]["base"] = base
        self.github.state["pr"]["base"]["sha"] = self.github.state["refs"]["base"] = base
        self.receipt["authorization"]["changed_paths"] = []
        self.application_fixture()
        with self.assertRaisesRegex(gate.GateError, "CI owns"):
            gate.deliver(self.receipt, self.github, self.root, record=True, merge=True)
        self.assertEqual(self.github.calls, [])

    def test_workflows_require_ci_mode(self):
        directory = self.root / ".github/workflows"
        directory.mkdir(parents=True)
        (directory / "ci.yml").write_text("name: Fixture\n")
        self.git("add", ".")
        self.git("commit", "-qm", "workflow")
        head = self.git("rev-parse", "HEAD")
        self.receipt["head"] = self.receipt["verification"]["head"] = head
        self.github.state["pr"]["head"]["sha"] = self.github.state["refs"]["head"] = head
        self.receipt["authorization"]["changed_paths"].append(".github/workflows/ci.yml")
        self.receipt["verification"]["mode"] = "tooling"
        self.blocked()

    def test_github_pages_fetches_beyond_first_hundred(self):
        github = gate.GitHub()
        paths = []
        def api(path):
            paths.append(path)
            return list(range(100)) if path.endswith("&page=1") else [100]
        github.api = api
        self.assertEqual(github.pages("fixture"), list(range(101)))
        self.assertEqual(len(paths), 2)

    def test_adapter_latest_statuses_checks_and_paginated_threads(self):
        github = gate.GitHub()
        cursor_requests = []
        def api(path, data=None):
            if path.endswith("/pulls/63"):
                return self.github.state["pr"]
            if "/git/ref/" in path:
                target = "base" if path.endswith("main") else "head"
                return {"object": {"sha": self.receipt[target]}}
            if path == "graphql":
                cursor = data["variables"]["cursor"]
                cursor_requests.append(cursor)
                return {"data": {"repository": {"pullRequest": {"closingIssuesReferences": {
                    "nodes": [], "pageInfo": {"hasNextPage": False}}, "reviewThreads": {
                    "nodes": [{"isResolved": cursor is None}],
                    "pageInfo": {"hasNextPage": cursor is None, "endCursor": "next"}}}}}}
            self.fail(path)
        def pages(path, key=None):
            if path.endswith("/statuses"):
                return [{"id": 1, "context": "Build", "state": "failure"},
                        {"id": 2, "context": "Build", "state": "success"}]
            if path.endswith("/check-runs"):
                return [{"id": 1, "app": {"id": 9}, "name": "Build", "conclusion": "failure"},
                        {"id": 2, "app": {"id": 9}, "name": "Build", "conclusion": "success"}]
            return [{"id": 2, "user": {"login": "fixture"}, "state": "APPROVED"},
                    {"id": 1, "user": {"login": "fixture"}, "state": "CHANGES_REQUESTED"}]
        github.api, github.pages = api, pages
        snapshot = github.snapshot(63)
        self.assertEqual(snapshot["statuses"]["Build"]["state"], "success")
        self.assertEqual(len(snapshot["checks"]), 1)
        self.assertEqual(snapshot["checks"][0]["conclusion"], "success")
        self.assertEqual(snapshot["reviews"], {"fixture": "APPROVED"})
        self.assertEqual(cursor_requests, [None, "next"])
        self.assertEqual(snapshot["threads"], [{"isResolved": True}, {"isResolved": False}])

    def test_unsubmitted_review_preserves_previous_change_request(self):
        github = gate.GitHub()
        mutations = []
        def api(path, data=None):
            if path.endswith("/pulls/63"):
                return self.github.state["pr"]
            if path.endswith("/issues/63"):
                return {"state": "open"}
            if "/git/ref/" in path:
                target = "base" if path.endswith("main") else "head"
                return {"object": {"sha": self.receipt[target]}}
            if path == "graphql":
                return {"data": {"repository": {"pullRequest": {"closingIssuesReferences": {
                    "nodes": [], "pageInfo": {"hasNextPage": False}}, "reviewThreads": {
                    "nodes": [], "pageInfo": {"hasNextPage": False, "endCursor": None}}}}}}
            self.fail(path)
        def pages(path, key=None):
            if path.endswith("/reviews"):
                return [{"id": 1, "user": {"login": "fixture"}, "state": "CHANGES_REQUESTED"},
                        {"id": 2, "user": {"login": "fixture"}, "state": "PENDING"}]
            return []
        github.api, github.pages = api, pages
        github.record = lambda receipt: mutations.append("record")
        github.merge = lambda receipt: mutations.append("merge")
        self.assertEqual(github.snapshot(63)["reviews"], {"fixture": "CHANGES_REQUESTED"})
        for flags in ({}, {"record": True}, {"record": True, "merge": True}, {"merge": True}):
            with self.subTest(flags=flags):
                with self.assertRaisesRegex(gate.GateError, "requests changes"):
                    gate.deliver(self.receipt, github, self.root, **flags)
                self.assertEqual(mutations, [])

    def test_real_record_adapter_never_overwrites_ci_verification(self):
        github = gate.GitHub()
        writes = []
        def api(path, data=None):
            writes.append((path, data))
            return {"html_url": "https://github.com/devofthings/sidequest/pull/63#issuecomment-1"}
        github.api = api
        self.receipt["verification"]["mode"] = "ci"
        github.record(self.receipt)
        self.assertEqual(len(writes), 2)
        self.assertEqual(writes[1][1]["context"], gate.REVIEW)
        self.assertEqual(writes[0][1]["body"], gate.audit_body(self.receipt))

    def test_whitespace_case_identity_cannot_self_certify(self):
        self.receipt["reviewer"] = " /ROOT/IMPLEMENTER "
        self.blocked()

    def test_github_adapter_merge_pins_head_without_bypass(self):
        commands = []
        original = gate.run
        gate.run = lambda args, **kwargs: commands.append(args) or ""
        self.addCleanup(setattr, gate, "run", original)
        github = gate.GitHub()
        responses = [{"merged": True, "merge_commit_sha": "e" * 40},
                     {"parents": [{"sha": self.receipt["base"]}]}]
        github.api = lambda *args: responses.pop(0)
        self.assertEqual(github.merge(self.receipt), "e" * 40)
        self.assertEqual(commands, [["gh", "pr", "merge", "63", "--repo", gate.REPO,
                                     "--squash", "--match-head-commit", self.receipt["head"]]])

    def test_partial_squash_uses_safe_title_and_empty_body(self):
        self.receipt["issue_completion"] = "partial"
        commands = []
        original = gate.run
        gate.run = lambda args, **kwargs: commands.append(args) or ""
        self.addCleanup(setattr, gate, "run", original)
        github = gate.GitHub()
        responses = [{"title": "Record scoped decision"},
                     {"merged": True, "merge_commit_sha": "e" * 40},
                     {"parents": [{"sha": self.receipt["base"]}]}]
        github.api = lambda *args: responses.pop(0)
        github.merge(self.receipt)
        self.assertEqual(commands[0][-4:], ["--subject", "Record scoped decision", "--body", ""])
        self.assertIn(self.receipt["head"], commands[0])

    def test_partial_squash_rechecks_title_before_merge(self):
        self.receipt["issue_completion"] = "partial"
        commands = []
        original = gate.run
        gate.run = lambda args, **kwargs: commands.append(args) or ""
        self.addCleanup(setattr, gate, "run", original)
        github = gate.GitHub()
        github.api = lambda *args: {"title": "CLOSES: #63"}
        with self.assertRaises(gate.GateError):
            github.merge(self.receipt)
        self.assertEqual(commands, [])

    def test_merge_outcome_detects_base_race(self):
        original = gate.run
        gate.run = lambda *args, **kwargs: ""
        self.addCleanup(setattr, gate, "run", original)
        github = gate.GitHub()
        responses = [{"merged": True, "merge_commit_sha": "e" * 40},
                     {"parents": [{"sha": "f" * 40}]}]
        github.api = lambda *args: responses.pop(0)
        with self.assertRaisesRegex(gate.GateError, "base changed"):
            github.merge(self.receipt)


if __name__ == "__main__":
    unittest.main()
