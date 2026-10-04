"""Owned native test execution with incremental compilation and explicit coverage selection."""

from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
import fcntl
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

SETTINGS = ["CODE_SIGNING_ALLOWED=NO"]
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-27-0"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro"


@contextmanager
def owned_execution():
    """Serialize native jobs on this Mac; only one owner may create worker devices."""
    with Path("/private/tmp/sidequest-native-execution.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Another Sidequest native job owns this Mac.") from None
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def inventory(root):
    """Every UI case must be classified; new cases cannot silently disappear from CI."""
    policy = json.loads((root / "scripts/native-test-inventory.json").read_text())
    actual = set()
    for source in (root / "SidequestUITests").rglob("*.swift"):
        body = source.read_text()
        classes = re.findall(r"final class (\w+): XCTestCase", body)
        if classes:
            actual.update(f"SidequestUITests/{classes[0]}/{name}" for name in re.findall(r"func (test\w+)\(", body))
    classified = set(policy["required"]) | set(policy["extended"])
    if actual != classified or set(policy["required"]) & set(policy["extended"]):
        raise RuntimeError(f"UI coverage inventory differs: {sorted(actual ^ classified)}")
    return policy


def selection(root, changed=None, extended=False):
    policy = inventory(root)
    selected = list(policy["required"])
    for name, rule in policy["extended"].items():
        if extended or changed is None or any(path.startswith(tuple(rule["paths"])) for path in changed):
            selected.append(name)
    return ["SidequestTests", *sorted(selected)]


def shards(selected, policy, workers):
    groups = [[] for _ in range(workers)]
    costs = [0] * workers
    for case in sorted(selected, key=lambda case: policy.get("seconds", {}).get(case, 6), reverse=True):
        worker = min(range(workers), key=lambda index: costs[index])
        groups[worker].append(case)
        costs[worker] += policy.get("seconds", {}).get(case, 6)
    return groups


def cache_identity(root, xcode, sdk, runtime):
    if isinstance(runtime, str):
        try:
            runtime = json.loads(runtime)
        except ValueError:
            pass
    if isinstance(runtime, dict) and "runtimes" in runtime:
        matching = [item for item in runtime["runtimes"] if item["identifier"] == RUNTIME]
        if len(matching) != 1 or not matching[0].get("isAvailable"):
            raise RuntimeError("The required simulator runtime is unavailable or ambiguous.")
        # simctl includes a changing lastUsage timestamp. It is not a build boundary.
        runtime = {name: matching[0].get(name) for name in
                   ("identifier", "version", "buildversion", "bundlePath", "runtimeRoot")}
    boundary = {"checkout": str(root.resolve()), "xcode": xcode.strip(), "sdk": sdk.strip(),
                "runtime": runtime, "configuration": "Debug", "project": "Sidequest.xcodeproj",
                "scheme": "Sidequest", "settings": SETTINGS}
    return boundary, hashlib.sha256(json.dumps(boundary, sort_keys=True).encode()).hexdigest()


def source_fingerprint(root):
    digest = hashlib.sha256()
    for folder in ("Sidequest", "SidequestTests", "SidequestUITests", "Sidequest.xcodeproj"):
        for path in sorted((root / folder).rglob("*")):
            if path.is_file() and path.suffix != ".md" and "xcuserdata" not in path.parts:
                digest.update(str(path.relative_to(root)).encode() + b"\0" + path.read_bytes())
    return digest.hexdigest()


@contextmanager
def owned_cache(cache_root, boundary, key):
    cache_root.mkdir(parents=True, exist_ok=True)
    # Nonblocking ownership: another job must finish; never mix two source builds.
    with (cache_root / f"{key}.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Debug cache is owned by another native run.") from None
        directory = cache_root / key
        directory.mkdir(exist_ok=True)
        identity = directory / "identity.json"
        if identity.exists() and json.loads(identity.read_text()) != boundary:
            raise RuntimeError("Debug cache boundary does not match its identity.")
        identity.write_text(json.dumps(boundary, indent=2) + "\n")
        try:
            yield directory / "DerivedData"
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def command(derived, destination):
    return ["xcodebuild", "-project", "Sidequest.xcodeproj", "-scheme", "Sidequest",
            "-configuration", "Debug", "-destination", destination,
            "-derivedDataPath", str(derived), *SETTINGS]


def actual_cases(root, target):
    cases = set()
    for source in (root / target).rglob("*.swift"):
        body = source.read_text()
        classes = re.findall(r"final class (\w+): XCTestCase", body)
        if classes:
            cases.update(f"{target}/{classes[0]}/{name}" for name in re.findall(r"func (test\w+)\(", body))
    return cases


