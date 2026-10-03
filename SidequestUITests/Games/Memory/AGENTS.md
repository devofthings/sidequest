# Memory running-app checks

The composition-owned DEBUG argument `-sidequest-memory-fixtures` must put a Memory card first and at least one other card next. Its board has adjacent pairs in `MemorySymbol.allCases` order. These original fixtures are isolated from personal content; production still shuffles through its normal board factory. Until this route is wired, the tests are prepared but must not be reported as passing.

Use accessible tile labels to verify that explicit start flips nothing, hidden cards disclose no symbol, matched cards remain revealed, mismatch resolution hides unmatched cards, skip restores the preview, and completion survives a revisit. Scroll inside the game surface to reach all tiles at the largest text size, while feed navigation stays separately usable. Wait for visible state changes instead of adding fixed sleeps. Unit tests separately control noncooperative delayed callbacks; running-app waits do not prove that stale callback boundary.
