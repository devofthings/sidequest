# Feed ownership

`Domain` owns deck/session behavior; presentation consumes domain values and shared lifecycle effects. See [CONTRACT.md](../../docs/CONTRACT.md) and [source ownership](../../docs/STRUCTURE.md).

Build and store a shuffled deck once per deliberate session creation using injected randomness. Rendering never reshuffles it. Reject duplicate card IDs rather than dropping content; multiple cards of the same game kind are valid when their IDs differ. Visibility means the host's selected card, not SwiftUI appearance. Feed presentation and background handling follow issue #3, not the contract's sample launch view.
