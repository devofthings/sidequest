# Memory pairs

Issue #6 owns this short, six-pair challenge. Keep `Rules` independent of UI and time; its presentation adapter consumes the retained `GameRuntime` established by #3. Composition owns one controller per card ID and binds its runtime once. No scores, persistence, replay, or additional game modes belong to this issue.

## Implementation question review

The implementation agent answered the project-local agent-grill questions; the lead coordinates shared runtime/composition ownership. The following delegated technical choices implement the accepted issue, with verification planned until actual results are recorded.

| Question | Kind | Answer and rationale | Evidence | Verification |
| --- | --- | --- | --- | --- |
| Which board stays short and readable? | Delegated technical choice | Six distinct symbols, each exactly twice; three columns normally and two at accessibility text sizes. Symbols have shape and spoken names, beyond color. | Issue #6 requires a fixed readable board and distinguishable pairs; CODING.md requires Dynamic Type and accessible labels. | Planned: controlled shuffle/pair-count rules tests and normal/largest-text running-app inspection. |
| How do flips and mismatch resolution behave? | Delegated technical choice | Pure value rules model choosing, unresolved mismatch, and completion. Ignore repeated, matched, out-of-bounds, or mismatch-pending input. Reveal a mismatch for 700 ms through an injected async delay, then conceal it. | Issue #6 matching/delay/input criteria. | Planned: double taps, locked mismatch, all-pairs completion, controlled delay without real sleeps. |
| Who owns an attempt and delayed work? | Fact and delegated technical choice | The single shared runtime owns lifecycle. `MemoryController` binds one weak effect handler, creates rules only on explicit start, owns/cancels its delay task, and checks cancellation plus current attempt/visibility after suspension. Reset clears rules; completion retains them. | Shared lifecycle and common game guidance require invalidation before reset and post-suspension eligibility checks. | Planned: skip while a mismatch is pending, resume canceled work after a new attempt, hidden/pre-start input, completed revisit, actual feed start/skip. |

Tests mirror this area under `SidequestTests/Games/Memory`; deterministic UI tests use only the composition root's DEBUG fixture route. Keep those fixtures original and separate from real content. No shared feed, app, or lifecycle interfaces are edited by this feature.
