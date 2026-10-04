# Integrated session tests

Use production `FeedSessionState`, throwing `FeedComposition`, and the News storage port. Controlled continuation gates simulate noncooperative stale startup success/error, cancellation during read, corrupt-news recovery, and modal/scene/session retirement without sleeps. Verify complete real card membership, exact reserved IDs, one shuffle, inactive preparation, and synchronous commit ordering. Fixtures remain original fictional data; real captures never enter test bundles.

## Endless session checks

`EndlessFeedTests` owns seeded generation sweeps, thousands of navigation steps, bounded adapters/hosted-owner release, all-game completed restoration including Bubble loss/Replay, frozen reset, and exact initial/future ID collision behavior. `EndlessConcurrencyTests` suspends actual preparation/read/save dependencies to verify cancellation, stale origin, retry, and the exclusive durable-save/adoption lease without noncooperative results mutating a newer session. Finite historical session checks select `useEndless: false` explicitly.
