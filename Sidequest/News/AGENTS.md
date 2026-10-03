# News ownership

`Domain/NewsSnapshot` is an immutable validated value in the pure Swift inner layer. Adapters decode inputs and presentation renders the value; see [CONTRACT.md](../../docs/CONTRACT.md).

Require nonblank ID, headline, excerpt, publisher, absolute HTTP(S) source URL with a host, and a finite captured timestamp. Publication time is optional. Preserve source text and timestamps; do not fabricate chronological constraints or rewrite excerpts. `isSample` is explicit and required so fictional content can be labeled. Decoder configuration belongs to the adapter; manual-import schema and source-link UI follow #4. Real captures stay outside Git and all synchronized source roots.
