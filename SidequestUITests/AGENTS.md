# UI tests

This filesystem-synchronized root belongs only to `SidequestUITests`. XCTest UI tests launch and interact with the running app through accessibility. The foundation verifies launch and the accessible heading; critical news/game/start/skip flows are added when their owning issues implement them. Follow [verification policy](../AGENTS.md#verification).

Load deterministic fictional inputs from this target's `Fixtures`, isolated from app and unit-test resources. Target-wide `*.md` exclusion keeps scoped guidance out of products. Mark UI-test methods `@MainActor` instead of changing the pure-core isolation defaults.

For #87, use the production full-card pager in feed and real-game tests. `FeedNavigationSupport` opens the compact accessible menu for deterministic next/previous requests. Direct gesture tests cover cancellation, distance/velocity settling, horizontal input, and edge arbitration. Reveal overflowing game controls through `feed.cardScroll`, with no long press on a control, and require full viewport containment before tapping. Keep simulator motion recordings and screenshots outside Git; retain observed failures as well as final passing evidence.

`SystemAccessibilitySupport.withReduceMotion` changes only the current test simulator through native Settings and restores its observed original value in `defer`. Use it for actual system-motion checks; an environment override alone cannot establish UIKit motion behavior. Source-link tests verify native browser handoff and unchanged feed selection without asserting live webpage content.

The DEBUG replacement fixture changes the controller while retaining outer FeedView identity and active scene phase. Navigate first to retain a real pending action identity, replace, then verify first-card preview and explicit gameplay; a fresh app launch alone cannot cover stale-request replay or activation.
