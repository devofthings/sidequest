# App composition

`SidequestApp` owns one retained `FeedSessionState` and one `NewsImportModel`. The model's prepare closure may retain the coordinator; the coordinator never retains the model or a stored closure capturing it. Its startup method receives the model transiently. Follow [coding rules](../../docs/CODING.md), [card contract](../../docs/CONTRACT.md), and [application boundaries](../AGENTS.md).

## Integration #9 decisions

Evolve the existing startup owner into the single session coordinator rather than adding a competing startup/library/deck state machine. Load immutable Chess fixtures through its async `@concurrent` adapter and saved news through the side-effect-free storage read. Check cancellation and the current loading UUID on success and error paths before constructing a deck or adopting news. Canceled or stale results cannot publish, erase current news, or become a corrupt-news fallback. Rendering, sheet reopening, and completed startup never reload or reshuffle.

The finite integration/legacy test constructor `FeedComposition(news:chessPuzzles:)` throws and constructs five real game cards: Sudoku, Memory, bubble shooter, and separate White/Black Chess cards. Validate all news IDs against the exact five reserved IDs and validate full composition before saving an import. Similar IDs, including the old single Chess demo ID, are permitted. Shuffle once per deliberate successful session creation. Retain one concrete controller/runtime per stable ID and the immutable Chess fixture cache. The feed never inspects game rules; `ComposedGame` owns concrete adapters. That finite historical constructor has no placeholder game or demo-news fallback.

Normal startup uses demo stories only for confirmed absent saved news; intentional empty news yields games only. Corrupt/unavailable news yields real games plus a retryable library error and leaves damaged bytes intact. Missing game fixtures yield an accessible startup failure with Retry, without publishing a fabricated feed. Initial loading disables the library; initial candidate construction finishes before synchronous news adoption and ready publication.

News import captures its originating session before reading the file, prepares the entire inactive candidate asynchronously from cached fixtures before persistence, and reserves the save/adoption boundary with a main-actor lease. The prepared commit cannot throw or suspend: retire the previous controller, apply CURRENT modal availability to the candidate, and publish it. No cancellation check follows successful durable save. The model and deck update in one main-actor turn. Opening the library synchronously makes the host unavailable and cancels unfinished work; reopening/canceling preserves order, position, and completed results. Existing `FeedController` retains scene eligibility and permanent retirement; background/foreground cannot override modal absence or reactivate old sessions. Existing `FeedView` applies current scene phase on controller replacement and rejects old navigation requests.

Normal production uses the nil-only demo or private imported English pool and the endless constructor described below; the recorded release uses the finite MVP deck. The accessible 44-point News button opens the retained model in a library with automatic restoration disabled; startup owns the initial restore. Shared unwrapped `NewsCardContent` stays within the pager's single owned content scroller. NewsLibrary's standalone Debug preview may restore its own samples under the explicit legacy fixture flag.

## Debug verification routes

Keep generic `-sidequest-feed-test`, `-sidequest-feed-games-only`, and `-sidequest-feed-replacement-test` on six fictional cards/four demos (games-only four). Deterministic Sudoku, Memory, White/Black Chess, and Bubble fixture routes retain their original adjacent fictional-news membership; the generic same-view replacement button is Debug only. `SampleSession.make`, `PlaceholderGameController`, and `FoundationView` are compiled only in Debug. Normal launch resolves absent saved news through the explicitly labeled demo policy below.

`-sidequest-integration-fixtures` uses the finite historical integration constructor, five real game IDs, original fictional files under Documents/Sidequest Fixtures v2, stable isolated Application Support/IntegrationNewsTests persistence, and deterministic sorted order. `-sidequest-integration-reset` deletes only that owned test store at initial setup, never normal captures. Native Files selection exercises valid, empty, malformed, and exact reserved-ID input; it does not bypass validation or persistence. Debug-only file sharing exposes Documents to the picker; Release has no file-sharing keys or fixture/reset implementation. Fixture file I/O is `@concurrent` away from the UI actor. Integration Memory uses adjacent original pairs and a two-second mismatch delay. Bubble's optional `-sidequest-bubble-slow-shot` uses a six-second flight to expose reset boundaries. `-sidequest-large-text` exercises the largest accessibility category; actual Reduce Motion is changed/restored through native Settings. Release ignores all test arguments.

