#!/usr/bin/env python3
"""Validate original fixed puzzles with a development-only pinned rules tool."""

import argparse
import json
from pathlib import Path

import chess


def validate(path, require_challenge=False):
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
        checking_nonmates = set()
        for move in legal_moves:
            if move.promotion is not None:
                raise ValueError(f"{puzzle_id}: promotion is excluded.")
            board.push(move)
            if board.is_checkmate():
                mates.add(move.uci())
            elif board.is_check():
                checking_nonmates.add(move.uci())
            board.pop()
        recorded_legal = fixture["legalMoves"]
        recorded_accepted = fixture["acceptedMoves"]
        if len(recorded_legal) != len(set(recorded_legal)) or set(recorded_legal) != legal:
            raise ValueError(f"{puzzle_id}: legal-move set incomplete or incorrect.")
        if not mates or len(recorded_accepted) != len(set(recorded_accepted)):
            raise ValueError(f"{puzzle_id}: expected nonempty unique accepted moves.")
        if set(recorded_accepted) != mates:
            raise ValueError(f"{puzzle_id}: accepted moves must equal ALL mate-in-one moves.")
        metadata = fixture.get("challenge")
        if require_challenge and metadata is None:
            raise ValueError(f"{puzzle_id}: challenge catalog requires metadata.")
        if metadata is not None:
            expected = "easy" if len(mates) >= 3 else "medium" if len(mates) == 2 else "hard"
            if metadata["difficulty"] != expected:
                raise ValueError(f"{puzzle_id}: difficulty does not match accepted-move proxy.")
            recorded_checks = metadata["checkingNonmates"]
            if len(recorded_checks) != len(set(recorded_checks)) or set(recorded_checks) != checking_nonmates:
                raise ValueError(f"{puzzle_id}: checking nonmate set incomplete or incorrect.")
            focus = metadata["focus"]
            start_file, start_rank, size = (focus[key] for key in ("fileStart", "rankStart", "size"))
            if any(type(value) is not int for value in (start_file, start_rank, size)) or not 3 <= size <= 5:
                raise ValueError(f"{puzzle_id}: invalid focus dimensions.")
            if not (0 <= start_file <= 8-size and 0 <= start_rank <= 8-size):
                raise ValueError(f"{puzzle_id}: focus outside standard board.")
            def contains(square):
                return start_file <= chess.square_file(square) < start_file+size and start_rank <= chess.square_rank(square) < start_rank+size
            required = set(board.piece_map())
            for move in legal_moves:
                if move.uci() in mates:
                    required.update((move.from_square, move.to_square))
            defender = board.king(not board.turn)
            required.update(chess.SquareSet(chess.BB_KING_ATTACKS[defender]))
            if not all(contains(square) for square in required):
                raise ValueError(f"{puzzle_id}: focus clips a piece, mate endpoint, or defending-king neighbor.")
        print(f"PASS {puzzle_id}: valid; {len(legal)} legal moves; mates {', '.join(sorted(mates))}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "fixtures", nargs="?", type=Path,
        default=None,
    )
    args = parser.parse_args()
    try:
        paths = [args.fixtures] if args.fixtures else [
            Path(__file__).resolve().parents[1] / "Sidequest/Resources" / name
            for name in ("chess-puzzles.json", "chess-challenges.json")
        ]
        for path in paths:
            validate(path, require_challenge=path.name == "chess-challenges.json")
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(1, f"FAIL {error}\n")


if __name__ == "__main__":
    main()
