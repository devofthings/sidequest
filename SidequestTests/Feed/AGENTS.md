# Feed adapter verification

Verify the public host/runtime interface with deterministic identities and retained test game owners. Cover preview-only visibility, idempotent start, reset ordering, stale tokens, scene inactivity, completed-result retention, and empty/end navigation. Keep rules outside the host and preserve fixture isolation under [test guidance](../AGENTS.md).

Reset tests observe ineligibility inside the delivered effect, before clearing simulated rule state. Unit tests cannot establish gesture usability; [running-app feed tests](../../SidequestUITests/FeedFlowTests.swift) cover those flows through accessibility.

Issue #87 adds settled adjacent-page commits and independent scene/host eligibility. Cover canceled/nonadjacent offsets, neighbor ineligibility, exactly-once skip reset, late commits while unavailable, and permanent retirement against stale activation callbacks. These tests verify lifecycle; actual UIKit gesture and hosting behavior requires running-app checks.

The native adapter regression gives a replacement pager a retired session request while the replacement is already active and has a laid-out viewport. Assert no movement/reset, then legitimate new-session movement, then rejection of stopped-host callbacks; an unlaid-out pager would produce a false passing rejection.
