#!/usr/bin/env python3
"""Publish a verified main simulator preview; preserve existing release identity/bytes."""

import hashlib
from datetime import datetime
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile
import zipfile

REPO = "devofthings/sidequest"
API = f"repos/{REPO}"
CHECK = "Sidequest / verification"
WORKFLOW = ".github/workflows/releases.yml"
RUNNER = "Sidequest-Mac-foreground"
# Integration #9 establishes functional readiness; only reviewed main may publish manually.
# No environment override. Main pushes never publish; native exact-event gates still apply.
PUBLICATION_ENABLED = True


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


class GitHub:
    def request(self, endpoint, method="GET", body=None, optional=False):
        command = ["gh", "api", endpoint, "--method", method]
        if body is not None:
            command += ["--input", "-"]
        result = subprocess.run(command, input=json.dumps(body) if body is not None else None,
                                capture_output=True, text=True)
        if result.returncode:
            if optional and "HTTP 404" in result.stderr:
                return None
            raise RuntimeError(f"GitHub {method} request failed: {endpoint}")
        return json.loads(result.stdout)

    def download(self, asset, destination):
        with destination.open("wb") as output:
            result = subprocess.run(["gh", "api", f"{API}/releases/assets/{asset['id']}",
                                     "--header", "Accept: application/octet-stream"],
                                    stdout=output, stderr=subprocess.PIPE)
        require(result.returncode == 0, "Release asset download failed.")

    def upload(self, tag, paths):
        result = subprocess.run(["gh", "release", "upload", tag, "--repo", REPO,
                                 *map(str, paths)], capture_output=True, text=True)
        # No --clobber: a conflicting server asset must fail, never be replaced.
        require(result.returncode == 0, "Release asset upload failed; preserve the draft and retry.")


def verified_job(github, head, run_id, attempt):
    require(re.fullmatch(r"[1-9][0-9]*", str(run_id)) and re.fullmatch(r"[1-9][0-9]*", str(attempt)),
            "Invalid verification run identity.")
    run = github.request(f"{API}/actions/runs/{run_id}")
    require(type(run.get("id")) is int and run["id"] == int(run_id) and
            run["head_sha"] == head and run["event"] == "workflow_dispatch" and
            run["head_branch"] == "main" and run["path"] == WORKFLOW,
            "Verification must belong to this exact main release event.")
    jobs = github.request(f"{API}/actions/runs/{run_id}/attempts/{attempt}/jobs?per_page=100")["jobs"]
    matches = [job for job in jobs if job["name"] == CHECK]
    require(len(matches) == 1, "Missing or ambiguous verification job; rerun the entire workflow.")
    job = matches[0]
    require(job["head_sha"] == head and job["status"] == "completed" and
            job["conclusion"] == "success" and job["runner_name"] == RUNNER,
            "Required exact-commit verification did not succeed on the foreground Mac.")
    check_id = job["check_run_url"].rsplit("/", 1)[1]
    require(re.fullmatch(r"[0-9]+", check_id), "Invalid native check identity.")
    check = github.request(f"{API}/check-runs/{check_id}")
    require(check["name"] == CHECK and check["head_sha"] == head and
            check["status"] == "completed" and check["conclusion"] == "success" and
            check["details_url"] == job["html_url"] and check["app"]["slug"] == "github-actions",
            "Native verification check does not match the tested commit/job.")
    return job, run, jobs


