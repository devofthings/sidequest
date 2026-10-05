# Pocket-game specification

Before changing pocket dimensions, piece rules, move depth, or compact challenge selection, read [the proposal](README.md) and [issue #117](https://github.com/devofthings/sidequest/issues/117). The owner approved the direction; the concrete first revision remains proposed pending the owner's selection. Keep current behavior authoritative until that choice is recorded.

The proposed Chess focus window changes presentation only: retain standard 8×8 coordinates and independently validated complete legal/mate sets. Freeze the window per challenge, display all pieces and accepted destinations, and preserve full-board coordinate input. A focus-window edge never becomes a chess-rule boundary. Genuine reduced-board rules and multi-move puzzles require a separate agreed specification.

This area owns proposal text and its supporting evidence, not application implementation. After agreement, coordinate the authoritative decision and game-owned guidance with their current editing owners before creating implementation tickets. Preserve explicit start, frozen challenges, unfinished reset, completed revisits, accessibility, and stable geometry under the existing shared rules.
