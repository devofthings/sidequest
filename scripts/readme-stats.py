#!/usr/bin/env python3
"""Print tracked Swift source statistics without modifying repository files."""

import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOTS = ("Sidequest", "SidequestTests", "SidequestUITests")


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root, stderr=subprocess.PIPE)


def statistics(root, baseline):
    # Release tags are safe to show literally in Markdown and cannot be Git options.
    if not re.fullmatch(r"(?:[0-9]{4}\.[0-9]{2}\.[1-9][0-9]*|preview-[a-f0-9]{40})", baseline):
        raise ValueError("baseline must be a published release tag (YYYY.MM.build or preview-<SHA>)")
    commit = git(root, "rev-parse", "--verify", f"refs/tags/{baseline}^{{commit}}").decode().strip()
    paths = set(git(root, "ls-files", "--cached", "-z", "--", *ROOTS).split(b"\0"))
    counts = {name: [0, 0] for name in ROOTS}
    for raw in sorted(paths):
        if not raw.endswith(b".swift"):
            continue
        name = raw.decode("utf-8")
        path = root / name
        if path.is_symlink() or any((root / parent).is_symlink() for parent in Path(name).parents):
            raise ValueError(f"refusing to read a Swift symlink: {name}")
        if not path.exists():
            continue  # A tracked deletion awaiting staging has no working-tree lines.
        content = path.read_bytes()
        content.decode("utf-8")  # Reject binary/non-UTF-8 source rather than miscount it.
        count = counts[name.split("/", 1)[0]]
        count[0] += 1
        count[1] += content.count(b"\n") + int(bool(content) and not content.endswith(b"\n"))

    added = removed = 0
    diff = git(root, "diff", "--no-ext-diff", "--no-textconv", "--no-renames",
               "--diff-algorithm=myers", "--numstat", "-z", commit, "--", *ROOTS)
    for record in diff.split(b"\0"):
        if not record:
            continue
        additions, deletions, name = record.split(b"\t", 2)
        if name.endswith(b".swift"):
            if additions == b"-" or deletions == b"-":
                raise ValueError("cannot calculate line changes for binary Swift source")
            added += int(additions)
            removed += int(deletions)

    rows = ["| Swift source | Files | Physical lines |", "| --- | ---: | ---: |"]
    for name, label in zip(ROOTS, ("App", "Unit tests", "UI tests")):
        files, lines = counts[name]
        rows.append(f"| {label} | {files:,} | {lines:,} |")
    rows.append(f"| **Total** | **{sum(c[0] for c in counts.values()):,}** | "
                f"**{sum(c[1] for c in counts.values()):,}** |")
    rows.extend(["", f"Swift changes since `{baseline}` (`{commit[:12]}`): "
                 f"**+{added:,} / −{removed:,} lines**."])
    return "\n".join(rows) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, help="local release tag used for Swift additions/deletions")
    args = parser.parse_args()
    try:
        root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel").decode().strip())
        block = statistics(root, args.baseline)
        print(block, end="")
    except (OSError, UnicodeError, ValueError, subprocess.CalledProcessError) as error:
        detail = error.stderr.decode(errors="replace").strip() if isinstance(error, subprocess.CalledProcessError) else str(error)
        print(f"Source statistics failed: {detail}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
