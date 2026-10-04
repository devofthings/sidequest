# News ownership

`Domain/NewsSnapshot` is the immutable pure Swift value defined in [CONTRACT.md](../../docs/CONTRACT.md). Adapters validate/decode files; presentation depends inward and shows source provenance. Real captures stay outside Git and all synchronized source roots.

## Import decisions for #4

The implementation agent conducted the [agent-grill](../../.agents/skills/agent-grill/SKILL.md) question review as a self-assessment while other agents owned feed/CI work.

| Question | Kind | Decision and rationale | Verification |
| --- | --- | --- | --- |
| How do private captures reach a phone without entering a release? | Delegated technical choice | Native Files picker imports a versioned JSON document. Save the validated set atomically in Application Support; bundle only fictional samples/schema. Avoid a build-time personal-data copy step. | Decode/save/reload/absent-folder/failed-import tests; running-app picker and cards. |
| How is input bounded and validated? | Delegated technical choice | Version 1 contains snapshots; core validation plus duplicate-ID rejection. Limit files to 1 MiB before reading and after decoding; accept the full-string RFC 3339 zoned ISO 8601 form with optional fractional seconds, limited to years 0001–9999. Year 0000 is explicitly unsupported. Validate proleptic Gregorian month lengths and century leap rules, then count epoch days directly to avoid Foundation’s historical calendar cutover; validate offset ranges before constructing a Date; never normalize invalid source dates. Leap-second values are rejected because the selected Date representation does not retain them. Errors identify fields/schema without echoing article contents. | Missing/blank fields, wrong types/schema, URLs/dates/duplicates/size and successful round trips. |
| Who owns file I/O and cancellation? | Delegated technical choice | `LocalNewsStore` explicitly uses `@concurrent` on the verified Swift compiler. The view owns/cancels its import task; the model serializes operations and updates on MainActor. Persist the original validated JSON bytes atomically to preserve source timestamp precision and text; failed reads/validation preserve the previous set. | Actual Swift 6 build, storage and model failure/cancellation tests. |
| Does this choose a news provider or automate retrieval? | Fact | No. Manual source-provided excerpts and original links remain the accepted MVP input. Import selection replaces the complete saved set, including an intentionally empty array. | Offline fixture/UI checks; no network client, API key, scraper, or rewriting added. |

`NewsCardContent(snapshot:)` is the unwrapped feed-injected surface: readable headline/excerpt, publisher, captured/publication dates, explicit sample label, and an accessible original-link action. Integration #9 opens `NewsLibraryView` from the mixed feed with its retained model; successful imports replace the deck through the prepared transaction below. The standalone Debug preview remains a separate test route. See [NEWS.md](../../docs/NEWS.md) for the format and privacy boundaries.

The DEBUG-only `-sidequest-news-fixtures` test argument selects a fresh temporary store, so repeatable UI checks never read or replace a user's saved captures. Only that explicit argument restores bundled fictional samples when storage is absent. A saved empty array stays empty; normal missing storage supplies no news.

Issue #87 gives the feed one owned native content scroller per page. `NewsCardView` wraps shared `NewsCardContent` in a SwiftUI ScrollView only for the standalone library. Feed composition injects the unwrapped content to preserve explicit nested-scroll arbitration without duplicating provenance or source-link presentation.

## Transaction decisions for #9

The delegated [agent-grill](../../.agents/skills/agent-grill/SKILL.md) readiness interview settled the following boundaries before implementation:

- `NewsSnapshotStorage` is a Sendable asynchronous port. `LocalNewsStore` keeps file operations off MainActor using `@concurrent`. Saving replaces the original validated bytes atomically or preserves the old document. After a durable write succeeds, the store must return success rather than report cancellation; otherwise the caller could retain an obsolete feed after changing disk state.
- `loadSavedSnapshots()` reads immutable data without changing observable model state or claiming `isBusy`. The app startup owner checks its generation before calling synchronous `adoptRestored`; the model does not own another startup generation or retain that coordinator. Adoption with an error message leaves restoration retryable.
- Imports validate the original document, check cancellation, synchronously prepare the complete replacement, check cancellation again, and then save. Preparation may fail before persistence. After save succeeds, snapshot adoption and the prepared nonthrowing commit execute in one MainActor turn with no suspension or cancellation check. A canceled task still completes that durable transaction exactly once.
- Standalone `restore()` serializes with imports, checks cancellation before adoption, and leaves failed or canceled attempts retryable. The production library uses the app startup owner's adopted state rather than starting a competing restoration. Missing or intentionally empty news remains a valid empty set.

Controlled offline tests prove immutable late reads cannot adopt state, failed preparation/save preserve the previous set, restoration retry and serialization work, cancellation before save preserves data, and cancellation after durable save commits once. Actual transaction test evidence belongs to the issue handoff; shared app integration remains with the composition owner.

## Asynchronous replacement #104

Capture the originating session/request before the first import/load await. Prepare all fallible generated-game/news state before persistence. Recheck identity after suspension, then exclusively acquire the main-actor save/adoption lease. Always release it on failure or after commit. After successful durable save, synchronously adopt news and feed even if canceled; no new check/throw/await may split that boundary. Imported stories appear once per session under the stated default. Exact initial game-ID collisions reject; later generated collisions skip that game sequence instead of banning a news-ID prefix. See [ENDLESS.md](../../docs/ENDLESS.md).

## Demo news and cadence #106

Bundle 30 original clearly fictional demo stories separately from the legacy two samples. Resolve only confirmed missing storage to demos, never empty/corrupt/unavailable data, and never persist demos automatically. Preserve import bytes and source IDs, and use truthful sample labels/source-placeholder wording. See [demo news policy](../../docs/DEMO_NEWS.md).
