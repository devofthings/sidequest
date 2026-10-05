# Sidequest MVP

## Confirmed direction

Build a private iPhone prototype that combines short news stories and simple games in one swipeable feed. News is an essential part of the experience, rather than a separate destination alongside a game catalog.

The first test asks whether switching between reading and playing is enjoyable enough to want to reopen the app. Use English news and build the iPhone app natively with SwiftUI.

Sidequest is the working name. The GitHub repository is private. Use GitHub Issues for small tasks, the private GitHub Project for workflow status, and repository documentation for durable decisions and agent context. See [WORKFLOW.md](WORKFLOW.md) when selecting or updating work.

## First-test experience

- Start with 30 clearly fictional English demo stories when saved news is absent, or import real English snapshots with source-provided excerpts and original links. Intentional empty imports stay empty. Automatic news fetching is deferred.
- Shuffle games and show one article after every five games, cycling the current story pool. The bottom card counter is removed. Swipe directly on full-page cards; cards track the finger and settle using native paging. A compact accessible navigation menu also moves between cards. Overflowing content scrolls within its card; outward gestures starting at its top/bottom edge page. Movement stays manual.
- Each game initially shows its inactive board. The first meaningful interaction starts the eligible card and applies that action immediately: select a Sudoku cell or Chess piece, reveal a Memory card, or aim/Fire in Bubble. There is no extra Tap to play step. Memory stays face down until an actual flip; answers remain hidden. Appearance and scrolling never start an attempt. See [first-interaction policy](GAME_PREVIEWS.md).
- Reset an unfinished game when its card is skipped. Returning shows the inactive frozen challenge; the next meaningful interaction starts a fresh attempt. Fresh attempts are more important than saved progress in this test.
- Include simple Sudoku, memory pairs, one-move chess puzzles, and a bubble shooter. Approved #104 extends current source to endless manual scrolling with new local challenges; the recorded MVP download remains finite.
- Test in the iPhone simulator and on the user's own iPhone through Xcode.

The overall experience is evaluated through personal testing; a quantitative retention target has not been established. Success means the user enjoys switching between news and games and wants to reopen Sidequest.

## Personal-test outcome

