# Chess verification

Test pure puzzle behavior through the same public attempt operations used by the adapter: every accepted solution, wrong legal moves, illegal moves, moving-side selection, coordinates, and frozen completion. Use original canonical fixtures with the reproducible external validation in [CHESS.md](../../../docs/CHESS.md). Tests must not fetch live puzzle data or rely on an engine installation.

Controller and app-flow tests cover preview/start with no selected piece, input gates, skip/reset, revisit/completion, and both moving colors through the retained presentation adapter. App-flow checks also measure the alternative controls' actual accessibility frames and perform edge actions before asserting the resulting selection and mate. Keep engine files, virtual environments, generated reports, and private output outside Git.

Await the real off-UI bundled loader in rule/controller tests. Startup tests suspend an injected loader to verify composition ordering, single load/cache reuse, visible failures, and cancellation plus late completion after replacement; never bypass loading with a fabricated success.

For #132, verify immutable White e5–h8 / Black a1–d4 window ordering, all pieces/mates and defending-king neighbors, unchanged standard-board nonmates outside the crop, and full-board fallback for unknown IDs, changed FENs, or accepted destinations outside the crop. The window owns presentation only; canonical move-table validation remains separate.

## Varied original catalog #177

`ChessChallengeTests` exercises the separate metadata-required catalog, both sides in each band, independent3/4/5 crops, every accepted mate, off-crop legal nonmates and frozen configuration through skip/reset/completed revisit. Negative decoding covers proxy mismatches, accepted/duplicate checking moves, missing metadata and malformed/clipping windows. Complete legal/checking/mating evidence belongs to the development-only validator, not a duplicated Swift rules engine. The historical two-fixture tests stay unchanged. Root owns native execution.