def result_evidence(tree, summary, destination, expected):
    cases = []
    def visit(node):
        if node.get("nodeType") == "Test Case":
            if node.get("result") != "Passed":
                raise RuntimeError("Native test result includes a failure, skip, or expected failure.")
            cases.append("/".join(node["nodeIdentifierURL"].split("/")[-3:]).removesuffix("()"))
        for child in node.get("children", []):
            visit(child)
    for node in tree["testNodes"]:
        visit(node)
    if len(cases) != len(set(cases)) or set(cases) != set(expected):
        raise RuntimeError("Actual XCTest inventory differs from the required worker selection.")
    if summary.get("result") != "Passed" or summary.get("passedTests") != len(cases) or not cases or any(
            summary.get(key) != 0 for key in ("failedTests", "skippedTests", "expectedFailures")):
        raise RuntimeError("Native summary does not establish complete passing execution.")
    identifiers = {device["deviceId"] for device in tree["devices"]}
    if identifiers != {destination.split("id=", 1)[1]}:
        raise RuntimeError("XCTest ran on a different or additional simulator.")
    return {"inventory": sorted(cases), "exit_code": 0, "passed": len(cases), "failed": 0, "skipped": 0,
            "test_seconds": summary["finishTime"] - summary["startTime"]}


def execute(root, diagnostics, cache_root, destinations, selected, run, xcode, sdk, runtime):
    boundary, key = cache_identity(root, xcode, sdk, runtime)
    source = source_fingerprint(root)
    with owned_cache(cache_root, boundary, key) as derived:
        started = time.monotonic()
        # Even an unchanged head rebuilds the CURRENT checkout before every execution.
        run("build-for-testing", command(derived, destinations[0]) + ["build-for-testing"])
        built = time.monotonic()
        groups = shards(selected, inventory(root), len(destinations))
        def worker(index):
            bundle = diagnostics / f"Tests-{index + 1}.xcresult"
            run(f"tests-{index + 1}", command(derived, destinations[index]) + [
                "-parallel-testing-enabled", "NO", "-collect-test-diagnostics", "never", "-resultBundlePath",
                str(bundle),
                *[f"-only-testing:{case}" for case in groups[index]], "test-without-building"])
            tree = json.loads(run(f"test-tree-{index + 1}", ["xcrun", "xcresulttool", "get", "test-results",
                                                           "tests", "--path", str(bundle), "--format", "json"]))
            summary = json.loads(run(f"test-summary-{index + 1}", ["xcrun", "xcresulttool", "get", "test-results",
                                                                 "summary", "--path", str(bundle), "--format", "json"]))
            expected = set()
            for case in groups[index]:
                expected.update(actual_cases(root, case) if "/" not in case else
                                {name for name in actual_cases(root, case.split("/")[0])
                                 if name == case or name.startswith(case + "/")})
            return {"destination": destinations[index], "tests": groups[index], "result_bundle": str(bundle),
                    **result_evidence(tree, summary, destinations[index], expected)}
        with ThreadPoolExecutor(max_workers=len(destinations)) as pool:
            evidence = list(pool.map(worker, range(len(destinations))))
        record = {"cache_boundary": boundary, "cache_key": key, "build_seconds": built - started,
                  "test_seconds": time.monotonic() - built, "workers": len(destinations),
                  "worker_inventory": evidence,
                  "inventory": sorted(case for item in evidence for case in item["inventory"]),
                  "selected": selected, "mode": "full"}
        if source_fingerprint(root) != source:
            raise RuntimeError("Native source changed during execution; results cannot verify the current checkout.")
        record["source_fingerprint"] = source
        (diagnostics / "native-tests.json").write_text(json.dumps(record, indent=2) + "\n")
        return record, derived


@contextmanager
def devices(run, name, count):
    owned = []
    try:
        for index in range(count):
            identifier = run(f"create-{index + 1}", ["xcrun", "simctl", "create", f"{name} {index + 1}",
                                                   DEVICE_TYPE, RUNTIME]).strip()
            owned.append(identifier)
            run(f"boot-{index + 1}", ["xcrun", "simctl", "boot", identifier])
            run(f"bootstatus-{index + 1}", ["xcrun", "simctl", "bootstatus", identifier, "-b"])
        yield [f"platform=iOS Simulator,id={identifier}" for identifier in owned]
    finally:
        for index, identifier in enumerate(owned):
            # Shutdown only these devices; retain their data for same-device repeatability.
            run(f"shutdown-{index + 1}", ["xcrun", "simctl", "shutdown", identifier])