On October 5, 2026 (Europe/Berlin), the owner reported successful installation and play on their iPhone and supplied [actual product feedback in #10](https://github.com/devofthings/sidequest/issues/10#issuecomment-5995830255). Device model, iOS version, exact installed source/build, and news snapshot dates were not supplied. Detailed per-game/news flows and device VoiceOver were not reported, so this record does not certify them or any unmerged PR. See [installation evidence boundaries](INSTALL.md#owner-reported-iphone-test).

The owner finds the app “a bit boring” and the games bland. Keep the mixed news/game concept, with coherent design, animations, and making the games fun as the next refinement priorities. The existing research-led design authorization in [#13](https://github.com/devofthings/sidequest/issues/13) remains accepted; its selected baseline and merged work are recorded in [DESIGN.md](DESIGN.md). Issue #13 is complete. This feedback guides further bounded refinement within that direction; it does not mean a new design or motion plan is already implemented.

The owner likes news interruptions but is unsure whether an article after five games is right. Current five-game cadence, manual paging, explicit tap-to-play, and skip/reset behavior remain in effect until a bounded replacement is accepted. [#10](https://github.com/devofthings/sidequest/issues/10) is closed for actual testing and feedback, without claiming positive retention or that the current games are already enjoyable.

The following proposals remain Ideas, with no research or implementation authorized:

- [#119](https://github.com/devofthings/sidequest/issues/119): adaptive game and news frequency after repeated skips.
- [#146](https://github.com/devofthings/sidequest/issues/146): multiple geographic news scopes, such as Hamburg, Germany, Europe, and global.
- [#147](https://github.com/devofthings/sidequest/issues/147): pocket Snake.
- [#148](https://github.com/devofthings/sidequest/issues/148): WarioWare-inspired or original microgames. The comparison selects no timers, automatic start/paging, licensed assets, or backend.

## Deferred work

On October 5, 2026, the owner authorized research-led visual design and animations for the MVP pitch in [design task #13](https://github.com/devofthings/sidequest/issues/13), superseding the earlier wait for personal testing. Use a vivid, modern, cohesive direction that draws attention and supports engaging play. Research common visual and motion practices before implementation; the lead may select the direction without waiting for owner design approval. Cover all four games, news, preview/play/completion, and navigation with readable text, accessible controls, Reduce Motion, and stable board geometry. Figma remains a proposed tool; no paid dependency is authorized.

Defer accounts, ads, payments, licensed game catalogs, and social-platform integrations. The user confirmed these boundaries for the first prototype. Automatic scraping and news refreshing are also deferred in favor of manual imports.

Phase two will introduce a backend for accounts and synced preferences, plus high scores and leaderboards. Backend provider and gamification rules are still open decisions; they are outside the first-test scope.

See [DECISIONS.md](DECISIONS.md) for the status of each decision.

## Delivery sequence

The selected [source structure](STRUCTURE.md) groups games into independently owned areas and defines scoped guidance and source discovery. The foundation provides runnable app/test targets and verified simulator commands using that layout. The shared card contract enables separate work on the feed, news imports, and four games. Integration follows those feature tasks; the personal test follows a working integrated build. GitHub Issues own the detailed acceptance criteria and prerequisite links.

## Current repository state

The SwiftUI feed, shared lifecycle contract, real Sudoku, Memory, two one-move Chess cards, and Bubble shooter are implemented. The recorded finite MVP integrates a once-shuffled deck with private saved English news and the native Files importer. Missing/empty news in that release leaves five real game cards; invalid input preserves saved bytes and the current deck. Tap-to-play remains explicit; skipping/backgrounding/library presentation resets unfinished play, while completed results persist within the session. That immutable release has no fictional-news fallback or game demos. Merged #104 source extends the deck with endless generated game batches; merged #106 source adds nil-only demo news and five-game cadence below. The legacy two-story samples remain separate Debug fixtures. Integrated delivery and selected-release source/download installation evidence are recorded in [#9](https://github.com/devofthings/sidequest/issues/9#issuecomment-5976928508). The owner completed personal testing and product feedback in #10; see [the personal-test outcome](#personal-test-outcome).

The [2026.10.14 MVP](https://github.com/devofthings/sidequest/releases/tag/2026.10.14) passed all 133 native tests (96 unit, 37 UI), Debug/ARM64 Release builds, strict lint, source discovery, and offline tooling on Xcode 27.0/iOS 27.0. Fresh actual-tag source and downloaded-app installation/normal launch also passed; see [delivery evidence](INSTALL.md#verified-mvp-delivery). Game-specific checks remain in [SUDOKU.md](SUDOKU.md#verification), [MEMORY.md](MEMORY.md#verification), [CHESS.md](CHESS.md), and [BUBBLES.md](BUBBLES.md).

The deployment target is iOS 17.0; execution there is unverified. Simulator-first delivery was selected in resolved [#79](https://github.com/devofthings/sidequest/issues/79). The owner subsequently reported successful installation and basic play on their iPhone in #10; exact device/OS/build/snapshot dates and device VoiceOver outcomes remain unknown. The personal-test feedback is separate from simulator tests and technical delivery. Routine exact-head PR verification remains required; the owner's #112 decision removes automatic main checks after merging. Publication remains separately owner-authorized and manual. Seven older preview release objects and 21 assets were removed after preserving tags/source, including the `2026.10.7` statistics baseline. Follow [release guidance](RELEASES.md) for actual availability and provenance.

## Approved follow-up: endless feed

On October 4, 2026, the user requested endless scrolling with automatically generated games in [#104](https://github.com/devofthings/sidequest/issues/104). Manual swiping continues beyond the initial cards using locally generated challenges; explicit tap-to-play and skip/reset remain accepted. Issue #104 merged after full 151-test verification and fresh review, with reused validated Chess puzzles and fresh Sudoku, Memory, and Bubble variants. Its initial news-once default is superseded by approved #106: the immutable `2026.10.14` release remains the verified finite-deck MVP. See [ENDLESS.md](ENDLESS.md).

## Approved follow-up: demo news cadence

The owner approved more clearly fictional English articles for realistic private testing, one article after four or five games, and removal of the visible bottom card counter in [#106](https://github.com/devofthings/sidequest/issues/106). The lead chose five and a 30-story original demo pool for genuinely absent saved news; imported or intentionally empty news stays authoritative. This supersedes the initial news-once/global mixed-shuffle default. Issue #106 merged through [PR #107](https://github.com/devofthings/sidequest/pull/107) as `f3dc1620b675a0d0e90119855a55f8326609d8eb` on October 4, 2026. The immutable finite-MVP download remains unchanged; see [DEMO_NEWS.md](DEMO_NEWS.md) for current source policy.

## Stable gameplay correction

Approved bug [#108](https://github.com/devofthings/sidequest/issues/108) keeps boards and primary controls stable during feedback/completion changes, with complete accessible text and owned overflow. See [GAME_LAYOUT.md](GAME_LAYOUT.md); this correction predates the separately authorized design work in #13.

## Requested pocket-game follow-ups

On October 4, 2026, the owner requested pocket-sized variants for every game, Chess closer to [Pocket Chess](https://play.google.com/store/apps/details?hl=en&id=com.dkxqzbfkjt.pocketchess), and different difficulties. On October 5, the owner selected [#117's first specification](pocket-games/README.md): fixed 4×4 Chess focus windows e5–h8 for White and a1–d4 for Black, with standard 8×8 rules and all coordinate controls; retain current compact 4×4 Sudoku and six-pair Memory configurations. [#132](https://github.com/devofthings/sidequest/issues/132) implements Chess. Genuine reduced-board rules and multiple-move Chess remain unselected; the reference does not define Sidequest's rule system.

The owner's subsequent October 5 instruction that all puzzles must be pocket-sized and Bubble should have better controls and be harder authorizes [#135](https://github.com/devofthings/sidequest/issues/135). That follow-up audits compact card layouts and replaces the current one-shot-only production Bubble default with compact attainable multi-shot challenges; the earlier specification's retention of that default is superseded for this follow-up. Bubble controls and generation are separate from #132. Preserve explicit Fire while the owner's shooting-semantics choice is pending. [#118](https://github.com/devofthings/sidequest/issues/118) owns the accepted mixed feed of Easy/Medium/Hard game cards with a difficulty label on each game; technical classification criteria and implementation remain pending. No automatic progression or manual tier selector is accepted. These follow-ups do not change the immutable published MVP's contents.

The owner also proposed reducing a game's future frequency after repeated skips. [#119](https://github.com/devofthings/sidequest/issues/119) records this in Ideas until signals, bounds, storage and reset behavior are specified. The October 5 feedback extends this Idea to news frequency; keep it separate from difficulty and retain the five-game/news cadence until a replacement is accepted. No recommendation algorithm, telemetry service or backend is selected. Current implementation and immutable release evidence remain as recorded above.

## Accepted personal-test refinements — October 5, 2026

The owner approved vivid, contemporary Chess and Memory artwork under [#159](https://github.com/devofthings/sidequest/issues/159), restrained interaction haptics and popping feedback under [#161](https://github.com/devofthings/sidequest/issues/161), and standard 9×9 Sudoku with digits 1–9 under [#162](https://github.com/devofthings/sidequest/issues/162). Difficulty support for Sudoku, Bubble, and Chess belongs to [#118](https://github.com/devofthings/sidequest/issues/118); the owner selected mixed Easy/Medium/Hard game cards with a difficulty label on each game; classifications and implementation remain pending. Varied compact Chess board sizes and piece configurations extend [#117](https://github.com/devofthings/sidequest/issues/117); the owner selected differently sized cropped areas under standard 8×8 rules; full-board legality and complete semantic coordinates remain authoritative. True smaller-board rules and multistep mechanics are not selected. These directions supersede retaining only the current 4×4 Sudoku and fixed Chess focus views as the eventual capability, without claiming those follow-ups are already implemented. [#163](https://github.com/devofthings/sidequest/issues/163) removes Bubble's visible numeric angle in favor of horizontal dragging and its dotted trajectory; Fire stays explicit. Adaptive frequency #119 and optional sounds [#164](https://github.com/devofthings/sidequest/issues/164) remain Ideas. The immutable released MVP and its delivery evidence remain unchanged.

For [#160](https://github.com/devofthings/sidequest/issues/160), the owner replaces the dedicated visible start button with a tap-sensitive inactive game surface and a lightweight hint. A tap only starts; swipes and canceled touches never start. The hint retains accessible and keyboard Start game activation, and its measured row stays reserved during play/completion. See [preview policy](GAME_PREVIEWS.md); actual native verification belongs to the PR evidence.

## Standard pocket Sudoku source #170

Approved #162 presentation child #170 adds standard9×9 production cards, digits1–9 and3×3 regions. A lead-selected maximum12 editable cells bounds the initial session, without defining difficulty. Mini fixtures remain compatible; native44point coordinate alternatives supplement the compact overview. #118 mixed labeled exposure and first-pass Chess/Memory criteria are accepted; Sudoku/Bubble criteria remain proposed and parent162 remains open. Actual native fit/gameplay evidence belongs to the PR; the immutable published MVP is unchanged.

## First-interaction activation #185

On October 5, the owner said "tap to play is annoying" and selected "The first game interaction also starts it." This supersedes #160's inert initiating tap and visible hint. Shared runtime eligibility, manual paging, skip/reset and quiet completed revisits remain. Production and every real-game fixture use the selected policy; the existing DEBUG placeholder demo retains its separately documented manual lifecycle contract. Implementation and native proof remain pending until the #185 PR passes review and exact-head verification.
