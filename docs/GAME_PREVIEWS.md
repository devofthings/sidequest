# Inactive boards and first interaction #185

On October 5, 2026, the owner selected "The first game interaction also starts it." This supersedes #160's inert initiating tap, top-row Tap to play hint and transparent interception surface for real games. Every real-game fixture and production composition uses this policy. No new historical activation flag exists.

## Ownership and eligibility

`GameRuntime` remains the only lifecycle authority. Controllers first validate a meaningful action, call `prepareInteraction(visibility:)` synchronously on MainActor, and apply that same action after the start effect initializes their rules. No suspension, duplicate attempt owner, view appearance effect, whole-view tap overlay or swallowed initiating action is involved.

Eligibility reads never start. Selected settled visibility already combines scene and modal/host availability. Hidden, completed and retired runtimes cannot initiate. Rendered actions capture visibility identity so a held callback cannot survive hide/reset/return. Existing attempt and Bubble lease gates still reject delayed stale work.

Sudoku editable-cell selection starts and selects that cell. Coordinate choices can read givens and change the cursor without starting; only resolving an editable cell starts. Preserve the requested coordinate locals across the synchronous start effect, which resets the old cursor. Invalid bounds and givens cannot initiate. Digit entry requires a selected cell.

Memory flips the first valid hidden tile immediately using its immutable initial layout. Invalid indices, matched/revealed cards and resolving mismatches are ignored. Skip cancels mismatch work and clears the attempt; a subsequent flip starts from the same frozen layout.

Chess starts when the user selects an own-side piece, then retains that selection. Before play, empty/opponent squares cannot initiate. Native board and full-size piece controls use the same controller. Standard chess rules, coordinate alternatives and quiet completed restoration remain.

Bubble starts from a finite user aim event, valid mapped drag, or explicit Fire. Direct-touch mapping must be validated before lease creation. Dragging/releasing never fires; Fire still shoots. Programmatic Slider synchronization and trajectory rendering never start. Held native gestures retain visibility/attempt leases. Invalid mapping, nonfinite input, hidden cards and completed results cannot initiate.

## Presentation and compatibility

Real game inputs are eligible in inactive preview; there is no start cue or intercept overlay. Keep the static empty 44-point chrome reservation across preview, play and completion so all anchors stay stable. Native scrolling, coordinate menus, keyboard/accessibility actions and 44-point controls remain.

The existing DEBUG-only placeholder feed demo retains explicit start as a historical manual lifecycle fixture. It uses explicit-policy runtime construction only in the existing `useDemoGames` branch; Release/normal production and all real-game routes cannot select it. Its retained journeys establish the manual API only and do not certify current real-game activation. The manual `GameRuntime` initializer/start API preserves its explicit contract; application composition explicitly selects first interaction.

## Readiness and evidence

The author used the local agent-grill self-assessment and a fresh read-only readiness reviewer. The lead rejected adding a historical real-game bypass. Invalid-action validation, coordinate start-reset ordering and stale held gestures were resolved before implementation. Actual native, fresh full review and exact-head PR CI are lead-owned and pending. Formatting/static checks alone certify no gameplay, accessibility, device or release result. The immutable finite MVP release evidence stays unchanged.
