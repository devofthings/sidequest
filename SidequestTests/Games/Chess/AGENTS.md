# Chess verification

Test pure puzzle behavior through the same public attempt operations used by the adapter: every accepted solution, wrong legal moves, illegal moves, moving-side selection, coordinates, and frozen completion. Use original canonical fixtures with the reproducible external validation in [CHESS.md](../../../docs/CHESS.md). Tests must not fetch live puzzle data or rely on an engine installation.

Controller and app-flow tests must cover preview/start with no selected piece, input gates, skip/reset, revisit/completion, and both moving colors when presentation is introduced. Keep engine files, virtual environments, generated reports, and private output outside Git.
