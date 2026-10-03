#!/usr/bin/env python3
"""Validate original fixed puzzles with a development-only pinned rules tool."""

import argparse
import json
from pathlib import Path

import chess


def validate(path):
    if chess.__version__ != "1.11.2":
        raise ValueError("Use pinned chess 1.11.2 from chess-validation-requirements.txt.")
    fixtures = json.loads(path.read_text())
    if not fixtures:
        raise ValueError("No puzzle fixtures.")
    ids = set()
    for fixture in fixtures:
        puzzle_id = fixture["id"]
        if not isinstance(puzzle_id, str) or not puzzle_id.strip() or puzzle_id in ids:
            raise ValueError("Puzzle IDs must be nonempty and unique.")
        ids.add(puzzle_id)
        if fixture["objective"] != "checkmate-in-one":
            raise ValueError(f"{puzzle_id}: unsupported objective.")
        board = chess.Board(fixture["fen"])
        if not board.is_valid() or board.is_game_over():
            raise ValueError(f"{puzzle_id}: invalid or already finished position.")
        if fixture["sideToMove"] != ("white" if board.turn else "black"):
            raise ValueError(f"{puzzle_id}: side-to-move mismatch.")
        pieces = board.piece_map().values()
        if len(board.piece_map()) != 3 or any(
            piece.piece_type not in (chess.KING, chess.QUEEN) for piece in pieces
        ):
            raise ValueError(f"{puzzle_id}: initial slice requires two kings and a queen.")
        if len(board.pieces(chess.QUEEN, board.turn)) != 1:
            raise ValueError(f"{puzzle_id}: moving side must own the queen.")
        if board.castling_rights or board.ep_square is not None:
            raise ValueError(f"{puzzle_id}: castling and en passant are excluded.")
        legal_moves = list(board.legal_moves)
        legal = {move.uci() for move in legal_moves}
        mates = set()
        for move in legal_moves:
            if move.promotion is not None:
                raise ValueError(f"{puzzle_id}: promotion is excluded.")
            board.push(move)
            if board.is_checkmate():
                mates.add(move.uci())
            board.pop()
        recorded_legal = fixture["legalMoves"]
        recorded_accepted = fixture["acceptedMoves"]
        if len(recorded_legal) != len(set(recorded_legal)) or set(recorded_legal) != legal:
            raise ValueError(f"{puzzle_id}: legal-move set incomplete or incorrect.")
        if not mates or len(recorded_accepted) != len(set(recorded_accepted)):
            raise ValueError(f"{puzzle_id}: expected nonempty unique accepted moves.")
        if set(recorded_accepted) != mates:
            raise ValueError(f"{puzzle_id}: accepted moves must equal ALL mate-in-one moves.")
        print(f"PASS {puzzle_id}: valid; {len(legal)} legal moves; mates {', '.join(sorted(mates))}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "fixtures", nargs="?", type=Path,
        default=Path(__file__).resolve().parents[1]
        / "Sidequest/Resources/chess-puzzles.json",
    )
    args = parser.parse_args()
    try:
        validate(args.fixtures)
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(1, f"FAIL {error}\n")


if __name__ == "__main__":
    main()
