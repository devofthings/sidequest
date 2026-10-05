# Visible inactive game boards

Issue [#88](https://github.com/devofthings/sidequest/issues/88) clarifies the owner’s accepted Tap to play behavior: the actual board is visible before starting. Issue [#160](https://github.com/devofthings/sidequest/issues/160) supersedes the dedicated above-board button: a lightweight top-row "Tap to play" hint accompanies a transparent tap surface over game content, with no opaque cover. Preview is still an inactive lifecycle phase; rendering does not start an attempt or accept input.

## Ownership and reset

The feed renders its existing retained game closure in every phase and disables preview gameplay. `GameRuntime` remains the only lifecycle authority; controller gates still reject programmatic or stale input. Views read state without creating controllers or generating challenges.

Sudoku retains an immutable initial `SudokuBoard` and derives `displayedBoard` from playable state or that initial value. Its playable board and selection stay nil before explicit start and after reset. Only givens appear in the preview.

Memory invokes its injected pure board factory once during controller composition, retains the frozen initial value, and derives `displayedRules` from playable state or that value. Every start copies the same face-down rules without flipping. Reset cancels the mismatch task before clearing playable rules. Hidden accessibility labels disclose only card numbers. This also freezes finite Debug layouts, superseding their older per-start shuffle description; generated production cards already had frozen layouts.

Chess renders the validated puzzle board when its attempt is absent, for both colors. Its existing selection/coordinate gates remain inactive before start. Bubble already retains its configured reset board and launcher; aim/fire remain disabled and no flight task is created before start. Completed values, inactive restoration, and Bubble Replay retain their existing contracts.

All phases use the same top anchor. The feed’s measured hint row hides its reservation from accessibility and input after starting while retaining its natural size. The hint uses an ordinary semantic button styled as informational text, labeled Start game for assistive and keyboard activation. A transparent UIKit tap surface exists only over inactive game content; the native recognizer waits for ancestor scrolling/paging pans to fail. Its first tap cannot reach the disabled board. News and viewport navigation remain outside that surface. A presentation-only visibility identity invalidates held start requests after real visibility changes or retirement; redundant visibility updates preserve a deliberate tap. Starting or completing removes the surface and cannot make it intercept active controls or Replay. This prevents the start action’s removal from moving the board, including at accessibility text sizes. Overflow uses the existing owned card scroller, with no additional scrolling surface.

## Implementation question review

The implementation agent used the project-local agent-grill self-assessment together with the lead’s independent readiness review. All prerequisites were merged before edits. No human-owned decision or spending choice remains open.

| Question | Kind | Settled answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| Can preview visuals use a real attempt? | Fact | Keep playable state absent and use immutable game-owned initial values. | CONTRACT.md’s explicit-start/input gate and issue #88 forbid starting for rendering. Chess/Bubble already expose initial inactive values. | Controller regressions inspect display values, nil attempts and rejected input; native checks remain lead-owned. |
| When does Memory choose its layout? | Delegated technical choice | Freeze the pure factory once during composition, reuse for every start/reset. | Production challenges already freeze before publication; an init-owned value also prevents finite preview/start reshuffling without view effects. | Factory-count, display/start equality and stale-delay tests. |
| How does starting preserve board position? | Delegated technical choice | Render one adapter in all phases, anchor at the top and retain the measured start footprint. | #108 requires stable game geometry; removing an unreserved start button would shift every board. | Explicit running-app preview/start frame comparison at ordinary/largest text. |
| Does preview need a new lifecycle or protocol? | Delegated technical choice | Use existing concrete controllers and derived display values. | One retained GameRuntime already owns every transition; there is no new replaceable boundary. | Existing feed/controller completion and reset tests remain applicable. |
| How broad is routine native verification? | Accepted owner decision | All unit tests and the existing three UI smoke cases; preview checks are explicit extended cases. | TESTING.md owns the temporary pre-design gate. | Exact-head PR CI and separately requested focused GamePreviewTests, with actual outcomes recorded by the lead. |

## Evidence boundary

The author performs formatting and offline tooling/documentation checks. The lead runs actual native compilation, exact-head PR verification and the focused running-app cases, then inspects their retained normal/largest-text screenshots. Final outcomes belong in the issue/PR evidence; this document does not certify unexecuted checks. Device VoiceOver, physical iPhone, and iOS 17 execution remain unverified. The existing finite MVP download is unchanged.

## Surface-start implementation question review #160

The implementation author and lead used agent-grill before edits. Shared feed composition is the fact-backed start boundary; no game rules or new lifecycle are needed. The lead selected top-row informational styling because it keeps the actual board unobscured and preserves a separate reachable semantic activation. A transparent UIView with a one-touch UIKit tap recognizer intercepts only preview content. Its own delegate waits for existing ancestor scroll-view pans to fail, without changing UIKit's pan delegates or adding a feed-pan exclusion marker. Canceled/dragged touches cannot recognize a tap. A request captures runtime visibility identity at touch receipt and checks it again before starting, blocking hide/return and retirement callbacks. The same real game view remains disabled until explicit start; no initiating value, flip, selection, aim, or shot is forwarded.

Meaningful unit coverage checks one inert start, duplicate activation, hidden/returned stale requests, idempotent visibility, completion, and retirement through actual runtime/controller interfaces. Root-owned running-app coverage must establish all-game surface taps, real drag/pan cancellation, largest owned scrolling, accessible activation, reset, and stable board/control geometry. These are planned checks until actual results appear in the issue/PR. The existing three-case required UI smoke policy stays unchanged.
