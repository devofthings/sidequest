"""Read-only proof that a main commit can inherit its reviewed PR's native tests."""

import importlib.util
import json
import math
from pathlib import Path
import re
import subprocess


class EvidenceError(Exception):
    pass


def require(condition):
    if not condition:
        raise EvidenceError("Incomplete or inconsistent inherited-test evidence")


def positive(value):
    require(not isinstance(value, bool) and re.fullmatch(r"[1-9][0-9]*", str(value)))
    return int(value)


def read_api(path):
    result = subprocess.run(["gh", "api", "--method", "GET", path],
                            capture_output=True, text=True, timeout=30, check=True)
    return json.loads(result.stdout)


def pages(api, path, key=None):
    items = []
    for page in range(1, 11):
        response = api(f"{path}?per_page=100&page={page}")
        batch = response[key] if key else response
        require(isinstance(batch, list))
        items.extend(batch)
        if len(batch) < 100:
            return items
    raise EvidenceError("Truncated evidence")


def identifiers(value):
    require(isinstance(value, list) and value and
            all(isinstance(item, str) and item.strip() == item and item for item in value))
    require(len(set(value)) == len(value))
    return set(value)


def validate_inventory(tests):
    require(tests["mode"] == "full")
    selected = identifiers(tests["selected"])
    inventory = identifiers(tests["inventory"])
    require(all(len(item.split("/")) == 3 for item in inventory))
    require("SidequestTests" in selected and any(
        item.startswith("SidequestTests/") for item in inventory))
    require(all(item == "SidequestTests" or
                (item.startswith("SidequestUITests/") and item in inventory)
                for item in selected))
    require(all(item.startswith("SidequestTests/") or item in selected for item in inventory))
    workers = tests["worker_inventory"]
    require(type(tests["workers"]) is int and tests["workers"] in (1, 2) and
            isinstance(workers, list) and len(workers) == tests["workers"])
    actual, planned, destinations = set(), set(), set()
    for worker in workers:
        cases = identifiers(worker["inventory"])
        choices = identifiers(worker["tests"])
        require(not actual.intersection(cases) and not planned.intersection(choices))
        require(type(worker["exit_code"]) is int and worker["exit_code"] == 0)
        require(type(worker["passed"]) is int and worker["passed"] == len(cases))
        require(type(worker["failed"]) is int and worker["failed"] == 0 and
                type(worker["skipped"]) is int and worker["skipped"] == 0)
        require(isinstance(worker["destination"], str) and
                worker["destination"].startswith("platform=iOS Simulator,id=") and
                worker["destination"] not in destinations)
        require(isinstance(worker["result_bundle"], str) and
                Path(worker["result_bundle"]).is_absolute())
        require(type(worker["test_seconds"]) in (int, float) and
                math.isfinite(worker["test_seconds"]) and worker["test_seconds"] > 0)
        require(all(case in choices or
                    (case.startswith("SidequestTests/") and "SidequestTests" in choices)
                    for case in cases))
        require(all(choice == "SidequestTests" or choice in cases for choice in choices))
        if "SidequestTests" in choices:
            require(any(case.startswith("SidequestTests/") for case in cases))
        actual.update(cases)
        planned.update(choices)
        destinations.add(worker["destination"])
    require(actual == inventory and planned == selected)


def committed_cases(git, head, target):
    cases = set()
    paths = git("ls-tree", "-r", "--name-only", "-z", head, "--", target).split("\0")
    for path in paths:
        if path.endswith(".swift"):
            body = git("show", f"{head}:{path}")
            classes = re.findall(r"final class (\w+): XCTestCase", body)
            require(len(classes) <= 1)
            if classes:
                cases.update(f"{target}/{classes[0]}/{name}"
                             for name in re.findall(r"func (test\w+)\(", body))
    require(bool(cases))
    return cases


def validate_committed_gate(git, head, base, tests):
    policy = json.loads(git("show", f"{head}:scripts/native-test-inventory.json"))
    active = policy["active_gate"]
    require(active in ("pre_design_smoke", "required") and tests["gate"] == active)
    ui = identifiers(policy[active])
    if active == "required":
        paths = git("diff", "--no-renames", "--name-only", "-z", base, head).split("\0")
        for case, rule in policy["extended"].items():
            if any(path.startswith(tuple(rule["paths"])) for path in paths if path):
                ui.add(case)
    require(ui.issubset(committed_cases(git, head, "SidequestUITests")))
    units = committed_cases(git, head, "SidequestTests")
    require(identifiers(tests["selected"]) == {"SidequestTests", *ui})
    require(identifiers(tests["inventory"]) == units | ui)
    return active


def resolve_inherited_tests(checkout, head, diagnostics_root, *,
                            repository="devofthings/sidequest",
                            runner_name="Sidequest-Mac-foreground", read_api=None):
    """Return original test provenance, or None to require fresh full verification.

    Every lookup is read-only. Receipt commands are never executed. Legacy,
    unavailable, failed, stale, or ambiguous evidence takes the full-test path.
    """
    try:
        return _resolve(Path(checkout), head, Path(diagnostics_root), repository,
                        runner_name, read_api or globals()["read_api"])
    except (EvidenceError, RuntimeError, OSError, ValueError, TypeError, KeyError, IndexError,
            subprocess.SubprocessError):
        return None


