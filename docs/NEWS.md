# Import news snapshots

The app reads short, manually selected news excerpts offline. It does not fetch or rewrite articles. Real original links open through iOS when you choose to read the source. Fresh normal startup also offers 30 original fictional demo stories when saved news is genuinely absent; samples carry an explicit label and a truthful placeholder-link action. See [DEMO_NEWS.md](DEMO_NEWS.md).

## Try the demo pool on an existing install

Valid saved imports take priority over demos, including saved fictional fixtures. An intentionally empty import stays games only. To choose the full demo pool yourself, transfer [demo-news.json](../Sidequest/Resources/demo-news.json) from `Sidequest/Resources` to Files, open **News snapshots**, and use **Import news JSON** to select that file. This is the ordinary explicit replacement: it replaces the saved set and starts a new session, with the same validation, atomic save, and error/cancellation behavior. Keep a private copy of any existing captures you want to restore later. No app reset or automatic overwrite is required.

## Prepare a file

Copy [sample-news.json](../Sidequest/Resources/sample-news.json) to ignored `.local-news/snapshots.json` and edit that local copy. Keep real captures out of `Sidequest`, test roots, tracked fixtures, screenshots attached to PRs, and release assets. The repository's [schema](../Sidequest/Resources/news-snapshot.schema.json) documents version 1; app validation is authoritative for source URLs, dates, size, and duplicate IDs.

The top-level object has `schemaVersion: 1` and a `snapshots` array. Each snapshot needs:

| Field | Value |
| --- | --- |
| `id` | Unique, stable, nonblank string; use a source-based news ID rather than its position. Production retains this source ID separately from unique repeated feed-appearance IDs and validates actual appearance collisions; it reserves no arbitrary news-ID prefix. The finite release/Debug integration route reserves its five `sample-game-*` IDs. See [endless identity](ENDLESS.md). |
| `headline`, `excerpt`, `publisher` | Nonblank strings. Preserve the source-provided excerpt and attribution; no full-article extraction or AI rewriting. |
| `sourceURL` | Absolute HTTP(S) original article URL with a host. |
| `capturedAt` | Actual capture timestamp in ISO 8601 with a time zone, such as `2026-10-03T19:00:00Z`; fractional seconds are accepted. Use the full RFC 3339 form (four-digit year 0001–9999, valid proleptic Gregorian date, hours 00–23, minutes/seconds 00–59, and Z or a valid signed hours:minutes offset). Year 0000 and leap-second values are unsupported. |
| `publishedAt` | Optional publication timestamp, or null when the precise time is unknown. Never invent an exact time from a day-only source date. |
| `isSample` | `true` for fictional examples; `false` for real source snapshots. |

Use distinct IDs, JSON booleans, and no comments/trailing commas. Files may be up to 1 MiB. The file is a whole replacement set; an empty array intentionally removes all saved news. The schema accepts field formats; the app also rejects invalid hosts/timestamps and duplicated IDs with actionable errors. Personal test content does not become a licensed production feed.

## Import, validate, and replace

1. Transfer the JSON file to Files on your iPhone, such as through AirDrop. In the simulator, use its Files/iCloud Drive location or Simulator's file-sharing facilities to make the file accessible.
2. Open **News snapshots** (the newspaper button in the feed header), choose **Import news JSON**, and select the file. The app validates the original bytes and prepares the complete real-game/news replacement before atomic saving. Success replaces the session, shuffles games only, and cycles the unchanged news pool after every five games across appended batches. Revisits preserve appearance identity and prior history. Errors or canceled selection preserve its current order, position, completed results, and saved news. Opening the library resets unfinished play, as leaving its card does.
3. Read the source, capture date, optional publication date, and sample label on each card. Use **Read original article** for real snapshots, or **Open sample placeholder** for fictional content. The news cards work offline; opening an external source needs whatever access that publisher requires.
4. To replace the set, import another file. Valid snapshots are stored in the app's local Application Support directory and restored on relaunch. No accounts, syncing, or backend are involved. With confirmed missing storage, current source uses the bundled demo pool without writing it to disk. An intentionally empty set supplies endless games only. The recorded finite MVP release contains five game cards. Corrupt or unavailable saved news leaves games playable, preserves the damaged bytes, and shows an error with library retry/import actions. Corrupt/unavailable storage never activates the demo pool. Startup and library retry share the same nil-only resolver. Successful imports preserve the exact validated JSON bytes, including timestamp precision.

The library uses the retained startup/import model; opening, closing, or reopening it does not reload or reshuffle the feed. The same outer feed updates after an import, retires its previous controllers, and blocks unfinished animation/mismatch results from old attempts. Background/foreground cannot enable input while the library is open. The DEBUG-only standalone **Read news** route remains for older fixture tests; Release ignores it. See [INSTALL.md](INSTALL.md) for source signing and native Files access. Physical-iPhone execution remains deferred and unverified under #79.
