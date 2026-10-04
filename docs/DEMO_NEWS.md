# Demo news and feed cadence

## Approved scope and status

On October 4, 2026, the owner requested more fake articles for realistic private testing, one article after four or five games, and removal of the bottom card counter in [#106](https://github.com/devofthings/sidequest/issues/106). The lead chose five within that range. This supersedes #104's initial news-once default and global mixed-card shuffle; game order remains shuffled. The initial implementation is in progress, not verified delivery. Current merged #104 source passed all 151 tests and main verification. The immutable `2026.10.14` download remains the historical finite MVP.

## Product policy

Use 30 original English demo stories, approximately 80–140 words each, to try the reading/playing habit without importing real articles first. Keep them distinct from the existing two-story test sample asset. Label fictional content visibly, use a fictional publisher and per-story example.com placeholder URL, retain a fixed authored capture timestamp, and invent no real publication or quotation. Sample links must use truthful placeholder wording. No live fetching or paid generation is introduced.

Normal startup uses demo stories only when the saved document is genuinely absent. Never write the demo to personal storage automatically. Saved empty news stays intentionally empty and produces games only; valid saved/imported news replaces the demo pool. Existing corrupt or unavailable storage remains an error with games available and recovery feedback. An invalid bundled demo resource fails visibly and retryably; it cannot fabricate successful restoration. Startup and retry use consistent resolution. Legacy finite Debug routes preserve their explicitly recorded fixtures.

When a pool is available, place one news card after exactly five game cards, across initial composition and every later batch. Cycle demo or imported stories in validated input order; only games shuffle. Revisiting existing history consumes no news and changes no prior card. An empty pool permits games only. Keep manual paging, explicit Tap to play, unfinished reset, completed revisits, and bounded nearby heavy owners.

Remove the visible bottom card counter completely. Preserve readable accessibility, existing navigation actions, native gesture arbitration, content scrolling, and game controls. Tests observe actual settled card identity through accessibility identifier metadata and semantic content; do not add a hidden numeric counter or expose raw IDs as spoken values.

## Technical readiness decisions

Interviewee: `/root`; read-only interviewer: `/root/plan_demo106`, using the tracked agent-grill skill against main `49bf466773af3b5d8db3321e010aeb64934dda36` and live #106. These are delegated technical choices within the owner's feature request, not fabricated human replies.

| Question | Kind | Selected answer and rationale | Planned verification |
| --- | --- | --- | --- |
| How are stories separated from appearances? | Technical choice | Pure `FeedNewsCard` owns an appearance ID and unchanged `NewsSnapshot`; legacy finite appearances may default to the snapshot ID. Repeated display cannot rewrite imported article IDs or bytes. | Equal source snapshots with unique repeated appearance IDs; actual appearance collisions; source ID resembling a game remains valid in the endless feed. |
| How is cadence carried across generation? | Technical choice | Keep eight-game generation batches. A pure cadence value carries partial game count, pool cursor, and appearance ordinal. Prepare full additions and next state, then commit only with a validated current append. | Varied batch boundaries, pool cycling, long traversal, stale/canceled generation, failure/retry and immutable history. |
| Can absence be inferred from `fileExists`? | Fact and necessary refinement | The storage port distinguishes nil, empty, and errors, but its Boolean existence probe cannot prove absence. Classify actual confirmed missing-file conditions; preserve unavailable or invalid existing paths as errors. | Actual adapter cases for missing, valid, empty, corrupt, oversized, unreadable/invalid paths and dangling links. |
| What happens at save/adoption? | Existing requirement | Preserve origin-before-read, asynchronous fallible preparation, exclusive save/adoption lease, and synchronous nonthrowing adoption after durable success. | Existing import races and durable-cancellation coverage plus cadence-bearing replacements. |
| How are UI tests synchronized? | Technical choice | Use settled selected-card identity and semantic content/nav bounds throughout all affected suites. Keep human-readable accessibility speech and remove the counter in every feed mode. | Native mixed demo batches, canceled drags, real game interaction, largest text and actual Reduce Motion; existing assertions retain their meaning. |

Read [ENDLESS.md](ENDLESS.md), [NEWS.md](NEWS.md), and [FEED.md](FEED.md) for existing generation, retention, import and native-page boundaries. Update their current contracts in this PR, while preserving explicitly historical fixture and release evidence. Implement first, then add meaningful tests under the accepted non-TDD policy.

## Verification and handoff

Local builds, relevant unit/UI tests, formatting, resource/source discovery and documentation checks remain pending. Fresh independent complete review, full exact-head CI, the normal tracked merge gate, and main verification are required. Physical-device execution remains deferred under #79 and personal feedback #10 is still owner-dependent. Publication is manual and is not part of this ticket; no paid service, backend, recurring run, additional game, or copied article is authorized.
