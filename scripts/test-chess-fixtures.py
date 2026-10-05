#!/usr/bin/env python3
"""Exercise original Chess catalog validation with the existing pinned development tool."""

import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("chess_validator", ROOT / "scripts/validate-chess-fixtures.py")
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


class ChessFixtureValidationTests(unittest.TestCase):
    def test_original_resources_pass(self):
        for name in ("chess-puzzles.json", "chess-challenges.json"):
            with contextlib.redirect_stdout(io.StringIO()):
                VALIDATOR.validate(ROOT / "Sidequest/Resources" / name, require_challenge=name == "chess-challenges.json")

    def test_catalog_rejects_false_evidence(self):
        fixtures = json.loads((ROOT / "Sidequest/Resources/chess-challenges.json").read_text())
        mutations = [
            lambda f: f[0]["legalMoves"].pop(),
            lambda f: f[0]["acceptedMoves"].append("c2a2"),
            lambda f: f[0]["challenge"].update(difficulty="easy"),
            lambda f: f[0]["challenge"]["checkingNonmates"].pop(),
            lambda f: f[0]["challenge"]["checkingNonmates"].append("c2b2"),
            lambda f: f[0]["challenge"]["focus"].update(size=2),
            lambda f: f[0]["challenge"]["focus"].update(size=6),
            lambda f: f[0]["challenge"]["focus"].update(fileStart=-1),
            lambda f: f[0]["challenge"]["focus"].update(fileStart=6),
            lambda f: f[0]["challenge"]["focus"].update(fileStart=True),
            lambda f: f[0]["challenge"]["focus"].update(fileStart=1),
            lambda f: f[0].pop("challenge"),
        ]
        with tempfile.TemporaryDirectory(prefix="sidequest-chess-fixtures-") as directory:
            path = Path(directory) / "mutated.json"
            for index, mutate in enumerate(mutations):
                bad = copy.deepcopy(fixtures)
                mutate(bad)
                path.write_text(json.dumps(bad))
                with self.subTest(mutation=index), contextlib.redirect_stdout(io.StringIO()):
                    with self.assertRaises(ValueError):
                        VALIDATOR.validate(path, require_challenge=True)


if __name__ == "__main__":
    unittest.main()