Select fixed Sudoku fixtures in finite Debug routes or generate production challenges before publication; skips reset the same puzzle. Memory owns its mismatch task and board factory; Chess owns validated original positions and coordinate input; Bubble owns swept collision, bounded shots, animation, and Replay. Composition creates adapters outside rendering and freezes each challenge once; the endless cache reconstructs inactive owners from completed values when necessary. Preserve minimum iOS17 and explicit actor boundaries. Simulator checks on iOS27 do not establish device/iOS17/VoiceOver operation; signing stays local under [INSTALL.md](../../docs/INSTALL.md).

Integration #9 readiness was a partial contribution until actual selected published-tag source/checksum/install proof existed. The verified MVP now has that [delivery evidence](../../docs/INSTALL.md#verified-mvp-delivery). The readiness change passed fresh independent review, exact-head CI, gated merge/main verification, and explicit manual publication. Preserve this manual-only policy and immutable release/source history; an old preview, environment value, or early issue closure cannot certify a future build. Personal enjoyment and deferred physical-device results require their own actual evidence. Follow [release policy](../../docs/RELEASES.md).

## Endless feed #104

The user approved extending production beyond its finite deck on October 4, 2026. Before changing replenishment, generated challenges, adapter eviction, or completed-result restoration, read [ENDLESS.md](../../docs/ENDLESS.md). Keep challenge identity/configuration stable per card, preserve manual settled paging and explicit start/reset, and retain completed revisits using lightweight state. Issue #106 supersedes the initial news-once default with five-game/news cadence and nil-only demo resolution. Validated Chess reuse remains a stated implementation default, not an owner answer. Issue #104 is merged; its evidence is recorded in ENDLESS.md. Preserve the immutable finite-MVP release evidence.

## Demo news and cadence #106

Normal startup resolves genuinely absent saved news to the original demo pool; empty, valid, corrupt and unavailable documents retain distinct outcomes. Never auto-save demos. Prepare five-game/news cadence and unique appearances before publishing; commit cursor state only with accepted current appends or safe session replacement. See [demo news policy](../../docs/DEMO_NEWS.md).

For #106, DEBUG integration fixtures use the new `Sidequest Fixtures v2` folder and skip writes when existing bytes match. Actual native probes showed identical newly named JSON imported while cached rewritten filenames remained inert across app installations; stable file identity avoids that provider race. Preserve the historical folder and all private captures. The v2 fixture contents retain the original valid/empty/malformed/reserved/collision cases; Release includes no fixture preparation. Current native helpers resolve the v2 container through Locations and require picker dismissal plus exact outcomes. See [demo verification](../../docs/DEMO_NEWS.md#verification-and-handoff).

## Visible inactive boards #88

Render the same game-owned initial board in preview and play, with gameplay disabled until the shared runtime accepts an explicit start. Preserve frozen configuration, face-down Memory, reset/completion behavior, and the reserved start footprint. Before changing this boundary, read [preview guidance](../../docs/GAME_PREVIEWS.md).

## Feedback verification composition #86

Both finite and rehydrating game composition use `GameFeedbackComposition.makeRuntime`. Production uses the runtime's standard 1.5-second celebration lifetime. Only Debug with `-sidequest-success-feedback-test` plus a recognized existing real-game fixture route injects a 10-second presentation lifetime for reliable XCTest observation. Game rules, move timing, completion gates, and native haptic requests remain unchanged; Release ignores this flag. Completed restoration receives only the completed attempt identity and never archives/replays presentation effects.

## Cold-launch logo introduction #91

The owner authorized a logo opening animation after selected Card S integration #14/PR133; the lead now starts this independent ticket in parallel with game work. Reuse the selected PNG bytes in a dedicated logo imageset. An App-retained presentation owner stays outside loading/error/ready, retry and session replacement. Prepare news/games in parallel without a minimum wait. Render only a brief noninteractive, accessibility-hidden decorative overlay: owner-approved #192 150 ms static introduction and 450 ms ease-in-out opacity fade without scale, maximum 600 ms nominal production clock. This supersedes the original 80/350 ms opacity/scale policy to soften the owner-reported abrupt fade. System Reduce Motion omits it immediately. Underlying loading/error/feed controls remain accessible; no game start, shot, page or haptic is introduced.