def release_version(run):
    """Use immutable workflow-run provenance, never a retry's clock or an override."""
    created = run.get("created_at")
    number = run.get("run_number")
    require(type(number) is int and number > 0 and isinstance(created, str) and
            re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z", created),
            "Invalid workflow run version provenance.")
    try:
        date = datetime.strptime(created, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError:
        raise RuntimeError("Invalid workflow run creation timestamp.") from None
    return f"{date.year:04d}.{date.month:02d}.{number}"


def package(app, directory):
    require(app.is_dir() and not any(path.is_symlink() for path in [app, *app.rglob("*")]),
            "Release app is missing or contains an unexpected symlink.")
    require(not any(path.suffix in (".mobileprovision", ".xctest", ".xcconfig", ".md")
                    or path.name.startswith(".credentials") for path in app.rglob("*")),
            "Release app contains signing, test, private configuration, or guidance files.")
    with (app / "Info.plist").open("rb") as source:
        info = plistlib.load(source)
    require(info["DTPlatformName"] == "iphonesimulator" and
            info["DTSDKName"] == "iphonesimulator27.0", "Only the verified simulator SDK is supported.")
    executable = app / info["CFBundleExecutable"]
    architecture = subprocess.check_output(["xcrun", "lipo", "-archs", str(executable)], text=True).strip()
    require(architecture == "arm64", "Preview archive must contain the verified ARM64 executable.")
    directory.mkdir(exist_ok=True)
    archive = directory / "Sidequest-simulator-arm64.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as output:
        for path in sorted([app, *app.rglob("*")]):
            name = str(path.relative_to(app.parent)) + ("/" if path.is_dir() else "")
            entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = path.stat().st_mode << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            output.writestr(entry, b"" if path.is_dir() else path.read_bytes())
    require(archive.stat().st_size < 2 * 1024 ** 3, "Release asset exceeds GitHub's 2 GiB limit.")
    return archive, info


def release_for_tag(github, tag):
    page = 1
    while True:
        releases = github.request(f"{API}/releases?per_page=100&page={page}")
        matches = [release for release in releases if release["tag_name"] == tag]
        require(len(matches) <= 1, "Multiple releases claim this version.")
        if matches:
            return matches[0]
        if len(releases) < 100:
            return None
        page += 1


def validate_metadata(metadata, head, tag, run):
    require(isinstance(metadata, dict) and metadata.get("schema") in (1, 2) and
            metadata.get("commit") == head and metadata.get("version") == tag and
            tag == release_version(run) and metadata.get("run_id") == str(run["id"]) and
            type(metadata.get("run_number")) is int and metadata["run_number"] == run["run_number"] and
            metadata.get("run_created_at") == run["created_at"] and
            metadata.get("archive") == "Sidequest-simulator-arm64.zip" and
            metadata.get("architecture") == "arm64" and metadata.get("runtime") == "iOS 27.0 (24A434)" and
            re.fullmatch(r"[0-9a-f]{64}", str(metadata.get("archive_sha256"))),
            "Release metadata conflicts with the expected source/version/asset.")
    if metadata["schema"] == 2:
        require(metadata.get("main_smoke_passed") is True, "Metadata lacks fresh main smoke evidence.")
        validate_test_record(metadata.get("tests"))


def validate_test_record(tests):
    require(isinstance(tests, dict) and tests.get("mode") in ("full", "inherited"),
            "Missing full or inherited test provenance.")
    require(tests.get("gate") == "pre_design_smoke", "Missing approved pre-design smoke gate identity.")
    if tests["mode"] == "inherited":
        for key in ("original_head", "reviewed_base", "tree"):
            require(re.fullmatch(r"[0-9a-f]{40}", str(tests.get(key))), "Invalid inherited test source.")
        require(type(tests.get("pr")) is int and tests["pr"] > 0 and
                re.fullmatch(r"[1-9][0-9]*", str(tests.get("run_id"))) and
                re.fullmatch(r"[1-9][0-9]*", str(tests.get("attempt"))) and
                isinstance(tests.get("run_url"), str) and tests["run_url"].startswith(f"https://github.com/{REPO}/actions/runs/") and
                isinstance(tests.get("receipt_url"), str) and bool(tests.get("inventory")),
                "Missing inherited native run/audit identity.")
    else:
        workers = tests.get("worker_inventory")
        require(tests.get("workers") == 1 and isinstance(workers, list) and len(workers) == tests["workers"],
                "Missing native worker evidence.")
        cases = []
        for worker in workers:
            require(worker.get("exit_code") == 0 and worker.get("failed") == 0 and worker.get("skipped") == 0 and
                    type(worker.get("passed")) is int and worker["passed"] > 0 and
                    isinstance(worker.get("inventory"), list) and len(worker["inventory"]) == worker["passed"],
                    "Native worker did not pass its complete inventory.")
            cases += worker["inventory"]
        require(len(cases) == len(set(cases)) and sorted(cases) == tests.get("inventory"),
                "Native inventory is missing, duplicated, or inconsistent.")


def inspect_assets(github, release, head, tag, run, scratch):
    assets = {asset["name"]: asset for asset in release["assets"]}
    require(len(assets) == len(release["assets"]) and
            set(assets) <= {"build-metadata.json", "SHA256SUMS", "Sidequest-simulator-arm64.zip"},
            "Release contains duplicate or unexpected assets; preserve it for review.")
    downloaded = {}
    for name, asset in assets.items():
        require(asset["state"] == "uploaded", "Release has an incomplete server asset; do not overwrite it.")
        path = scratch / name
        github.download(asset, path)
        server_digest = asset.get("digest")
        require(not server_digest or server_digest == "sha256:" + digest(path),
                "Downloaded asset conflicts with GitHub's digest.")
        downloaded[name] = path
    if "build-metadata.json" not in downloaded:
        require(not assets and release["draft"], "Release assets lack source metadata.")
        return None, downloaded
    metadata = json.loads(downloaded["build-metadata.json"].read_text())
    validate_metadata(metadata, head, tag, run)
    expected_checksums = (f"{metadata['archive_sha256']}  Sidequest-simulator-arm64.zip\n"
                          f"{digest(downloaded['build-metadata.json'])}  build-metadata.json\n")
    if "SHA256SUMS" in downloaded:
        require(downloaded["SHA256SUMS"].read_text() == expected_checksums,
                "Release checksum file conflicts with its metadata.")
    if "Sidequest-simulator-arm64.zip" in downloaded:
        require(digest(downloaded["Sidequest-simulator-arm64.zip"]) == metadata["archive_sha256"],
                "Published archive checksum conflicts with its source metadata.")
    if not release["draft"]:
        require(len(downloaded) == 3, "Published release is incomplete; preserve it for review.")
    return metadata, downloaded


def publish(github, environment, verification_directory):
    require(environment.get("GITHUB_EVENT_NAME") == "workflow_dispatch" and
            environment.get("GITHUB_REF") == "refs/heads/main" and
            environment.get("GITHUB_REPOSITORY") == REPO and
            environment.get("RUNNER_NAME") == RUNNER, "Publication requires an explicit main dispatch on this foreground Mac.")
    require(PUBLICATION_ENABLED, "Publication is held until the MVP readiness follow-up is reviewed and merged.")
    head = environment["GITHUB_SHA"]
    require(re.fullmatch(r"[0-9a-f]{40}", head), "Invalid source commit.")
    require(subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip() == head,
            "Publisher checkout differs from the event commit.")
    require(github.request(API)["private"], "Publication requires a private repository.")
    job, run, jobs = verified_job(github, head, environment["GITHUB_RUN_ID"], environment["GITHUB_RUN_ATTEMPT"])
    tag = release_version(run)
    require(environment.get("GITHUB_RUN_NUMBER") == str(run["run_number"]),
            "Environment run number differs from live workflow provenance.")
    publishers = [item for item in jobs if item["name"] == "Sidequest / publish preview"]
    require(len(publishers) == 1 and publishers[0]["runner_id"] == job["runner_id"] and
            publishers[0]["runner_name"] == RUNNER, "Local handoff must remain on the same registered Mac runner.")
    parent = Path(environment["RUNNER_TEMP"]).resolve().parent / "sidequest-diagnostics"
    directory = Path(verification_directory).resolve()
    require(directory == parent / f"{environment['GITHUB_RUN_ID']}-{environment['GITHUB_RUN_ATTEMPT']}",
            "Missing or different-host verification directory; no upload fallback is allowed.")
    manifest = json.loads((directory / "verification.json").read_text())
    require(manifest.get("schema") == 2 and manifest.get("commit") == head and
            manifest.get("all_checks_passed") is True and manifest.get("event") == "workflow_dispatch" and
            manifest.get("ref") == "refs/heads/main" and manifest.get("runner_name") == RUNNER and
            manifest.get("runtime") == "iOS 27.0 (24A434)" and
            manifest.get("run_id") == environment["GITHUB_RUN_ID"] and
            manifest.get("run_number") == str(run["run_number"]) and
            manifest.get("attempt") == environment["GITHUB_RUN_ATTEMPT"],
            "Local verification manifest does not match this successful main event.")
    require(manifest.get("main_smoke_passed") is True, "Fresh main install/launch smoke did not pass.")
    validate_test_record(manifest.get("tests"))
    import native_tests
    policy = native_tests.inventory(Path.cwd())
    expected_cases = sorted(native_tests.actual_cases(Path.cwd(), "SidequestTests") | set(policy["pre_design_smoke"]))
    require(manifest["tests"]["gate"] == policy["active_gate"] and manifest["tests"].get("inventory") == expected_cases,
            "Manifest does not verify the full approved unit and UI smoke gate.")
    if manifest["tests"]["mode"] == "full":
        require(manifest["tests"].get("selected") == native_tests.selection(Path.cwd()),
                "Manifest selection differs from the approved active gate.")
    if manifest["tests"]["mode"] == "inherited":
        from verification_provenance import resolve_inherited_tests
        current = resolve_inherited_tests(Path.cwd(), head, parent, read_api=github.request)
        require(current == manifest["tests"], "Inherited test provenance changed or is no longer verifiable.")
    reference = github.request(f"{API}/git/ref/tags/{tag}", optional=True)
    if reference:
        require(reference["object"]["type"] == "commit" and reference["object"]["sha"] == head,
                "Existing version tag points at a different source; never replace it.")
    release = release_for_tag(github, tag)
    if release:
        require(release["name"] == tag and release["prerelease"] and release["target_commitish"] == head,
                "Existing release conflicts with the expected display version/preview identity.")
    with tempfile.TemporaryDirectory() as temporary:
        metadata, downloaded = inspect_assets(github, release, head, tag, run, Path(temporary)) if release else (None, {})
        if metadata:
            original_job, original_run, _ = verified_job(github, head, metadata["run_id"], metadata["attempt"])
            validate_metadata(metadata, head, tag, original_run)
            require(original_job["html_url"] == metadata["verification_job_url"], "Original build verification identity changed.")
        if release and not release["draft"]:
            require(reference is not None and release["prerelease"], "Existing version lacks its expected tag/preview identity.")
            return release["html_url"]
        if not metadata:
            if release:
                require(f"[Workflow run]({run['html_url']})" in release.get("body", ""),
                        "Empty draft belongs to a different workflow run; preserve the version collision.")
            app = directory / "DerivedData/Build/Products/Release-iphonesimulator/Sidequest.app"
            require(Path(manifest["release_app"]).resolve() == app.resolve() and app.resolve().is_relative_to(directory),
                    "Release product is outside the verified local build.")
            archive, info = package(app, directory / "release")
            metadata = {"schema": 2, "commit": head, "version": tag, "archive": archive.name,
                        "archive_sha256": digest(archive), "architecture": "arm64", "runtime": manifest["runtime"],
                        "minimum_ios": info["MinimumOSVersion"], "xcode": manifest["xcode"],
                        "bundle_identifier": info["CFBundleIdentifier"], "run_id": environment["GITHUB_RUN_ID"],
                        "run_number": run["run_number"], "run_created_at": run["created_at"],
                        "attempt": environment["GITHUB_RUN_ATTEMPT"], "workflow_run_url": run["html_url"],
                        "verification_job_url": job["html_url"],
                        "installation_url": f"https://github.com/{REPO}/blob/{tag}/docs/INSTALL.md",
                        "tests": manifest["tests"], "main_smoke_passed": True}
            validate_metadata(metadata, head, tag, run)
            metadata_path = directory / "release/build-metadata.json"
            metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n")
        else:
            # A draft retry uses its original retained package, not newly rebuilt bytes.
            original_directory = parent / f"{metadata['run_id']}-{metadata['attempt']}" / "release"
            archive = original_directory / metadata["archive"]
            metadata_path = downloaded["build-metadata.json"]
        checksum_path = directory / "release/SHA256SUMS"
        checksum_path.parent.mkdir(exist_ok=True)
        checksum_path.write_text(f"{metadata['archive_sha256']}  {metadata['archive']}\n"
                                 f"{digest(metadata_path)}  build-metadata.json\n")
        if not reference:
            github.request(f"{API}/git/refs", "POST", {"ref": "refs/tags/" + tag, "sha": head})
        test_note = "Tests executed on this main commit." if metadata.get("tests", {}).get("mode", "full") == "full" else (
            f"Tests inherited from PR #{metadata['tests']['pr']} at `{metadata['tests']['original_head']}` "
            f"([original native run]({metadata['tests']['run_url']})); this main commit was freshly compiled, installed, and launched.")
        if metadata.get("tests", {}).get("gate") == "pre_design_smoke":
            test_note += " Approved pre-design coverage: all unit tests and three UI smoke cases. Comprehensive UI journeys are deferred until design agreement."
        notes = (f"Private simulator preview from `{head}`.\n\n"
                 f"ARM64 Mac; {metadata['runtime']}; Xcode 27.0 (27A266a). This is a simulator `.app`, not an iPhone IPA.\n\n"
                 f"[Verified build]({metadata['verification_job_url']}) · [Workflow run]({metadata['workflow_run_url']}) · "
                 f"[Installation and source-based iPhone signing]({metadata['installation_url']})\n\n"
                 f"{test_note}\n\n"
                 "SHA256SUMS and build-metadata.json identify the exact archived build. Personal content and signing are excluded.")
        if not release:
            release = github.request(f"{API}/releases", "POST", {"tag_name": tag, "target_commitish": head,
                                     "name": tag, "body": notes,
                                     "draft": True, "prerelease": True, "make_latest": "false"})
        else:
            # An empty interrupted draft can select this newly verified package.
            # Reconcile its unpublished notes with the selected metadata too.
            release = github.request(f"{API}/releases/{release['id']}", "PATCH", {"body": notes})
        for path in [metadata_path, checksum_path, archive]:
            if path.name not in downloaded:
                require(path.is_file(), "Original draft package is unavailable; preserve the draft and recover its exact bytes.")
                if path == archive:
                    require(digest(path) == metadata["archive_sha256"], "Original draft archive changed; never replace its identity.")
                github.upload(tag, [path])
        ready = github.request(f"{API}/releases/{release['id']}")
        complete, assets = inspect_assets(github, ready, head, tag, run, Path(temporary))
        require(complete == metadata and len(assets) == 3, "Draft does not contain the complete verified asset set.")
        github.request(f"{API}/releases/{release['id']}", "PATCH", {"draft": False, "prerelease": True, "make_latest": "false"})
        return release["html_url"]


if __name__ == "__main__":
    try:
        url = publish(GitHub(), os.environ, os.environ.get("SIDEQUEST_VERIFICATION_DIRECTORY", ""))
        print(f"Private preview verified: {url}")
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as output:
            output.write(f"### Private simulator preview\n\n[Release]({url})\n\nCommit: `{os.environ['GITHUB_SHA']}`.\n")
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Publication failed: {error}", file=sys.stderr)
        sys.exit(1)
