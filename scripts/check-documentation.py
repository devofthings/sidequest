#!/usr/bin/env python3
"""Check tracked Markdown inline links and GitHub-style heading anchors offline."""

from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit


def prose(path):
    fence = None
    for line in path.read_text().splitlines():
        match = re.match(r"^\s*(`{3,}|~{3,})", line)
        if match:
            marker = match.group(1)[0]
            fence = None if fence == marker else (marker if fence is None else fence)
            continue
        if fence is None:
            yield line


def anchors(path):
    result, counts = set(), {}
    for line in prose(path):
        match = re.match(r"^#{1,6}\s+(.+?)(?:\s+#+)?$", line)
        if match:
            label = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", match.group(1))
            slug = re.sub(r"[^\w\- ]", "", label.lower()).replace(" ", "-")
            count = counts.get(slug, 0)
            counts[slug] = count + 1
            result.add(slug + (f"-{count}" if count else ""))
    return result


def check(root):
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
    files = [root / name for name in tracked if name.endswith(".md")]
    links, anchor_checks, failures = 0, 0, []
    for path in files:
        for line in prose(path):
            for destination in re.findall(r"\]\(([^)]+)\)", line):
                destination = destination.strip().split(' "')[0].strip("<>")
                parsed = urlsplit(destination)
                if parsed.scheme or parsed.netloc:
                    continue
                target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
                links += 1
                if not target.is_file():
                    failures.append(f"{path.relative_to(root)}: missing {destination}")
                elif parsed.fragment and target.suffix == ".md":
                    anchor_checks += 1
                    if unquote(parsed.fragment) not in anchors(target):
                        failures.append(f"{path.relative_to(root)}: missing anchor {destination}")
    print(f"Checked {len(files)} tracked Markdown files, {links} local links, {anchor_checks} anchors.")
    for failure in failures:
        print(failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(check(Path.cwd()))