Agent-grill decision: Use a structured root task keyed by permanent finished state; mark consumed before the first suspension. Background/disappearance/Reduce Motion dismissal permanently finishes the model and cancels the root task, with post-await cancellation/phase checks rejecting late callbacks. Initial inactive scene is not a background event. Never recreate intro ownership on Retry/import/foreground, and never use a persisted onboarding preference. Actual launch timing/motion and device VoiceOver remain pending root verification.

## Standard Sudoku #170

Production generated Sudoku uses standard9×9 with at most12 editable cells under #170. Preserve legacy batch RNG draws by consuming the historical mini generator, then prepare standard Sudoku from a separate stable seed/index integer stream; this compatibility work keeps Memory/Bubble/shuffle witnesses unchanged. Finite mini routes stay historical. DEBUG-only -sidequest-standard-sudoku-test selects the original standard12-blank fixture and one news card; Release ignores it.

GameGenerationComposition explicitly selects mini only for the existing DEBUG endless fixture route, preserving its historical4×4 completion assertions. GeneratedGameBatch takes an explicit configuration with standard as its default; normal/Release production uses standard. The new standard route exercises the same9×9 rules/controller/view through deterministic original input.

## Branded launch canvas #181

Owner-approved #181 keeps the selected Card S introduction and its #91 lifetime unchanged. The root fills the window with the `LaunchCanvas` named color, including safe areas, underneath loading, failure, and ready states. It matches the static system launch background and current shared palette (light `#F5F3FF`, dark `#101427`). Keep preparation and input independent of the introduction. Loading/error titles use rounded system type; Retry uses the existing accessible prominent button style. Before changing launch assets, configuration, or timing, read [launch guidance](../../docs/design/LAUNCH.md).

## First meaningful interaction #185

The owner selected first interaction starts and applies the same action, superseding #160's inert tap/hint for real games. Follow [the authoritative preview policy](../../docs/GAME_PREVIEWS.md). Validate meaningful input before synchronous runtime preparation; capture visibility identity for held callbacks and preserve attempt/lease cancellation. No appearance/scroll activation, swallowed first action, real-fixture bypass or new lifecycle owner. Keep the static empty chrome reservation and native accessible controls. Actual native/CI proof remains pending in the owning PR.

## Varied Chess validation #177

DEBUG-only `-sidequest-chess-catalog <id>` paired with an existing `-sidequest-chess-white-fixture` or `-sidequest-chess-black-fixture` route loads the separate immutable original catalog off the UI actor and selects that exact puzzle for the same composed Chess controller. Reject missing IDs, unknown IDs, or color mismatches through the ordinary fixture failure path. This route supplies real rendered 3×3/5×5 verification without changing normal startup, historical fixtures, production selection, or Release loading. Example: `-sidequest-chess-black-fixture -sidequest-chess-catalog hard-five-black -sidequest-large-text`. Rules, move tables, timing, feedback, and lifecycle remain real; no injected win or test-only game behavior.

## Memory workload validation #178

Only DEBUG with the existing finite `-sidequest-memory-fixtures` route and an additional `-sidequest-memory-three-pairs` or `-sidequest-memory-four-pairs` argument selects a frozen original seed178 challenge through the actual challenge-aware controller. Three takes precedence if both modifiers are supplied. Normal production, the six-pair fixture, integration fixtures, and generation RNG remain unchanged; Release ignores these modifiers. This narrow verification seam does not expose production difficulty labels or mixed-tier feed distribution.

## Mixed difficulty rollout #201

Agent-grill self-assessment: game-owned challenge APIs certify immutable tiers; legacy descriptors and generators remain supported. Normal app composition explicitly opts into mixed generation. Each game occurrence cycles Easy/Medium/Hard using a session-seeded per-kind offset; challenge RNG uses isolated streams while historical generation draws and batch shuffle order are retained. Load the separate Chess catalog once with startup fixtures and retain it through imports/replenishment.

