# Feed adapter verification

Verify the public host/runtime interface with deterministic identities and retained test game owners. Cover preview-only visibility, idempotent start, reset ordering, stale tokens, scene inactivity, completed-result retention, and empty/end navigation. Keep rules outside the host and preserve fixture isolation under [test guidance](../AGENTS.md).

Reset tests observe ineligibility inside the delivered effect, before clearing simulated rule state. Unit tests cannot establish gesture usability; [running-app feed tests](../../SidequestUITests/FeedFlowTests.swift) cover those flows through accessibility.

Issue #87 adds settled adjacent-page commits and independent scene/host eligibility. Cover canceled/nonadjacent offsets, neighbor ineligibility, exactly-once skip reset, late commits while unavailable, and permanent retirement against stale activation callbacks. These tests verify lifecycle; actual UIKit gesture and hosting behavior requires running-app checks.

The native adapter regression gives a replacement pager a retired session request while the replacement is already active and has a laid-out viewport. Assert no movement/reset, then legitimate new-session movement, then rejection of stopped-host callbacks; an unlaid-out pager would produce a false passing rejection.

`FeedNewsCadenceTests` verifies carried five-game cadence over varied preparation boundaries and complete demo-pool cycles, with unique appearance IDs and unchanged source snapshots. Preparing or repeating a candidate must leave the prior cadence value unchanged. See [demo policy](../../docs/DEMO_NEWS.md).

`GameLayoutBudgetTests` cover the presentation-only native viewport minus independent stable chrome, real viewport changes and44-point board-target floors when content cannot fit. These values never enter feed-domain/game-rule/controller behavior. Actual containment and hit targets require root-owned native checks.

## Preview start requests #160

`PreviewStartRequestTests` use the real runtime and Sudoku controller to cover inert/duplicate activation, stale visibility leases after hide/return, idempotent host visibility, retirement, and completion. These deterministic tests do not establish UIKit tap/pan arbitration; actual native surface/scroll checks remain separately required.
