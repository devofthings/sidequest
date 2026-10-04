# Chess verification

Test pure puzzle behavior through the same public attempt operations used by the adapter: every accepted solution, wrong legal moves, illegal moves, moving-side selection, coordinates, and frozen completion. Use original canonical fixtures with the reproducible external validation in [CHESS.md](../../../docs/CHESS.md). Tests must not fetch live puzzle data or rely on an engine installation.

Controller and app-flow tests cover preview/start with no selected piece, input gates, skip/reset, revisit/completion, and both moving colors through the retained presentation adapter. App-flow checks also measure the alternative controls' actual accessibility frames and perform edge actions before asserting the resulting selection and mate. Keep engine files, virtual environments, generated reports, and private output outside Git.

Await the real off-UI bundled loader in rule/controller tests. Startup tests suspend an injected loader to verify composition ordering, single load/cache reuse, visible failures, and cancellation plus late completion after replacement; never bypass loading with a fabricated success.