def _resolve(checkout, head, diagnostics_root, repository, runner_name, api):
    require(isinstance(head, str) and re.fullmatch(r"[0-9a-f]{40}", head))
    require(re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository))

    def git(*args):
        return subprocess.run(["git", *args], cwd=checkout, text=True,
                              capture_output=True, timeout=15, check=True).stdout.strip()

    require(git("rev-parse", "HEAD") == head)
    prefix = f"repos/{repository}"
    prs = pages(api, f"{prefix}/commits/{head}/pulls")
    matches = [pr for pr in prs if pr.get("merge_commit_sha") == head and pr.get("merged_at")]
    require(len(matches) == 1)
    pr = matches[0]
    number = positive(pr["number"])
    require(pr["state"] == "closed" and pr["base"]["ref"] == "main" and
            pr["head"]["repo"]["full_name"] == repository)
    original = pr["head"]["sha"]
    require(isinstance(original, str) and re.fullmatch(r"[0-9a-f]{40}", original))
    statuses = pages(api, f"{prefix}/commits/{original}/statuses")
    statuses = [status for status in statuses
                if status.get("context") == "Sidequest / independent review"]
    require(bool(statuses))
    status = max(statuses, key=lambda item: positive(item["id"]))
    require(status["state"] == "success")
    receipt_url = status["target_url"]
    match = re.fullmatch(rf"https://github\.com/{re.escape(repository)}/(?:pull|issues)/"
                         rf"{number}#issuecomment-([1-9][0-9]*)", receipt_url)
    require(match is not None)
    comment = api(f"{prefix}/issues/comments/{match[1]}")
    require(comment["issue_url"] == f"https://api.github.com/{prefix}/issues/{number}")
    require(comment["html_url"] == receipt_url)
    body = comment["body"]
    block = re.fullmatch(r"Sidequest gate receipt SHA-256: [0-9a-f]{64}\n\n"
                         r"Issue contribution: (?:complete|partial)\.\n\n```json\n(.*)\n```",
                         body, flags=re.DOTALL)
    require(block is not None)
    receipt = json.loads(block[1])
    spec = importlib.util.spec_from_file_location("sidequest_review_gate",
                                                Path(__file__).with_name("review-gate.py"))
    gate = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gate)
    try:
        gate.validate_receipt(receipt)
    except gate.GateError as error:
        raise EvidenceError(str(error)) from error
    require(body == gate.audit_body(receipt))
    require(receipt["pr"] == number and receipt["head"] == original and
            receipt["verification"]["mode"] == "ci")
    require(git("rev-list", "--parents", "-n", "1", head).split() == [head, receipt["base"]])
    tree = git("rev-parse", f"{head}^{{tree}}")
    require(tree == git("rev-parse", f"{original}^{{tree}}"))
    checks = pages(api, f"{prefix}/commits/{original}/check-runs", "check_runs")
    checks = [check for check in checks if check.get("name") == "Sidequest / verification"
              and check.get("app", {}).get("slug") == "github-actions"]
    require(bool(checks))
    check = max(checks, key=lambda item: positive(item["id"]))
    require(check["head_sha"] == original and check["status"] == "completed" and
            check["conclusion"] == "success")
    run_url = check["details_url"]
    require(receipt["verification"]["run_url"] == run_url)
    match = re.fullmatch(rf"https://github\.com/{re.escape(repository)}/actions/runs/"
                         r"([1-9][0-9]*)/job/([1-9][0-9]*)", run_url)
    require(match is not None)
    run_id, job_id = map(int, match.groups())
    check_id = positive(check["id"])
    run = api(f"{prefix}/actions/runs/{run_id}")
    job = api(f"{prefix}/actions/jobs/{job_id}")
    attempt, run_number = positive(run["run_attempt"]), positive(run["run_number"])
    require(positive(run["id"]) == run_id and run["event"] == "pull_request" and
            run["path"] == ".github/workflows/verification.yml" and
            run["repository"]["full_name"] == repository and
            run["head_repository"]["full_name"] == repository)
    for item in (run, job):
        require(item["head_sha"] == original and item["status"] == "completed" and
                item["conclusion"] == "success")
    require(positive(job["id"]) == job_id and positive(job["run_id"]) == run_id and
            positive(job["run_attempt"]) == attempt and job["runner_name"] == runner_name and
            job["name"] == "Sidequest / verification" and job["html_url"] == run_url and
            job["check_run_url"] == f"https://api.github.com/{prefix}/check-runs/{check_id}")
    manifest = json.loads((diagnostics_root / f"{run_id}-{attempt}" /
                           "verification.json").read_text())
    require(type(manifest["schema"]) is int and manifest["schema"] == 2 and
            manifest["commit"] == original and manifest["all_checks_passed"] is True and
            manifest["event"] == "pull_request" and manifest["ref"] == f"refs/pull/{number}/merge" and
            manifest["runner_name"] == runner_name and positive(manifest["run_id"]) == run_id and
            positive(manifest["attempt"]) == attempt and positive(manifest["run_number"]) == run_number)
    validate_inventory(manifest["tests"])
    gate = validate_committed_gate(git, head, receipt["base"], manifest["tests"])
    return {"mode": "inherited", "gate": gate, "original_head": original, "pr": number,
            "reviewed_base": receipt["base"], "run_id": run_id, "attempt": attempt,
            "run_url": run_url, "original_run_number": run_number,
            "inventory": manifest["tests"]["inventory"], "receipt_url": receipt_url,
            "tree": tree, "original_selected": manifest["tests"]["selected"],
            "original_workers": manifest["tests"]["workers"],
            "original_worker_inventory": manifest["tests"]["worker_inventory"]}
