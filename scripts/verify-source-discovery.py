#!/usr/bin/env python3
"""Exercise synchronized target membership in a disposable source copy."""

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile


def verify(root, destination):
    with tempfile.TemporaryDirectory(prefix="sidequest-source-discovery-") as directory:
        checkout = Path(directory)
        for name in ("Sidequest.xcodeproj", "Sidequest", "SidequestTests", "SidequestUITests"):
            shutil.copytree(
                root / name, checkout / name,
                ignore=shutil.ignore_patterns("xcuserdata", "*.xcuserstate", "LocalSigning.xcconfig"),
            )
        project = checkout / "Sidequest.xcodeproj/project.pbxproj"
        original = hashlib.sha256(project.read_bytes()).hexdigest()
        derived = checkout / "DerivedData"

        def build(action="build", error=None):
            command = [
                "xcodebuild", "-project", "Sidequest.xcodeproj", "-scheme", "Sidequest",
                "-configuration", "Debug", "-destination", destination,
                "-derivedDataPath", str(derived), "CODE_SIGNING_ALLOWED=NO", action,
            ]
            result = subprocess.run(command, cwd=checkout, text=True, capture_output=True)
            output = result.stdout + result.stderr
            if error is None:
                if result.returncode:
                    raise RuntimeError(output[-10000:])
            elif result.returncode == 0 or error not in output:
                raise RuntimeError(f"Expected compilation to reject {error}\n{output[-10000:]}")
            if hashlib.sha256(project.read_bytes()).hexdigest() != original:
                raise RuntimeError("Source discovery changed the project file")

        def add(path, text):
            target = checkout / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
            return target

        probe = add("Sidequest/Core/DiscoveryProbe.swift", '#error("APP_DISCOVERY_PROBE")\n')
        build(error="APP_DISCOVERY_PROBE")
        probe.unlink()
        build()
        print("PASS app source addition/removal discovered without project edits")

        for folder, marker in (("SidequestTests", "UNIT_DISCOVERY_PROBE"),
                               ("SidequestUITests", "UI_DISCOVERY_PROBE")):
            probe = add(f"{folder}/DiscoveryProbe.swift", f'#error("{marker}")\n')
            build()
            build("build-for-testing", error=marker)
            probe.unlink()
        print("PASS unit/UI sources discovered by their test target and excluded from app")

        add("Sidequest/Games/DiscoveryProbe/AGENTS.md", "Disposable nested guidance exclusion probe.\n")
        add("SidequestTests/DiscoveryProbe/AGENTS.md", "Disposable unit guidance probe.\n")
        add("SidequestUITests/DiscoveryProbe/AGENTS.md", "Disposable UI guidance probe.\n")
        add("Sidequest/Resources/DiscoveryApp.json", '{"owner":"app"}\n')
        add(".local-news/PrivateCapture.json", '{"owner":"private-probe"}\n')
        build("build-for-testing")

        products = derived / "Build/Products/Debug-iphonesimulator"
        app = products / "Sidequest.app"
        unit = app / "PlugIns/SidequestTests.xctest"
        ui = products / "SidequestUITests-Runner.app/PlugIns/SidequestUITests.xctest"
        for bundle in (app, unit, ui):
            if not bundle.is_dir():
                raise RuntimeError(f"Missing product bundle: {bundle}")
            if list(bundle.rglob("*.md")):
                raise RuntimeError(f"Documentation leaked into {bundle}")
            if list(bundle.rglob("PrivateCapture.json")):
                raise RuntimeError(f"Private input leaked into {bundle}")

        if not (app / "DiscoveryApp.json").is_file():
            raise RuntimeError("App resource was not discovered")
        if not (unit / "FoundationFixture.json").is_file():
            raise RuntimeError("Unit resource was not discovered")
        if not (ui / "FoundationLaunch.json").is_file():
            raise RuntimeError("UI resource was not discovered")
        for bundle, unexpected in ((app, "FoundationFixture.json"), (app, "FoundationLaunch.json"),
                                   (unit, "DiscoveryApp.json"), (unit, "FoundationLaunch.json"),
                                   (ui, "DiscoveryApp.json"), (ui, "FoundationFixture.json")):
            if (bundle / unexpected).exists():
                raise RuntimeError(f"Wrong target resource: {bundle / unexpected}")
        print("PASS app/unit/UI fixture isolation and current/future nested Markdown exclusion")
        print("PASS private inputs outside synchronized roots excluded; project hash unchanged")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", required=True,
                        help="Available iPhone simulator destination, e.g. platform=iOS Simulator,id=<UDID>")
    args = parser.parse_args()
    verify(Path(__file__).resolve().parents[1], args.destination)