Reconstruction validates descriptor kind/tier and completed archive compatibility before creating invisible adapters. Window preparation stages replacements and archives before retiring existing owners; navigation stages selection before accepting a fallible window. Failure keeps the current selection, owners, descriptors, and completion, and exposes Retry games. Initial preparation/import must reject invalid descriptors before persistence. No fallback may silently discard completion or claim an uncertified tier. Native compilation, actual mixed-tier journeys, and exact-head CI remain pending in the owning PR.

Readiness evidence: GeneratedGameBatch preserves legacy RNG; MemoryController's typed restoration throws on mismatched completed layout; FeedSelection is a value and supports staged navigation; game metadata is immutable. Planned verification covers all tiers, retry/cancellation, completed eviction/restoration, unchanged cadence, and normal/largest label geometry. No human-owned behavior or spending question remains.

The lead accepted a bounded main-actor reconstruction closure at the real fallible adapter boundary, defaulting to ComposedGame.generated. Tests may inject preparation failure to verify concrete-owner/attempt preservation and retry; no unsafe archive setter or alternate production lifecycle owner is introduced.

### Readiness self-assessment #201

| Question | Kind | Selected answer | Evidence and rationale | Verification needed |
| --- | --- | --- | --- | --- |
| Where does production opt into classified cards? | Technical choice | App-owned preparation closure; direct defaults and historical Debug routes stay legacy. | GeneratedGameBatch preserves the historical random stream; all four game-owned tier APIs exist. | Native all-tier, cross-batch, and legacy shuffle checks. |
| How does throwing restoration cross the navigation boundary? | Fact and technical choice | Validate typed descriptor/archive compatibility, stage invisible adapters, then commit owners and selection. | MemoryController rejects an incompatible completed layout; FeedSelection is a value. | Concrete factory rejection, preserved current owner/attempt, retry and completed eviction tests. |
| When is the separate Chess catalog loaded? | Technical choice | Once during off-UI startup, retained with historical fixtures for imports and replenishment. | ChessPuzzleLoader exposes separate historical and classified resources; FeedComposition retains its immutable input array. | Startup/replacement integration and missing-catalog rejection. |
| How are titles and difficulty labels stable? | Technical choice | Shared persistent header measures all supported text footprints at current width/type. | Header #199 already reserves all titles; GameHeading adds all tier subtitles without phase dependence. | Actual normal/largest label and control geometry. |
| Does any choice need new owner approval? | Fact | No. | #118 already accepts mixed labeled tiers; #201 records bounded integration and no new Ideas or spending. | Fresh review and exact-head free CI remain delivery gates. |

The plan is ready within delegated scope; these answers establish implementation choices, not passing native evidence or independent review.

Restored Bubble aim validates the controller’s exact closed degree range [-60,60]. Converting the radians limit back into degrees rounds slightly below60 and rejects legitimate endpoint witnesses, preventing completed reverse navigation. Preserve exact endpoint acceptance and reject nonfinite/out-of-range archives; the regression exercises reconstruction and Replay, not weakened navigation assertions.

## Private live news #213

The owner authorized implementation and personal image testing on October 6. Normal cold launch uses official Tagesschau RSS, without a fictional fallback or loading saved imports. Games prepare independently of network access. Refresh on foreground activation, retaining the last valid in-memory feed on failure; no article/image archive or disk URL cache. Keep saved private imports intact. A successful explicit import selects manual news for the current session and invalidates live refresh; the next launch selects Tagesschau again. Public distribution remains outside this personal test.

Readiness used the project agent-grill with `/root/tagesschau_readiness`: source metadata supplies images/complete credits, so no article scraping is needed. Refresh changes news payloads/pool synchronously in the existing composition, preserving appearance IDs, selection, all game owners/challenges/completions, and cadence count. An initially offline/pending feed is games-only; articles enter at future five-game generation boundaries, without retroactive deck insertion. Bound ephemeral HTTPS transport and external XML/HTML parsing; tests use original offline fixtures. See [private news decisions](../../docs/TAGESSCHAU.md).
