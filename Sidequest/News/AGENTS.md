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

`NewsCardContent(snapshot:)` is the unwrapped feed-injected surface: readable headline/excerpt, publisher, captured/publication dates, explicit sample label, and an accessible original-link action. `NewsLibraryView` supplies the standalone importer/preview route until integration #9 wires imports into the mixed deck. See [NEWS.md](../../docs/NEWS.md) for the format and privacy boundaries.

The DEBUG-only `-sidequest-news-fixtures` test argument selects a fresh temporary store, so repeatable UI checks never read or replace a user's saved captures. Production storage is unchanged.

Issue #87 gives the feed one owned native content scroller per page. `NewsCardView` wraps shared `NewsCardContent` in a SwiftUI ScrollView only for the standalone library. Feed composition injects the unwrapped content to preserve explicit nested-scroll arbitration without duplicating provenance or source-link presentation.
