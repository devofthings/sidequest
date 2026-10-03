#!/usr/bin/env python3
"""Exercise private publication, tamper rejection, failure gating, and draft retries offline."""

import copy
import importlib.util
import json
from pathlib import Path
import plistlib
import shutil
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
        self.tags = {}
        self.run_number = 24
        self.created_at = "2026-10-01T23:59:59Z"
        self.run_override = {}
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
                return {"id": int(run_id), "head_sha": HEAD, "event": "push", "head_branch": "main", "path": release.WORKFLOW,
                        "run_number": self.run_number, "created_at": self.created_at,
                        "html_url": f"https://github.com/{release.REPO}/actions/runs/{run_id}", **self.run_override}
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
            tag = path.rsplit("/", 1)[1]
            return {"object": {"type": "commit", "sha": self.tags[tag]}} if tag in self.tags else None
        if path == "/git/refs":
            self.tags[body["ref"].removeprefix("refs/tags/")] = body["sha"]
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
                            "GITHUB_RUN_ATTEMPT": "1", "GITHUB_RUN_NUMBER": "24", "RUNNER_NAME": release.RUNNER,
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
                         "ref": "refs/heads/main", "run_number": "24", "runner_name": release.RUNNER, "all_checks_passed": True,
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
        self.assertEqual(self.github.tags["2026.10.24"], HEAD)
        self.assertEqual(self.github.releases[0]["name"], "2026.10.24")
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

    def test_empty_draft_retry_reconciles_notes_with_new_verified_metadata(self):
        self.github.failure = "build-metadata.json"
        with self.assertRaisesRegex(RuntimeError, "interrupted"):
            self.publish()
        self.assertTrue(self.github.releases[0]["draft"])
        self.assertEqual(self.github.releases[0]["assets"], [])
        self.assertIn("/runs/100/job/42", self.github.releases[0]["body"])
        self.github.failure = None
        self.environment["GITHUB_RUN_ATTEMPT"] = "2"
        self.directory = self.root / "sidequest-diagnostics/100-2"
        new_app = self.directory / "DerivedData/Build/Products/Release-iphonesimulator/Sidequest.app"
        shutil.copytree(self.app, new_app)
        (new_app / "Sidequest").write_bytes(b"new verified bytes")
        self.manifest.update(attempt="2", release_app=str(new_app))
        self.write_manifest()
        self.publish()
        item = self.github.releases[0]
        metadata_asset = next(asset for asset in item["assets"] if asset["name"] == "build-metadata.json")
        metadata = json.loads(self.github.bytes[metadata_asset["id"]])
        self.assertEqual(metadata["run_id"], "100")
        self.assertEqual(metadata["attempt"], "2")
        self.assertEqual(metadata["version"], "2026.10.24")
        self.assertIn(metadata["verification_job_url"], item["body"])
        self.assertIn(metadata["workflow_run_url"], item["body"])
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
        self.github.tags["2026.10.24"] = "b" * 40
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

    def test_rerun_in_later_month_keeps_original_version_and_bytes(self):
        self.github.created_at = "2026-10-31T23:59:59Z"
        self.publish()
        before = copy.deepcopy(self.github.releases), copy.deepcopy(self.github.bytes)
        self.github.writes.clear()
        self.github.run_override["updated_at"] = "2026-11-01T00:00:01Z"
        self.github.run_override["run_started_at"] = "2026-11-01T00:00:01Z"
        self.environment["GITHUB_RUN_ATTEMPT"] = "2"
        self.directory = self.root / "sidequest-diagnostics/100-2"
        self.directory.mkdir()
        self.manifest["attempt"] = "2"
        self.write_manifest()
        self.publish()
        self.assertEqual(self.github.releases[0]["tag_name"], "2026.10.24")
        self.assertEqual((self.github.releases, self.github.bytes), before)
        self.assertEqual(self.github.writes, [])

    def test_next_month_run_gets_new_version_without_resetting_build(self):
        self.publish()
        old_release, old_bytes = copy.deepcopy(self.github.releases[0]), copy.deepcopy(self.github.bytes)
        self.environment.update(GITHUB_RUN_ID="200", GITHUB_RUN_NUMBER="25")
        self.github.run_number = 25
        self.github.created_at = "2026-11-01T00:00:00Z"
        self.directory = self.root / "sidequest-diagnostics/200-1"
        new_app = self.directory / "DerivedData/Build/Products/Release-iphonesimulator/Sidequest.app"
        shutil.copytree(self.app, new_app)
        self.manifest.update(run_id="200", run_number="25", release_app=str(new_app))
        self.write_manifest()
        self.publish()
        self.assertEqual(self.github.releases[1]["tag_name"], "2026.11.25")
        self.assertEqual(self.github.releases[1]["name"], "2026.11.25")
        self.assertEqual(self.github.releases[0], old_release)
        self.assertTrue(all(self.github.bytes[key] == value for key, value in old_bytes.items()))

    def test_january_format_and_metadata_bind_full_source_and_run_provenance(self):
        self.github.created_at = "2027-01-01T00:00:00Z"
        self.github.run_number = 1
        self.environment["GITHUB_RUN_NUMBER"] = "1"
        self.manifest["run_number"] = "1"
        self.write_manifest()
        self.publish()
        item = self.github.releases[0]
        self.assertEqual(item["tag_name"], "2027.01.1")
        self.assertEqual(item["name"], "2027.01.1")
        asset = next(a for a in item["assets"] if a["name"] == "build-metadata.json")
        metadata = json.loads(self.github.bytes[asset["id"]])
        self.assertEqual(metadata["commit"], HEAD)
        self.assertEqual(metadata["run_id"], "100")
        self.assertEqual(metadata["run_number"], 1)
        self.assertEqual(metadata["run_created_at"], "2027-01-01T00:00:00Z")

    def test_bad_live_run_version_provenance_fails_before_writes(self):
        for field, value in [("run_number", 0), ("run_number", True), ("run_number", "24"),
                             ("run_number", -1), ("created_at", "2026-02-30T12:00:00Z"),
                             ("created_at", "2026-10-01T23:59:59Zextra"),
                             ("created_at", "2026-10-01T23:59:59+01:00"), ("created_at", None),
                             ("id", 200), ("id", True), ("path", ".github/workflows/other.yml")]:
            with self.subTest(field=field, value=value):
                self.github.run_override = {field: value}
                with self.assertRaises(RuntimeError):
                    self.publish()
                self.assertEqual(self.github.writes, [])

    def test_spoofed_environment_or_manifest_run_number_cannot_select_version(self):
        self.environment["GITHUB_RUN_NUMBER"] = "99"
        with self.assertRaisesRegex(RuntimeError, "run number"):
            self.publish()
        self.environment["GITHUB_RUN_NUMBER"] = "24"
        self.manifest["run_number"] = "99"
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, "manifest"):
            self.publish()
        self.assertEqual(self.github.writes, [])
        self.manifest["run_number"] = "24"
        self.write_manifest()
        self.environment["SIDEQUEST_RELEASE_VERSION"] = "2099.12.999"
        self.publish()
        self.assertEqual(self.github.releases[0]["tag_name"], "2026.10.24")

    def test_uploaded_provenance_collision_preserves_release(self):
        self.publish()
        original_bytes, original_releases = copy.deepcopy(self.github.bytes), copy.deepcopy(self.github.releases)
        for field, value in [("run_id", "200"), ("run_number", 25), ("run_created_at", "2026-11-01T00:00:00Z")]:
            with self.subTest(field=field):
                self.github.bytes = copy.deepcopy(original_bytes)
                self.github.releases = copy.deepcopy(original_releases)
                asset = next(a for a in self.github.releases[0]["assets"] if a["name"] == "build-metadata.json")
                metadata = json.loads(self.github.bytes[asset["id"]])
                metadata[field] = value
                self.github.bytes[asset["id"]] = json.dumps(metadata).encode()
                asset.pop("digest")  # Exercise metadata binding, independent of optional server digests.
                self.github.writes.clear()
                with self.assertRaisesRegex(RuntimeError, "metadata conflicts"):
                    self.publish()
                self.assertEqual(self.github.writes, [])

    def test_empty_draft_from_different_run_is_not_adopted(self):
        self.github.failure = "build-metadata.json"
        with self.assertRaises(RuntimeError):
            self.publish()
        before = copy.deepcopy(self.github.releases)
        self.environment["GITHUB_RUN_ID"] = "200"
        self.directory = self.root / "sidequest-diagnostics/200-1"
        self.directory.mkdir()
        self.manifest["run_id"] = "200"
        self.write_manifest()
        self.github.failure = None
        self.github.writes.clear()
        with self.assertRaisesRegex(RuntimeError, "different workflow run"):
            self.publish()
        self.assertEqual(self.github.releases, before)
        self.assertEqual(self.github.writes, [])

    def test_historical_preview_tag_and_release_are_untouched(self):
        legacy = {"id": 9, "tag_name": "preview-" + HEAD, "name": "Sidequest preview " + HEAD[:12],
                  "draft": False, "prerelease": True, "assets": [], "body": "Historical evidence"}
        self.github.releases.append(copy.deepcopy(legacy))
        self.github.tags[legacy["tag_name"]] = HEAD
        self.publish()
        self.assertEqual(self.github.releases[0], legacy)
        self.assertEqual(self.github.tags[legacy["tag_name"]], HEAD)
        self.assertEqual(self.github.releases[1]["tag_name"], "2026.10.24")

    def test_display_or_source_collision_fails_without_writes(self):
        self.publish()
        for field, value in [("name", "different version"), ("target_commitish", "b" * 40)]:
            with self.subTest(field=field):
                saved = self.github.releases[0][field]
                self.github.releases[0][field] = value
                self.github.writes.clear()
                with self.assertRaisesRegex(RuntimeError, "display version"):
                    self.publish()
                self.assertEqual(self.github.writes, [])
                self.github.releases[0][field] = saved


if __name__ == "__main__":
    unittest.main()
