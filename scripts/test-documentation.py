#!/usr/bin/env python3
"""Exercise broken links/anchors and fenced examples in a disposable repository."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("documentation", Path(__file__).with_name("check-documentation.py"))
documentation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(documentation)


class DocumentationTests(unittest.TestCase):
    def test_links_and_duplicate_anchors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q", directory], check=True)
            (root / "target.md").write_text("# Heading\n# Heading\n```\n# Not a heading\n```\n")
            source = root / "source.md"
            source.write_text("[Valid](target.md#heading-1)\n```\n[Example](missing.md)\n```\n")
            subprocess.run(["git", "add", "."], cwd=root, check=True)
            self.assertEqual(documentation.check(root), 0)
            source.write_text("[Missing](missing.md)\n")
            self.assertEqual(documentation.check(root), 1)
            source.write_text("[Missing anchor](target.md#not-a-heading)\n")
            self.assertEqual(documentation.check(root), 1)


if __name__ == "__main__":
    unittest.main()
