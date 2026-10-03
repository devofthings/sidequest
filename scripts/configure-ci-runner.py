#!/usr/bin/env python3
"""Register Sidequest's pinned, foreground-only runner without printing tokens."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import urllib.request

VERSION = "2.337.0"
SHA256 = "5a2cd92908a93d7276a194e1de6008099f3e7946f3f8e14aa7a1a7b4a31fdec2"
REPOSITORY = "devofthings/sidequest"


def github(endpoint, method="GET"):
    result = subprocess.run(["gh", "api", "--method", method, endpoint],
                            capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError("GitHub runner setup request failed; check repository admin access.")
    return json.loads(result.stdout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, required=True)
    args = parser.parse_args()
    directory = args.directory.resolve()
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        raise RuntimeError("This pinned runner requires an Apple-silicon Mac.")
    if not github(f"repos/{REPOSITORY}")["private"]:
        raise RuntimeError("The runner is restricted to the private Sidequest repository.")
    if directory.exists():
        raise RuntimeError("Runner directory already exists; preserve it and choose a fresh path.")
    if shutil.disk_usage(directory.parent).free < 1024 ** 3:
        raise RuntimeError("Runner installation requires at least 1 GiB free disk space.")
    directory.mkdir(mode=0o700)
    archive = directory / "runner.tar.gz"
    url = (f"https://github.com/actions/runner/releases/download/v{VERSION}/"
           f"actions-runner-osx-arm64-{VERSION}.tar.gz")
    urllib.request.urlretrieve(url, archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise RuntimeError("Official runner download checksum does not match the pinned digest.")
    subprocess.run(["tar", "-xzf", str(archive), "-C", str(directory)], check=True)
    archive.unlink()
    token = github(f"repos/{REPOSITORY}/actions/runners/registration-token", "POST")["token"]
    # config.sh necessarily receives the short-lived token; never echo its args/output.
    result = subprocess.run([
        str(directory / "config.sh"), "--unattended", "--url",
        f"https://github.com/{REPOSITORY}", "--token", token,
        "--name", "Sidequest-Mac-foreground", "--labels", "sidequest,xcode-27",
        "--work", "_work", "--disableupdate",
    ], cwd=directory, capture_output=True, text=True)
    del token
    if result.returncode:
        raise RuntimeError("Runner registration failed; private configuration remains outside Git.")
    for name in (".credentials", ".credentials_rsaparams", ".runner"):
        path = directory / name
        if path.exists():
            os.chmod(path, 0o600)
    print(f"Registered official runner {VERSION} at {directory}; no service installed.")
    print(f"Start only during authorized work: cd '{directory}' && ./run.sh")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.CalledProcessError) as error:
        # Setup failures after token acquisition must not expose subprocess arguments.
        print(f"Runner setup failed: {error if not isinstance(error, subprocess.CalledProcessError) else 'archive extraction failed'}",
              file=sys.stderr)
        sys.exit(1)
