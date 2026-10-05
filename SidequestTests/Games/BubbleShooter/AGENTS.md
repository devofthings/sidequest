# Bubble-shooter verification

Use deterministic pure-rule inputs and actual aim traces from the game interface. The fixed challenge wins with 0°, 0°, and 6° right; seven straight shots lose at the danger row. An independent injected challenge proves the eight-shot limit. Check finite-segment clearance against every stationary bubble, valid staggered-slot attachment, color components/detachment, and old-plan rejection after reset.

Presentation tests additionally own reset during a pending shot and fresh completed-visible replay. Keep test clocks/sleep injected and preserve the shared runtime's attempt gate; no wall-time luck or direct feed/game internals in running-app checks. See [game decisions](../../../Sidequest/Games/BubbleShooter/AGENTS.md) and [unit guidance](../../AGENTS.md).


Use a test-owned noncooperative main-actor continuation gate for shot pauses. Await named arrival/return signals rather than sleeps, yields, or the controller's private Task. Resume every continuation, including canceled old work while a new flight is pending, and assert public rules/flight/outcome. The pause closure returns on the same actor, letting the controller apply its post-await gate before the waiting test's next actor turn.

For #137, generated and fallback challenges must retain three independent ceiling colors, require three clearing actions, and replay to a win within the existing eight-shot rules. Probe every supported integer first-shot angle on representative seeded games in addition to the structural lower bound; a longer optional witness is not proof of harder play. Keep deterministic frozen reset and seed diversity tests. Historical fixed-fixture three-shot rules remain separate from normal production generation.

Reset verification compares observable frozen board, next color, shot counter and outcome, then replays the same witness against a fresh challenge. Never require whole-game equality after reset: the private revision deliberately advances to reject old shot plans. Assert stale-plan rejection instead of weakening that protection.


#138 mapping tests establish actual uniform-scale vertical/45-degree rays, angle clamps and rejection of nonfinite/out-of-area/launcher/downward points. Controller tests exercise public originating leases, no input on preview, replacement/cancel/Slider/reset/retirement invalidation and rejection after a same-attempt nonterminal Fire finishes. Beginning a lease without a valid initial ray makes no aim/shot mutation; the native test begins on the visible launcher then moves upward. The real guide is compared to reflected traceShot geometry without mutating board/revision. Use the existing named noncooperative gate, not sleeps or private tasks.


#163 supersedes the historical #138 ray mapping assertions: horizontal position alone maps center/edges/interior at every valid vertical height and supported board scale, including the launcher. Reject nonfinite/out-of-region input without mutation. Existing controller originating-lease and real-trace tests remain required; no controller/rule changes are selected. Native tests observe the direct control's real accessibility value after gestures instead of a removed visible angle label.

## Attempt-budget verification #188

Opt-in Easy8/Medium5/Hard3 configurations keep the original witnessed three-clearing-shot challenges and RNG consumption. Test generated and fallback witnesses through actual rules, including Hard's final permitted winning shot; injected nonwinning states isolate actual shot exhaustion from earlier danger loss. Reject mismatched tier metadata and invalid caps. Preserve first-action activation, stale leases, frozen reset, completed restoration and Replay with the existing noncooperative delay gate. No sampled aim-tolerance or human calibration claim is established by these tests. Root owns native execution; author format/doc checks are not gameplay evidence.
