"""Exercise commit checks in temporary repositories without changing this checkout."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GOOD = 'import SwiftUI\n\nstruct Probe: View {\n  var body: some View {\n    Text("Sidequest")\n  }\n}\n'
BAD = 'import SwiftUI\nstruct Probe:View{var body:some View{Text("Sidequest")}}\n'


class CommitHookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sidequest-hook-test-")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.env = os.environ.copy()
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(key, None)
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL="/dev/null")
        self.git("init", "-q")
        self.git("config", "user.name", "Hook Test")
        self.git("config", "user.email", "hook-test@example.test")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", str(ROOT / ".githooks"))
        shutil.copyfile(ROOT / ".swift-format", self.repo / ".swift-format")
        self.git("add", ".swift-format")
        self.git("commit", "-qm", "Configuration")

    def command(self, *args, check=True):
        return subprocess.run(args, cwd=self.repo, env=self.env, capture_output=True,
                              text=True, check=check)

    def git(self, *args, check=True):
        return self.command("git", *args, check=check)

    def stage(self, name, content):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        self.git("--literal-pathspecs", "add", "--", name)
        return path

    def commit(self, succeeds):
        before = (self.git("diff", "--cached", "--binary").stdout,
                  self.git("diff", "--binary").stdout)
        result = self.git("commit", "-qm", "Probe", check=False)
        self.assertEqual(result.returncode == 0, succeeds, result.stderr)
        if not succeeds:
            after = (self.git("diff", "--cached", "--binary").stdout,
                     self.git("diff", "--binary").stdout)
            self.assertEqual(before, after, "Hook changed the index or working tree")
        return result

    def test_formatted_source_commits(self):
        self.stage("Probe.swift", GOOD)
        self.commit(True)

    def test_unformatted_source_rejected(self):
        self.stage("Probe.swift", BAD)
        self.assertIn("staged Swift check failed", self.commit(False).stderr)

    def test_formatted_index_unformatted_worktree_commits(self):
        path = self.stage("Probe.swift", GOOD)
        path.write_text(BAD)
        self.commit(True)
        self.assertEqual(path.read_text(), BAD)
        self.assertEqual(self.git("show", "HEAD:Probe.swift").stdout, GOOD)

    def test_unformatted_index_formatted_worktree_rejected(self):
        path = self.stage("Probe.swift", BAD)
        path.write_text(GOOD)
        self.commit(False)
        self.assertEqual(path.read_text(), GOOD)

    def test_spaces_newlines_unicode_and_leading_dash_in_paths(self):
        for name in ("folder with spaces/Probe.swift", "line\nbreak.swift",
                     "-Probe.swift", "é/Probe.swift", ":(glob)Probe.swift"):
            self.stage(name, GOOD)
        self.commit(True)

    def test_staged_configuration_used(self):
        (self.repo / ".swift-format").write_text("invalid unstaged configuration")
        self.stage("Probe.swift", GOOD)
        self.commit(True)

    def test_invalid_staged_configuration_rejected(self):
        self.stage(".swift-format", "invalid staged configuration")
        shutil.copyfile(ROOT / ".swift-format", self.repo / ".swift-format")
        self.stage("Probe.swift", GOOD)
        self.commit(False)

    def test_missing_staged_configuration_rejected(self):
        self.git("rm", ".swift-format")
        self.stage("Probe.swift", GOOD)
        self.assertIn("staged .swift-format is missing", self.commit(False).stderr)

    def test_staged_whitespace_rejected(self):
        self.stage("notes.md", "trailing space \n")
        self.assertIn("staged whitespace", self.commit(False).stderr)

    def test_document_only_commit_without_formatter(self):
        fake_bin = self.repo / "fake-bin"
        fake_bin.mkdir()
        fake = fake_bin / "xcrun"
        fake.write_text("#!/bin/sh\nexit 99\n")
        fake.chmod(0o755)
        self.env["PATH"] = str(fake_bin) + os.pathsep + self.env["PATH"]
        self.stage("notes.md", "clean documentation\n")
        self.commit(True)
        self.stage("Probe.swift", GOOD)
        self.assertIn("swift-format is unavailable", self.commit(False).stderr)

    def test_deletion_and_rename(self):
        self.stage("Probe.swift", GOOD)
        self.commit(True)
        self.git("mv", "Probe.swift", "Renamed Probe.swift")
        self.commit(True)
        self.git("rm", "Renamed Probe.swift")
        self.commit(True)

    def test_generated_source_and_symlink_skipped(self):
        self.stage("Generated/Probe.swift", BAD)
        (self.repo / "Link.swift").symlink_to("missing-target")
        self.git("add", "Link.swift")
        self.commit(True)

    def test_installer_is_explicit_and_repeatable(self):
        self.git("config", "--unset", "core.hooksPath")
        shutil.copytree(ROOT / ".githooks", self.repo / ".githooks")
        for _ in range(2):
            self.command("bash", str(ROOT / "scripts/install-git-hooks.sh"))
            self.assertEqual(self.git("config", "--local", "--get", "core.hooksPath").stdout.strip(),
                             ".githooks")

    def test_installer_preserves_existing_configuration(self):
        shutil.copytree(ROOT / ".githooks", self.repo / ".githooks")
        self.git("config", "core.hooksPath", "existing-hooks")
        result = self.command("bash", str(ROOT / "scripts/install-git-hooks.sh"), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("config", "--get", "core.hooksPath").stdout.strip(), "existing-hooks")

    def install_forwarder_fixture(self):
        self.git("config", "--unset", "core.hooksPath")
        shutil.copytree(ROOT / ".githooks", self.repo / ".githooks")
        forwarders = self.repo / "global-hooks"
        forwarders.mkdir()
        hook = forwarders / "pre-commit"
        hook.write_text('''#!/bin/sh
# tokensave: chain-repo-hook
repo_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
if [ -x "$repo_hook" ] && [ "$repo_hook" != "$0" ]; then
\t"$repo_hook" "$@"
fi
''')
        hook.chmod(0o755)
        self.env["GIT_CONFIG_GLOBAL"] = str(self.repo / "global-config")
        self.git("config", "--global", "core.hooksPath", str(forwarders))
        return forwarders

    def test_tokensave_forwarder_preserved_and_hook_runs(self):
        forwarders = self.install_forwarder_fixture()
        message_hook = forwarders / "commit-msg"
        message_hook.write_text("#!/bin/sh\nprintf ran > other-hook-ran\n")
        message_hook.chmod(0o755)
        global_before = (self.repo / "global-config").read_bytes()
        forwarder_before = (forwarders / "pre-commit").read_bytes()
        for _ in range(2):
            self.command("bash", str(ROOT / "scripts/install-git-hooks.sh"))
        self.assertEqual((self.repo / "global-config").read_bytes(), global_before)
        self.assertEqual((forwarders / "pre-commit").read_bytes(), forwarder_before)
        self.assertNotEqual(self.git("config", "--local", "--get", "core.hooksPath", check=False).returncode, 0)
        self.stage("Probe.swift", BAD)
        self.commit(False)
        self.stage("Probe.swift", GOOD)
        self.commit(True)
        self.assertEqual((self.repo / "other-hook-ran").read_text(), "ran")

    def test_forwarder_does_not_overwrite_repository_hook(self):
        self.install_forwarder_fixture()
        existing = self.repo / ".git/hooks/pre-commit"
        existing.write_text("#!/bin/sh\nexit 0\n")
        before = existing.read_bytes()
        result = self.command("bash", str(ROOT / "scripts/install-git-hooks.sh"), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(existing.read_bytes(), before)

    def test_forwarder_preserves_linked_repository_hook(self):
        self.install_forwarder_fixture()
        target = self.repo / "existing-dispatcher"
        target.write_text('''#!/bin/sh
# Sidequest: delegate to the tracked pre-commit hook.
exec "$(git rev-parse --show-toplevel)/.githooks/pre-commit" "$@"
''')
        (self.repo / ".git/hooks/pre-commit").symlink_to(target)
        before = target.read_bytes()
        result = self.command("bash", str(ROOT / "scripts/install-git-hooks.sh"), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
