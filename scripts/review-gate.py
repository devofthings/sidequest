#!/usr/bin/env python3
"""Validate commit-bound review evidence; mutate GitHub only with explicit flags."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import quote

REPO = "devofthings/sidequest"
REVIEW = "Sidequest / independent review"
VERIFICATION = "Sidequest / verification"


class GateError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise GateError(message)


def run(args, *, cwd=None, payload=None):
    completed = subprocess.run(args, cwd=cwd, input=payload, text=True,
                               capture_output=True, check=False)
    require(completed.returncode == 0,
            f"Command failed: {args[0]}: {completed.stderr.strip()}")
    return completed.stdout.strip()


def text_field(value, name):
    require(isinstance(value, str) and bool(value.strip()), f"Missing {name}")
    return value


def validate_receipt(receipt):
    require(isinstance(receipt, dict), "Receipt must be an object")
    require(type(receipt.get("schema")) is int and receipt["schema"] == 1, "Unsupported receipt schema")
    for name in ("pr", "issue"):
        require(type(receipt.get(name)) is int and receipt[name] > 0,
                f"Invalid {name} number")
    require(receipt.get("issue_completion", "complete") in ("complete", "partial"),
            "Issue completion must be complete or partial")
    for name in ("head", "base"):
        require(isinstance(receipt.get(name), str) and
                re.fullmatch(r"[0-9a-f]{40}", receipt[name]), f"Invalid {name} SHA")
    reviewer = text_field(receipt.get("reviewer"), "reviewer")
    contributors = receipt.get("contributors")
    require(isinstance(contributors, list) and contributors,
            "List every implementing and fixing agent in contributors")
    for contributor in contributors:
        text_field(contributor, "contributor identity")
    require(reviewer.strip().casefold() not in {item.strip().casefold() for item in contributors}, "Reviewer implemented or fixed the change")
    require(receipt.get("findings") == [], "Review has unresolved findings")
    require(type(receipt.get("round")) is int and receipt["round"] > 0,
            "Missing review round")
    require(isinstance(receipt.get("resolutions"), list), "Missing resolutions")
    for resolution in receipt["resolutions"]:
        text_field(resolution, "finding resolution")
    scope = receipt.get("authorization")
    require(isinstance(scope, dict), "Missing authorization evidence")
    for name in ("source", "decision", "approved_scope", "confirmed_by"):
        text_field(scope.get(name), f"authorization.{name}")
    require(not re.fullmatch(r"https?://\S+", scope["decision"].strip()),
            "Authorization needs the decision, not a link alone")
    paths = scope.get("changed_paths")
    require(isinstance(paths, list) and paths and all(
        isinstance(path, str) and path and not path.startswith("/") and
        ".." not in path.split("/") for path in paths), "Invalid authorized paths")
    verification = receipt.get("verification")
    require(isinstance(verification, dict), "Missing verification")
    require(verification.get("head") == receipt["head"] and
            verification.get("base") == receipt["base"], "Verification target differs")
    require(verification.get("mode") in ("documentation", "tooling", "application", "ci"),
            "Invalid verification mode")
    commands = verification.get("commands")
    require(isinstance(commands, list) and commands, "Missing actual command results")
    for command in commands:
        require(isinstance(command, dict), "Malformed command result")
        text_field(command.get("command"), "verification command")
        text_field(command.get("result"), "verification result")
        require(type(command.get("exit_code")) is int and command["exit_code"] == 0,
                "Verification command failed or lacks an exit code")
    require(isinstance(verification.get("unavailable_checks"), list),
            "List unavailable checks explicitly")
    for unavailable in verification["unavailable_checks"]:
        text_field(unavailable, "unavailable check and reason")
    if verification["mode"] == "application":
        environment = verification.get("environment")
        require(isinstance(environment, dict), "Missing local app verification environment")
        for name in ("xcode", "destination", "project", "scheme"):
            text_field(environment.get(name), f"verification.environment.{name}")
        require({"build", "tests", "format"}.issubset(
            {command.get("check") for command in commands if isinstance(command.get("check"), str)}),
            "Local app verification requires successful build, tests, and strict format evidence")
    if verification["mode"] == "ci":
        text_field(verification.get("run_url"), "CI run URL")


def audit_body(receipt):
    data = json.dumps(receipt, sort_keys=True, indent=2)
    digest = hashlib.sha256(data.encode()).hexdigest()
    completion = receipt.get("issue_completion", "complete")
    return f"Sidequest gate receipt SHA-256: {digest}\n\nIssue contribution: {completion}.\n\n```json\n{data}\n```"


class GitHub:
    def api(self, path, data=None):
        args = ["gh", "api", path]
        if data is not None:
            args += ["--method", "POST", "--input", "-"]
        return json.loads(run(args, payload=json.dumps(data) if data is not None else None))

    def pages(self, path, key=None):
        items = []
        page = 1
        while True:
            separator = "&" if "?" in path else "?"
            response = self.api(f"{path}{separator}per_page=100&page={page}")
            batch = response[key] if key else response
            items.extend(batch)
            if len(batch) < 100:
                return items
            page += 1

    def snapshot(self, number):
        pr = self.api(f"repos/{REPO}/pulls/{number}")
        head = pr["head"]["sha"]
        refs = {}
        for kind in ("head", "base"):
            branch = quote(pr[kind]["ref"], safe="")
            refs[kind] = self.api(f"repos/{REPO}/git/ref/heads/{branch}")["object"]["sha"]
        statuses = self.pages(f"repos/{REPO}/commits/{head}/statuses")
        latest = {}
        for status in sorted(statuses, key=lambda item: item["id"], reverse=True):
            latest.setdefault(status["context"], status)
        runs = self.pages(f"repos/{REPO}/commits/{head}/check-runs", "check_runs")
        latest_runs = {}
        for check in sorted(runs, key=lambda item: item["id"], reverse=True):
            latest_runs.setdefault((check["app"]["id"], check["name"]), check)
        checks = list(latest_runs.values())
        reviews = self.pages(f"repos/{REPO}/pulls/{number}/reviews")
        latest_reviews = {}
        for review in sorted(reviews, key=lambda item: item["id"]):
            # An unsubmitted draft leaves the last submitted decision in force.
            if review["state"] not in ("COMMENTED", "PENDING"):
                latest_reviews[review["user"]["login"]] = review["state"]
        threads = []
        closing_issues = []
        cursor = None
        while True:
            query = """query($number:Int!,$cursor:String){repository(owner:"devofthings",name:"sidequest"){
              pullRequest(number:$number){closingIssuesReferences(first:100){
                nodes{number repository{nameWithOwner}} pageInfo{hasNextPage}}
                reviewThreads(first:100,after:$cursor){
                nodes{isResolved} pageInfo{hasNextPage endCursor}}}}}"""
            response = self.api("graphql", {"query": query, "variables": {
                "number": number, "cursor": cursor}})
            require(not response.get("errors"), "Review-thread lookup failed")
            metadata = response["data"]["repository"]["pullRequest"]
            linked = metadata["closingIssuesReferences"]
            require(not linked["pageInfo"]["hasNextPage"], "Closing-issue metadata is truncated")
            closing_issues = linked["nodes"]
            connection = metadata["reviewThreads"]
            threads.extend(connection["nodes"])
            if not connection["pageInfo"]["hasNextPage"]:
                break
            cursor = connection["pageInfo"]["endCursor"]
        return {"pr": pr, "refs": refs, "statuses": latest, "checks": checks,
                "reviews": latest_reviews, "threads": threads, "closing_issues": closing_issues}

    def issue(self, number):
        return self.api(f"repos/{REPO}/issues/{number}")

    def record(self, receipt):
        comment = self.api(f"repos/{REPO}/issues/{receipt['pr']}/comments",
                           {"body": audit_body(receipt)})
        for context in (REVIEW, VERIFICATION):
            if context == VERIFICATION and receipt["verification"]["mode"] == "ci":
                continue  # CI owns its gate; local agents never overwrite it.
            self.api(f"repos/{REPO}/statuses/{receipt['head']}", {
                "state": "success", "context": context,
                "description": "Exact head/base evidence in linked gate receipt",
                "target_url": comment["html_url"]})
        return comment["html_url"]

    def audit(self, url):
        match = re.fullmatch(r"https://github.com/devofthings/sidequest/issues/\d+#issuecomment-(\d+)", url)
        # GitHub also returns PR URLs for comments on pull requests.
        if match is None:
            match = re.fullmatch(r"https://github.com/devofthings/sidequest/pull/\d+#issuecomment-(\d+)", url)
        require(match is not None, "Gate status lacks a repository audit comment")
        return self.api(f"repos/{REPO}/issues/comments/{match[1]}")

    def merge(self, receipt):
        args = ["gh", "pr", "merge", str(receipt["pr"]), "--repo", REPO,
                "--squash", "--match-head-commit", receipt["head"]]
        if receipt.get("issue_completion", "complete") == "partial":
            pr = self.api(f"repos/{REPO}/pulls/{receipt['pr']}")
            title = text_field(pr.get("title"), "partial PR title")
            require(not re.search(closing_pattern(receipt["issue"]), title),
                    "Partial PR title must not close the originating issue")
            # Default squash text can copy closing keywords from feature commits.
            args += ["--subject", title, "--body", ""]
        run(args)
        pr = self.api(f"repos/{REPO}/pulls/{receipt['pr']}")
        require(pr.get("merged") is True, "Merge command did not produce a verified merge")
        commit = self.api(f"repos/{REPO}/git/commits/{pr['merge_commit_sha']}")
        require([parent["sha"] for parent in commit["parents"]] == [receipt["base"]],
                "Merged base changed during the API race; checkpoint and audit the merge")
        return pr["merge_commit_sha"]


def issue_target(number):
    return rf"(?:https://github\.com/{re.escape(REPO)}/issues/|(?:{re.escape(REPO)})?#){number}\b"


def closing_pattern(number):
    return rf"(?i)\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)(?:\s*:\s*|\s+){issue_target(number)}"


def validate(receipt, github, checkout, *, recorded=False):
    validate_receipt(receipt)
    snapshot = github.snapshot(receipt["pr"])
    pr = snapshot["pr"]
    require(pr["state"] == "open" and not pr["draft"], "PR must be open and non-draft")
    require(pr["base"]["ref"] == "main", "PR must target main")
    require(pr["head"]["repo"]["full_name"] == REPO and
            pr["base"]["repo"]["full_name"] == REPO, "Forks or other repositories are unsupported")
    require(pr["head"]["ref"].startswith(f"codex/{receipt['issue']}-"),
            "Feature branch must identify the originating issue")
    require((pr["head"]["sha"], pr["base"]["sha"]) == (receipt["head"], receipt["base"]) and
            snapshot["refs"] == {"head": receipt["head"], "base": receipt["base"]},
            "Head or base changed; obtain a fresh review and verification")
    require(pr.get("mergeable") is True, "Mergeability is conflicting or still unknown; retry later")
    issue = github.issue(receipt["issue"])
    require("pull_request" not in issue and issue["state"] == "open", "Originating issue is not open")
    closing = closing_pattern(receipt["issue"])
    body = pr.get("body") or ""
    if receipt.get("issue_completion", "complete") == "partial":
        reference = rf"(?i)\b(?:refs?|related\s+to|part\s+of)\s+{issue_target(receipt['issue'])}"
        require(re.search(reference, body), "Partial PR must explicitly reference the originating issue")
        require(not re.search(closing, body) and not re.search(closing, pr.get("title") or ""),
                "Partial PR must not close the originating issue")
        require(not any(item["number"] == receipt["issue"] and
                        item["repository"]["nameWithOwner"].casefold() == REPO.casefold()
                        for item in snapshot["closing_issues"]),
                "Partial PR must not have a closing link to the originating issue")
    else:
        require(re.search(closing, body), "PR must close the originating issue")
    require(not any(not thread["isResolved"] for thread in snapshot["threads"]),
            "GitHub review threads remain unresolved")
    require("CHANGES_REQUESTED" not in snapshot["reviews"].values(),
            "GitHub review requests changes")
    mode = receipt["verification"]["mode"]
    for context, status in snapshot["statuses"].items():
        if context == REVIEW or (context == VERIFICATION and mode != "ci"):
            continue
        require(status["state"] == "success", f"Status is not passing: {context}")
    for check in snapshot["checks"]:
        require(check["status"] == "completed" and check["conclusion"] == "success",
                f"Check is not passing: {check['name']}")
    if mode == "ci":
        require(any(check["name"] == VERIFICATION and
                    check.get("details_url") == receipt["verification"]["run_url"] and
                    check.get("head_sha") == receipt["head"]
                    for check in snapshot["checks"]),
                "CI verification must identify its successful run and reviewed head")
    git = lambda *args: run(["git", *args], cwd=checkout)
    git("merge-base", "--is-ancestor", receipt["base"], receipt["head"])
    git("diff", "--check", receipt["base"] + "..." + receipt["head"])
    changed = set(git("diff", "--name-only", "-z", receipt["base"] + "..." + receipt["head"]).split("\0")) - {""}
    require(changed and changed == set(receipt["authorization"]["changed_paths"]),
            "Authorization paths differ from the complete current diff")
    if mode == "documentation":
        require(all(path.endswith(".md") for path in changed),
                "Documentation verification cannot cover code or configuration")
    elif mode == "tooling":
        require(all(path.endswith(".md") or path.startswith(("scripts/", ".githooks/")) or
                    path == ".swift-format" for path in changed),
                "Tooling verification cannot cover application changes")
    elif mode == "application":
        require(all(path.endswith(".md") or path.startswith(("Sidequest/", "SidequestTests/",
                    "SidequestUITests/", "Sidequest.xcodeproj/")) or
                    path in (".gitignore", ".swift-format", "scripts/verify-source-discovery.py") for path in changed),
                "Local app verification cannot cover unrelated tooling or workflow changes")
        if "scripts/verify-source-discovery.py" in changed:
            require(any(command.get("check") == "source-discovery"
                        for command in receipt["verification"]["commands"]),
                    "Changed discovery verifier requires successful source-discovery evidence")
    files = git("ls-tree", "-r", "--name-only", receipt["head"]).splitlines()
    if any(path.startswith(".github/workflows/") for path in files):
        require(mode == "ci", "CI owns verification when workflows exist")
    if mode != "ci":
        require(receipt["verification"]["unavailable_checks"],
                "Local evidence must explicitly explain unavailable app/CI checks")
    if recorded:
        contexts = [REVIEW] + ([VERIFICATION] if mode != "ci" else [])
        for context in contexts:
            status = snapshot["statuses"].get(context, {})
            require(status.get("state") == "success", f"Missing recorded gate: {context}")
            comment = github.audit(status.get("target_url", ""))
            require(comment["body"] == audit_body(receipt) and
                    comment["issue_url"].endswith(f"/issues/{receipt['pr']}"),
                    "Published audit differs from this receipt or belongs to another PR")
    return snapshot


def deliver(receipt, github, checkout, *, record=False, merge=False):
    validate(receipt, github, checkout)
    audit = None
    if record:
        # A second live check before writes reduces the snapshot-to-mutation window.
        validate(receipt, github, checkout)
        audit = github.record(receipt)
    if merge:
        validate(receipt, github, checkout, recorded=True)
        return {"merged_commit": github.merge(receipt), "audit": audit}
    return {"validated": True, "head": receipt["head"], "base": receipt["base"], "audit": audit}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path, help="Target-bound independent-review JSON receipt")
    parser.add_argument("--checkout", type=Path, default=Path.cwd(), help="Checkout containing reviewed Git objects")
    parser.add_argument("--record", action="store_true", help="Publish audit and local gates after validation")
    parser.add_argument("--merge", action="store_true", help="Revalidate recorded gates, then squash with head pinned")
    args = parser.parse_args()
    try:
        receipt = json.loads(args.receipt.read_text())
        result = deliver(receipt, GitHub(), args.checkout, record=args.record, merge=args.merge)
        print(json.dumps(result, indent=2))
    except (GateError, OSError, ValueError, KeyError, TypeError) as error:
        print(f"Gate blocked: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
