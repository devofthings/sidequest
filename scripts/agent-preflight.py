#!/usr/bin/env python3
"""Read-only preparation checks; installs nothing and never starts app work."""

import os
from pathlib import Path
import shutil
import re
import subprocess
import sys

FORWARDER = """#!/bin/sh
# tokensave: chain-repo-hook
repo_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
if [ -x "$repo_hook" ] && [ "$repo_hook" != "$0" ]; then
	"$repo_hook" "$@"
fi
"""
DISPATCHER = """#!/bin/sh
# Sidequest: delegate to the tracked pre-commit hook.
exec "$(git rev-parse --show-toplevel)/.githooks/pre-commit" "$@"
"""


def command(*args):
    result = subprocess.run(args, capture_output=True, text=True, env=dict(os.environ, GIT_OPTIONAL_LOCKS="0"))
    if result.returncode:
        raise ValueError(result.stderr.strip() or f"{' '.join(args)} failed")
    return result.stdout.strip()


def executable(path):
    return path.is_file() and os.access(path, os.X_OK)


def sidequest_hooks(root):
    """Recognize only the direct hook or the installer's preserved chain."""
    tracked = root / ".githooks/pre-commit"
    if not executable(tracked):
        return False
    configured = command("git", "config", "--get", "core.hooksPath")
    hook_dir = Path(configured)
    if not hook_dir.is_absolute():
        hook_dir = root / hook_dir
    if hook_dir.resolve() == (root / ".githooks").resolve():
        return True
    forwarder = hook_dir / "pre-commit"
    dispatcher = Path(command("git", "rev-parse", "--absolute-git-dir")) / "hooks/pre-commit"
    return (
        executable(forwarder)
        and forwarder.read_text().rstrip("\n") == FORWARDER.rstrip("\n")
        and not dispatcher.is_symlink()
        and executable(dispatcher)
        and dispatcher.read_text().rstrip("\n") == DISPATCHER.rstrip("\n")
    )


def main():
    failures = []

    def check(name, operation):
        try:
            detail = operation()
            if detail is False:
                raise ValueError("requirement not satisfied")
            print(f"PASS {name}" + (f": {detail}" if isinstance(detail, str) else ""))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            failures.append(name)
            print(f"FAIL {name}: {error}")

    def tool(name):
        if not shutil.which(name):
            raise ValueError(f"install {name} explicitly before retrying")
        return command(name, "--version") if name != "xcrun" else "available"

    for name in ("git", "gh", "python3", "xcrun", "xcodebuild"):
        check(f"tool {name}", lambda name=name: tool(name)) if name != "xcodebuild" else check(
            "Xcode", lambda: command("xcodebuild", "-version")
        )
    try:
        root = Path(command("git", "rev-parse", "--show-toplevel"))
    except (OSError, ValueError) as error:
        print(f"FAIL repository: {error}")
        return 1

    def remote():
        url = command("git", "remote", "get-url", "origin").removesuffix(".git").rstrip("/")
        if url not in ("https://github.com/devofthings/sidequest", "git@github.com:devofthings/sidequest", "ssh://git@github.com/devofthings/sidequest"):
            raise ValueError("origin must identify devofthings/sidequest")
        return url

    def branch():
        name = command("git", "symbolic-ref", "--quiet", "--short", "HEAD")
        if not re.fullmatch(r"codex/[0-9]+-[a-z0-9][a-z0-9-]*", name):
            raise ValueError("select a codex/<issue>-<description> feature branch")
        return name

    def clean():
        if command("git", "status", "--porcelain", "--untracked-files=all"):
            raise ValueError("preserve and resolve current changes before assigning this checkout")
        return True

    def skill():
        path = root / ".agents/skills/my-review/SKILL.md"
        text = path.read_text()
        if not text.startswith("---\nname: my-review\n") or "description:" not in text.split("---", 2)[1]:
            raise ValueError("tracked my-review skill is missing valid identity metadata")
        return True

    check("repository origin", remote)
    check("feature branch", branch)
    check("clean checkout", clean)
    check("GitHub access", lambda: command("gh", "repo", "view", "devofthings/sidequest", "--json", "nameWithOwner", "--jq", ".nameWithOwner") == "devofthings/sidequest")
    check("local review skill", skill)
    check("swift-format", lambda: command("xcrun", "swift-format", "--version"))
    check("format configuration", lambda: (root / ".swift-format").is_file())
    check("Sidequest hooks (install explicitly with bash scripts/install-git-hooks.sh)", lambda: sidequest_hooks(root))
    if (root / "Sidequest.xcodeproj/project.pbxproj").is_file():
        print("INFO App target present; run the current build/test commands in docs/INSTALL.md. Preflight does not build or verify the app.")
    else:
        print("INFO App build, gameplay tests, and releases unavailable until the app foundation.")
    print("INFO App implementation was authorized October 3, 2026; scheduling remains undecided. Hosted CI/release execution needs a zero-cost check or spending approval.")
    print("INFO Lead must separately check included Codex allowance with the account tool before starting an issue or reviewer; preflight does not verify billing or authorize work.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
