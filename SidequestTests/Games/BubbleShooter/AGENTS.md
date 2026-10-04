# Bubble-shooter verification

Use deterministic pure-rule inputs and actual aim traces from the game interface. The fixed challenge wins with 0°, 0°, and 6° right; seven straight shots lose at the danger row. An independent injected challenge proves the eight-shot limit. Check finite-segment clearance against every stationary bubble, valid staggered-slot attachment, color components/detachment, and old-plan rejection after reset.

Presentation tests additionally own reset during a pending shot and fresh completed-visible replay. Keep test clocks/sleep injected and preserve the shared runtime's attempt gate; no wall-time luck or direct feed/game internals in running-app checks. See [game decisions](../../../Sidequest/Games/BubbleShooter/AGENTS.md) and [unit guidance](../../AGENTS.md).


Use a test-owned noncooperative main-actor continuation gate for shot pauses. Await named arrival/return signals rather than sleeps, yields, or the controller's private Task. Resume every continuation, including canceled old work while a new flight is pending, and assert public rules/flight/outcome. The pause closure returns on the same actor, letting the controller apply its post-await gate before the waiting test's next actor turn.
