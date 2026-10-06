#!/usr/bin/env python3
"""Exercise read-only source statistics offline in disposable Git repositories."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("readme-stats.py").resolve()


class ReadmeStatisticsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="sidequest-readme-stats-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "core.hooksPath", "/dev/null")
        self.write("README.md", "# Keep me\n\nStable project introduction.\n")
        self.write("Sidequest/App/Spaced name.swift", "// comment\n\nlet café = 1")
        self.write("SidequestTests/Rules.swift", "let answer = 42\r\n")
        self.write("SidequestUITests/Flow.swift", "")
        self.write("Sidequest/Resources/Notes.md", "not Swift\n")
        self.git("add", ".")
        self.git("commit", "-qm", "baseline")
        self.git("tag", "2026.10.7")

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.root, env=self.env, stderr=subprocess.PIPE)

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value.encode())

    def run_script(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), "--baseline", "2026.10.7", *args],
                              cwd=self.root, env=self.env, capture_output=True, text=True)

    def test_read_only_counts_ignore_untracked_and_non_source_files(self):
        self.write("Sidequest/Private.swift", "secret\n" * 50)
        self.write(".local-news/Personal.swift", "secret\n" * 50)
        before = self.git("status", "--porcelain")
        readme = (self.root / "README.md").read_bytes()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("| App | 1 | 3 |", result.stdout)
        self.assertIn("| Unit tests | 1 | 1 |", result.stdout)
        self.assertIn("| UI tests | 1 | 0 |", result.stdout)
        self.assertIn("**+0 / −0 lines**", result.stdout)
        self.assertEqual(before, self.git("status", "--porcelain"))
        self.assertEqual(readme, (self.root / "README.md").read_bytes())

    def test_staged_additions_and_working_tree_deletions_include_churn(self):
        self.write("Sidequest/New.swift", "one\ntwo\n")
        self.git("add", "Sidequest/New.swift")
        (self.root / "SidequestTests/Rules.swift").unlink()
        self.write("Sidequest/App/Spaced name.swift", "// comment\n\nlet café = 2\n")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("| App | 2 | 5 |", result.stdout)
        self.assertIn("| Unit tests | 0 | 0 |", result.stdout)
        self.assertIn("**+3 / −2 lines**", result.stdout)

    def test_removed_write_option_cannot_modify_readme(self):
        readme = self.root / "README.md"
        original = readme.read_bytes()
        before = self.git("status", "--porcelain")
        result = self.run_script("--write")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unrecognized arguments: --write", result.stderr)
        self.assertEqual(original, readme.read_bytes())
        self.assertEqual(before, self.git("status", "--porcelain"))

    def test_missing_or_unsafe_baseline_never_modifies_readme(self):
        original = (self.root / "README.md").read_bytes()
        for baseline in ("2026.10.999", "--help", "bad]tag"):
            with self.subTest(baseline=baseline):
                result = self.run_script("--baseline=" + baseline)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(original, (self.root / "README.md").read_bytes())

    def test_source_symlink_cannot_read_private_content(self):
        self.write(".local-news/private.txt", "private content")
        (self.root / "Sidequest/Linked.swift").symlink_to("../.local-news/private.txt")
        self.git("add", "Sidequest/Linked.swift")
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("symlink", result.stderr)
        self.assertNotIn("private content", result.stdout + result.stderr)

    def test_source_parent_symlink_cannot_read_private_content(self):
        (self.root / "Sidequest/App/Spaced name.swift").unlink()
        (self.root / "Sidequest/App").rmdir()
        self.write(".local-news/App/Spaced name.swift", "private content")
        (self.root / "Sidequest/App").symlink_to("../.local-news/App", target_is_directory=True)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("symlink", result.stderr)
        self.assertNotIn("private content", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
