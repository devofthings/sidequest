# Import news snapshots

The app reads short, manually selected news excerpts offline. It does not fetch or rewrite articles. Original links open through iOS when you choose to read the source.

## Prepare a file

Copy [sample-news.json](../Sidequest/Resources/sample-news.json) to ignored `.local-news/snapshots.json` and edit that local copy. Keep real captures out of `Sidequest`, test roots, tracked fixtures, screenshots attached to PRs, and release assets. The repository's [schema](../Sidequest/Resources/news-snapshot.schema.json) documents version 1; app validation is authoritative for source URLs, dates, size, and duplicate IDs.

The top-level object has `schemaVersion: 1` and a `snapshots` array. Each snapshot needs:

| Field | Value |
| --- | --- |
| `id` | Unique, stable, nonblank string; use a source-based news ID rather than its position. |
| `headline`, `excerpt`, `publisher` | Nonblank strings. Preserve the source-provided excerpt and attribution; no full-article extraction or AI rewriting. |
| `sourceURL` | Absolute HTTP(S) original article URL with a host. |
| `capturedAt` | Actual capture timestamp in ISO 8601 with a time zone, such as `2026-10-03T19:00:00Z`; fractional seconds are accepted. Use the full RFC 3339 form (four-digit year, valid Gregorian date, hours 00–23, minutes/seconds 00–59, and Z or a valid signed hours:minutes offset). Leap-second values are unsupported. |
| `publishedAt` | Optional publication timestamp, or null when the precise time is unknown. Never invent an exact time from a day-only source date. |
| `isSample` | `true` for fictional examples; `false` for real source snapshots. |

Use distinct IDs, JSON booleans, and no comments/trailing commas. Files may be up to 1 MiB. The file is a whole replacement set; an empty array intentionally removes all saved news. The schema accepts field formats; the app also rejects invalid hosts/timestamps and duplicated IDs with actionable errors. Personal test content does not become a licensed production feed.

## Import, validate, and replace

1. Transfer the JSON file to Files on your iPhone, such as through AirDrop. In the simulator, use its Files/iCloud Drive location or Simulator's file-sharing facilities to make the file accessible.
2. Open Sidequest's **Read news** preview, choose **Import news JSON**, and select the file. Selection validates it before saving; errors keep the previous set. Canceling the picker changes nothing.
3. Read the source, capture date, optional publication date, and sample label on each card. Use **Read original article** to open its original URL. The news cards work offline; opening an external source needs whatever access that publisher requires.
4. To replace the set, import another file. Valid snapshots are stored in the app's local Application Support directory and restored on relaunch. No accounts, syncing, or backend are involved. With no saved file, the app shows explicitly fictional bundled examples. Corrupt saved input shows an error rather than silently presenting samples as real news.

The preview is an implementation/testing route; the feed integration in #9 will compose this news surface and importer with games. Install/build instructions are in [INSTALL.md](INSTALL.md). Physical-iPhone execution remains unverified until a connected signed device is tested.
