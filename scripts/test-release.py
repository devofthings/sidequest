#!/usr/bin/env python3
"""Exercise private publication, tamper rejection, failure gating, and draft retries offline."""

import copy
import importlib.util
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location("release", Path(__file__).with_name("publish-release.py"))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)
HEAD = "a" * 40


class FakeGitHub:
    def __init__(self):
        self.releases = []
        self.tag = None
        self.bytes = {}
        self.writes = []
        self.failure = None
        self.verification_conclusion = "success"
        self.verification_head = HEAD
        self.publisher_runner = 2

    def request(self, endpoint, method="GET", body=None, optional=False):
        path = endpoint.removeprefix(release.API)
        if method != "GET":
            self.writes.append((method, path))
        if path == "":
            return {"private": True}
        if path.startswith("/actions/runs/"):
            run_id = path.split("/")[3]
            if "/attempts/" not in path:
                return {"head_sha": HEAD, "event": "push", "head_branch": "main", "path": release.WORKFLOW,
                        "html_url": f"https://github.com/{release.REPO}/actions/runs/{run_id}"}
            return {"jobs": [
                {"name": release.CHECK, "head_sha": self.verification_head, "status": "completed",
                 "conclusion": self.verification_conclusion, "runner_name": release.RUNNER, "runner_id": 2,
                 "check_run_url": f"https://api.github.com/{release.API}/check-runs/{run_id}",
                 "html_url": f"https://github.com/{release.REPO}/actions/runs/{run_id}/job/42"},
                {"name": "Sidequest / publish preview", "runner_name": release.RUNNER,
                 "runner_id": self.publisher_runner},
            ]}
        if path.startswith("/check-runs/"):
            run_id = path.rsplit("/", 1)[1]
            return {"name": release.CHECK, "head_sha": HEAD, "status": "completed", "conclusion": "success",
                    "details_url": f"https://github.com/{release.REPO}/actions/runs/{run_id}/job/42",
                    "app": {"slug": "github-actions"}}
        if path.startswith("/git/ref/tags/"):
            return {"object": {"type": "commit", "sha": self.tag}} if self.tag else None
        if path == "/git/refs":
            self.tag = body["sha"]
            return {}
        if path.startswith("/releases?"):
            return copy.deepcopy(self.releases)
        if path == "/releases" and method == "POST":
            item = {**body, "id": len(self.releases) + 1, "html_url": "https://github.com/fixture/release", "assets": []}
            self.releases.append(item)
            return copy.deepcopy(item)
        if path.startswith("/releases/"):
            item = next(item for item in self.releases if item["id"] == int(path.rsplit("/", 1)[1]))
            if method == "PATCH":
                item.update(body)
            return copy.deepcopy(item)
        raise AssertionError(endpoint)

    def upload(self, tag, paths):
        self.writes.append(("UPLOAD", paths[0].name))
        if paths[0].name == self.failure:
            raise RuntimeError("intentional interrupted upload")
        item = next(item for item in self.releases if item["tag_name"] == tag)
        for path in paths:
            assert path.name not in [asset["name"] for asset in item["assets"]]
            asset_id = len(self.bytes) + 1
            self.bytes[asset_id] = path.read_bytes()
            item["assets"].append({"id": asset_id, "name": path.name, "state": "uploaded",
                                   "digest": "sha256:" + release.digest(path)})

    def download(self, asset, destination):
        destination.write_bytes(self.bytes[asset["id"]])


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.environment = {"GITHUB_EVENT_NAME": "push", "GITHUB_REF": "refs/heads/main",
                            "GITHUB_REPOSITORY": release.REPO, "GITHUB_SHA": HEAD, "GITHUB_RUN_ID": "100",
                            "GITHUB_RUN_ATTEMPT": "1", "RUNNER_NAME": release.RUNNER,
                            "RUNNER_TEMP": str(self.root / "_temp")}
        self.directory = self.root / "sidequest-diagnostics/100-1"
        self.app = self.directory / "DerivedData/Build/Products/Release-iphonesimulator/Sidequest.app"
        self.app.mkdir(parents=True)
        info = {"DTPlatformName": "iphonesimulator", "DTSDKName": "iphonesimulator27.0",
                "CFBundleExecutable": "Sidequest", "CFBundleIdentifier": "dev.devofthings.sidequest",
                "MinimumOSVersion": "17.0"}
        (self.app / "Info.plist").write_bytes(plistlib.dumps(info))
        (self.app / "Sidequest").write_bytes(b"fictional executable")
        (self.app / "Sidequest").chmod(0o755)
        self.manifest = {"schema": 1, "commit": HEAD, "run_id": "100", "attempt": "1", "event": "push",
                         "ref": "refs/heads/main", "runner_name": release.RUNNER, "all_checks_passed": True,
                         "runtime": "iOS 27.0 (24A434)",
                         "xcode": "Xcode 27.0\nBuild version 27A266a", "release_app": str(self.app)}
        self.write_manifest()
        self.github = FakeGitHub()
        original = subprocess.check_output

        def controlled(command, **kwargs):
            if command == ["git", "rev-parse", "HEAD"]:
                return HEAD + "\n"
            if command[:3] == ["xcrun", "lipo", "-archs"]:
                return "arm64\n"
            return original(command, **kwargs)

        self.process = patch.object(subprocess, "check_output", side_effect=controlled)
        self.process.start()

    def tearDown(self):
        self.process.stop()
        self.temporary.cleanup()

    def write_manifest(self):
        (self.directory / "verification.json").write_text(json.dumps(self.manifest))

    def publish(self):
        return release.publish(self.github, self.environment, str(self.directory))

    def test_draft_assets_complete_before_publication_and_zip_permissions(self):
        self.publish()
        self.assertFalse(self.github.releases[0]["draft"])
        self.assertTrue(self.github.releases[0]["prerelease"])
        self.assertEqual(self.github.tag, HEAD)
        self.assertEqual([write[1] for write in self.github.writes if write[0] == "UPLOAD"],
                         ["build-metadata.json", "SHA256SUMS", "Sidequest-simulator-arm64.zip"])
        self.assertEqual(self.github.writes[-1], ("PATCH", "/releases/1"))
        with zipfile.ZipFile(self.directory / "release/Sidequest-simulator-arm64.zip") as archive:
            self.assertEqual((archive.getinfo("Sidequest.app/Sidequest").external_attr >> 16) & 0o777, 0o755)
            self.assertIn("Sidequest.app/Info.plist", archive.namelist())

    def test_completed_retry_preserves_original_bytes_without_writes(self):
        self.publish()
        before = copy.deepcopy(self.github.releases), copy.deepcopy(self.github.bytes)
        self.github.writes.clear()
        (self.app / "Sidequest").write_bytes(b"different rebuilt bytes")
        self.publish()
        self.assertEqual(self.github.writes, [])
        self.assertEqual((self.github.releases, self.github.bytes), before)

    def test_interrupted_draft_resumes_exact_retained_archive(self):
        self.github.failure = "Sidequest-simulator-arm64.zip"
        with self.assertRaisesRegex(RuntimeError, "interrupted"):
            self.publish()
        self.assertTrue(self.github.releases[0]["draft"])
        self.github.failure = None
        (self.app / "Sidequest").write_bytes(b"different rebuilt bytes")
        self.publish()
        self.assertFalse(self.github.releases[0]["draft"])

    def test_new_workflow_attempt_recovers_original_draft_bytes(self):
        self.github.failure = "Sidequest-simulator-arm64.zip"
        with self.assertRaisesRegex(RuntimeError, "interrupted"):
            self.publish()
        original_archive = (self.directory / "release/Sidequest-simulator-arm64.zip").read_bytes()
        self.github.failure = None
        self.environment["GITHUB_RUN_ATTEMPT"] = "2"
        self.directory = self.root / "sidequest-diagnostics/100-2"
        self.directory.mkdir()
        self.manifest["attempt"] = "2"
        self.write_manifest()
        self.publish()
        item = self.github.releases[0]
        archive = next(asset for asset in item["assets"] if asset["name"].endswith(".zip"))
        metadata = next(asset for asset in item["assets"] if asset["name"] == "build-metadata.json")
        self.assertEqual(self.github.bytes[archive["id"]], original_archive)
        self.assertEqual(json.loads(self.github.bytes[metadata["id"]])["attempt"], "1")
        self.assertFalse(item["draft"])

    def test_failed_verification_performs_no_publication(self):
        self.github.verification_conclusion = "failure"
        with self.assertRaisesRegex(RuntimeError, "did not succeed"):
            self.publish()
        self.assertEqual(self.github.writes, [])
        self.assertEqual(self.github.releases, [])

    def test_wrong_verification_commit_and_host_are_rejected_before_writes(self):
        self.github.verification_head = "b" * 40
        with self.assertRaisesRegex(RuntimeError, "did not succeed"):
            self.publish()
        self.github.verification_head = HEAD
        self.github.publisher_runner = 3
        with self.assertRaisesRegex(RuntimeError, "same registered Mac"):
            self.publish()
        self.assertEqual(self.github.writes, [])

    def test_pr_event_cannot_publish_or_access_github(self):
        self.environment["GITHUB_EVENT_NAME"] = "pull_request"
        with patch.object(self.github, "request", side_effect=AssertionError("No GitHub access allowed")):
            with self.assertRaisesRegex(RuntimeError, "restricted"):
                self.publish()

    def test_wrong_local_directory_or_manifest_prevents_publication(self):
        with self.assertRaisesRegex(RuntimeError, "different-host"):
            release.publish(self.github, self.environment, str(self.root))
        self.manifest["all_checks_passed"] = False
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, "manifest"):
            self.publish()
        self.assertEqual(self.github.writes, [])

    def test_conflicting_tag_is_never_replaced(self):
        self.github.tag = "b" * 40
        with self.assertRaisesRegex(RuntimeError, "different source"):
            self.publish()
        self.assertEqual(self.github.writes, [])

    def test_corrupt_published_asset_fails_without_overwrite(self):
        self.publish()
        asset = next(asset for asset in self.github.releases[0]["assets"] if asset["name"].endswith(".zip"))
        self.github.bytes[asset["id"]] = b"corrupted"
        self.github.writes.clear()
        with self.assertRaisesRegex(RuntimeError, "digest"):
            self.publish()
        self.assertEqual(self.github.writes, [])

    def test_missing_original_draft_package_cannot_publish(self):
        self.github.failure = "Sidequest-simulator-arm64.zip"
        with self.assertRaises(RuntimeError):
            self.publish()
        (self.directory / "release/Sidequest-simulator-arm64.zip").unlink()
        self.github.failure = None
        with self.assertRaisesRegex(RuntimeError, "unavailable"):
            self.publish()
        self.assertTrue(self.github.releases[0]["draft"])

    def test_private_or_signing_files_are_excluded_from_release(self):
        (self.app / "embedded.mobileprovision").write_bytes(b"fictional profile")
        with self.assertRaisesRegex(RuntimeError, "signing"):
            self.publish()
        self.assertEqual(self.github.writes, [])


if __name__ == "__main__":
    unittest.main()
